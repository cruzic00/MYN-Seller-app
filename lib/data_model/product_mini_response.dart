// To parse this JSON data, do
//
//     final productMiniResponse = productMiniResponseFromJson(jsonString);
//https://app.quicktype.io/
import 'dart:convert';

import 'package:myn_seller_app/app_config.dart';

ProductMiniResponse productMiniResponseFromJson(String str) =>
    ProductMiniResponse.fromJson(json.decode(str));

String productMiniResponseToJson(ProductMiniResponse data) =>
    json.encode(data.toJson());

class ProductMiniResponse {
  ProductMiniResponse({
    this.products,
    this.meta,
    this.success,
    this.status,
  });

  List<Product>? products;
  bool? success;
  int? status;
  Meta? meta;

  factory ProductMiniResponse.fromJson(Map<String, dynamic> json) {
    final data = json["data"];

    // MYN online-shop API: { success, message, data: { stocklist: [...] } }.
    // It returns the whole list in one response, so there is no meta/paging.
    if (data is Map<String, dynamic>) {
      final list = (data["stocklist"] as List?) ?? const [];
      final products = list
          .map((x) => Product.fromJson(x as Map<String, dynamic>))
          .toList();
      return ProductMiniResponse(
        products: products,
        // This endpoint has no server-side paging, but the product screens
        // dereference meta with `!` (e.g. productlist.dart reads meta!.total),
        // so describe the payload as a single full page rather than null.
        meta: Meta(
          currentPage: 1,
          from: products.isEmpty ? 0 : 1,
          lastPage: 1,
          perPage: products.length,
          to: products.length,
          total: products.length,
        ),
        success: json["success"],
        status: json["statusCode"],
      );
    }

    // Legacy Laravel CMS: { data: [...], meta: {...} }.
    return ProductMiniResponse(
      products: List<Product>.from(
          (data as List).map((x) => Product.fromJson(x))),
      meta: json["meta"] == null ? null : Meta.fromJson(json["meta"]),
      success: json["success"],
      status: json["status"],
    );
  }

  Map<String, dynamic> toJson() => {
        "data": List<dynamic>.from(products!.map((x) => x.toJson())),
        "meta": meta == null ? null : meta!.toJson(),
        "success": success,
        "status": status,
      };
}

class Product {
  Product({
    this.id,
    this.mongo_id,
    this.name,
    this.thumbnail_image,
    this.main_price,
    this.stroked_price,
    this.seller_price,
    this.has_discount,
    this.rating,
    this.sales,
    this.links,
    this.is_active,
  });

  int? id;

  /// MongoDB `_id` of the stocklist entry. Null for legacy Laravel payloads.
  String? mongo_id;
  String? name;
  String? thumbnail_image;
  String? main_price;
  String? stroked_price;
  String? seller_price;
  bool? has_discount;
  int? rating;
  int? sales;
  Links? links;
  bool? is_active;

  factory Product.fromJson(Map<String, dynamic> json) {
    // MYN online-shop stocklist item (MongoDB): productName / appPrice / mrp /
    // imageUrl / status, keyed by a String _id.
    if (json.containsKey("productName") || json.containsKey("appPrice")) {
      // Restaurant/hypermarket items price per variant ("Plate", "500g", ...),
      // leaving the top-level appPrice/mrp at 0. Fall back to the first variant
      // so the card shows the real price instead of ₹0.00.
      final variants = (json["variants"] as List?) ?? const [];
      final Map<String, dynamic> v0 = variants.isNotEmpty
          ? (variants.first as Map<String, dynamic>)
          : const {};

      var appPrice = _toDouble(json["appPrice"]);
      if (appPrice == 0) appPrice = _toDouble(v0["appPrice"]);
      if (appPrice == 0) appPrice = _toDouble(v0["base_price"]);

      var mrp = _toDouble(json["mrp"]);
      if (mrp == 0) mrp = _toDouble(v0["mrp"]);
      if (mrp == 0) mrp = _toDouble(v0["compare_at_price"]);

      final status = json["status"];

      return Product(
        id: null,
        mongo_id: json["_id"]?.toString(),
        name: json["productName"] ?? json["foodName"] ?? "",
        thumbnail_image: _absoluteImageUrl(
            _firstNonEmpty([json["imageUrl"], v0["imageUrl"]])),
        main_price: _formatPrice(appPrice),
        stroked_price: _formatPrice(mrp),
        seller_price: _formatPrice(appPrice),
        has_discount: mrp > appPrice,
        rating: 0,
        sales: 0,
        // status is a string like "active"/"inactive" on this API.
        is_active: status is bool
            ? status
            : status?.toString().toLowerCase() != "inactive",
        links: null,
      );
    }

    return Product(
      id: json["id"],
      name: json["name"],
      thumbnail_image: json["thumbnail_image"],
      main_price: json["main_price"],
      stroked_price: json["stroked_price"],
      seller_price: json["seller_price"],
      has_discount: json["has_discount"],
      rating: json["rating"]?.toInt(),
      sales: json["sales"],
      is_active: json["is_active"],
      links: json["links"] == null ? null : Links.fromJson(json["links"]),
    );
  }

  static String _firstNonEmpty(List<dynamic> candidates) {
    for (final c in candidates) {
      final s = c?.toString() ?? "";
      if (s.isNotEmpty) return s;
    }
    return "";
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static String _formatPrice(double v) => "₹${v.toStringAsFixed(2)}";

  /// The API returns image paths relative to the site root
  /// (`/api/images/...`, `/api/proxy-image?url=...`), which Flutter cannot load
  /// directly — prefix them with the site origin.
  static String _absoluteImageUrl(dynamic raw) {
    final url = raw?.toString() ?? "";
    if (url.isEmpty) return "";
    if (url.startsWith("http")) return url;
    if (url.startsWith("/")) return "${AppConfig.RAW_BASE_URL}$url";
    return url;
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "_id": mongo_id,
        "name": name,
        "thumbnail_image": thumbnail_image,
        "main_price": main_price,
        "stroked_price": stroked_price,
        "seller_price": seller_price,
        "has_discount": has_discount,
        "rating": rating,
        "sales": sales,
        "is_active": is_active,
        "links": links?.toJson(),
      };
}

class Links {
  Links({
    this.details,
  });

  String? details;

  factory Links.fromJson(Map<String, dynamic> json) => Links(
        details: json["details"],
      );

  Map<String, dynamic> toJson() => {
        "details": details,
      };
}

class Meta {
  Meta({
    this.currentPage,
    this.from,
    this.lastPage,
    this.path,
    this.perPage,
    this.to,
    this.total,
  });

  int? currentPage;
  int? from;
  int? lastPage;
  String? path;
  int? perPage;
  int? to;
  int? total;

  factory Meta.fromJson(Map<String, dynamic> json) => Meta(
        currentPage: json["current_page"],
        from: json["from"],
        lastPage: json["last_page"],
        path: json["path"],
        perPage: json["per_page"],
        to: json["to"],
        total: json["total"],
      );

  Map<String, dynamic> toJson() => {
        "current_page": currentPage,
        "from": from,
        "last_page": lastPage,
        "path": path,
        "per_page": perPage,
        "to": to,
        "total": total,
      };
}
