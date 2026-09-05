import 'package:shared_value/shared_value.dart';

final SharedValue<bool> is_logged_in = SharedValue(
  value: false, // initial value
  key: "is_logged_in", // disk storage key for shared_preferences
  autosave: true, // autosave to shared prefs when value changes
);
final SharedValue<bool> app_language_rtl = SharedValue(
  value: false, // initial value
  key: "app_language_rtl", // disk storage key for shared_preferences
);
final SharedValue<String?> access_token = SharedValue(
  value: "", // initial value
  key: "access_token", // disk storage key for shared_preferences
  autosave: true, // autosave to shared prefs when value changes
);

/// Traded for a new access_token when that one expires. See SessionManager:
/// without it the seller was signed out a couple of hours after logging in.
final SharedValue<String?> refresh_token = SharedValue(
  value: "", // initial value
  key: "refresh_token", // disk storage key for shared_preferences
  autosave: true, // autosave to shared prefs when value changes
);
final SharedValue<String> app_language = SharedValue(
  value: "en", // initial value
  key: "app_language", // disk storage key for shared_preferences
);
final SharedValue<bool> is_updated_version = SharedValue(
  value: true, // initial value
  key: "is_updated_version", // disk storage key for shared_preferences
  autosave: true, // autosave to shared prefs when value changes
);
final SharedValue<bool> has_internet = SharedValue(
  value: true, // initial value
  key: "has_internet", // disk storage key for shared_preferences
  autosave: true, // autosave to shared prefs when value changes
);
final SharedValue<int?> user_id = SharedValue(
  value: 0, // initial value
  key: "user_id", // disk storage key for shared_preferences
  autosave: true, // autosave to shared prefs when value changes
);
final SharedValue<bool> showNotificationPermissionRequest = SharedValue(
  value: true, // initial value
  key:
      "showNotificationPermissionRequest", // disk storage key for shared_preferences
  autosave: true, // autosave to shared prefs when value changes
);
final SharedValue<String> showNotificationToken = SharedValue(
  value: "", // initial value
  key: "showNotificationToken", // disk storage key for shared_preferences
  autosave: true, // autosave to shared prefs when value changes
);
final SharedValue<bool> shop_active = SharedValue(
  value: false, // initial value
  key: "shop_active", // disk storage key for shared_preferences
  autosave: true, // autosave to shared prefs when value changes
);

final SharedValue<String?> avatar_original = SharedValue(
  value: "", // initial value
  key: "avatar_original", // disk storage key for shared_preferences
  autosave: true, // autosave to shared prefs when value changes
);

final SharedValue<String?> user_name = SharedValue(
  value: "", // initial value
  key: "user_name", // disk storage key for shared_preferences
  autosave: true, // autosave to shared prefs when value changes
);

// ── MYN online-shop (MongoDB) seller identity ──────────────────────────────
// The legacy Laravel API identified a seller by an int `user_id`. MongoDB uses
// String ObjectIds, and the Node API keys most seller routes off `uid`, so the
// String identity is kept alongside `user_id` while endpoints are migrated.

final SharedValue<String?> seller_mongo_id = SharedValue(
  value: "", // MongoDB _id of the logged-in seller
  key: "seller_mongo_id", // disk storage key for shared_preferences
  autosave: true, // autosave to shared prefs when value changes
);

final SharedValue<String?> seller_uid = SharedValue(
  value: "", // business-facing seller id used as :uid in Node routes
  key: "seller_uid", // disk storage key for shared_preferences
  autosave: true, // autosave to shared prefs when value changes
);

final SharedValue<String?> seller_username = SharedValue(
  value: "", // login username
  key: "seller_username", // disk storage key for shared_preferences
  autosave: true, // autosave to shared prefs when value changes
);

final SharedValue<String?> seller_role = SharedValue(
  value: "", // role returned by the API (seller, admin, ...)
  key: "seller_role", // disk storage key for shared_preferences
  autosave: true, // autosave to shared prefs when value changes
);

final SharedValue<String?> user_email = SharedValue(
  value: "", // initial value
  key: "user_email", // disk storage key for shared_preferences
  autosave: true, // autosave to shared prefs when value changes
);

final SharedValue<String?> user_phone = SharedValue(
  value: "", // initial value
  key: "user_phone", // disk storage key for shared_preferences
  autosave: true, // autosave to shared prefs when value changes
);

/// The seller's businessCategory, cached from GET /api/auth/me.
///
/// Decides which product form the app shows: a restaurant edits dishes with
/// portions and addons, a hypermarket edits stock lines with supplier price and
/// GST. The server draws the same line — routes/businessDataRoutes.js matches
/// businessCategory against a food keyword list to pick RestaurantSellerProduct
/// over SellerProduct — so the app must use the same list, kept in
/// isFoodBusiness() below.
final SharedValue<String?> seller_business_category = SharedValue(
  value: "",
  key: "seller_business_category", // disk storage key for shared_preferences
  autosave: true, // autosave to shared prefs when value changes
);

/// Mirrors `foodKeywords` in routes/businessDataRoutes.js. If the two ever drift
/// the app would offer portions on an item the server files as a stock line.
bool isFoodBusiness() {
  const foodKeywords = [
    "restaurant",
    "hotal",
    "hotel",
    "bakery",
    "cafe",
    "home food",
  ];
  final category = (seller_business_category.$ ?? "").toLowerCase();
  return foodKeywords.any(category.contains);
}

/// Shop logo and banner, cached from GET /api/auth/me.
///
/// The side panel is built before any screen fetches a profile, so it read
/// avatar_original — a legacy Laravel field the MYN API never fills — and every
/// seller got the initial-letter monogram. These are set when the dashboard
/// loads the profile and persist, so the panel is right from the next launch on.
final SharedValue<String?> seller_logo_url = SharedValue(
  value: "",
  key: "seller_logo_url", // disk storage key for shared_preferences
  autosave: true, // autosave to shared prefs when value changes
);

final SharedValue<String?> seller_banner_url = SharedValue(
  value: "",
  key: "seller_banner_url", // disk storage key for shared_preferences
  autosave: true, // autosave to shared prefs when value changes
);
