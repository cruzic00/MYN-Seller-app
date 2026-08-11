import 'dart:convert';

import 'package:myn_seller_app/app_config.dart';

/// Models the user document returned by `GET /api/auth/me`
/// (server/controllers/auth.controller.js `getMe` -> data.user).
MynProfile mynProfileFromJson(String str) {
  final body = json.decode(str) as Map<String, dynamic>;
  final data = (body["data"] as Map<String, dynamic>?) ?? const {};
  final user = (data["user"] as Map<String, dynamic>?) ?? const {};
  return MynProfile.fromJson(user);
}

class MynProfile {
  final String businessName;
  final String username;
  final String role;
  final String email;
  final String phone;

  final String taxId;
  final String businessCategory;
  final String description;

  final String address;
  final String city;
  final String state;
  final String country;
  final String postalCode;
  final String mapLocation;

  final String logoUrl;
  final String bannerUrl;

  // Payout details. Read-only in the app: updateOwnProfile's editable-field
  // allowlist does not include them, so the app must not pretend to save them.
  final String accountHolderName;
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  final String branchName;
  final String upiId;

  MynProfile({
    required this.businessName,
    required this.username,
    required this.role,
    required this.email,
    required this.phone,
    required this.taxId,
    required this.businessCategory,
    required this.description,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.postalCode,
    required this.mapLocation,
    required this.logoUrl,
    required this.bannerUrl,
    required this.accountHolderName,
    required this.bankName,
    required this.accountNumber,
    required this.ifscCode,
    required this.branchName,
    required this.upiId,
  });

  factory MynProfile.fromJson(Map<String, dynamic> json) => MynProfile(
        businessName: _s(json["businessName"]).isNotEmpty
            ? _s(json["businessName"])
            : _s(json["name"]),
        username: _s(json["username"]),
        role: _s(json["role"]),
        email: _s(json["email"]),
        phone: _s(json["phone"]),
        taxId: _s(json["taxId"]),
        businessCategory: _s(json["businessCategory"]),
        description: _s(json["description"]),
        address: _s(json["address"]),
        city: _s(json["city"]),
        state: _s(json["state"]),
        country: _s(json["country"]),
        postalCode: _s(json["postalCode"]),
        mapLocation: _s(json["mapLocation"]),
        // The model carries two aliases for each image; take whichever is set.
        logoUrl: absoluteUrl(
            _firstNonEmpty([json["logoUrl"], json["profileImageUrl"]])),
        bannerUrl: absoluteUrl(
            _firstNonEmpty([json["bannerUrl"], json["bannerImageUrl"]])),
        accountHolderName: _s(json["accountHolderName"]),
        bankName: _s(json["bankName"]),
        accountNumber: _s(json["accountNumber"]),
        ifscCode: _s(json["ifscCode"]),
        branchName: _s(json["branchName"]),
        upiId: _s(json["upiId"]),
      );

  /// Image fields come back either absolute or rooted at the site
  /// (`/api/images/...`, `/api/proxy-image?url=...`).
  static String absoluteUrl(String raw) {
    if (raw.isEmpty) return "";
    if (raw.startsWith("http")) return raw;
    if (raw.startsWith("/")) return "${AppConfig.RAW_BASE_URL}$raw";
    return "${AppConfig.RAW_BASE_URL}/$raw";
  }

  static String _s(dynamic v) => v?.toString().trim() ?? "";

  static String _firstNonEmpty(List<dynamic> candidates) {
    for (final c in candidates) {
      final s = _s(c);
      if (s.isNotEmpty) return s;
    }
    return "";
  }
}
