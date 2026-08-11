import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:myn_seller_app/app_config.dart';
import 'package:myn_seller_app/data_model/myn_profile_response.dart';
import 'package:myn_seller_app/helpers/shared_value_helper.dart';

class MynProfileRepository {
  /// GET /api/auth/me — the full user document for the bearer token, including
  /// the logo/banner URLs and payout details.
  Future<MynProfile> getMyProfile() async {
    final uri = Uri.parse("${AppConfig.MYN_BASE_URL}/auth/me");

    final response = await http.get(uri, headers: {
      "Authorization": "Bearer ${access_token.$}",
      "Content-Type": "application/json",
    });

    log("Request URL: $uri");
    log("Response Status: ${response.statusCode}");

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to load profile (${response.statusCode}): ${response.body}');
    }
    return mynProfileFromJson(response.body);
  }

  /// POST /api/auth/update-own-profile.
  ///
  /// Only the server's editable-field allowlist is accepted (email, phone,
  /// address, city, state, country, postalCode, taxId, businessName,
  /// businessCategory, description, mapLocation) — bank details are not in it,
  /// so they are never sent from here.
  Future<bool> updateOwnProfile(Map<String, dynamic> updates) async {
    final uri =
        Uri.parse("${AppConfig.MYN_BASE_URL}/auth/update-own-profile");

    final response = await http.post(
      uri,
      headers: {
        "Authorization": "Bearer ${access_token.$}",
        "Content-Type": "application/json",
      },
      body: jsonEncode(updates),
    );

    log("POST $uri -> ${response.statusCode}");
    return response.statusCode == 200;
  }
}
