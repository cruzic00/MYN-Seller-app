import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:myn_seller_app/app_config.dart';
import 'package:myn_seller_app/helpers/shared_value_helper.dart';
import 'package:myn_seller_app/repositories/product_repository.dart';

/// One of the seller's own categories, with the subcategories nested under it.
///
/// The scan screen offers these as a dropdown rather than free text so a
/// scanned menu cannot quietly invent a 41st category that the storefront has
/// no section for.
class ShopCategory {
  final String id;
  final String name;
  final List<ShopSubcategory> subcategories;

  ShopCategory({
    required this.id,
    required this.name,
    required this.subcategories,
  });

  factory ShopCategory.fromJson(Map<String, dynamic> json) {
    final raw = (json["subcategories"] as List?) ?? const [];
    return ShopCategory(
      // `id` is the shop-local id; `_id` is Mongo's. Either identifies it.
      id: (json["id"] ?? json["_id"] ?? "").toString(),
      name: json["name"]?.toString() ?? "",
      subcategories: raw
          .whereType<Map<String, dynamic>>()
          .map(ShopSubcategory.fromJson)
          .where((s) => s.name.isNotEmpty)
          .toList(),
    );
  }
}

class ShopSubcategory {
  final String id;
  final String name;

  ShopSubcategory({required this.id, required this.name});

  factory ShopSubcategory.fromJson(Map<String, dynamic> json) =>
      ShopSubcategory(
        id: (json["id"] ?? json["_id"] ?? "").toString(),
        name: json["name"]?.toString() ?? "",
      );
}

/// Best guess at which of the seller's categories a scanned heading belongs to.
///
/// A menu prints "BIRIYANI" where the shop calls the section "Biriyani", and
/// "Soft Drinks" where the shop has "Beverages" — so match case-insensitively
/// and then by containment before giving up and leaving the seller to choose.
ShopCategory? matchShopCategory(List<ShopCategory> categories, String scanned) {
  final needle = scanned.trim().toLowerCase();
  if (needle.isEmpty || categories.isEmpty) return null;

  for (final c in categories) {
    if (c.name.toLowerCase() == needle) return c;
  }
  for (final c in categories) {
    final name = c.name.toLowerCase();
    if (name.contains(needle) || needle.contains(name)) return c;
  }
  return null;
}

class BusinessCategoryRepository {
  /// GET /api/business/business-categories/:uid
  ///
  /// Tries each identifier the seller was issued at login. The route resolves
  /// :uid through findUserIdString and answers 403 "You can only manage your
  /// own catalog" for one it does not recognise as this seller — and for some
  /// accounts the stored uid is the shop_order_gen_field, which it does not.
  /// The old code took any non-200 as "this shop has no categories", so that
  /// 403 arrived as a silently empty dropdown.
  Future<List<ShopCategory>> getCategories() async {
    Object? lastError;

    for (final uid in ProductRepository.sellerIdentifiers()) {
      final uri = Uri.parse(
          "${AppConfig.MYN_BASE_URL}/business/business-categories/${Uri.encodeComponent(uid)}");

      try {
        final response = await http
            .get(uri, headers: {"Authorization": "Bearer ${access_token.$}"})
            .timeout(const Duration(seconds: 20));

        log("GET $uri -> ${response.statusCode}");

        // 403 means this identifier is not the one the route accepts for this
        // seller; the next one may be. Any other failure is worth reporting.
        if (response.statusCode == 403) continue;
        if (response.statusCode != 200) {
          lastError = "Categories unavailable (${response.statusCode})";
          continue;
        }

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = (body["data"] as Map<String, dynamic>?) ?? const {};
        final raw = (data["categories"] as List?) ?? const [];

        final categories = raw
            .whereType<Map<String, dynamic>>()
            .map(ShopCategory.fromJson)
            .where((c) => c.name.isNotEmpty)
            .toList();

        // An empty list from an identifier the server accepted is a real
        // answer: this shop has no categories yet.
        return categories;
      } catch (e) {
        lastError = e;
      }
    }

    if (lastError != null) throw Exception(lastError.toString());
    return [];
  }
}
