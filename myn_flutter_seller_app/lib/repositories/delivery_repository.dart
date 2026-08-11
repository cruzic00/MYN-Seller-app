import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:myn_seller_app/app_config.dart';
import 'package:myn_seller_app/data_model/cancel_request_response.dart';
import 'package:myn_seller_app/data_model/collection_summary_response.dart';
import 'package:myn_seller_app/data_model/delivery_status_change_response.dart';
import 'package:myn_seller_app/data_model/earning_or_collection_response.dart';
import 'package:myn_seller_app/data_model/earning_summary_response.dart';
import 'package:myn_seller_app/data_model/order_mini_response.dart';
import 'package:myn_seller_app/helpers/shared_value_helper.dart';

class DeliveryRepository {
  Future<OrderMiniResponse> getDeliveryListResponse(
      {String type = "completed",
      int page = 1,
      String dateRange = "",
      String? paymentType}) async {
    var url = Uri.parse(
        "${AppConfig.BASE_URL}/${AppConfig.DELIVERY_PREFIX}/deliveries/${type}/${user_id.$}?date_range=$dateRange&payment_type=$paymentType&page=$page");

    try {
      final response = await http
          .get(url, headers: {"Authorization": "Bearer ${access_token.$}"});

      if (response.statusCode == 200) {
        return orderMiniResponseFromJson(response.body);
      } else {
        throw Exception('Failed to load delivery list: ${response.body}');
      }
    } catch (e) {
      log('Error fetching delivery list: $e');
      rethrow;
    }
  }

  Future<EarningSummaryResponse> getEarningSummaryResponse() async {
    var url = Uri.parse(
        "${AppConfig.BASE_URL}/${AppConfig.DELIVERY_PREFIX}/earning-summary/${user_id.$}");

    try {
      final response = await http
          .get(url, headers: {"Authorization": "Bearer ${access_token.$}"});

      if (response.statusCode == 200) {
        return earningSummaryResponseFromJson(response.body);
      } else {
        throw Exception('Failed to load earning summary: ${response.body}');
      }
    } catch (e) {
      log('Error fetching earning summary: $e');
      return EarningSummaryResponse();
    }
  }

  Future<CollectionSummaryResponse> getCollectionSummaryResponse() async {
    var url = Uri.parse(
        "${AppConfig.BASE_URL}/${AppConfig.DELIVERY_PREFIX}/collection-summary/${user_id.$}");

    try {
      final response = await http
          .get(url, headers: {"Authorization": "Bearer ${access_token.$}"});

      if (response.statusCode == 200) {
        return collectionSummaryResponseFromJson(response.body);
      } else {
        throw Exception('Failed to load collection summary: ${response.body}');
      }
    } catch (e) {
      log('Error fetching collection summary: $e');
      return CollectionSummaryResponse();
    }
  }

  Future<EarningOrCollectionResponse> getEarningResponse({int page = 1}) async {
    var url = Uri.parse(
        "${AppConfig.BASE_URL}/${AppConfig.DELIVERY_PREFIX}/earning/${user_id.$}?page=${page}");

    try {
      final response = await http
          .get(url, headers: {"Authorization": "Bearer ${access_token.$}"});

      if (response.statusCode == 200) {
        return earningOrCollectionResponseFromJson(response.body);
      } else {
        throw Exception('Failed to load earning data: ${response.body}');
      }
    } catch (e) {
      log('Error fetching earning data: $e');
      return EarningOrCollectionResponse(success: false, status: 400, data: []);
    }
  }

  Future<EarningOrCollectionResponse> getCollectionResponse(
      {int page = 1}) async {
    var url = Uri.parse(
        "${AppConfig.BASE_URL}/${AppConfig.DELIVERY_PREFIX}/collection/${user_id.$}");

    try {
      final response = await http
          .get(url, headers: {"Authorization": "Bearer ${access_token.$}"});

      if (response.statusCode == 200) {
        return earningOrCollectionResponseFromJson(response.body);
      } else {
        throw Exception('Failed to load collection data: ${response.body}');
      }
    } catch (e) {
      log('Error fetching collection data: $e');
      return EarningOrCollectionResponse(success: false, status: 400, data: []);
    }
  }

  Future<CancelRequestResponse> getCancelRequestResponse(String orderId) async {
    var url = Uri.parse(
        "${AppConfig.BASE_URL}/${AppConfig.DELIVERY_PREFIX}/cancel-request/${orderId}");

    try {
      final response = await http
          .get(url, headers: {"Authorization": "Bearer ${access_token.$}"});

      if (response.statusCode == 200) {
        return cancelRequestResponseFromJson(response.body);
      } else {
        throw Exception('Failed to cancel request: ${response.body}');
      }
    } catch (e) {
      log('Error cancelling request: $e');
      rethrow;
    }
  }

  Future<DeliveryStatusChangeResponse> getDeliveryStatusChangeResponse(
      {required String status, required int orderId}) async {
    var postBody = jsonEncode({
      "seller_id": "${user_id.$}",
      "status": status,
      "order_id": orderId.toString()
    });

    var url = Uri.parse(
        "${AppConfig.BASE_URL}/${AppConfig.DELIVERY_PREFIX}/change-delivery-status");

    try {
      final response = await http.post(url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer ${access_token.$}"
          },
          body: postBody);

      if (response.statusCode == 200) {
        return deliveryStatusChangeResponseFromJson(response.body);
      } else {
        throw Exception('Failed to change delivery status: ${response.body}');
      }
    } catch (e) {
      log('Error changing delivery status: $e');
      return DeliveryStatusChangeResponse(result: false, message: "Error");
    }
  }
}
