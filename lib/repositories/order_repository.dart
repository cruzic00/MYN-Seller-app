import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:myn_seller_app/app_config.dart';
import 'package:myn_seller_app/data_model/myn_order_response.dart';
import 'package:myn_seller_app/data_model/order_detail_response.dart';
import 'package:myn_seller_app/data_model/order_item_response.dart';
import 'package:myn_seller_app/helpers/shared_value_helper.dart';

class OrderRepository {
  /// Business orders from the MYN online-shop API
  /// (GET /api/admin/orders). The server scopes results to the caller's own
  /// shop from the bearer token, so no seller id is passed.
  ///
  /// [period] accepts the same values the web panel sends: today, yesterday,
  /// week, month, 5month, year. Omit it for "All".
  Future<MynOrderListResponse> getMynOrders({
    String? period,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    final params = <String, String>{};
    if (period != null && period.isNotEmpty) params["period"] = period;
    if (status != null && status.isNotEmpty) params["status"] = status;
    if (startDate != null && startDate.isNotEmpty) params["startDate"] = startDate;
    if (endDate != null && endDate.isNotEmpty) params["endDate"] = endDate;

    final uri = Uri.parse("${AppConfig.MYN_BASE_URL}/admin/orders")
        .replace(queryParameters: params.isEmpty ? null : params);

    final response = await http.get(uri, headers: {
      "Authorization": "Bearer ${access_token.$}",
      "Content-Type": "application/json",
    });

    log("Request URL: $uri");
    log("Response Status: ${response.statusCode}");

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to load orders (${response.statusCode}): ${response.body}');
    }
    return mynOrderListResponseFromJson(response.body);
  }

  /// Full order document for the detail screen
  /// (GET /api/admin/orders/:id -> data.order). Returned raw because the
  /// OrderShop document carries nested items/tax arrays whose shape varies by
  /// business category, and the detail screen renders them defensively.
  Future<Map<String, dynamic>> getMynOrderDetail(String orderId) async {
    final uri = Uri.parse("${AppConfig.MYN_BASE_URL}/admin/orders/$orderId");

    final response = await http.get(uri, headers: {
      "Authorization": "Bearer ${access_token.$}",
      "Content-Type": "application/json",
    });

    log("Request URL: $uri");
    log("Response Status: ${response.statusCode}");

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to load order detail (${response.statusCode}): ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body["data"];
    if (data is Map<String, dynamic> && data["order"] is Map) {
      return Map<String, dynamic>.from(data["order"] as Map);
    }
    throw Exception('Unexpected order payload');
  }

  /// PATCH /api/admin/orders/:id/status
  Future<bool> updateMynOrderStatus(String orderId, String status) async {
    final uri =
        Uri.parse("${AppConfig.MYN_BASE_URL}/admin/orders/$orderId/status");

    final response = await http.patch(
      uri,
      headers: {
        "Authorization": "Bearer ${access_token.$}",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"status": status}),
    );

    log("PATCH $uri -> ${response.statusCode}");
    return response.statusCode == 200;
  }

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
