import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:myn_seller_app/app_config.dart';
import 'package:myn_seller_app/data_model/myn_product_response.dart';
import 'package:myn_seller_app/helpers/shared_value_helper.dart';

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
