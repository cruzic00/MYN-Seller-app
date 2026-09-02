import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:myn_seller_app/app_config.dart';
import 'package:myn_seller_app/data_model/myn_product_response.dart';
import 'package:myn_seller_app/helpers/shared_value_helper.dart';
import 'package:myn_seller_app/repositories/product_repository.dart';

class MynProductRepository {
  /// GET /api/business/business-product/:productId
  ///
  /// Keyed on the Mongo `_id`. The legacy ProductRepository.getProductDetails
  /// hits `/api/v2/products/{int id}`, a Laravel route this API does not have
  /// and which MYN stocklist rows have no integer id for anyway.
  Future<MynProduct> getProduct(String mongoId) async {
    final uri = Uri.parse(
        "${AppConfig.MYN_BASE_URL}/business/business-product/$mongoId");

    final response = await http.get(uri, headers: {
      "Authorization": "Bearer ${access_token.$}",
    });

    log("GET $uri -> ${response.statusCode}");

    if (response.statusCode != 200) {
      throw Exception(_messageFrom(response.body, response.statusCode));
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = (body["data"] as Map<String, dynamic>?) ?? const {};
    final product = data["product"];

    if (product is! Map<String, dynamic>) {
      throw Exception("Product not found");
    }
    return MynProduct.fromJson(product);
  }

  /// POST /api/business/business-stocklist
  ///
  /// Creates one standalone item — the same call the menu scanner makes for an
  /// approved row. The shop is keyed off `bywhom`, and the endpoint works out
  /// restaurant vs hypermarket from the seller's businessCategory, so the app
  /// does not have to. Returns the new Mongo _id, or "" if the reply omitted it.
  Future<String> createProduct(Map<String, dynamic> product) async {
    final uri =
        Uri.parse("${AppConfig.MYN_BASE_URL}/business/business-stocklist");

    final response = await http.post(
      uri,
      headers: {
        "Authorization": "Bearer ${access_token.$}",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "bywhom": ProductRepository.sellerIdentifier(),
        ...product,
      }),
    );

    log("POST $uri -> ${response.statusCode}");

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_messageFrom(response.body, response.statusCode));
    }

    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = (body["data"] as Map<String, dynamic>?) ?? const {};
      final item = data["stockItem"];
      if (item is Map && item["_id"] != null) return item["_id"].toString();
    } catch (_) {}
    return "";
  }

  /// PATCH /api/business/business-stocklist/:uid/:productId
  ///
  /// The endpoint takes a flat patch and does the rest itself: it keeps
  /// productName/foodName in step, runs syncVariantPriceFields over `variants`,
  /// and pushes a `data:` imageUrl to S3 before saving. So send plain values.
  Future<bool> updateProduct(String mongoId, Map<String, dynamic> updates) async {
    final uid = ProductRepository.sellerIdentifier();
    final uri = Uri.parse(
        "${AppConfig.MYN_BASE_URL}/business/business-stocklist/$uid/$mongoId");

    final response = await http.patch(
      uri,
      headers: {
        "Authorization": "Bearer ${access_token.$}",
        "Content-Type": "application/json",
      },
      body: jsonEncode(updates),
    );

    log("PATCH $uri -> ${response.statusCode}");

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_messageFrom(response.body, response.statusCode));
    }
    return true;
  }

  String _messageFrom(String body, int status) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded["message"] != null) {
        return decoded["message"].toString();
      }
    } catch (_) {}
    return "Couldn't load this product ($status)";
  }
}
