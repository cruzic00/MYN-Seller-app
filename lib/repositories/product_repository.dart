import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:myn_seller_app/app_config.dart';
import 'package:myn_seller_app/data_model/product_details_response.dart';
import 'package:myn_seller_app/data_model/product_mini_response.dart';
import 'package:myn_seller_app/data_model/variant_response.dart';
import 'package:myn_seller_app/helpers/shared_value_helper.dart';

class ProductRepository {
  Future<ProductMiniResponse> getFeaturedProducts({int page = 1}) async {
    Uri url = Uri.parse(
        "${AppConfig.BASE_URL}/products/featured?page=${page}&seller_user_id=${user_id.$}");

    try {
      final response = await http.get(url, headers: {
        "App-Language": app_language.$,
      });

      log("Request URL: $url");
      log("Response Status: ${response.statusCode}");
      log("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return productMiniResponseFromJson(response.body);
      } else {
        log('Failed to load featured products: ${response.body}');
        throw Exception('Failed to load featured products');
      }
    } catch (e) {
      log('Error fetching featured products: $e');
      rethrow;
    }
  }

  Future<ProductMiniResponse> getBestSellingProducts() async {
    Uri url = Uri.parse(
        "${AppConfig.BASE_URL}/products/best-seller?seller_user_id=${user_id.$}");

    try {
      final response = await http.get(url, headers: {
        "App-Language": app_language.$,
      });

      log("Request URL: $url");
      log("Response Status: ${response.statusCode}");
      log("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return productMiniResponseFromJson(response.body);
      } else {
        log('Failed to load best-selling products: ${response.body}');
        throw Exception('Failed to load best-selling products');
      }
    } catch (e) {
      log('Error fetching best-selling products: $e');
      rethrow;
    }
  }

  Future<ProductMiniResponse> getTodaysDealProducts() async {
    Uri url = Uri.parse(
        "${AppConfig.BASE_URL}/products/todays-deal?seller_user_id=${user_id.$}");

    try {
      final response = await http.get(url, headers: {
        "App-Language": app_language.$,
      });

      log("Request URL: $url");
      log("Response Status: ${response.statusCode}");
      log("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return productMiniResponseFromJson(response.body);
      } else {
        log('Failed to load today\'s deal products: ${response.body}');
        throw Exception('Failed to load today\'s deal products');
      }
    } catch (e) {
      log('Error fetching today\'s deal products: $e');
      rethrow;
    }
  }

  Future<ProductMiniResponse> getFlashDealProducts({int id = 0}) async {
    Uri url = Uri.parse(
        "${AppConfig.BASE_URL}/flash-deal-products/${id}?seller_user_id=${user_id.$}");

    try {
      final response = await http.get(url, headers: {
        "App-Language": app_language.$,
      });

      log("Request URL: $url");
      log("Response Status: ${response.statusCode}");
      log("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return productMiniResponseFromJson(response.body);
      } else {
        log('Failed to load flash deal products: ${response.body}');
        throw Exception('Failed to load flash deal products');
      }
    } catch (e) {
      log('Error fetching flash deal products: $e');
      rethrow;
    }
  }

  /// Identifier the MYN online-shop API accepts for a seller. Its handlers
  /// match `_id`, `uid`, `username` or `email`, so fall through the ones we
  /// stored at login until a non-empty value is found.
  static String sellerIdentifier() {
    for (final candidate in [seller_uid.$, seller_mongo_id.$, seller_username.$]) {
      if (candidate != null && candidate.isNotEmpty) return candidate;
    }
    return "";
  }

