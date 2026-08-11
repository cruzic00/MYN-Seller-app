import 'dart:convert';
import 'dart:developer';

import 'package:myn_seller_app/app_config.dart';
import 'package:myn_seller_app/data_model/download_report_response.dart';
import 'package:myn_seller_app/helpers/shared_value_helper.dart';
import 'package:http/http.dart' as http;

class OrderRepository {
  Future<ApiResponse> getOrderReports(String fromDate, String toDate) async {
    final url = Uri.parse(
        '${AppConfig.BASE_URL}/reports?id=${user_id.$}&date_from=$fromDate&date_to=$toDate');

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${access_token.$}",
        },
      );

      if (response.statusCode == 200) {
        return ApiResponse.fromJson(jsonDecode(response.body));
      } else {
        log('Failed to load order reports: ${response.body}');
        throw Exception('Failed to load order reports');
      }
    } catch (e) {
      log('Error fetching order reports: $e');
      rethrow; // Rethrow the caught exception
    }
  }
}
