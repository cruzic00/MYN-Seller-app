// To parse this JSON data, do
//
//     final loginResponse = loginResponseFromJson(jsonString);

import 'dart:convert';

LoginResponse loginResponseFromJson(String str) =>
    LoginResponse.fromJson(json.decode(str));

String loginResponseToJson(LoginResponse data) => json.encode(data.toJson());

class LoginResponse {
  LoginResponse({
    this.result,
    this.message,
    this.access_token,
    this.refresh_token,
    this.token_type,
    this.expires_at,
    this.user,
  });

  bool? result;
  String? message;
  String? access_token;

  /// Long-lived token the app trades for a new access_token when the short one
  /// expires, so a seller is not signed out a couple of hours after logging in.
  String? refresh_token;
  String? token_type;
  DateTime? expires_at;
  User? user;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    // The MYN online-shop Node API wraps every payload in
    // { success, statusCode, message, data: {...}, timestamp } (ApiResponse).
    // The legacy Laravel CMS returned the fields at the top level instead, so
    // support both shapes while endpoints are being migrated.
    if (json.containsKey("success")) {
      final data = (json["data"] ?? const {}) as Map<String, dynamic>;
      return LoginResponse(
        result: json["success"] == true,
        message: json["message"],
        access_token: data["token"],
        refresh_token: data["refreshToken"],
        token_type: "Bearer",
        // The Node API signs JWTs with expiresIn: '24h' and does not return an
        // explicit expiry, so derive it rather than leaving it null.
        expires_at: data["token"] == null
            ? null
            : DateTime.now().add(const Duration(hours: 24)),
        user: data["user"] == null
            ? null
            : User.fromJson(data["user"] as Map<String, dynamic>),
      );
    }

    return LoginResponse(
      result: json["result"],
      message: json["message"],
      access_token: json["access_token"] == null ? null : json["access_token"],
      token_type: json["token_type"] == null ? null : json["token_type"],
      expires_at: json["expires_at"] == null
          ? null
          : DateTime.parse(json["expires_at"]),
      user: json["user"] == null ? null : User.fromJson(json["user"]),
    );
  }

  Map<String, dynamic> toJson() => {
        "result": result,
        "message": message,
        "access_token": access_token == null ? null : access_token,
        "token_type": token_type == null ? null : token_type,
        "expires_at": expires_at == null ? null : expires_at!.toIso8601String(),
        "user": user == null ? null : user!.toJson(),
      };
}

class User {
  User({
    this.id,
    this.mongo_id,
    this.uid,
    this.username,
    this.type,
    this.name,
    this.email,
    this.avatar,
    this.avatar_original,
    this.phone,
  });

  /// Legacy Laravel auto-increment id. Always null against the Node API, which
  /// identifies sellers by [mongo_id] / [uid] instead.
  int? id;

  /// MongoDB ObjectId (`_id`) as returned by the MYN online-shop API.
  String? mongo_id;

  /// Business-facing seller id the Node API keys most routes off (`:uid`).
  String? uid;
  String? username;
  String? type;
  String? name;
  String? email;
  String? avatar;
  String? avatar_original;
  String? phone;

  factory User.fromJson(Map<String, dynamic> json) {
    // Node/Mongo shape: _id, username, uid, role, businessName, email, phone.
    if (json.containsKey("_id") || json.containsKey("uid")) {
      return User(
        id: null,
        mongo_id: json["_id"]?.toString(),
        uid: json["uid"]?.toString(),
        username: json["username"],
        type: json["role"],
        // Sellers are shown by business name; fall back to the login name.
        name: json["businessName"] ?? json["username"],
        email: json["email"],
        avatar: json["avatar"],
        avatar_original: json["avatar"],
        phone: json["phone"] ?? json["mobileNumber"],
      );
    }

    return User(
      id: json["id"],
      type: json["type"],
      name: json["name"],
      email: json["email"],
      avatar: json["avatar"],
      avatar_original: json["avatar_original"],
      phone: json["phone"],
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "_id": mongo_id,
        "uid": uid,
        "username": username,
        "type": type,
        "name": name,
        "email": email,
        "avatar": avatar,
        "avatar_original": avatar_original,
        "phone": phone,
      };
}
