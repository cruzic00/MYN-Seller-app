import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myn_seller_app/app_config.dart';
import 'package:myn_seller_app/data_model/login_response.dart';
import 'package:myn_seller_app/data_model/logout_response.dart';
import 'package:myn_seller_app/data_model/user_by_token.dart';
import 'package:myn_seller_app/helpers/shared_value_helper.dart';

import '../data_model/confirm_code_response.dart';
import '../data_model/resend_code_response.dart';

class AuthRepository {
  Future<LoginResponse> getLoginResponse(String? email, String password) async {
    var postBody = jsonEncode(
        {"user_type": "delivery_boy", "phone": email, "password": password});

    try {
      final response = await http.post(
        Uri.parse("${AppConfig.BASE_URL}/auth/sellerlogin"),
        headers: {
          "Content-Type": "application/json",
          "X-Requested-With": "XMLHttpRequest"
        },
        body: postBody,
      );

      if (response.statusCode == 200) {
        return loginResponseFromJson(response.body);
      } else {
        throw Exception('Failed to login: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
      rethrow; // Rethrow the caught exception
    }
  }

  Future<int> getShowStatusResponse() async {
    try {
      if (user_id.$ == 0) {
        throw Exception('Failed to get User');
      }
      final response = await http.get(
        Uri.parse(
            "${AppConfig.BASE_URL}/${AppConfig.DELIVERY_PREFIX}/shopstatus?user_id=${user_id.$}"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${access_token.$}",
          "X-Requested-With": "XMLHttpRequest"
        },
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        return responseBody["shop_active"] ?? 0; // Default to 0 if null
      } else {
        throw Exception('Failed to load show status: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
      return 0; // Default to 0 in case of error
    }
  }

  Future<bool> changeStatusResponse(bool status) async {
    try {
      final response = await http.get(
        Uri.parse(
            "${AppConfig.BASE_URL}/${AppConfig.DELIVERY_PREFIX}/shopstatus?user_id=${user_id.$}&shop_active=${status ? 1 : 0}"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${access_token.$}",
          "X-Requested-With": "XMLHttpRequest"
        },
      );

      if (response.statusCode == 200) {
        return status;
      } else {
        throw Exception('Failed to change status: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
      return !status; // Return the opposite status in case of error
    }
  }

  Future<LogoutResponse> getLogoutResponse() async {
    try {
      final response = await http.get(
        Uri.parse("${AppConfig.BASE_URL}/auth/logout"),
        headers: {
          "Authorization": "Bearer ${access_token.$}",
          "X-Requested-With": "XMLHttpRequest"
        },
      );

      // if (response.statusCode == 200) {
      return logoutResponseFromJson(response.body);
      // } else {
      //   throw Exception('Failed to logout: ${response.body}');
      // }
    } catch (e) {
      print('Error: $e');
      rethrow; // Rethrow the caught exception
    }
  }

  Future<LoginResponse> getLoginResponseByID(String id) async {
    var postBody = jsonEncode({"id": id});

    try {
      final response = await http.post(
        Uri.parse("${AppConfig.BASE_URL}/auth/loginbyid"),
        headers: {
          "Content-Type": "application/json",
          "App-Language": app_language.$,
        },
        body: postBody,
      );

      if (response.statusCode == 200) {
        return loginResponseFromJson(response.body);
      } else {
        throw Exception('Failed to login by ID: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
      rethrow; // Rethrow the caught exception
    }
  }

  Future<ConfirmCodeResponse> getConfirmCodeResponse(
      int? userId, String verificationCode) async {
    var postBody = jsonEncode(
        {"user_id": "$userId", "verification_code": "$verificationCode"});

    try {
      final response = await http.post(
        Uri.parse("${AppConfig.BASE_URL}/auth/confirm_code"),
        headers: {
          "Content-Type": "application/json",
          "App-Language": app_language.$,
        },
        body: postBody,
      );

      if (response.statusCode == 200) {
        return confirmCodeResponseFromJson(response.body);
      } else {
        throw Exception('Failed to confirm code: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
      rethrow; // Rethrow the caught exception
    }
  }

  Future<ResendCodeResponse> getResendCodeResponse(
      int? userId, String? verifyBy) async {
    var postBody =
        jsonEncode({"user_id": "$userId", "register_by": "$verifyBy"});

    try {
      final response = await http.post(
        Uri.parse("${AppConfig.BASE_URL}/auth/resend_code"),
        headers: {
          "Content-Type": "application/json",
          "App-Language": app_language.$,
        },
        body: postBody,
      );

      if (response.statusCode == 200) {
        return resendCodeResponseFromJson(response.body);
      } else {
        throw Exception('Failed to resend code: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
      rethrow; // Rethrow the caught exception
    }
  }

  Future<UserByTokenResponse> getUserByTokenResponse() async {
    var postBody = jsonEncode({"access_token": "${access_token.$}"});

    try {
      final response = await http.post(
        Uri.parse("${AppConfig.BASE_URL}/get-user-by-access_token"),
        headers: {"Content-Type": "application/json"},
        body: postBody,
      );

      if (response.statusCode == 200) {
        return userByTokenResponseFromJson(response.body);
      } else {
        throw Exception('Failed to get user by token: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
      rethrow; // Rethrow the caught exception
    }
  }
}
