import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:myn_seller_app/app_config.dart';
import 'package:myn_seller_app/helpers/shared_value_helper.dart';
import 'package:myn_seller_app/repositories/business_category_repository.dart';
import 'package:myn_seller_app/repositories/product_repository.dart';

/// One dish read off a menu photo, before the seller has approved it.
///
/// Everything the web Business Panel's edit dialog shows is editable here too,
/// so a scanned item lands complete rather than needing a second pass on the
/// panel to fill in brand, subcategory and status.
class ScannedMenuItem {
  String name;
  String category;
  String description;
  String confidence;
  List<ScannedVariant> variants;

  String brand;
  String subCategory;
  String status;

  /// Set from the category dropdown so the storefront can group the item by id
  /// rather than by a name that might be re-spelled later.
  String categoryId;
  String subcategoryId;

  /// A `data:` URL from the image generator. addStockItem materialises this to
  /// S3 on save, so it never has to be uploaded separately.
  String? imageDataUrl;

  /// Sellers deselect rows they don't want rather than deleting them, so a
  /// misread item can be corrected instead of forcing a re-scan.
  bool selected;

  ScannedMenuItem({
    required this.name,
    required this.category,
    required this.description,
    required this.confidence,
    required this.variants,
    this.brand = "",
    this.subCategory = "",
    this.status = "Active",
    this.categoryId = "",
    this.subcategoryId = "",
    this.imageDataUrl,
    this.selected = true,
  });

  factory ScannedMenuItem.fromJson(Map<String, dynamic> json) {
    final rawVariants = (json["variants"] as List?) ?? const [];
    final variants = rawVariants
        .whereType<Map<String, dynamic>>()
        .map(ScannedVariant.fromJson)
        .toList();

    return ScannedMenuItem(
      name: json["name"]?.toString() ?? "",
      category: json["category"]?.toString() ?? "",
      description: json["description"]?.toString() ?? "",
      confidence: json["confidence"]?.toString() ?? "medium",
      variants:
          variants.isEmpty ? [ScannedVariant(unit: "Regular", price: 0)] : variants,
      // Anything the model flagged as a guess starts unticked, so a low-quality
      // read can never reach the storefront just by tapping Save.
      selected: (json["confidence"]?.toString() ?? "") != "low",
    );
  }

  bool get hasZeroPrice => variants.any((v) => v.price <= 0);

  bool get hasImage => imageDataUrl != null && imageDataUrl!.isNotEmpty;

  /// Points the item at one of the seller's own categories, clearing any
  /// subcategory that belonged to the previous one.
  void applyCategory(ShopCategory? cat) {
    category = cat?.name ?? "";
    categoryId = cat?.id ?? "";
    subCategory = "";
    subcategoryId = "";
  }

  void applySubcategory(ShopSubcategory? sub) {
    subCategory = sub?.name ?? "";
    subcategoryId = sub?.id ?? "";
  }
}

class ScannedVariant {
  String unit;
  double price;

  ScannedVariant({required this.unit, required this.price});

  factory ScannedVariant.fromJson(Map<String, dynamic> json) => ScannedVariant(
        unit: json["unit"]?.toString() ?? "Regular",
        price: _toDouble(json["price"]),
      );

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}

class MenuScanResult {
  final List<ScannedMenuItem> items;
  final String notes;

  MenuScanResult({required this.items, required this.notes});
}

class MenuScanRepository {
  /// POST /api/business/scan-menu — returns candidates only; nothing is saved
  /// until [addScannedItem] is called for the rows the seller approved.
  Future<MenuScanResult> scanMenu(List<String> base64Images,
      {String mediaType = "image/jpeg"}) async {
    final uri = Uri.parse("${AppConfig.MYN_BASE_URL}/business/scan-menu");

    final response = await http.post(
      uri,
      headers: {
        "Authorization": "Bearer ${access_token.$}",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "images": base64Images
            .map((d) => {"mediaType": mediaType, "data": d})
            .toList(),
      }),
    );

