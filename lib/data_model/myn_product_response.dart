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
  final String description;
  final String imageUrl;
  final String status;
  final String imageStatus;
  final String foodType;
  final List<MynProductVariant> variants;

  MynProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.subCategory,
    required this.description,
    required this.imageUrl,
    required this.status,
    required this.imageStatus,
    required this.foodType,
    required this.variants,
  });

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
      description: (json["description"] ?? "").toString(),
      imageUrl: (json["imageUrl"] ?? "").toString(),
      status: (json["status"] ?? "").toString(),
      imageStatus: (json["imageStatus"] ?? "None").toString(),
      foodType: (json["foodType"] ?? "").toString(),
      variants: raw
          .whereType<Map<String, dynamic>>()
          .map(MynProductVariant.fromJson)
          .toList(),
    );
  }
}

class MynProductVariant {
  final String unit;
  final double price;
  final double compareAtPrice;
  final double taxRate;
  final double offerPrice;
  final bool offerActive;

  MynProductVariant({
    required this.unit,
    required this.price,
    required this.compareAtPrice,
    required this.taxRate,
    required this.offerPrice,
    required this.offerActive,
  });

  factory MynProductVariant.fromJson(Map<String, dynamic> json) =>
      MynProductVariant(
        unit: (json["unit"] ?? json["name"] ?? "Regular").toString(),
        price: _num(json["base_price"] ?? json["appPrice"]),
        compareAtPrice: _num(json["compare_at_price"] ?? json["mrp"]),
        taxRate: _num(json["taxRate"]),
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
