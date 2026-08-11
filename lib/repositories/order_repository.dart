import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:myn_seller_app/app_config.dart';
import 'package:myn_seller_app/data_model/order_detail_response.dart';
import 'package:myn_seller_app/data_model/order_item_response.dart';

class OrderRepository {
  Future<OrderDetailResponse> getOrderDetails({int? id = 0}) async {
    var url = "${AppConfig.BASE_URL}/purchase-history-details-seller/" +
        id.toString();

    try {
      final response = await http.get(Uri.parse(url));

      log("Order URL: $url");
      log("Response Status: ${response.statusCode}");
      log("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return orderDetailResponseFromJson(response.body);
      } else {
        log('Failed to load order details: ${response.body}');
        throw Exception('Failed to load order details');
      }
    } catch (e) {
      log('Error fetching order details: $e');
      rethrow;
    }
  }

  Future<OrderItemResponse> getOrderItems({int? id = 0}) async {
    var url = "${AppConfig.BASE_URL}/purchase-history-items/" + id.toString();

    try {
      final response = await http.get(Uri.parse(url));

      log("Order Items URL: $url");
      log("Response Status: ${response.statusCode}");
      log("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return orderItemResponseFromJson(response.body);
      } else {
        log('Failed to load order items: ${response.body}');
        throw Exception('Failed to load order items');
      }
    } catch (e) {
      log('Error fetching order items: $e');
      rethrow;
    }
  }
}
