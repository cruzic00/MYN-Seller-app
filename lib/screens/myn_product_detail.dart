import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myn_seller_app/data_model/myn_product_response.dart';
import 'package:myn_seller_app/my_theme.dart';
import 'package:myn_seller_app/myn_palette.dart';
import 'package:myn_seller_app/repositories/business_category_repository.dart';
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
  final String productId;
  final String? fallbackName;

  const MynProductDetail({Key? key, required this.productId, this.fallbackName})
      : super(key: key);

  @override
  State<MynProductDetail> createState() => _MynProductDetailState();
}

/// One editable price row. The first is the item's default price — what the web
/// dialog calls Selling Price / MRP; the rest are extra portion sizes.
class _PortionRow {
  final TextEditingController unit;
  final TextEditingController price;
  final TextEditingController mrp;

  _PortionRow({String unit = "", String price = "", String mrp = ""})
      : unit = TextEditingController(text: unit),
        price = TextEditingController(text: price),
        mrp = TextEditingController(text: mrp);

  void dispose() {
    unit.dispose();
    price.dispose();
    mrp.dispose();
  }
}

class _MynProductDetailState extends State<MynProductDetail> {
  static const List<String> _statuses = ["Active", "Inactive"];
  static const List<String> _foodTypes = ["Veg", "Non-Veg", "Egg", "Vegan"];

  final ImagePicker _picker = ImagePicker();

  bool _loading = true;
  bool _saving = false;
  String? _error;
  MynProduct? _product;

  final TextEditingController _name = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _packaging = TextEditingController(text: "0");
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
    for (final p in _portions) {
      p.dispose();
    }
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = await MynProductRepository().getProduct(widget.productId);
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
    _packaging.text = p.packagingCharge == 0
        ? "0"
        : p.packagingCharge.toStringAsFixed(2);
    _status = _statuses.contains(p.status) ? p.status : "Active";
    _foodType = _foodTypes.contains(p.foodType) ? p.foodType : "Veg";
    _category = p.category;
    _offerActive = p.offerActive;

    for (final row in _portions) {
      row.dispose();
    }
    _portions
      ..clear()
      ..addAll(p.variants.map((v) => _PortionRow(
            unit: v.unit,
            price: v.price == 0 ? "" : v.price.toStringAsFixed(2),
            mrp: v.compareAtPrice == 0 ? "" : v.compareAtPrice.toStringAsFixed(2),
          )));
    if (_portions.isEmpty) _portions.add(_PortionRow(unit: "Regular"));
  }

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
      _toast("Give the dish a name.");
      return;
    }

    final variants = <Map<String, dynamic>>[];
    for (final row in _portions) {
      final unit = row.unit.text.trim();
      final price = double.tryParse(row.price.text.trim()) ?? 0;
      if (unit.isEmpty && price <= 0) continue;
      if (price <= 0) {
        _toast("\"${unit.isEmpty ? 'A portion' : unit}\" needs a price above zero.");
        return;
      }
      final mrp = double.tryParse(row.mrp.text.trim()) ?? price;
      variants.add({
        "unit": unit.isEmpty ? "Regular" : unit,
        "appPrice": price,
        "base_price": price,
        "mrp": mrp,
        "compare_at_price": mrp,
      });
    }
    if (variants.isEmpty) {
      _toast("Add at least one portion size with a price.");
      return;
    }

    setState(() => _saving = true);
    try {
      await MynProductRepository().updateProduct(widget.productId, {
        "productName": _name.text.trim(),
        "description": _description.text.trim(),
        "category": _category,
        "foodType": _foodType,
        "status": _status,
        "packagingCharge": double.tryParse(_packaging.text.trim()) ?? 0,
        "offerActive": _offerActive,
        "variants": variants,
        if (_newImageDataUrl != null) ...{
          "imageUrl": _newImageDataUrl,
          // Same review queue as any seller-uploaded photo.
          "imageStatus": "Pending",
        },
      });
      if (!mounted) return;
      _toast("Saved");
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        _toast(e.toString().replaceFirst("Exception: ", ""));
        setState(() => _saving = false);
      }
    }
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
        title: Text(widget.fallbackName ?? "Edit item"),
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

  Widget _buildForm() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _section("Food image"),
        _buildImagePicker(),
        const SizedBox(height: 18),
        _section("Dish name"),
        _field(_name, "e.g. Chicken Biriyani"),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _section("Category"),
                  _buildCategoryDropdown(),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _section("Food type"),
                  _dropdown(_foodTypes, _foodType,
                      (v) => setState(() => _foodType = v)),
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
                  _section("Packaging charge (₹)"),
                  _field(_packaging, "0", numeric: true),
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
        _buildPortionsCard(),
        const SizedBox(height: 18),
        _section("Description"),
        _field(_description, "Anything printed under the item", lines: 3),
        const SizedBox(height: 14),
        _buildOfferToggle(),
      ],
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
    final existing = _product?.imageUrl ?? "";

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

  Widget _buildCategoryDropdown() {
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
      {bool numeric = false, int lines = 1}) {
    return TextField(
      controller: c,
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
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
                  : Text("Save changes",
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
