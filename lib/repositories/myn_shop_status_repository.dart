import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:myn_seller_app/app_config.dart';
import 'package:myn_seller_app/helpers/shared_value_helper.dart';

/// Reads and flips the shop's "taking orders" switch.
///
/// Replaces AuthRepository.getShowStatusResponse / changeStatusResponse, which
/// called `${BASE_URL}/delivery-boy/shopstatus` — a legacy Laravel route the MYN
/// API never had. It answered 404, the catch block returned 0, and the
/// dashboard therefore showed "Closed" for every seller regardless of what they
/// tapped. These calls hit the real endpoints and never throw.
class MynShopStatusRepository {
  static final Uri _uri =
      Uri.parse("${AppConfig.MYN_BASE_URL}/business/shop-status");

  /// GET /api/business/shop-status
  ///
  /// Returns null when the answer is unknown (offline, signed out, server
  /// error) so the caller can leave the switch where it is instead of showing
  /// a shut shop that is actually open.
  Future<bool?> fetch() async {
    if ((access_token.$ ?? "").isEmpty) return null;

    try {
      final response = await http
          .get(_uri, headers: _headers)
          .timeout(const Duration(seconds: 15));

      log("GET $_uri -> ${response.statusCode}");
      if (response.statusCode != 200) return null;

      return _readShopOpen(response.body);
    } catch (e) {
      log("Shop status fetch failed: $e");
      return null;
    }
  }

  /// PATCH /api/business/shop-status  { "shopOpen": true|false }
  ///
  /// Returns the state the server confirmed, or null if the change did not
  /// land — the dashboard reverts the switch on null rather than leaving the
  /// seller believing they closed a shop that is still taking orders.
  Future<bool?> update(bool shopOpen) async {
    if ((access_token.$ ?? "").isEmpty) return null;

    try {
      final response = await http
          .patch(_uri,
              headers: _headers, body: jsonEncode({"shopOpen": shopOpen}))
          .timeout(const Duration(seconds: 15));

      log("PATCH $_uri -> ${response.statusCode}");
      if (response.statusCode != 200) return null;

      return _readShopOpen(response.body) ?? shopOpen;
    } catch (e) {
      log("Shop status update failed: $e");
      return null;
    }
  }

  Map<String, String> get _headers => {
        "Authorization": "Bearer ${access_token.$}",
        "Content-Type": "application/json",
      };

  /// The API wraps payloads as { success, message, data: {...} }; older
  /// handlers answer flat. Both shapes are read so a change on either side
  /// does not silently close every shop.
  bool? _readShopOpen(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) return null;

      final data = decoded["data"];
      final source = data is Map ? data : decoded;
      final value = source["shopOpen"];

      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) return value == "true" || value == "1";
      return null;
    } catch (e) {
      log("Shop status parse failed: $e");
      return null;
    }
  }
}
