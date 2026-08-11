import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myn_seller_app/my_theme.dart';
import 'package:myn_seller_app/myn_palette.dart';
import 'package:myn_seller_app/repositories/business_category_repository.dart';
import 'package:myn_seller_app/repositories/menu_scan_repository.dart';

/// Photograph a menu, review what was read off it, then save the approved rows
/// to the stocklist.
///
/// The review step is deliberate: a misread price would otherwise go straight
/// to customers. Nothing is written until the seller taps Save.
class MenuScanScreen extends StatefulWidget {
  @override
  _MenuScanScreenState createState() => _MenuScanScreenState();
}

enum _Stage { pick, scanning, review, saving }

class _MenuScanScreenState extends State<MenuScanScreen> {
  final ImagePicker _picker = ImagePicker();

  /// Roughly what one generated image costs at the configured size. Shown on
  /// the button because a 40-item menu is a real amount of money, unlike the
  /// scan itself which is a rupee or two.
  static const double _rupeesPerImage = 6;

  static const List<String> _statuses = ["Active", "Inactive"];

  _Stage _stage = _Stage.pick;
  String? _error;
  String _notes = "";
  File? _photo;
  List<ScannedMenuItem> _items = [];
  int _savedCount = 0;

  List<ShopCategory> _categories = [];
  bool _loadingCategories = false;

  final Set<int> _expanded = {};
  final Set<int> _generating = {};
  bool _bulkGenerating = false;

  /// Decoded once per generated image. Decoding the base64 inside build() would
  /// redo the work for every card on every keystroke.
  final Map<int, Uint8List> _thumbs = {};

  ShopCategory? _categoryFor(ScannedMenuItem item) {
    for (final c in _categories) {
      if (c.name == item.category) return c;
    }
    return null;
  }

  ShopSubcategory? _subcategoryFor(ScannedMenuItem item) {
    for (final s in _categoryFor(item)?.subcategories ?? const <ShopSubcategory>[]) {
      if (s.name == item.subCategory) return s;
    }
    return null;
  }

