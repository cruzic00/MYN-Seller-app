import 'package:myn_seller_app/helpers/shared_value_helper.dart';
import 'package:myn_seller_app/screens/login.dart';
import 'package:myn_seller_app/screens/main.dart';
import 'package:flutter/material.dart';

class AuthHelper {
  setUserData(loginResponse) {
    if (loginResponse.result == true) {
      is_logged_in.$ = true;
      access_token.$ = loginResponse.access_token;
      refresh_token.$ = loginResponse.refresh_token ?? "";
      // The Node/Mongo API has no int id; keep 0 so legacy `user_id.$ == 0`
      // guards stay meaningful instead of tripping over null.
      user_id.$ = loginResponse.user.id ?? 0;
      seller_mongo_id.$ = loginResponse.user.mongo_id;
      seller_uid.$ = loginResponse.user.uid;
      seller_username.$ = loginResponse.user.username;
      seller_role.$ = loginResponse.user.type;
      user_name.$ = loginResponse.user.name;
      user_email.$ = loginResponse.user.email;
      user_phone.$ = loginResponse.user.phone;
      avatar_original.$ = loginResponse.user.avatar_original;
    }
  }

  clearUserData() {
    is_logged_in.$ = false;
    access_token.$ = "";
    refresh_token.$ = "";
    user_id.$ = 0;
    seller_mongo_id.$ = "";
    seller_uid.$ = "";
    seller_username.$ = "";
    seller_role.$ = "";
    user_name.$ = "";
    user_email.$ = "";
    user_phone.$ = "";
    avatar_original.$ = "";
    showNotificationPermissionRequest.$ = true;
  }

  ifNotLoggedIn(context) async {
    if (is_logged_in.$ == false) {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return Login();
      }));
    }
  }

  ifLoggedIn(context) async {
    if (is_logged_in.$ == true) {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return Main();
      }));
    }
  }
}
