import 'package:myn_seller_app/app_config.dart';

/// One stocklist item as `GET /api/business/business-product/:id` returns it.
///
/// The endpoint merges the shop's row over the master catalogue row, so a
/// seller override always wins and every field here is already resolved.
class MynProduct {
  final String id;
  final String name;
  final String brand;
  final String category;
  final String subCategory;

  /// Shop code the panel issues on create (e.g. HYP-0002). Read-only in the app.
  final String code;
  final String description;
  final String imageUrl;
  final String status;
  final String imageStatus;
  final String foodType;
  final double packagingCharge;
  final bool offerActive;
  final List<MynProductVariant> variants;
  final List<MynAddonGroup> addonGroups;

  MynProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.subCategory,
    required this.code,
    required this.description,
    required this.imageUrl,
    required this.status,
    required this.imageStatus,
    required this.foodType,
    required this.packagingCharge,
    required this.offerActive,
    required this.variants,
    required this.addonGroups,
  });

  static String _resolveImage(Map<String, dynamic> json, List raw) {
    final variant = raw.isNotEmpty && raw.first is Map ? raw.first as Map : const {};

    for (final candidate in [json["imageUrl"], variant["imageUrl"]]) {
      final url = candidate?.toString() ?? "";
      if (url.isEmpty) continue;
      if (url.startsWith("http")) return url;
      if (url.startsWith("/")) return "${AppConfig.RAW_BASE_URL}$url";
      return url;
    }
    return "";
  }

  factory MynProduct.fromJson(Map<String, dynamic> json) {
    final raw = (json["variants"] as List?) ?? const [];
    return MynProduct(
      id: json["_id"]?.toString() ?? "",
      // The aggregate coalesces productName/foodName, but a legacy row can
      // still arrive with only one of them set.
      name: (json["productName"] ?? json["foodName"] ?? "").toString(),
      brand: (json["brand"] ?? "").toString(),
      category: (json["category"] ?? "").toString(),
      subCategory: (json["subCategory"] ?? "").toString(),
      code: (json["productCode"] ?? json["code"] ?? json["sku"] ?? "").toString(),
      description: (json["description"] ?? "").toString(),
      // A row uploaded through the panel can carry its picture on the first
      // variant rather than at the top level, and a legacy row stores a path
      // rather than a URL. The grid already resolved both; the detail screen
      // read only the top-level field and so showed an empty picker for an item
      // that visibly had an image one screen back.
      imageUrl: _resolveImage(json, raw),
      status: (json["status"] ?? "").toString(),
      imageStatus: (json["imageStatus"] ?? "None").toString(),
      foodType: (json["foodType"] ?? "").toString(),
      packagingCharge: MynProductVariant._num(json["packagingCharge"]),
      offerActive: json["offerActive"] == true,
      variants: raw
          .whereType<Map<String, dynamic>>()
          .map(MynProductVariant.fromJson)
          .toList(),
      addonGroups: (((json["addonGroups"] as List?) ?? const [])
              .whereType<Map<String, dynamic>>())
          .map(MynAddonGroup.fromJson)
          .toList(),
    );
  }
}

class MynProductVariant {
  final String unit;
  final double price;
  final double compareAtPrice;
  final double supplierPrice;
  final double taxRate;
  final double cgst;
  final double sgst;
  final double commission;
  final double offerPrice;
  final bool offerActive;

  MynProductVariant({
    required this.unit,
    required this.price,
    required this.compareAtPrice,
    required this.supplierPrice,
    required this.taxRate,
    required this.cgst,
    required this.sgst,
    required this.commission,
    required this.offerPrice,
    required this.offerActive,
  });

  factory MynProductVariant.fromJson(Map<String, dynamic> json) =>
      MynProductVariant(
        unit: (json["unit"] ?? json["name"] ?? "Regular").toString(),
        price: _num(json["base_price"] ?? json["appPrice"]),
        compareAtPrice: _num(json["compare_at_price"] ?? json["mrp"]),
        // The hypermarket form edits these three; the food form leaves them at
        // whatever the row already carried.
        supplierPrice: _num(json["supplierPrice"]),
        taxRate: _num(json["taxRate"]),
        cgst: _num(json["cgst"]),
        sgst: _num(json["sgst"]),
        commission: _num(json["mynCommission"]),
        offerPrice: _num(json["offerPrice"]),
        offerActive: json["isOfferActive"] == true,
      );

  /// True when the shop is advertising a strike-through price worth showing.
  bool get hasDiscount => compareAtPrice > price && price > 0;

  static double _num(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}
/// A customisation group on a restaurant dish — "Extra Toppings", "Crust Type".
class MynAddonGroup {
  final String name;
  final int minSelection;
  final int maxSelection;
  final List<MynAddon> addons;

  MynAddonGroup({
    required this.name,
    required this.minSelection,
    required this.maxSelection,
    required this.addons,
  });

  factory MynAddonGroup.fromJson(Map<String, dynamic> json) {
    final raw = (json["addons"] as List?) ?? const [];
    return MynAddonGroup(
      name: (json["groupName"] ?? "").toString(),
      minSelection: (json["minSelection"] as num?)?.toInt() ?? 0,
      maxSelection: (json["maxSelection"] as num?)?.toInt() ?? 1,
      addons: raw
          .whereType<Map<String, dynamic>>()
          .map(MynAddon.fromJson)
          .toList(),
    );
  }
}

class MynAddon {
  final String name;
  final double price;
  final String foodType;

  MynAddon({
    required this.name,
    required this.price,
    required this.foodType,
  });

  factory MynAddon.fromJson(Map<String, dynamic> json) => MynAddon(
        name: (json["name"] ?? "").toString(),
        price: MynProductVariant._num(json["price"]),
        foodType: (json["foodType"] ?? "Veg").toString(),
      );
}