  Future<void> _capture(ImageSource source) async {
    try {
      final XFile? shot = await _picker.pickImage(
        source: source,
        // Menus are text-dense; too much compression makes small print
        // unreadable, so keep the image large and lightly compressed.
        maxWidth: 2400,
        imageQuality: 92,
      );
      if (shot == null) return;

      setState(() {
        _photo = File(shot.path);
        _stage = _Stage.scanning;
        _error = null;
      });

      final bytes = await shot.readAsBytes();
      final result = await MenuScanRepository().scanMenu(
        [base64Encode(bytes)],
        mediaType: _mediaTypeFor(shot.path),
      );

      if (!mounted) return;
      setState(() {
        _items = result.items;
        _notes = result.notes;
        _stage = _Stage.review;
        _expanded.clear();
      });

      await _loadCategories();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _stage = _Stage.pick;
      });
    }
  }

  /// Pulls the seller's own categories and points each scanned row at the
  /// closest one. A row that matches nothing is left unset for the seller to
  /// choose, rather than guessing and being silently wrong.
  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    try {
      final cats = await BusinessCategoryRepository().getCategories();
      if (!mounted) return;
      setState(() {
        _categories = cats;
        for (final item in _items) {
          final match = matchShopCategory(cats, item.category);
          if (match != null) item.applyCategory(match);
        }
      });
    } catch (_) {
      // A failed category fetch must not block the review — the dropdown just
      // comes up empty and the seller can still fix things on the panel.
    } finally {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  String _mediaTypeFor(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith(".png")) return "image/png";
    if (lower.endsWith(".webp")) return "image/webp";
    return "image/jpeg";
  }

  Future<void> _generateImage(int index) async {
    final item = _items[index];
    if (item.name.trim().isEmpty) {
      _toast("Give the item a name first.");
      return;
    }

    setState(() => _generating.add(index));
    try {
      final url = await MenuScanRepository().generateImage(item);
      if (!mounted) return;
      setState(() => _applyImage(index, url));
    } catch (e) {
      if (mounted) _toast(_clean(e));
    } finally {
      if (mounted) setState(() => _generating.remove(index));
    }
  }

  /// Generates for every selected row that has no image yet, one at a time so
  /// progress is visible and a mid-way failure keeps what already succeeded.
  Future<void> _generateAllImages() async {
    final targets = <int>[];
    for (int i = 0; i < _items.length; i++) {
      if (_items[i].selected && !_items[i].hasImage) targets.add(i);
    }
    if (targets.isEmpty) return;

    final confirmed = await _confirmBulkGenerate(targets.length);
    if (confirmed != true) return;

    setState(() => _bulkGenerating = true);
    int failed = 0;
    for (final i in targets) {
      if (!mounted || !_bulkGenerating) break;
      try {
        setState(() => _generating.add(i));
        final url = await MenuScanRepository().generateImage(_items[i]);
        if (!mounted) return;
        setState(() => _applyImage(i, url));
      } catch (_) {
        failed++;
      } finally {
        if (mounted) setState(() => _generating.remove(i));
      }
    }
    if (!mounted) return;
    setState(() => _bulkGenerating = false);
    if (failed > 0) _toast("$failed image(s) could not be generated.");
  }

  Future<bool?> _confirmBulkGenerate(int count) {
    final cost = (count * _rupeesPerImage).round();
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text("Generate $count images?",
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: MynPalette.heading)),
        content: Text(
          "These are illustrations created from each dish name, not photos of "
          "your own cooking. They go to MYN for approval before customers see "
          "them, and you can replace any of them with a real photo later.\n\n"
          "Roughly ₹$cost in all.",
          style: TextStyle(
              fontSize: 13.5, height: 1.45, color: MynPalette.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Cancel", style: TextStyle(color: MynPalette.muted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: MyTheme.accent_color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text("Generate"),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final approved = _items.where((i) => i.selected).toList();
    if (approved.isEmpty) return;

    final blocked = approved.where((i) => i.hasZeroPrice || i.name.trim().isEmpty);
    if (blocked.isNotEmpty) {
      _toast(
          "${blocked.length} selected item(s) still need a name and a price above zero.");
      return;
    }

    setState(() {
      _stage = _Stage.saving;
      _savedCount = 0;
    });

    int failed = 0;
    for (final item in approved) {
      try {
        final ok = await MenuScanRepository().addScannedItem(item);
        if (ok) {
          _savedCount++;
        } else {
          failed++;
        }
      } catch (_) {
        failed++;
      }
      if (mounted) setState(() {});
    }

    if (!mounted) return;
    _toast(failed == 0
        ? "Added $_savedCount item(s) to your stock"
        : "Added $_savedCount, failed $failed");
    Navigator.pop(context, _savedCount > 0);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _clean(Object e) =>
      e.toString().replaceFirst("Exception: ", "");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MynPalette.surface,
      appBar: AppBar(
        titleTextStyle: TextStyle(
            fontSize: 19, fontWeight: FontWeight.w700, color: Colors.white),
        title: Text("Scan Menu"),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: MyTheme.accent_color,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: _buildBody(),
      bottomNavigationBar: _stage == _Stage.review ? _buildSaveBar() : null,
    );
  }

  Widget _buildBody() {
    switch (_stage) {
      case _Stage.pick:
        return _buildPicker();
      case _Stage.scanning:
        return _buildScanning();
      case _Stage.review:
        return _buildReview();
      case _Stage.saving:
        return _buildSaving();
    }
  }

  Widget _buildPicker() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      children: [
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: MynPalette.blueTint,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(Icons.document_scanner_outlined,
              size: 62, color: MynPalette.blue),
        ),
        const SizedBox(height: 26),
        Text(
          "Photograph your menu",
          textAlign: TextAlign.center,
          style: TextStyle(
              color: MynPalette.heading,
              fontSize: 20,
              fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          "Every dish and price that can be read will be listed for you to check before anything is added to your stock.",
          textAlign: TextAlign.center,
          style:
              TextStyle(color: MynPalette.muted, fontSize: 13.5, height: 1.45),
        ),
        const SizedBox(height: 24),
        _tip("Lay the menu flat and fill the frame"),
        _tip("Avoid glare and shadows across the prices"),
        _tip("Photograph long menus one section at a time"),
        const SizedBox(height: 26),
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: MynPalette.redTint,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Color.fromRGBO(220, 90, 68, 0.28)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline_rounded,
                    color: MynPalette.red, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_clean(_error!),
                      style: TextStyle(
                          color: MynPalette.heading,
                          fontSize: 12.5,
                          height: 1.4)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _capture(ImageSource.camera),
            icon: Icon(Icons.photo_camera_rounded),
            label: Text("Take a photo",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: MyTheme.accent_color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _capture(ImageSource.gallery),
            icon: Icon(Icons.photo_library_outlined),
            label: Text("Choose from gallery",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: MyTheme.accent_color,
              padding: const EdgeInsets.symmetric(vertical: 15),
              side: BorderSide(color: MyTheme.accent_color, width: 1.4),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_rounded, size: 17, color: MynPalette.green),
          const SizedBox(width: 9),
          Expanded(
            child: Text(text,
                style: TextStyle(color: MynPalette.muted, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildScanning() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_photo != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child:
                  Image.file(_photo!, width: 190, height: 190, fit: BoxFit.cover),
            ),
          const SizedBox(height: 26),
          CircularProgressIndicator(color: MyTheme.accent_color),
          const SizedBox(height: 18),
          Text("Reading your menu…",
              style: TextStyle(
                  color: MynPalette.heading,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text("This can take up to a minute for a long menu.",
              style: TextStyle(color: MynPalette.muted, fontSize: 12.5)),
        ],
      ),
    );
  }

  Widget _buildSaving() {
    final total = _items.where((i) => i.selected).length;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: MyTheme.accent_color),
          const SizedBox(height: 18),
          Text("Adding to your stock…",
              style: TextStyle(
                  color: MynPalette.heading,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text("$_savedCount of $total saved",
              style: TextStyle(color: MynPalette.muted, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildReview() {
    if (_items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 52, color: MynPalette.muted),
            const SizedBox(height: 14),
            Text("Nothing readable in that photo",
                style: TextStyle(
                    color: MynPalette.heading,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              _notes.isEmpty
                  ? "Try again with more light and the menu filling the frame."
                  : _notes,
              textAlign: TextAlign.center,
              style: TextStyle(color: MynPalette.muted, fontSize: 13),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => setState(() => _stage = _Stage.pick),
              style: ElevatedButton.styleFrom(
                backgroundColor: MyTheme.accent_color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text("Try another photo"),
            ),
          ],
        ),
      );
    }

    final missingImages =
        _items.where((i) => i.selected && !i.hasImage).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: MynPalette.amberTint,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Color.fromRGBO(217, 142, 34, 0.30)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.fact_check_outlined, color: MynPalette.amber, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Check every name and price against your menu before saving. Nothing has been added to your stock yet.",
                  style: TextStyle(
                      color: MynPalette.heading, fontSize: 12.5, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        if (_notes.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(_notes,
              style: TextStyle(
                  color: MynPalette.muted,
                  fontSize: 12,
                  fontStyle: FontStyle.italic)),
        ],
        const SizedBox(height: 14),
        if (missingImages > 0) _buildGenerateAllCard(missingImages),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              "${_items.where((i) => i.selected).length} of ${_items.length} selected",
              style: TextStyle(
                  color: MynPalette.heading,
                  fontSize: 15,
                  fontWeight: FontWeight.w700),
            ),
            Spacer(),
            TextButton(
              onPressed: () {
                final allOn = _items.every((i) => i.selected);
                setState(() {
                  for (final i in _items) {
                    i.selected = !allOn;
                  }
                });
              },
              child: Text(
                _items.every((i) => i.selected) ? "Clear all" : "Select all",
                style: TextStyle(
                    color: MyTheme.accent_color, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        for (int i = 0; i < _items.length; i++) _buildItemCard(_items[i], i),
      ],
    );
  }

  Widget _buildGenerateAllCard(int count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: MynPalette.blueTint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Color.fromRGBO(58, 122, 168, 0.24)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, size: 20, color: MynPalette.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("$count item(s) have no picture",
                    style: TextStyle(
                        color: MynPalette.heading,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                    "Create illustrations from the dish names · about ₹${(count * _rupeesPerImage).round()}",
                    style:
                        TextStyle(color: MynPalette.muted, fontSize: 11.5)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _bulkGenerating
              ? TextButton(
                  onPressed: () => setState(() => _bulkGenerating = false),
                  child: Text("Stop",
                      style: TextStyle(
                          color: MynPalette.red,
                          fontWeight: FontWeight.w700)),
                )
              : ElevatedButton(
                  onPressed: _generateAllImages,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyTheme.accent_color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text("Generate",
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                ),
        ],
      ),
    );
  }

  Widget _buildItemCard(ScannedMenuItem item, int index) {
    final bool needsAttention = item.hasZeroPrice || item.confidence == "low";
    final bool open = _expanded.contains(index);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: needsAttention
                  ? Color.fromRGBO(217, 142, 34, 0.45)
                  : MynPalette.cardBorder),
          boxShadow: const [
            BoxShadow(
                color: Color.fromRGBO(16, 42, 45, 0.05),
                blurRadius: 14,
                offset: Offset(0, 6)),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 34,
                  child: Checkbox(
                    value: item.selected,
                    activeColor: MyTheme.accent_color,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (v) =>
                        setState(() => item.selected = v ?? false),
                  ),
                ),
                _buildThumb(item, index),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    initialValue: item.name,
                    onChanged: (v) => item.name = v,
                    style: TextStyle(
                        color: MynPalette.heading,
                        fontSize: 15,
                        fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: "Item name",
                    ),
                  ),
                ),
                if (needsAttention)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(Icons.error_outline_rounded,
                        size: 18, color: MynPalette.amber),
                  ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                      open
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: MynPalette.muted),
                  onPressed: () => setState(() {
                    open ? _expanded.remove(index) : _expanded.add(index);
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildCategoryDropdown(item, index),
            const SizedBox(height: 8),
            for (final v in item.variants) _buildVariantRow(item, v),
            if (open) ...[
              const Divider(height: 22),
              _buildSubcategoryDropdown(item, index),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: item.brand,
                      onChanged: (v) => item.brand = v,
                      style: TextStyle(
                          color: MynPalette.heading, fontSize: 13),
                      decoration: _fieldDecoration("Brand"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: _buildStatusDropdown(item)),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: item.description,
                onChanged: (v) => item.description = v,
                maxLines: 2,
                style: TextStyle(color: MynPalette.heading, fontSize: 13),
                decoration: _fieldDecoration("Description"),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildThumb(ScannedMenuItem item, int index) {
    final busy = _generating.contains(index);

    return GestureDetector(
      onTap: busy ? null : () => _generateImage(index),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: MynPalette.surface,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: MynPalette.cardBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: busy
            ? Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: MyTheme.accent_color),
                ),
              )
            : _thumbs[index] != null
                ? Image.memory(_thumbs[index]!, fit: BoxFit.cover)
                : Icon(Icons.auto_awesome_outlined,
                    size: 19, color: MynPalette.muted),
      ),
    );
  }

  Widget _buildCategoryDropdown(ScannedMenuItem item, int index) {
    return DropdownButtonFormField<ShopCategory>(
      // A dropdown built from `initialValue` keeps its own state, so without a
      // key that moves with the selection it would still show empty after the
      // category list arrives and auto-matched every row.
      key: ValueKey("cat-$index-${item.categoryId}-${_categories.length}"),
      initialValue: _categoryFor(item),
      isExpanded: true,
      icon: Icon(Icons.expand_more_rounded, color: MynPalette.muted, size: 20),
      style: TextStyle(color: MynPalette.heading, fontSize: 13),
      decoration: _fieldDecoration(_loadingCategories
          ? "Loading your categories…"
          // Keep the unmatched heading visible so the seller can see what the
          // menu actually said while they pick the shop's own name for it.
          : item.category.isEmpty
              ? "Category"
              : "Category — menu said “${item.category}”"),
      items: [
        for (final c in _categories)
          DropdownMenuItem(value: c, child: Text(c.name)),
      ],
      onChanged: (c) => setState(() => item.applyCategory(c)),
    );
  }

  Widget _buildSubcategoryDropdown(ScannedMenuItem item, int index) {
    final subs =
        _categoryFor(item)?.subcategories ?? const <ShopSubcategory>[];

    return DropdownButtonFormField<ShopSubcategory>(
      // Keyed on the parent category: changing it empties the subcategory, and
      // a stale value left behind would assert against the new item list.
      key: ValueKey("sub-$index-${item.categoryId}-${item.subcategoryId}"),
      initialValue: _subcategoryFor(item),
      isExpanded: true,
      icon: Icon(Icons.expand_more_rounded, color: MynPalette.muted, size: 20),
      style: TextStyle(color: MynPalette.heading, fontSize: 13),
      decoration: _fieldDecoration(subs.isEmpty
          ? "No subcategories in this category"
          : "Sub category"),
      items: [
        for (final s in subs) DropdownMenuItem(value: s, child: Text(s.name)),
      ],
      onChanged:
          subs.isEmpty ? null : (s) => setState(() => item.applySubcategory(s)),
    );
  }

  Widget _buildStatusDropdown(ScannedMenuItem item) {
    return DropdownButtonFormField<String>(
      initialValue: _statuses.contains(item.status) ? item.status : "Active",
      isExpanded: true,
      icon: Icon(Icons.expand_more_rounded, color: MynPalette.muted, size: 20),
      style: TextStyle(color: MynPalette.heading, fontSize: 13),
      decoration: _fieldDecoration("Status"),
      items: [
        for (final s in _statuses) DropdownMenuItem(value: s, child: Text(s)),
      ],
      onChanged: (s) => setState(() => item.status = s ?? "Active"),
    );
  }

  Widget _buildVariantRow(ScannedMenuItem item, ScannedVariant variant) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: TextFormField(
              initialValue: variant.unit,
              onChanged: (v) => variant.unit = v,
              style: TextStyle(color: MynPalette.muted, fontSize: 13),
              decoration: _fieldDecoration("Unit"),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue:
                  variant.price == 0 ? "" : variant.price.toStringAsFixed(2),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) => setState(
                  () => variant.price = double.tryParse(v.trim()) ?? 0),
              style: TextStyle(
                  color:
                      variant.price <= 0 ? MynPalette.red : MynPalette.heading,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700),
              decoration: _fieldDecoration("Price ₹"),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: TextStyle(color: MynPalette.muted, fontSize: 12.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      filled: true,
      fillColor: MynPalette.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: MynPalette.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: MynPalette.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: MyTheme.accent_color, width: 1.3),
      ),
    );
  }

  Widget _buildSaveBar() {
    final count = _items.where((i) => i.selected).length;

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
              onPressed: () => setState(() => _stage = _Stage.pick),
              style: OutlinedButton.styleFrom(
                foregroundColor: MynPalette.muted,
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: MynPalette.cardBorder),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text("Rescan"),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: count == 0 ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: MyTheme.accent_color,
                foregroundColor: Colors.white,
                disabledBackgroundColor: MynPalette.cardBorder,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                count == 0 ? "Nothing selected" : "Add $count to stock",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
