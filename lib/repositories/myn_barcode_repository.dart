import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:myn_seller_app/app_config.dart';
import 'package:myn_seller_app/helpers/shared_value_helper.dart';

/// What MYN knows about a scanned pack.
///
/// The barcode itself holds nothing but a number, so every field here comes
/// from MYN's own catalogue. Price is deliberately absent: MRP moves, and what
/// a shop charges is that shop's decision — prefilling it would be setting
/// someone else's price for them.
class ScannedProduct {
  final bool found;
  final String barcode;

  /// "master" when it came from the MYN catalogue, "stocklist" when it came
  /// from another shop that had already added this pack.
  final String source;

  final String? masterProductId;
  final String name;
  final String brand;
  final String category;
  final String? categoryId;
  final String subCategory;
  final String description;
  final String imageUrl;
  final String unit;

  const ScannedProduct({
    required this.found,
    required this.barcode,
    this.source = "",
    this.masterProductId,
    this.name = "",
    this.brand = "",
    this.category = "",
    this.categoryId,
    this.subCategory = "",
    this.description = "",
    this.imageUrl = "",
    this.unit = "",
  });

  factory ScannedProduct.fromJson(Map<String, dynamic> data, String barcode) {
    final p = (data["product"] as Map<String, dynamic>?) ?? const {};
    String s(dynamic v) => v?.toString() ?? "";

    return ScannedProduct(
      found: data["found"] == true,
      barcode: s(data["barcode"]).isEmpty ? barcode : s(data["barcode"]),
      source: s(data["source"]),
      masterProductId: p["masterProductId"]?.toString(),
      name: s(p["productName"]),
      brand: s(p["brand"]),
      category: s(p["category"]),
      categoryId: p["categoryId"]?.toString(),
      subCategory: s(p["subCategory"]),
      description: s(p["description"]),
      imageUrl: s(p["imageUrl"]),
      unit: s(p["unit"]),
    );
  }
}

class MynBarcodeRepository {
  /// GET /api/business/barcode-lookup?barcode=...
  ///
  /// A code nobody has scanned before is not a failure — it comes back with
  /// `found: false` so the form can be filled in by hand and the barcode saved
  /// alongside it, which is what teaches the catalogue.
  Future<ScannedProduct> lookup(String barcode) async {
    final code = barcode.trim();
    final uri = Uri.parse(
        "${AppConfig.MYN_BASE_URL}/business/barcode-lookup?barcode=${Uri.encodeComponent(code)}");

    final response = await http.get(uri, headers: {
      "Authorization": "Bearer ${access_token.$}",
    }).timeout(const Duration(seconds: 20));

    log("GET $uri -> ${response.statusCode}");

    if (response.statusCode != 200) {
      throw Exception("Couldn't check this barcode (${response.statusCode})");
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = (body["data"] as Map<String, dynamic>?) ?? const {};
    return ScannedProduct.fromJson(data, code);
  }
}
