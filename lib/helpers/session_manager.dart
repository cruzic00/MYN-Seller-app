import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:myn_seller_app/app_config.dart';
import 'package:myn_seller_app/helpers/shared_value_helper.dart';

/// Keeps the seller signed in across a short-lived access token.
///
/// The API issues an access token that expires in a couple of hours, and the
/// app had no way to renew it. A seller who closed the app and opened it again
/// the next morning met a dashboard of "Couldn't load your summary" on every
/// card, with nothing saying the session had run out and no way back except
/// finding Logout in the drawer and signing in again.
///
/// [ensureFresh] is called before the first request of a session and again
/// whenever the app returns to the foreground. It reads the token's own expiry
/// rather than asking the server, so the common case — a still-valid token —
/// costs nothing.
class SessionManager {
  /// Renew this far ahead of the deadline. A request that starts inside the
  /// window would otherwise be answered 401 while the app still believed the
  /// token was good.
  static const Duration _renewBefore = Duration(minutes: 5);

  static Future<void>? _inFlight;

  /// Refreshes the access token when it is expired or close to it.
  ///
  /// Returns true when the session is usable afterwards. Concurrent callers
  /// share one refresh: the dashboard, the orders list and the product grid all
  /// wake at the same moment, and three refreshes would rotate the token twice
  /// and invalidate the winner.
  static Future<bool> ensureFresh() async {
    final token = access_token.$ ?? "";
    if (token.isEmpty) return false;
    if (!_expiresWithin(token, _renewBefore)) return true;

    final pending = _inFlight ??= _refresh().whenComplete(() {
      _inFlight = null;
    });
    await pending;

    return (access_token.$ ?? "").isNotEmpty;
  }

  /// True when the session is gone for good and the seller has to sign in.
  ///
  /// Distinct from "the network was down": a failed refresh leaves the tokens
  /// alone so a seller in a lift is not signed out, and only a server that
  /// actually rejected the refresh token clears them.
  static bool get isSignedOut => (access_token.$ ?? "").isEmpty;

  static Future<void> _refresh() async {
    final refresh = refresh_token.$ ?? "";

    // Sessions created before the app stored refresh tokens have none. Nothing
    // to renew with, so leave the access token in place: it may still have
    // minutes left, and clearing it here would sign the seller out mid-task.
    if (refresh.isEmpty) {
      log("Session refresh skipped: no refresh token stored");
      return;
    }

    final uri = Uri.parse("${AppConfig.MYN_BASE_URL}/auth/refresh");

    try {
      final response = await http
          .post(uri,
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({"refreshToken": refresh}))
          .timeout(const Duration(seconds: 20));

      log("POST $uri -> ${response.statusCode}");

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = (body is Map ? body["data"] : null);
        if (data is Map) {
          final next = data["token"]?.toString() ?? "";
          if (next.isNotEmpty) access_token.$ = next;

          // The server rotates the refresh token on every use, so the old one
          // stops working the moment this lands.
          final nextRefresh = data["refreshToken"]?.toString() ?? "";
          if (nextRefresh.isNotEmpty) refresh_token.$ = nextRefresh;
        }
        return;
      }

      // 401 is the server saying this refresh token is finished — revoked,
      // rotated past, or expired. Anything else (500, a proxy error) is not
      // proof of that, so the session is left alone to be retried.
      if (response.statusCode == 401) {
        log("Session refresh rejected; signing out");
        access_token.$ = "";
        refresh_token.$ = "";
      }
    } catch (e) {
      // Offline. Keep the tokens; the next foreground will try again.
      log("Session refresh failed: $e");
    }
  }

  /// Reads `exp` out of the JWT without verifying it — the signature is the
  /// server's business, the app only needs to know when to ask for a new one.
  ///
  /// A token this cannot parse is treated as due for renewal: better one
  /// unnecessary refresh than a screen of errors.
  static bool _expiresWithin(String token, Duration window) {
    try {
      final parts = token.split(".");
      if (parts.length != 3) return true;

      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final exp = payload is Map ? payload["exp"] : null;
      if (exp is! num) return true;

      final expiry = DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
      return expiry.isBefore(DateTime.now().add(window));
    } catch (e) {
      log("Could not read token expiry: $e");
      return true;
    }
  }
}
