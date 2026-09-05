import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myn_seller_app/data_model/myn_product_response.dart';
import 'package:myn_seller_app/helpers/shared_value_helper.dart';
import 'package:myn_seller_app/my_theme.dart';
import 'package:myn_seller_app/myn_palette.dart';
import 'package:myn_seller_app/repositories/business_category_repository.dart';
import 'package:myn_seller_app/repositories/myn_barcode_repository.dart';
import 'package:myn_seller_app/screens/barcode_scan.dart';
import 'package:myn_seller_app/repositories/myn_product_repository.dart';
import 'package:myn_seller_app/ui_elements/skeleton.dart';

/// Edit one stocklist item, with the same fields as the web panel's
/// "Edit Food Item" dialog.
///
/// Replaces the legacy ProductDetails screen for MYN rows: that one fetched
/// four Laravel endpoints (details, related, top-from-seller, variant info),
/// none of which exist here, and none of its calls were guarded — so the first
/// failure left the screen spinning forever with nothing on it.
class MynProductDetail extends StatefulWidget {
  /// Null means "new item": the same form, with nothing to fetch first and a
  /// POST instead of a PATCH on save. Add and Edit ask for exactly the same
  /// fields, so giving them one screen means a change to either lands on both —
  /// the old ProductAdd screen was a second form against dead Laravel routes
  /// (`/api/v2/product/add`, `getCategoryList`) that could not load a category
  /// or save an item.
  final String? productId;
  final String? fallbackName;

  const MynProductDetail({Key? key, required this.productId, this.fallbackName})
      : super(key: key);

  /// Blank form for adding a product.
  const MynProductDetail.create({Key? key})
      : productId = null,
        fallbackName = null,
        super(key: key);

  @override
  State<MynProductDetail> createState() => _MynProductDetailState();
}

/// One editable price row. For a restaurant this is a portion — the first is
/// the default Regular price; for a hypermarket it is a variant, and the extra
/// controllers below carry the supplier, tax and commission columns the web
/// panel edits alongside it.
class _PortionRow {
  final TextEditingController unit;
  final TextEditingController price;
  final TextEditingController mrp;
  final TextEditingController supplier;
  final TextEditingController cgst;
  final TextEditingController sgst;
  final TextEditingController commission;

  _PortionRow({
    String unit = "",
    String price = "",
    String mrp = "",
    String supplier = "",
    String cgst = "",
    String sgst = "",
    String commission = "",
  })  : unit = TextEditingController(text: unit),
        price = TextEditingController(text: price),
        mrp = TextEditingController(text: mrp),
        supplier = TextEditingController(text: supplier),
        cgst = TextEditingController(text: cgst),
        sgst = TextEditingController(text: sgst),
        commission = TextEditingController(text: commission);

  void dispose() {
    unit.dispose();
    price.dispose();
    mrp.dispose();
    supplier.dispose();
    cgst.dispose();
    sgst.dispose();
    commission.dispose();
  }
}

/// One customisation choice inside an addon group — "Extra cheese, ₹30".
class _Addon {
  final TextEditingController name;
  final TextEditingController price;

  _Addon({String name = "", String price = ""})
      : name = TextEditingController(text: name),
        price = TextEditingController(text: price);

  void dispose() {
    name.dispose();
    price.dispose();
  }
}

class _AddonGroup {
  final TextEditingController name;
  final List<_Addon> addons;

  _AddonGroup({String name = "", List<_Addon>? addons})
      : name = TextEditingController(text: name),
        addons = addons ?? [_Addon()];

  void dispose() {
    name.dispose();
    for (final a in addons) {
      a.dispose();
    }
  }
}

class _MynProductDetailState extends State<MynProductDetail> {
  // Matches the web dialog. "Not Active" is the panel's third state — kept in
  // the list so editing an item already in it does not silently flip it back to
  // Active on the next save.
  static const List<String> _statuses = ["Active", "Inactive", "Not Active"];
  static const List<String> _foodTypes = ["Veg", "Non-Veg", "Egg", "Vegan"];

  final ImagePicker _picker = ImagePicker();

  bool _loading = true;
  bool _saving = false;
  String? _error;
  MynProduct? _product;