  Future<ProductMiniResponse> getCategoryProducts(
      {int page = 1, String? name}) async {
    // GET /api/business/business-stocklist/:uid — returns the seller's full
    // stocklist in one response (no server-side paging), optionally filtered
    // by ?search=.
    String url =
        "${AppConfig.MYN_BASE_URL}/business/business-stocklist/${Uri.encodeComponent(sellerIdentifier())}";

    if (name != null && name.isNotEmpty) {
      url += "?search=${Uri.encodeComponent(name)}";
    }

    Uri uri = Uri.parse(url);

    try {
      final response = await http.get(uri, headers: {
        "App-Language": app_language.$,
        "Authorization": "Bearer ${access_token.$}",
      });

      log("Request URL: $uri");
      log("Response Status: ${response.statusCode}");
      log("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return productMiniResponseFromJson(response.body);
      } else {
        log('Failed to load category products: ${response.body}');
        throw Exception('Failed to load category products');
      }
    } catch (e) {
      log('Error fetching category products: $e');
      rethrow;
    }
  }

  Future<ProductMiniResponse> getShopProducts(
      {int id = 0, String name = "", int page = 1}) async {
    Uri url = Uri.parse(
        "${AppConfig.BASE_URL}/products/seller/${id}?page=${page}&name=${name}");

    try {
      final response = await http.get(url, headers: {
        "App-Language": app_language.$,
      });

      log("Request URL: $url");
      log("Response Status: ${response.statusCode}");
      log("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return productMiniResponseFromJson(response.body);
      } else {
        log('Failed to load shop products: ${response.body}');
        throw Exception('Failed to load shop products');
      }
    } catch (e) {
      log('Error fetching shop products: $e');
      rethrow;
    }
  }

  Future<ProductMiniResponse> getBrandProducts(
      {int? id = 0, String name = "", int page = 1}) async {
    Uri url = Uri.parse(
        "${AppConfig.BASE_URL}/products/brand/${id}?page=${page}&name=${name}&seller_user_id=${user_id.$}");

    try {
      final response = await http.get(url, headers: {
        "App-Language": app_language.$,
      });

      log("Request URL: $url");
      log("Response Status: ${response.statusCode}");
      log("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return productMiniResponseFromJson(response.body);
      } else {
        log('Failed to load brand products: ${response.body}');
        throw Exception('Failed to load brand products');
      }
    } catch (e) {
      log('Error fetching brand products: $e');
      rethrow;
    }
  }

  Future<ProductMiniResponse> getFilteredProducts(
      {String name = "",
      String sortKey = "",
      int page = 1,
      String brands = "",
      String categories = "",
      String min = "",
      String max = ""}) async {
    Uri url = Uri.parse(
        "${AppConfig.BASE_URL}/products/search?page=${page}&name=${name}&sort_key=${sortKey}&brands=${brands}&categories=${categories}&min=${min}&max=${max}&seller_user_id=${user_id.$}");

    try {
      final response = await http.get(url, headers: {
        "App-Language": app_language.$,
      });

      log("Request URL: $url");
      log("Response Status: ${response.statusCode}");
      log("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return productMiniResponseFromJson(response.body);
      } else {
        log('Failed to load filtered products: ${response.body}');
        throw Exception('Failed to load filtered products');
      }
    } catch (e) {
      log('Error fetching filtered products: $e');
      rethrow;
    }
  }

  /// Fetches one stocklist item from the MYN online-shop API
  /// (GET /api/business/business-product/:productId).
  ///
  /// Returns the raw product map rather than [ProductDetailsResponse]: this
  /// API's product shape (productName / variants[] / status) does not line up
  /// with the legacy Laravel model, and the edit screen needs the untouched
  /// variant list so it can PATCH it back without dropping fields.
  Future<Map<String, dynamic>> getMynProduct(String productId) async {
    final uri = Uri.parse(
        "${AppConfig.MYN_BASE_URL}/business/business-product/$productId");

    final response = await http.get(uri, headers: {
      "Authorization": "Bearer ${access_token.$}",
    });

    log("Request URL: $uri");
    log("Response Status: ${response.statusCode}");

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to load product details (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body["data"];
    if (data is Map<String, dynamic> && data["product"] is Map) {
      return Map<String, dynamic>.from(data["product"] as Map);
    }
    throw Exception('Unexpected product payload');
  }

  /// Applies a partial update to a stocklist item
  /// (PATCH /api/business/business-stocklist/:uid/:productId).
  Future<bool> updateMynProduct(
      String productId, Map<String, dynamic> updates) async {
    final uri = Uri.parse(
        "${AppConfig.MYN_BASE_URL}/business/business-stocklist/${Uri.encodeComponent(sellerIdentifier())}/$productId");

    final response = await http.patch(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${access_token.$}",
      },
      body: jsonEncode(updates),
    );

    log("PATCH $uri -> ${response.statusCode}");
    return response.statusCode == 200;
  }

