import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:myn_seller_app/app_config.dart';
import 'package:myn_seller_app/data_model/device_token_update_response.dart';
import 'package:myn_seller_app/data_model/profile_image_update_response.dart';
import 'package:myn_seller_app/data_model/profile_update_response.dart';
import 'package:myn_seller_app/helpers/shared_value_helper.dart';

class ProfileRepository {
  Future<ProfileUpdateResponse> getProfileUpdateResponse(
      String name, String email, String phone) async {
    var postBody = jsonEncode({
      "id": user_id.$,
      "name": name,
      "email": email,
      "phone": phone,
    });

    Uri url = Uri.parse("${AppConfig.BASE_URL}/profile/update");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${access_token.$}",
        },
        body: postBody,
      );

      log("Request URL: $url");
      log("Request Body: $postBody");
      log("Response Status: ${response.statusCode}");
      log("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return profileUpdateResponseFromJson(response.body);
      } else {
        log('Failed to update profile: ${response.body}');
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      log('Error updating profile: $e');
      rethrow;
    }
  }

  Future<DeviceTokenUpdateResponse> getDeviceTokenUpdateLoginResponse(
      String userID, String deviceToken) async {
    var postBody = jsonEncode({
      "id": userID,
      "device_token": deviceToken,
    });

    Uri url = Uri.parse("${AppConfig.BASE_URL}/profile/update-device-token");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$,
        },
        body: postBody,
      );

      log("Request URL: $url");
      log("Request Body: $postBody");
      log("Response Status: ${response.statusCode}");
      log("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return deviceTokenUpdateResponseFromJson(response.body);
      } else {
        log('Failed to update device token: ${response.body}');
        throw Exception('Failed to update device token');
      }
    } catch (e) {
      log('Error updating device token: $e');
      rethrow;
    }
  }

  Future<ProfileImageUpdateResponse> getProfileImageUpdateResponse(
      String image, String filename) async {
    var postBody = jsonEncode({
      "id": user_id.$,
      "image": image,
      "filename": filename,
    });

    Uri url = Uri.parse("${AppConfig.BASE_URL}/profile/update-image");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${access_token.$}",
        },
        body: postBody,
      );

      log("Request URL: $url");
      log("Request Body: $postBody");
      log("Response Status: ${response.statusCode}");
      log("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return profileImageUpdateResponseFromJson(response.body);
      } else {
        log('Failed to update profile image: ${response.body}');
        throw Exception('Failed to update profile image');
      }
    } catch (e) {
      log('Error updating profile image: $e');
      rethrow;
    }
  }
}
