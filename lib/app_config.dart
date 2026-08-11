var this_year = DateTime.now().year.toString();

class AppConfig {
  static String copyright_text =
      "@ MYN " + this_year; //this shows in the splash screen
  static String app_name = "MYN The Seller"; //this shows in the splash screen

  //configure this
  static const bool HTTPS = true;

  //configure this
  static const DOMAIN_PATH = "safesmilez.com";
  //static const DOMAIN_PATH = "demo.activeitzone.com/ecommerce_flutter_demo";
  // static const DOMAIN_PATH = "dopmarket.com";

  //do not configure these below
  // Legacy Active-eCommerce (Laravel) CMS prefix. Endpoints that have not been
  // migrated to the MYN online-shop Node API still hang off this.
  static const String API_ENDPATH = "api/v2";

  // The MYN online-shop Node API mounts every route group under /api
  // (see myn-onlineshop/server/routes/index.js). Migrated calls use MYN_BASE_URL.
  static const String MYN_API_ENDPATH = "api";

  static const String PUBLIC_FOLDER = "public";
  static const String DELIVERY_PREFIX = "delivery-boy";
  static const String PROTOCOL = HTTPS ? "https://" : "http://";
  static const String RAW_BASE_URL = "${PROTOCOL}${DOMAIN_PATH}";
  static const String BASE_URL = "${RAW_BASE_URL}/${API_ENDPATH}";
  static const String MYN_BASE_URL = "${RAW_BASE_URL}/${MYN_API_ENDPATH}";

  //configure this if you are using amazon s3 like services
  //give direct link to file like https://[[bucketname]].s3.ap-southeast-1.amazonaws.com/
  //otherwise do not change anythink
  static const String BASE_PATH = "${RAW_BASE_URL}/${PUBLIC_FOLDER}/";
  static const String BASE_IMAGE_PATH = "https://safesmilez1.s3.ap-south-1.amazonaws.com/";
}