  final TextEditingController _name = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _packaging = TextEditingController(text: "0");

  /// Backs the free-text category field shown when the shop has no categories
  /// of its own yet.
  final TextEditingController _categoryText = TextEditingController();

  // Hypermarket-only fields. A restaurant dish has no brand, shop code or
  // subcategory, so the food form never draws these.
  final TextEditingController _brand = TextEditingController();
  final TextEditingController _code = TextEditingController();
  final TextEditingController _subCategory = TextEditingController();

  final List<_AddonGroup> _addonGroups = [];

  // Barcode scanning. _barcode is saved with the item so the next seller who
  // scans the same pack gets a match; _scannedImageUrl is the catalogue picture,
  // already approved, sent through as a plain URL rather than a new upload.
  String _barcode = "";
  String? _masterProductId;
  String? _scannedImageUrl;
  bool _scanning = false;
  final List<_PortionRow> _portions = [];

  String _status = "Active";
  String _foodType = "Veg";
  String _category = "";
  bool _offerActive = false;

  List<ShopCategory> _categories = [];

  /// Set when the seller picks a new photo; sent as a `data:` URL, which the
  /// update endpoint pushes to S3 before saving.
  String? _newImageDataUrl;
  File? _newImageFile;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _packaging.dispose();
    _categoryText.dispose();
    _brand.dispose();
    _code.dispose();
    _subCategory.dispose();
    for (final g in _addonGroups) {
      g.dispose();
    }
    for (final p in _portions) {
      p.dispose();
    }
    super.dispose();
  }

  bool get _isNew => widget.productId == null;

  /// Restaurants, hotels, bakeries and cafes edit dishes; everyone else edits
  /// stock lines. Same split the server makes when it chooses between
  /// RestaurantSellerProduct and SellerProduct.
  bool get _isFood => isFoodBusiness();

  Future<void> _fetch() async {
    // Nothing to load for a new item: show the empty form at once and pull the
    // categories in the background.
    if (_isNew) {
      setState(() {
        _loading = false;
        _error = null;
        if (_portions.isEmpty) _portions.add(_PortionRow(unit: "Regular"));
      });
      _loadCategories();
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = await MynProductRepository().getProduct(widget.productId!);
      if (!mounted) return;
      setState(() {
        _product = p;
        _applyToForm(p);
        _loading = false;
      });
      _loadCategories();
    } catch (e) {
      if (!mounted) return;
      // Every failure lands somewhere the seller can see and retry from,
      // instead of an endless spinner.
      setState(() {
        _error = e.toString().replaceFirst("Exception: ", "");
        _loading = false;
      });
    }
  }

  void _applyToForm(MynProduct p) {
    _name.text = p.name;
    _description.text = p.description;
    _brand.text = p.brand;
    _code.text = p.code;
    _subCategory.text = p.subCategory;
    _packaging.text =
        p.packagingCharge == 0 ? "0" : p.packagingCharge.toStringAsFixed(2);
    _status = _statuses.contains(p.status) ? p.status : "Active";
    _foodType = _foodTypes.contains(p.foodType) ? p.foodType : "Veg";
    _category = p.category;
    _categoryText.text = p.category;
    _offerActive = p.offerActive;

    for (final row in _portions) {
      row.dispose();
    }
    _portions
      ..clear()
      ..addAll(p.variants.map((v) => _PortionRow(
            unit: v.unit,
            price: v.price == 0 ? "" : v.price.toStringAsFixed(2),
            mrp: v.compareAtPrice == 0
                ? ""
                : v.compareAtPrice.toStringAsFixed(2),
            supplier:
                v.supplierPrice == 0 ? "" : v.supplierPrice.toStringAsFixed(2),
            cgst: v.cgst == 0 ? "" : _trim(v.cgst),
            sgst: v.sgst == 0 ? "" : _trim(v.sgst),
            commission: v.commission == 0 ? "" : _trim(v.commission),
          )));
    if (_portions.isEmpty) _portions.add(_PortionRow(unit: "Regular"));

    for (final g in _addonGroups) {
      g.dispose();
    }
    _addonGroups
      ..clear()
      ..addAll(p.addonGroups.map((g) => _AddonGroup(
            name: g.name,
            addons: g.addons
                .map((a) => _Addon(
                      name: a.name,
                      price: a.price == 0 ? "" : _trim(a.price),
                    ))
                .toList(),
          )));
  }

  /// 5 rather than 5.00 for percentages and whole-rupee figures, which is how
  /// the web panel shows them.
  String _trim(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  Future<void> _loadCategories() async {
    try {
      final cats = await BusinessCategoryRepository().getCategories();
      if (mounted) setState(() => _categories = cats);
    } catch (_) {
      // A failed category fetch leaves the dropdown empty; the rest of the
      // form still saves.
    }
  }

  Future<void> _pickImage() async {
    final XFile? shot = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1400,
      imageQuality: 88,
    );
    if (shot == null) return;

    final bytes = await shot.readAsBytes();
    final mime = shot.path.toLowerCase().endsWith(".png")
        ? "image/png"
        : "image/jpeg";
    if (!mounted) return;
    setState(() {
      _newImageFile = File(shot.path);
      _newImageDataUrl = "data:$mime;base64,${base64Encode(bytes)}";
    });
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      _toast(_isFood ? "Give the dish a name." : "Give the product a name.");
      return;
    }

    final variants = <Map<String, dynamic>>[];
    for (final row in _portions) {
      final unit = row.unit.text.trim();
      final price = double.tryParse(row.price.text.trim()) ?? 0;
      if (unit.isEmpty && price <= 0) continue;
      if (price <= 0) {
        _toast(
            "\"${unit.isEmpty ? 'A portion' : unit}\" needs a price above zero.");
        return;
      }
      final mrp = double.tryParse(row.mrp.text.trim()) ?? price;

      // Selling price above MRP would show customers a negative discount, and
      // the panel refuses it for the same reason.
      if (mrp > 0 && price > mrp) {
        _toast("\"${unit.isEmpty ? 'Regular' : unit}\" sells above its MRP.");
        return;
      }

      final variant = <String, dynamic>{
        "unit": unit.isEmpty ? "Regular" : unit,
        "appPrice": price,
        "base_price": price,
        "mrp": mrp,
        "compare_at_price": mrp,
      };

      // Supplier cost, the GST split and MYN's commission are hypermarket
      // columns; sending them from the food form would overwrite whatever the
      // row already carried with blanks.
      if (!_isFood) {
        final cgst = double.tryParse(row.cgst.text.trim()) ?? 0;
        final sgst = double.tryParse(row.sgst.text.trim()) ?? 0;
        variant.addAll({
          "supplierPrice": double.tryParse(row.supplier.text.trim()) ?? 0,
          "cgst": cgst,
          "sgst": sgst,
          // syncVariantPriceFields recomputes this server-side too; sending it
          // keeps the value right even if that helper is ever changed.
          "taxRate": cgst + sgst,
          "mynCommission": double.tryParse(row.commission.text.trim()) ?? 0,
        });
      }

      variants.add(variant);
    }
    if (variants.isEmpty) {
      _toast(_isFood
          ? "Add at least one portion size with a price."
          : "Add at least one variant with a price.");
      return;
    }

    setState(() => _saving = true);
    final payload = <String, dynamic>{
      "productName": _name.text.trim(),
      "description": _description.text.trim(),
      "category": _category,
      "status": _status,
      "offerActive": _offerActive,
      "variants": variants,
      if (_isFood) ...{
        "foodType": _foodType,
        "packagingCharge": double.tryParse(_packaging.text.trim()) ?? 0,
        "addonGroups": _addonGroupsPayload(),
      } else ...{
        "brand": _brand.text.trim(),
        "subCategory": _subCategory.text.trim(),
      },
      if (_newImageDataUrl != null) ...{
        "imageUrl": _newImageDataUrl,
        // Same review queue as any seller-uploaded photo.
        "imageStatus": "Pending",
      } else if (_scannedImageUrl != null) ...{
        // Came from the catalogue, where an admin already cleared it, so it
        // goes straight in rather than back through the review queue.
        "imageUrl": _scannedImageUrl,
        "imageStatus": "Approved",
      },
      if (_barcode.isNotEmpty) "barcode": _barcode,
      if (_masterProductId != null) "masterProductId": _masterProductId,
    };

    try {
      if (_isNew) {
        // categoryId travels with the name so the storefront can file the item
        // under the seller's own section rather than matching on the label.
        final match = _categories.where((c) => c.name == _category);
        if (match.isNotEmpty) payload["categoryId"] = match.first.id;

        await MynProductRepository().createProduct(payload);
      } else {
        await MynProductRepository().updateProduct(widget.productId!, payload);
      }
      if (!mounted) return;
      _toast(_isNew ? "Product added" : "Saved");
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        _toast(e.toString().replaceFirst("Exception: ", ""));
        setState(() => _saving = false);
      }
    }
  }

  /// Groups with no name and no priced addon are dropped rather than saved as
  /// empty rows the customer app would render as a blank choice.
  List<Map<String, dynamic>> _addonGroupsPayload() {
    final groups = <Map<String, dynamic>>[];

    for (final g in _addonGroups) {
      final addons = <Map<String, dynamic>>[];
      for (final a in g.addons) {
        final name = a.name.text.trim();
        if (name.isEmpty) continue;
        addons.add({
          "name": name,
          "price": double.tryParse(a.price.text.trim()) ?? 0,
          "foodType": _foodType,
        });
      }

      final name = g.name.text.trim();
      if (name.isEmpty && addons.isEmpty) continue;

      groups.add({
        "groupName": name,
        "minSelection": 0,
        "maxSelection": addons.isEmpty ? 1 : addons.length,
        "addons": addons,
      });
    }

    return groups;
  }

  void _toast(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MynPalette.surface,
      appBar: AppBar(
        titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: MynPalette.onYellow),
        title: Text(_isNew ? "Add product" : (widget.fallbackName ?? "Edit item")),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: MynPalette.brandYellow,
        systemOverlayStyle: MynPalette.overlayDark,
        iconTheme: IconThemeData(color: MynPalette.onYellow),
      ),
      body: _error != null ? _buildError() : _buildForm(),
      bottomNavigationBar:
          _loading || _error != null ? null : _buildSaveBar(),
    );
  }

  Widget _buildError() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 90, 28, 28),
      children: [
        Icon(Icons.error_outline_rounded, size: 48, color: MynPalette.red),
        const SizedBox(height: 14),
        Text("Couldn't load this product",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: MynPalette.heading,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(_error!,
            textAlign: TextAlign.center,
            style:
                TextStyle(color: MynPalette.muted, fontSize: 13, height: 1.4)),
        const SizedBox(height: 20),
        Center(
          child: ElevatedButton.icon(
            onPressed: _fetch,
            icon: Icon(Icons.refresh_rounded, size: 18),
            label: Text("Try again"),
            style: ElevatedButton.styleFrom(
              backgroundColor: MyTheme.accent_color,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  /// Scans a pack and fills in whatever MYN already knows about it.
  ///
  /// The barcode carries only a number, so everything on screen after this
  /// comes from MYN's catalogue. Price is never filled in — MRP moves, and what
  /// this shop charges is the seller's own call.
  Future<void> _scanBarcode() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScanScreen()),
    );
    if (code == null || code.isEmpty || !mounted) return;

    setState(() => _scanning = true);
    try {
      final match = await MynBarcodeRepository().lookup(code);
      if (!mounted) return;

      setState(() {
        _barcode = match.barcode;
        _scanning = false;

        if (!match.found) return;

        _masterProductId = match.masterProductId;
        if (match.name.isNotEmpty) _name.text = match.name;
        if (match.brand.isNotEmpty) _brand.text = match.brand;
        if (match.description.isNotEmpty) _description.text = match.description;
        if (match.subCategory.isNotEmpty) _subCategory.text = match.subCategory;

        // Only offer a category this shop actually has a section for; the
        // catalogue's own name may mean nothing on this storefront.
        if (match.category.isNotEmpty &&
            (_categories.isEmpty ||
                _categories.any((c) => c.name == match.category))) {
          _category = match.category;
          _categoryText.text = match.category;
        }

        if (match.unit.isNotEmpty && _portions.isNotEmpty) {
          _portions.first.unit.text = match.unit;
        }

        // The catalogue picture is already approved, so it needs no review —
        // _newImageDataUrl stays null and the existing URL is sent as-is.
        if (match.imageUrl.isNotEmpty) _scannedImageUrl = match.imageUrl;
      });

      _toast(match.found
          ? "Found: ${match.name}. Add your price."
          : "New product. Fill it in and it will be saved against this barcode.");
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _barcode = code;
        _scanning = false;
      });
      _toast(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  /// The scan button, shown only when adding: an item already in the stocklist
  /// has nothing to prefill.
  Widget _buildScanButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _scanning ? null : _scanBarcode,
        icon: _scanning
            ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(Icons.qr_code_scanner_rounded,
                size: 20, color: MyTheme.accent_color),
        label: Text(
          _scanning
              ? "Checking..."
              : _barcode.isEmpty
                  ? "Scan barcode"
                  : "Scanned $_barcode - tap to rescan",
          style: TextStyle(
              color: MyTheme.accent_color,
              fontSize: 13.5,
              fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 13),
          side: BorderSide(color: MyTheme.accent_color),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  /// A restaurant edits dishes; a hypermarket edits stock lines. The two ask for
  /// genuinely different things — portions and addons versus supplier price and
  /// GST — and the server already files them in different collections, so the
  /// app shows one form or the other rather than a union of both.
  Widget _buildForm() => _isFood ? _buildFoodForm() : _buildRetailForm();

  Widget _buildFoodForm() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        if (_isNew) ...[
          _buildScanButton(),
          const SizedBox(height: 18),
        ],
        _section("Food image"),
        _buildImagePicker(),
        const SizedBox(height: 18),
        _section("Dish name"),
        _field(_name, "e.g. Chicken Biriyani"),
        const SizedBox(height: 18),
        _section("Category"),
        _buildCategoryDropdown(),
        const SizedBox(height: 18),
        _section("Food type"),
        _buildChips(_foodTypes, _foodType, (v) => setState(() => _foodType = v)),
        const SizedBox(height: 18),
        _section("Packaging charge (₹)"),
        _field(_packaging, "0", numeric: true),
        const SizedBox(height: 18),
        _section("Status"),
        _buildChips(_statuses, _status, (v) => setState(() => _status = v)),
        const SizedBox(height: 18),
        _buildDefaultPricingCard(),
        const SizedBox(height: 14),
        _buildPortionsCard(),
        const SizedBox(height: 14),
        _buildAddonGroupsCard(),
        const SizedBox(height: 18),
        _section("Description"),
        _field(_description, "Anything printed under the item", lines: 3),
        const SizedBox(height: 14),
        _buildOfferToggle(),
      ],
    );
  }

  Widget _buildRetailForm() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        if (_isNew) ...[
          _buildScanButton(),
          const SizedBox(height: 18),
        ],
        _section("Product image"),
        _buildImagePicker(),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _section("Name"),
                  _field(_name, "e.g. AVT Green Tea"),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _section("Code"),
                  // The shop code is issued by the panel when the row is
                  // created, so it is shown read-only rather than inviting an
                  // edit the server would ignore.
                  _field(_code, _isNew ? "Set after saving" : "",
                      enabled: false),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _section("Brand"),
                  _field(_brand, "e.g. AVT"),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _section("Category"),
                  _buildCategoryDropdown(),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _section("Subcategory"),
                  _buildSubcategoryDropdown(),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _section("Status"),
                  _dropdown(_statuses, _status,
                      (v) => setState(() => _status = v)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _section("Description"),
        _field(_description, "What the pack says", lines: 3),
        const SizedBox(height: 18),
        _buildVariantsCard(),
        const SizedBox(height: 14),
        _buildOfferToggle(),
      ],
    );
  }

  /// Segmented chips, as the web dialog draws Food type and Status. A dropdown
  /// hides the options behind a tap; four short words fit on one line.
  Widget _buildChips(
      List<String> options, String value, void Function(String) onChanged) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in options)
          GestureDetector(
            onTap: () => onChanged(o),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: o == value ? MyTheme.accent_color : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: o == value
                        ? MyTheme.accent_color
                        : MynPalette.cardBorder),
              ),
              child: Text(
                o,
                style: TextStyle(
                  color: o == value ? Colors.white : MynPalette.heading,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Selling price and MRP for the default Regular portion — the pair the web
  /// dialog puts above Portion sizes. They edit the first portion row directly,
  /// so the default price has one source of truth rather than two.
  Widget _buildDefaultPricingCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: MynPalette.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Default pricing",
              style: TextStyle(
                  color: MynPalette.heading,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text("Selling price is what customers pay. It cannot exceed MRP.",
              style: TextStyle(color: MynPalette.muted, fontSize: 11.5)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _section("Selling price (₹)"),
                    _field(_portions.first.price, "0", numeric: true),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _section("MRP (₹)"),
                    _field(_portions.first.mrp, "0", numeric: true),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Addon groups — Extra Toppings, Crust Type and the like.
  ///
  /// Sent as `addonGroups`, which the create and update endpoints pass straight
  /// through to RestaurantSellerProduct.
  Widget _buildAddonGroupsCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: MynPalette.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Addon groups",
                        style: TextStyle(
                            color: MynPalette.heading,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text("Customisations such as Extra Toppings or Crust Type.",
                        style:
                            TextStyle(color: MynPalette.muted, fontSize: 11.5)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _addonGroups.add(_AddonGroup())),
                icon: Icon(Icons.add_circle_rounded,
                    color: MyTheme.accent_color, size: 26),
              ),
            ],
          ),
          if (_addonGroups.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 2),
              child: Text("No addon groups yet.",
                  style: TextStyle(color: MynPalette.muted, fontSize: 12.5)),
            )
          else
            for (int g = 0; g < _addonGroups.length; g++) _buildAddonGroup(g),
        ],
      ),
    );
  }

  Widget _buildAddonGroup(int g) {
    final group = _addonGroups[g];

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: MynPalette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MynPalette.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _field(group.name, "Group name")),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 34),
                icon: Icon(Icons.delete_outline_rounded,
                    color: MynPalette.red, size: 20),
                onPressed: () {
                  setState(() {
                    _addonGroups[g].dispose();
                    _addonGroups.removeAt(g);
                  });
                },
              ),
            ],
          ),
          for (int a = 0; a < group.addons.length; a++)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                      flex: 5, child: _field(group.addons[a].name, "Addon name")),
                  const SizedBox(width: 8),
                  Expanded(
                      flex: 3,
                      child:
                          _field(group.addons[a].price, "₹", numeric: true)),
                  SizedBox(
                    width: 34,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.remove_circle_outline_rounded,
                          color: MynPalette.red, size: 20),
                      onPressed: () {
                        setState(() {
                          group.addons[a].dispose();
                          group.addons.removeAt(a);
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => group.addons.add(_Addon())),
              icon:
                  Icon(Icons.add_rounded, size: 18, color: MyTheme.accent_color),
              label: Text("Add addon",
                  style: TextStyle(
                      color: MyTheme.accent_color,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  /// Hypermarket pricing: the seven columns the web panel's "Variants & pricing"
  /// block edits, laid out over three rows so they fit a phone.
  Widget _buildVariantsCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: MynPalette.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text("Variants & pricing",
                    style: TextStyle(
                        color: MynPalette.heading,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700)),
              ),
              IconButton(
                onPressed: () =>
                    setState(() => _portions.add(_PortionRow(unit: ""))),
                icon: Icon(Icons.add_circle_rounded,
                    color: MyTheme.accent_color, size: 26),
              ),
            ],
          ),
          if (_loading)
            for (int i = 0; i < 2; i++)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Skeleton(width: 240, height: 40, radius: 10),
              )
          else
            for (int i = 0; i < _portions.length; i++) _buildVariantBlock(i),
        ],
      ),
    );
  }

  Widget _buildVariantBlock(int i) {
    final row = _portions[i];

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: MynPalette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MynPalette.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text("VARIANT ${i + 1}",
                    style: TextStyle(
                        color: MynPalette.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7)),
              ),
              if (_portions.length > 1)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 30),
                  icon: Icon(Icons.remove_circle_outline_rounded,
                      color: MynPalette.red, size: 20),
                  onPressed: () {
                    setState(() {
                      _portions[i].dispose();
                      _portions.removeAt(i);
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _labelled("Unit", row.unit, "1 kg")),
              const SizedBox(width: 10),
              Expanded(child: _labelled("MRP (₹)", row.mrp, "0", numeric: true)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _labelled("Supplier (₹)", row.supplier, "0",
                      numeric: true)),
              const SizedBox(width: 10),
              Expanded(
                  child: _labelled("App price (₹)", row.price, "0",
                      numeric: true)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _labelled("CGST (%)", row.cgst, "0", numeric: true)),
              const SizedBox(width: 10),
              Expanded(
                  child: _labelled("SGST (%)", row.sgst, "0", numeric: true)),
              const SizedBox(width: 10),
              Expanded(
                  child: _labelled("Commission (₹)", row.commission, "0",
                      numeric: true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _labelled(String label, TextEditingController c, String hint,
      {bool numeric = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section(label),
        _field(c, hint, numeric: numeric),
      ],
    );
  }

  /// Subcategories belong to the chosen category, so the list re-derives every
  /// time the category changes rather than holding a stale set.
  Widget _buildSubcategoryDropdown() {
    final match = _categories.where((c) => c.name == _category);
    final names = match.isEmpty
        ? <String>[]
        : match.first.subcategories.map((s) => s.name).toList();

    if (names.isEmpty) {
      return TextField(
        controller: _subCategory,
        style: TextStyle(color: MynPalette.heading, fontSize: 13.5),
        decoration: _decoration("Type a subcategory"),
      );
    }

    final value = names.contains(_subCategory.text) ? _subCategory.text : null;

    return DropdownButtonFormField<String>(
      key: ValueKey("sub-$_category-${names.length}"),
      initialValue: value,
      isExpanded: true,
      icon: Icon(Icons.expand_more_rounded, color: MynPalette.muted, size: 20),
      style: TextStyle(color: MynPalette.heading, fontSize: 13.5),
      decoration: _decoration(_subCategory.text.isEmpty
          ? "Choose a subcategory"
          : _subCategory.text),
      items: [
        for (final n in names) DropdownMenuItem(value: n, child: Text(n)),
      ],
      onChanged: (v) => setState(() => _subCategory.text = v ?? ""),
    );
  }

  Widget _section(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
              color: MynPalette.muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7),
        ),
      );

  Widget _buildImagePicker() {
    // A scanned match brings the catalogue picture with it, so a new item can
    // have one before it has been saved.
    final existing = _product?.imageUrl.isNotEmpty == true
        ? _product!.imageUrl
        : (_scannedImageUrl ?? "");

    return GestureDetector(
      onTap: _loading ? null : _pickImage,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MynPalette.cardBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: _loading
            ? Center(child: Skeleton(width: 110, height: 110, radius: 14))
            : _newImageFile != null
                ? Image.file(_newImageFile!,
                    fit: BoxFit.cover, width: double.infinity)
                : existing.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: existing,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorWidget: (c, u, e) => _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
      ),
    );
  }

  Widget _imagePlaceholder() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_a_photo_outlined,
                size: 32, color: MynPalette.muted),
            const SizedBox(height: 8),
            Text("Tap to upload an image",
                style: TextStyle(color: MynPalette.muted, fontSize: 12.5)),
          ],
        ),
      );

  /// Dropdown when the shop has categories, a plain text field when it has
  /// none.
  ///
  /// A DropdownButtonFormField with an empty item list will not open at all, so
  /// a seller whose shop has no ShopCategory rows yet met a control that looked
  /// tappable and did nothing — the same dead end the old add screen showed as
  /// "No Categorys Found for your Account". The backend stores `category` as a
  /// plain string, so typing one is a real answer, not a workaround.
  Widget _buildCategoryDropdown() {
    if (_categories.isEmpty) {
      return TextField(
        controller: _categoryText,
        onChanged: (v) => _category = v.trim(),
        style: TextStyle(color: MynPalette.heading, fontSize: 13.5),
        decoration: _decoration("Type a category"),
      );
    }

    final names = _categories.map((c) => c.name).toList();
    final value = names.contains(_category) ? _category : null;

    return DropdownButtonFormField<String>(
      key: ValueKey("cat-$_category-${names.length}"),
      initialValue: value,
      isExpanded: true,
      icon: Icon(Icons.expand_more_rounded, color: MynPalette.muted, size: 20),
      style: TextStyle(color: MynPalette.heading, fontSize: 13.5),
      decoration: _decoration(
          _category.isEmpty ? "Choose a category" : _category),
      items: [
        for (final n in names) DropdownMenuItem(value: n, child: Text(n)),
      ],
      onChanged: (v) => setState(() => _category = v ?? ""),
    );
  }

  Widget _dropdown(
      List<String> options, String value, void Function(String) onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: options.contains(value) ? value : options.first,
      isExpanded: true,
      icon: Icon(Icons.expand_more_rounded, color: MynPalette.muted, size: 20),
      style: TextStyle(color: MynPalette.heading, fontSize: 13.5),
      decoration: _decoration(""),
      items: [
        for (final o in options) DropdownMenuItem(value: o, child: Text(o)),
      ],
      onChanged: (v) => onChanged(v ?? options.first),
    );
  }

  Widget _buildPortionsCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: MynPalette.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Portion sizes & pricing",
                        style: TextStyle(
                            color: MynPalette.heading,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text("The first one is the default price.",
                        style: TextStyle(
                            color: MynPalette.muted, fontSize: 11.5)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () =>
                    setState(() => _portions.add(_PortionRow(unit: ""))),
                icon: Icon(Icons.add_circle_rounded,
                    color: MyTheme.accent_color, size: 26),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (_loading)
            for (int i = 0; i < 2; i++)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Skeleton(width: 240, height: 40, radius: 10),
              )
          else
            for (int i = 0; i < _portions.length; i++) _buildPortionRow(i),
        ],
      ),
    );
  }

  Widget _buildPortionRow(int i) {
    final row = _portions[i];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
              flex: 4,
              child: _field(row.unit, i == 0 ? "Regular" : "Half / Full")),
          const SizedBox(width: 8),
          Expanded(
              flex: 3, child: _field(row.price, "Price", numeric: true)),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: _field(row.mrp, "MRP", numeric: true)),
          SizedBox(
            width: 34,
            child: _portions.length > 1
                ? IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.remove_circle_outline_rounded,
                        color: MynPalette.red, size: 20),
                    onPressed: () => setState(() {
                      _portions.removeAt(i).dispose();
                    }),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferToggle() {
    return Container(
      decoration: BoxDecoration(
        color: MynPalette.amberTint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color.fromRGBO(217, 142, 34, 0.30)),
      ),
      child: CheckboxListTile(
        value: _offerActive,
        onChanged: (v) => setState(() => _offerActive = v ?? false),
        activeColor: MyTheme.accent_color,
        controlAffinity: ListTileControlAffinity.leading,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text("Mark as offer active",
            style: TextStyle(
                color: MynPalette.heading,
                fontSize: 13.5,
                fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint,
      {bool numeric = false, int lines = 1, bool enabled = true}) {
    return TextField(
      controller: c,
      enabled: enabled,
      maxLines: lines,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      style: TextStyle(
          color: MynPalette.heading,
          fontSize: 13.5,
          fontWeight: FontWeight.w600),
      decoration: _decoration(hint),
    );
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
          color: MynPalette.muted, fontSize: 13, fontWeight: FontWeight.w400),
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: MynPalette.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: MynPalette.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: MyTheme.accent_color, width: 1.4),
      ),
    );
  }

  Widget _buildSaveBar() {
    // The extra bottom inset keeps the buttons clear of the gesture handle:
    // the app draws edge to edge, so this bar sits under the system bar.
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 20 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: MynPalette.cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _saving ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: MynPalette.muted,
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: MynPalette.cardBorder),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text("Cancel"),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: MyTheme.accent_color,
                foregroundColor: Colors.white,
                disabledBackgroundColor: MynPalette.cardBorder,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.2, color: Colors.white),
                    )
                  : Text(_isNew ? "Add product" : "Save changes",
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
