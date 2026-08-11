import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myn_seller_app/my_theme.dart';
import 'package:myn_seller_app/myn_palette.dart';
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

  _Stage _stage = _Stage.pick;
  String? _error;
  String _notes = "";
  File? _photo;
  List<ScannedMenuItem> _items = [];
  int _savedCount = 0;

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
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _stage = _Stage.pick;
      });
    }
  }

  String _mediaTypeFor(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith(".png")) return "image/png";
    if (lower.endsWith(".webp")) return "image/webp";
    return "image/jpeg";
  }

  Future<void> _save() async {
    final approved = _items.where((i) => i.selected).toList();
    if (approved.isEmpty) return;

    final blocked = approved.where((i) => i.hasZeroPrice || i.name.trim().isEmpty);
    if (blocked.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            "${blocked.length} selected item(s) still need a name and a price above zero."),
      ));
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(failed == 0
          ? "Added $_savedCount item(s) to your stock"
          : "Added $_savedCount, failed $failed"),
    ));
    Navigator.pop(context, _savedCount > 0);
  }

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
      bottomNavigationBar:
          _stage == _Stage.review ? _buildSaveBar() : null,
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
          style: TextStyle(
              color: MynPalette.muted, fontSize: 13.5, height: 1.45),
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
                  child: Text(_error!,
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
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
              child: Image.file(_photo!,
                  width: 190, height: 190, fit: BoxFit.cover),
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
              Icon(Icons.fact_check_outlined,
                  color: MynPalette.amber, size: 20),
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
        const SizedBox(height: 18),
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

  Widget _buildItemCard(ScannedMenuItem item, int index) {
    final bool needsAttention = item.hasZeroPrice || item.confidence == "low";

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
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: item.selected,
                  activeColor: MyTheme.accent_color,
                  onChanged: (v) =>
                      setState(() => item.selected = v ?? false),
                ),
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
                  Icon(Icons.error_outline_rounded,
                      size: 18, color: MynPalette.amber),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.category.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: MynPalette.surface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(item.category,
                            style: TextStyle(
                                color: MynPalette.muted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  for (final v in item.variants) _buildVariantRow(item, v),
                ],
              ),
            ),
          ],
        ),
      ),
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
                  color: variant.price <= 0
                      ? MynPalette.red
                      : MynPalette.heading,
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
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
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
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