  Future<ProductDetailsResponse> getProductDetails({int? id = 0}) async {
    Uri url = Uri.parse("${AppConfig.BASE_URL}/products/${id}");

    try {
      final response = await http.get(url, headers: {
        "App-Language": app_language.$,
      });

      log("Request URL: $url");
      log("Response Status: ${response.statusCode}");
      log("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return productDetailsResponseFromJson(response.body);
      } else {
        log('Failed to load product details: ${response.body}');
        throw Exception('Failed to load product details');
      }
    } catch (e) {
      log('Error fetching product details: $e');
      rethrow;
    }
  }

  Future<ProductMiniResponse> getRelatedProducts({int? id = 0}) async {
    Uri url = Uri.parse(
        "${AppConfig.BASE_URL}/products/related/${id}?seller_user_id=${user_id.$}");

    try {
      final response = await http.get(url, headers: {
        "App-Language": app_language.$,
      });

      log("Request URL: $url");
      log("Response Status: ${response.statusCode}");
      log("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return productMiniResponseFromJson(response.body);
      } else {
        log('Failed to load related products: ${response.body}');
        throw Exception('Failed to load related products');
      }
    } catch (e) {
      log('Error fetching related products: $e');
      rethrow;
    }
  }

  Future<dynamic> getCategoryList() async {
    Uri url = Uri.parse(
        "${AppConfig.BASE_URL}/getusercategories?user_id=${user_id.$}");

    try {
      final response = await http.get(url);

      log("Request URL: $url");
      log("Response Status: ${response.statusCode}");
      log("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        log('Failed to load category list: ${response.body}');
        throw Exception('Failed to load category list');
      }
    } catch (e) {
      log('Error fetching category list: $e');
      rethrow;
    }
  }

  Future<ProductMiniResponse> getTopFromThisSellerProducts(
      {int? id = 0}) async {
    Uri url = Uri.parse(
        "${AppConfig.BASE_URL}/products/top-from-seller/${id}?seller_user_id=${user_id.$}");

    try {
      final response = await http.get(url, headers: {
        "App-Language": app_language.$,
      });

      log("Request URL: $url");
      log("Response Status: ${response.statusCode}");
      log("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return productMiniResponseFromJson(response.body);
      } else {
        log('Failed to load top products from this seller: ${response.body}');
        throw Exception('Failed to load top products from this seller');
      }
    } catch (e) {
      log('Error fetching top products from this seller: $e');
      rethrow;
    }
  }

  Future<VariantResponse> getVariantWiseInfo(
      {int? id = 0, String color = '', String variants = ''}) async {
    Uri url = Uri.parse(
        "${AppConfig.BASE_URL}/products/variant/price?id=${id}&color=${color}&variants=${variants}");

    try {
      final response = await http.get(url, headers: {
        "App-Language": app_language.$,
      });

      log("Request URL: $url");
      log("Response Status: ${response.statusCode}");
      log("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return variantResponseFromJson(response.body);
      } else {
        log('Failed to load variant wise info: ${response.body}');
        throw Exception('Failed to load variant wise info');
      }
    } catch (e) {
      log('Error fetching variant wise info: $e');
      rethrow;
    }
  }
}