    log("POST $uri -> ${response.statusCode}");

    if (response.statusCode != 200) {
      throw Exception(_messageFrom(response.body, response.statusCode));
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = (body["data"] as Map<String, dynamic>?) ?? const {};
    final rawItems = (data["items"] as List?) ?? const [];

    return MenuScanResult(
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(ScannedMenuItem.fromJson)
          .toList(),
      notes: data["notes"]?.toString() ?? "",
    );
  }

  /// POST /api/business/generate-product-image — an illustrative photo for one
  /// dish, returned as a `data:` URL. Nothing is stored until the item is saved.
  Future<String> generateImage(ScannedMenuItem item) async {
    final uri = Uri.parse(
        "${AppConfig.MYN_BASE_URL}/business/generate-product-image");

    final response = await http.post(
      uri,
      headers: {
        "Authorization": "Bearer ${access_token.$}",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "name": item.name.trim(),
        "category": item.category.trim(),
        "description": item.description.trim(),
      }),
    );

    log("POST $uri (${item.name}) -> ${response.statusCode}");

    if (response.statusCode != 200) {
      throw Exception(_messageFrom(response.body, response.statusCode));
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = (body["data"] as Map<String, dynamic>?) ?? const {};
    final url = data["dataUrl"]?.toString() ?? "";
    if (url.isEmpty) throw Exception("No image returned");
    return url;
  }

  /// POST /api/business/business-stocklist — one approved item.
  ///
  /// Shaped for `addStockItem`, which keys the shop off `bywhom` and derives
  /// restaurant vs hypermarket from the seller's businessCategory.
  Future<bool> addScannedItem(ScannedMenuItem item) async {
    final uri =
        Uri.parse("${AppConfig.MYN_BASE_URL}/business/business-stocklist");

    final payload = {
      "bywhom": ProductRepository.sellerIdentifier(),
      "productName": item.name.trim(),
      "brand": item.brand.trim(),
      "category": item.category.trim(),
      "categoryId": item.categoryId,
      "subCategory": item.subCategory.trim(),
      "subcategoryId": item.subcategoryId,
      "description": item.description.trim(),
      "status": item.status,
      if (item.hasImage) ...{
        "imageUrl": item.imageDataUrl,
        // Same review queue as a seller-uploaded photo: an admin approves it on
        // the verification page before customers see it.
        "imageStatus": "Pending",
      },
      "variants": item.variants
          .map((v) => {
                "variantUnit": v.unit.trim(),
                "appPrice": v.price,
                "base_price": v.price,
                "mrp": v.price,
                "compare_at_price": v.price,
                "taxRate": 0,
              })
          .toList(),
    };

    final response = await http.post(
      uri,
      headers: {
        "Authorization": "Bearer ${access_token.$}",
        "Content-Type": "application/json",
      },
      body: jsonEncode(payload),
    );

    log("POST $uri (${item.name}) -> ${response.statusCode}");
    return response.statusCode == 200 || response.statusCode == 201;
  }

  String _messageFrom(String body, int status) {
    String? serverMessage;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded["message"] != null) {
        serverMessage = decoded["message"].toString();
      }
    } catch (_) {}

    // A message that names a server-side setup problem (a missing API key,
    // an unconfigured integration) is meaningless to a seller and just adds
    // alarm — show something they can act on instead.
    if (serverMessage != null && _looksLikeServerMisconfiguration(serverMessage)) {
      return "Menu scanning isn't available right now. Please try again in "
          "a while, or contact support if this keeps happening.";
    }

    return serverMessage ?? "Request failed ($status)";
  }

  bool _looksLikeServerMisconfiguration(String message) {
    final lower = message.toLowerCase();
    return lower.contains("api_key") ||
        lower.contains("api key") ||
        lower.contains("not configured");
  }
}
