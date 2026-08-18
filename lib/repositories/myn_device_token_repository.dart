import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:myn_seller_app/app_config.dart';
import 'package:myn_seller_app/helpers/shared_value_helper.dart';

/// Registers this phone's FCM token with the MYN backend so new orders ring.
///
/// The legacy ProfileRepository.getDeviceTokenUpdateLoginResponse posts to
/// `${BASE_URL}/profile/update-device-token`, a Laravel route the MYN API does
/// not have — it 404s and then throws, which used to abort the rest of the
/// Firebase setup. These calls target the MYN endpoints and never throw.
class MynDeviceTokenRepository {
  /// POST /api/business/device-token
  ///
  /// Safe to call on every launch: the server holds tokens as a set, so a
  /// repeat registration is a no-op, and a seller signed in on two phones
  /// keeps both.
  Future<bool> register(String token) => _send("POST", token);

  /// DELETE /api/business/device-token
  ///
  /// Called on sign-out so a handed-over phone stops receiving that shop's
  /// orders.
  Future<bool> unregister(String token) => _send("DELETE", token);

  Future<bool> _send(String method, String token) async {
    if (token.isEmpty || (access_token.$ ?? "").isEmpty) return false;

    final uri = Uri.parse("${AppConfig.MYN_BASE_URL}/business/device-token");
    final request = http.Request(method, uri)
      ..headers.addAll({
        "Authorization": "Bearer ${access_token.$}",
        "Content-Type": "application/json",
      })
      ..body = jsonEncode({"token": token});

    try {
      final streamed = await request.send().timeout(
            const Duration(seconds: 15),
          );
      final response = await http.Response.fromStream(streamed);

      log("$method $uri -> ${response.statusCode}");
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      // A seller who cannot reach the server still needs a working app, so
      // this is logged and swallowed rather than surfaced.
      log("Device token $method failed: $e");
      return false;
    }
  }
}
