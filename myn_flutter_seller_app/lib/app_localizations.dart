import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

/// Callers can lookup localized strings with an instance of AppLocalizations returned
/// by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// localizationDelegates list, and the locales they support in the app's
/// supportedLocales list. For example:
///
/// ```
/// import 'gen_l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @common_login_warning.
  ///
  /// In en, this message translates to:
  /// **'You need to log in'**
  String get common_login_warning;

  /// No description provided for @common_nothing_to_pay.
  ///
  /// In en, this message translates to:
  /// **'Nothing to pay'**
  String get common_nothing_to_pay;

  /// No description provided for @common_see_details.
  ///
  /// In en, this message translates to:
  /// **'see details'**
  String get common_see_details;

  /// No description provided for @common_no_payment_method_added.
  ///
  /// In en, this message translates to:
  /// **'No payment method is added'**
  String get common_no_payment_method_added;

  /// No description provided for @common_payment_choice_warning.
  ///
  /// In en, this message translates to:
  /// **'Please choose one option to pay'**
  String get common_payment_choice_warning;

  /// No description provided for @common_no_data_available.
  ///
  /// In en, this message translates to:
  /// **'No data is available'**
  String get common_no_data_available;

  /// No description provided for @common_no_address_added.
  ///
  /// In en, this message translates to:
  /// **'No Addresses is added'**
  String get common_no_address_added;

  /// No description provided for @common_loading_more_products.
  ///
  /// In en, this message translates to:
  /// **'Loading More Products ...'**
  String get common_loading_more_products;

  /// No description provided for @common_no_more_products.
  ///
  /// In en, this message translates to:
  /// **'No More Products'**
  String get common_no_more_products;

  /// No description provided for @common_no_product_is_available.
  ///
  /// In en, this message translates to:
  /// **'No product is available'**
  String get common_no_product_is_available;

  /// No description provided for @common_loading_more_brands.
  ///
  /// In en, this message translates to:
  /// **'Loading More Brands ...'**
  String get common_loading_more_brands;

  /// No description provided for @common_no_more_brands.
  ///
  /// In en, this message translates to:
  /// **'No More Brands'**
  String get common_no_more_brands;

  /// No description provided for @common_no_brand_is_available.
  ///
  /// In en, this message translates to:
  /// **'No brand is available'**
  String get common_no_brand_is_available;

  /// No description provided for @common_loading_more_items.
  ///
  /// In en, this message translates to:
  /// **'Loading More Items ...'**
  String get common_loading_more_items;

  /// No description provided for @common_no_more_items.
  ///
  /// In en, this message translates to:
  /// **'No More Items'**
  String get common_no_more_items;

  /// No description provided for @common_no_item_is_available.
  ///
  /// In en, this message translates to:
  /// **'No item is available'**
  String get common_no_item_is_available;

  /// No description provided for @common_loading_more_shops.
  ///
  /// In en, this message translates to:
  /// **'Loading More Shops ...'**
  String get common_loading_more_shops;

  /// No description provided for @common_no_more_shops.
  ///
  /// In en, this message translates to:
  /// **'No More Shops'**
  String get common_no_more_shops;

  /// No description provided for @common_no_shop_is_available.
  ///
  /// In en, this message translates to:
  /// **'No shop is available'**
  String get common_no_shop_is_available;

  /// No description provided for @common_loading_more_histories.
  ///
  /// In en, this message translates to:
  /// **'Loading More Histories ...'**
  String get common_loading_more_histories;

  /// No description provided for @common_no_more_histories.
  ///
  /// In en, this message translates to:
  /// **'No More Histories'**
  String get common_no_more_histories;

  /// No description provided for @common_no_history_is_available.
  ///
  /// In en, this message translates to:
  /// **'No history is available'**
  String get common_no_history_is_available;

  /// No description provided for @common_loading_more_categories.
  ///
  /// In en, this message translates to:
  /// **'Loading More Categories ...'**
  String get common_loading_more_categories;

  /// No description provided for @common_no_more_categories.
  ///
  /// In en, this message translates to:
  /// **'No More Categories'**
  String get common_no_more_categories;

  /// No description provided for @common_no_category_is_available.
  ///
  /// In en, this message translates to:
  /// **'No category is available'**
  String get common_no_category_is_available;

  /// No description provided for @common_coming_soon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get common_coming_soon;

  /// No description provided for @common_close_in_all_capital.
  ///
  /// In en, this message translates to:
  /// **'CLOSE'**
  String get common_close_in_all_capital;

  /// No description provided for @common_close_in_all_lower.
  ///
  /// In en, this message translates to:
  /// **'close'**
  String get common_close_in_all_lower;

  /// No description provided for @common_close_ucfirst.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get common_close_ucfirst;

  /// No description provided for @common_cancel_in_all_capital.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get common_cancel_in_all_capital;

  /// No description provided for @common_cancel_in_all_lower.
  ///
  /// In en, this message translates to:
  /// **'cancel'**
  String get common_cancel_in_all_lower;

  /// No description provided for @common_cancel_ucfirst.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get common_cancel_ucfirst;

  /// No description provided for @common_confirm_in_all_capital.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM'**
  String get common_confirm_in_all_capital;

  /// No description provided for @common_confirm_in_all_lower.
  ///
  /// In en, this message translates to:
  /// **'confirm'**
  String get common_confirm_in_all_lower;

  /// No description provided for @common_confirm_ucfirst.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get common_confirm_ucfirst;

  /// No description provided for @common_update_in_all_capital.
  ///
  /// In en, this message translates to:
  /// **'UPDATE'**
  String get common_update_in_all_capital;

  /// No description provided for @common_update_in_all_lower.
  ///
  /// In en, this message translates to:
  /// **'update'**
  String get common_update_in_all_lower;

  /// No description provided for @common_update_ucfirst.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get common_update_ucfirst;

  /// No description provided for @common_send_in_all_capital.
  ///
  /// In en, this message translates to:
  /// **'SEND'**
  String get common_send_in_all_capital;

  /// No description provided for @common_send_in_all_lower.
  ///
  /// In en, this message translates to:
  /// **'send'**
  String get common_send_in_all_lower;

  /// No description provided for @common_send_ucfirst.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get common_send_ucfirst;

  /// No description provided for @common_clear_in_all_capital.
  ///
  /// In en, this message translates to:
  /// **'CLEAR'**
  String get common_clear_in_all_capital;

  /// No description provided for @common_clear_in_all_lower.
  ///
  /// In en, this message translates to:
  /// **'clear'**
  String get common_clear_in_all_lower;

  /// No description provided for @common_clear_ucfirst.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get common_clear_ucfirst;

  /// No description provided for @common_apply_in_all_capital.
  ///
  /// In en, this message translates to:
  /// **'APPLY'**
  String get common_apply_in_all_capital;

  /// No description provided for @common_apply_in_all_lower.
  ///
  /// In en, this message translates to:
  /// **'apply'**
  String get common_apply_in_all_lower;

  /// No description provided for @common_apply_ucfirst.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get common_apply_ucfirst;

  /// No description provided for @common_add_in_all_capital.
  ///
  /// In en, this message translates to:
  /// **'ADD'**
  String get common_add_in_all_capital;

  /// No description provided for @common_add_in_all_lower.
  ///
  /// In en, this message translates to:
  /// **'add'**
  String get common_add_in_all_lower;

  /// No description provided for @common_add_ucfirst.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get common_add_ucfirst;

  /// No description provided for @common_copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get common_copied;

  /// No description provided for @common_proceed.
  ///
  /// In en, this message translates to:
  /// **'Proceed'**
  String get common_proceed;

  /// No description provided for @common_proceed_in_all_caps.
  ///
  /// In en, this message translates to:
  /// **'PROCEED'**
  String get common_proceed_in_all_caps;

  /// No description provided for @common_submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get common_submit;

  /// No description provided for @common_view_more.
  ///
  /// In en, this message translates to:
  /// **'View More'**
  String get common_view_more;

  /// No description provided for @common_show_less.
  ///
  /// In en, this message translates to:
  /// **'Show Less'**
  String get common_show_less;

  /// No description provided for @common_selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get common_selected;

  /// No description provided for @common_creating_order.
  ///
  /// In en, this message translates to:
  /// **'Creating order ...'**
  String get common_creating_order;

  /// No description provided for @common_payment_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Payment Cancelled'**
  String get common_payment_cancelled;

  /// No description provided for @common_photo_permission.
  ///
  /// In en, this message translates to:
  /// **'Photo Permission'**
  String get common_photo_permission;

  /// No description provided for @common_app_needs_permission.
  ///
  /// In en, this message translates to:
  /// **'This app needs permission'**
  String get common_app_needs_permission;

  /// No description provided for @common_deny.
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get common_deny;

  /// No description provided for @common_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get common_settings;

  /// No description provided for @common_give_photo_permission.
  ///
  /// In en, this message translates to:
  /// **'Go to your application settings and give photo permission'**
  String get common_give_photo_permission;

  /// No description provided for @common_no_file_chosen.
  ///
  /// In en, this message translates to:
  /// **'No file is chosen'**
  String get common_no_file_chosen;

  /// No description provided for @main_drawer_not_logged_in.
  ///
  /// In en, this message translates to:
  /// **'Not Logged In'**
  String get main_drawer_not_logged_in;

  /// No description provided for @main_drawer_change_location.
  ///
  /// In en, this message translates to:
  /// **'Change Location'**
  String get main_drawer_change_location;

  /// No description provided for @main_drawer_change_language.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get main_drawer_change_language;

  /// No description provided for @main_drawer_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get main_drawer_home;

  /// No description provided for @main_drawer_profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get main_drawer_profile;

  /// No description provided for @main_drawer_orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get main_drawer_orders;

  /// No description provided for @main_drawer_my_wishlist.
  ///
  /// In en, this message translates to:
  /// **'My Wishlist'**
  String get main_drawer_my_wishlist;

  /// No description provided for @main_drawer_messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get main_drawer_messages;

  /// No description provided for @main_drawer_wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get main_drawer_wallet;

  /// No description provided for @main_drawer_login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get main_drawer_login;

  /// No description provided for @main_drawer_logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get main_drawer_logout;

  /// No description provided for @home_screen_top_categories.
  ///
  /// In en, this message translates to:
  /// **'Top Categories'**
  String get home_screen_top_categories;

  /// No description provided for @home_screen_brands.
  ///
  /// In en, this message translates to:
  /// **'Brands'**
  String get home_screen_brands;

  /// No description provided for @home_screen_top_sellers.
  ///
  /// In en, this message translates to:
  /// **'Top Sellers'**
  String get home_screen_top_sellers;

  /// No description provided for @home_screen_todays_deal.
  ///
  /// In en, this message translates to:
  /// **'Todays Deal'**
  String get home_screen_todays_deal;

  /// No description provided for @home_screen_flash_deal.
  ///
  /// In en, this message translates to:
  /// **'Flash Deal'**
  String get home_screen_flash_deal;

  /// No description provided for @home_screen_featured_categories.
  ///
  /// In en, this message translates to:
  /// **'Featured Categories'**
  String get home_screen_featured_categories;

  /// No description provided for @home_screen_featured_products.
  ///
  /// In en, this message translates to:
  /// **'Featured Products'**
  String get home_screen_featured_products;

  /// No description provided for @home_screen_search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get home_screen_search;

  /// No description provided for @home_screen_no_carousel_image_found.
  ///
  /// In en, this message translates to:
  /// **'No carousel image found'**
  String get home_screen_no_carousel_image_found;

  /// No description provided for @home_screen_no_category_found.
  ///
  /// In en, this message translates to:
  /// **'No category found'**
  String get home_screen_no_category_found;

  /// No description provided for @category_list_screen_top_categories.
  ///
  /// In en, this message translates to:
  /// **'Top Categories'**
  String get category_list_screen_top_categories;

  /// No description provided for @category_list_screen_categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get category_list_screen_categories;

  /// No description provided for @category_list_screen_view_products.
  ///
  /// In en, this message translates to:
  /// **'View Products'**
  String get category_list_screen_view_products;

  /// No description provided for @category_list_screen_view_subcategories.
  ///
  /// In en, this message translates to:
  /// **'View Sub-Categories'**
  String get category_list_screen_view_subcategories;

  /// No description provided for @category_list_screen_no_subcategories.
  ///
  /// In en, this message translates to:
  /// **'No sub categories available'**
  String get category_list_screen_no_subcategories;

  /// No description provided for @category_list_screen_all_products_of.
  ///
  /// In en, this message translates to:
  /// **'All Products of'**
  String get category_list_screen_all_products_of;

  /// No description provided for @cart_screen_cannot_order_more_than.
  ///
  /// In en, this message translates to:
  /// **'Cannot order more than'**
  String get cart_screen_cannot_order_more_than;

  /// No description provided for @cart_screen_items_of_this.
  ///
  /// In en, this message translates to:
  /// **'item(s) of this'**
  String get cart_screen_items_of_this;

  /// No description provided for @cart_screen_sure_remove_item.
  ///
  /// In en, this message translates to:
  /// **'Are you sure to remove this item ?'**
  String get cart_screen_sure_remove_item;

  /// No description provided for @cart_screen_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cart_screen_cancel;

  /// No description provided for @cart_screen_confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get cart_screen_confirm;

  /// No description provided for @cart_screen_cart_empty.
  ///
  /// In en, this message translates to:
  /// **'Cart is empty'**
  String get cart_screen_cart_empty;

  /// No description provided for @cart_screen_total_amount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get cart_screen_total_amount;

  /// No description provided for @cart_screen_update_cart.
  ///
  /// In en, this message translates to:
  /// **'UPDATE CART'**
  String get cart_screen_update_cart;

  /// No description provided for @cart_screen_proceed_to_shipping.
  ///
  /// In en, this message translates to:
  /// **'PROCEED TO SHIPPING'**
  String get cart_screen_proceed_to_shipping;

  /// No description provided for @cart_screen_shopping_cart.
  ///
  /// In en, this message translates to:
  /// **'Shopping Cart'**
  String get cart_screen_shopping_cart;

  /// No description provided for @cart_screen_please_log_in.
  ///
  /// In en, this message translates to:
  /// **'Please log in to see the cart items'**
  String get cart_screen_please_log_in;

  /// No description provided for @profile_screen_please_log_in.
  ///
  /// In en, this message translates to:
  /// **'Please log in to see the profile'**
  String get profile_screen_please_log_in;

  /// No description provided for @profile_screen_orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get profile_screen_orders;

  /// No description provided for @profile_screen_profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile_screen_profile;

  /// No description provided for @profile_screen_address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get profile_screen_address;

  /// No description provided for @profile_screen_notification.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get profile_screen_notification;

  /// No description provided for @profile_screen_purchase_history.
  ///
  /// In en, this message translates to:
  /// **'Purchase History'**
  String get profile_screen_purchase_history;

  /// No description provided for @profile_screen_earning_points.
  ///
  /// In en, this message translates to:
  /// **'Earning Points History'**
  String get profile_screen_earning_points;

  /// No description provided for @profile_screen_refund_requests.
  ///
  /// In en, this message translates to:
  /// **'Refund Requests'**
  String get profile_screen_refund_requests;

  /// No description provided for @profile_screen_in_your_cart.
  ///
  /// In en, this message translates to:
  /// **'In your cart'**
  String get profile_screen_in_your_cart;

  /// No description provided for @profile_screen_in_wishlist.
  ///
  /// In en, this message translates to:
  /// **'In wishlist'**
  String get profile_screen_in_wishlist;

  /// No description provided for @profile_screen_in_ordered.
  ///
  /// In en, this message translates to:
  /// **'In Ordered'**
  String get profile_screen_in_ordered;

  /// No description provided for @profile_screen_check_balance.
  ///
  /// In en, this message translates to:
  /// **'Check Balance'**
  String get profile_screen_check_balance;

  /// No description provided for @profile_screen_account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profile_screen_account;

  /// No description provided for @flash_deal_list_screen_flash_deal_has_ended.
  ///
  /// In en, this message translates to:
  /// **'Flashdeal has ended'**
  String get flash_deal_list_screen_flash_deal_has_ended;

  /// No description provided for @flash_deal_list_screen_ended.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get flash_deal_list_screen_ended;

  /// No description provided for @flash_deal_list_flash_deals.
  ///
  /// In en, this message translates to:
  /// **'Flash Deals'**
  String get flash_deal_list_flash_deals;

  /// No description provided for @todays_deal_products_screen_todays_deal.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Deal'**
  String get todays_deal_products_screen_todays_deal;

  /// No description provided for @top_selling_products_screen_top_selling_products.
  ///
  /// In en, this message translates to:
  /// **'Top Selling Products'**
  String get top_selling_products_screen_top_selling_products;

  /// No description provided for @filter_screen_product.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get filter_screen_product;

  /// No description provided for @filter_screen_products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get filter_screen_products;

  /// No description provided for @filter_screen_sellers.
  ///
  /// In en, this message translates to:
  /// **'Sellers'**
  String get filter_screen_sellers;

  /// No description provided for @filter_screen_brands.
  ///
  /// In en, this message translates to:
  /// **'Brands'**
  String get filter_screen_brands;

  /// No description provided for @filter_screen_categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get filter_screen_categories;

  /// No description provided for @filter_screen_filter_warning.
  ///
  /// In en, this message translates to:
  /// **'You can use filters while searching for products.'**
  String get filter_screen_filter_warning;

  /// No description provided for @filter_screen_filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter_screen_filter;

  /// No description provided for @filter_screen_sort_products_by.
  ///
  /// In en, this message translates to:
  /// **'Sort Products By'**
  String get filter_screen_sort_products_by;

  /// No description provided for @filter_screen_price_high_to_low.
  ///
  /// In en, this message translates to:
  /// **'Price high to low'**
  String get filter_screen_price_high_to_low;

  /// No description provided for @filter_screen_price_low_to_high.
  ///
  /// In en, this message translates to:
  /// **'Price low to high'**
  String get filter_screen_price_low_to_high;

  /// No description provided for @filter_screen_price_new_arrival.
  ///
  /// In en, this message translates to:
  /// **'New Arrival'**
  String get filter_screen_price_new_arrival;

  /// No description provided for @filter_screen_popularity.
  ///
  /// In en, this message translates to:
  /// **'Popularity'**
  String get filter_screen_popularity;

  /// No description provided for @filter_screen_top_rated.
  ///
  /// In en, this message translates to:
  /// **'Top Rated'**
  String get filter_screen_top_rated;

  /// No description provided for @filter_screen_maximum.
  ///
  /// In en, this message translates to:
  /// **'Maximum'**
  String get filter_screen_maximum;

  /// No description provided for @filter_screen_minimum.
  ///
  /// In en, this message translates to:
  /// **'Minimum'**
  String get filter_screen_minimum;

  /// No description provided for @filter_screen_price_range.
  ///
  /// In en, this message translates to:
  /// **'Price Range'**
  String get filter_screen_price_range;

  /// No description provided for @filter_screen_search_here.
  ///
  /// In en, this message translates to:
  /// **'Search here ?'**
  String get filter_screen_search_here;

  /// No description provided for @filter_screen_no_suggestion_available.
  ///
  /// In en, this message translates to:
  /// **'No suggestion is available'**
  String get filter_screen_no_suggestion_available;

  /// No description provided for @filter_screen_searched_for.
  ///
  /// In en, this message translates to:
  /// **'searched for'**
  String get filter_screen_searched_for;

  /// No description provided for @filter_screen_times.
  ///
  /// In en, this message translates to:
  /// **'time(s)'**
  String get filter_screen_times;

  /// No description provided for @filter_screen_found.
  ///
  /// In en, this message translates to:
  /// **'found'**
  String get filter_screen_found;

  /// No description provided for @filter_screen_loading_suggestions.
  ///
  /// In en, this message translates to:
  /// **'Loading suggestions...'**
  String get filter_screen_loading_suggestions;

  /// No description provided for @filter_screen_sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get filter_screen_sort;

  /// No description provided for @filter_screen_default.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get filter_screen_default;

  /// No description provided for @filter_screen_sort_warning.
  ///
  /// In en, this message translates to:
  /// **'You can use sorting while searching for products.'**
  String get filter_screen_sort_warning;

  /// No description provided for @filter_screen_min_max_warning.
  ///
  /// In en, this message translates to:
  /// **'Min price cannot be larger than max price'**
  String get filter_screen_min_max_warning;

  /// No description provided for @product_details_screen_copy_product_link.
  ///
  /// In en, this message translates to:
  /// **'Copy Product Link'**
  String get product_details_screen_copy_product_link;

  /// No description provided for @product_details_screen_share_options.
  ///
  /// In en, this message translates to:
  /// **'Share Options'**
  String get product_details_screen_share_options;

  /// No description provided for @product_details_screen_seller_chat_title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get product_details_screen_seller_chat_title;

  /// No description provided for @product_details_screen_seller_chat_enter_title.
  ///
  /// In en, this message translates to:
  /// **'Enter Title'**
  String get product_details_screen_seller_chat_enter_title;

  /// No description provided for @product_details_screen_seller_chat_messasge.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get product_details_screen_seller_chat_messasge;

  /// No description provided for @product_details_screen_seller_chat_enter_messasge.
  ///
  /// In en, this message translates to:
  /// **'Enter Message'**
  String get product_details_screen_seller_chat_enter_messasge;

  /// No description provided for @product_details_screen_seller_chat_title_message_empty_warning.
  ///
  /// In en, this message translates to:
  /// **'Title or message cannot be empty'**
  String get product_details_screen_seller_chat_title_message_empty_warning;

  /// No description provided for @product_details_screen_seller_chat_creation_unable_warning.
  ///
  /// In en, this message translates to:
  /// **'Could not create conversation'**
  String get product_details_screen_seller_chat_creation_unable_warning;

  /// No description provided for @product_details_screen_snackbar_added_to_cart.
  ///
  /// In en, this message translates to:
  /// **'Added to cart'**
  String get product_details_screen_snackbar_added_to_cart;

  /// No description provided for @product_details_screen_snackbar_show_cart.
  ///
  /// In en, this message translates to:
  /// **'SHOW CART'**
  String get product_details_screen_snackbar_show_cart;

  /// No description provided for @product_details_screen_description.
  ///
  /// In en, this message translates to:
  /// **'Description:'**
  String get product_details_screen_description;

  /// No description provided for @product_details_screen_brand.
  ///
  /// In en, this message translates to:
  /// **'Brand:'**
  String get product_details_screen_brand;

  /// No description provided for @product_details_screen_total_price.
  ///
  /// In en, this message translates to:
  /// **'Total Price:'**
  String get product_details_screen_total_price;

  /// No description provided for @product_details_screen_price.
  ///
  /// In en, this message translates to:
  /// **'Price:'**
  String get product_details_screen_price;

  /// No description provided for @product_details_screen_color.
  ///
  /// In en, this message translates to:
  /// **'Color:'**
  String get product_details_screen_color;

  /// No description provided for @product_details_screen_seller.
  ///
  /// In en, this message translates to:
  /// **'Seller'**
  String get product_details_screen_seller;

  /// No description provided for @product_details_screen_club_point.
  ///
  /// In en, this message translates to:
  /// **'Club Point:'**
  String get product_details_screen_club_point;

  /// No description provided for @product_details_screen_quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity:'**
  String get product_details_screen_quantity;

  /// No description provided for @product_details_screen_video_not_available.
  ///
  /// In en, this message translates to:
  /// **'Video not available'**
  String get product_details_screen_video_not_available;

  /// No description provided for @product_details_screen_video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get product_details_screen_video;

  /// No description provided for @product_details_screen_reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get product_details_screen_reviews;

  /// No description provided for @product_details_screen_seller_policy.
  ///
  /// In en, this message translates to:
  /// **'Seller Policy'**
  String get product_details_screen_seller_policy;

  /// No description provided for @product_details_screen_return_policy.
  ///
  /// In en, this message translates to:
  /// **'Return Policy'**
  String get product_details_screen_return_policy;

  /// No description provided for @product_details_screen_support_policy.
  ///
  /// In en, this message translates to:
  /// **'Support Policy'**
  String get product_details_screen_support_policy;

  /// No description provided for @product_details_screen_products_may_like.
  ///
  /// In en, this message translates to:
  /// **'Products you may also like'**
  String get product_details_screen_products_may_like;

  /// No description provided for @product_details_screen_top_selling_products_from_seller.
  ///
  /// In en, this message translates to:
  /// **'Top Selling Products from this seller'**
  String get product_details_screen_top_selling_products_from_seller;

  /// No description provided for @product_details_screen_chat_with_seller.
  ///
  /// In en, this message translates to:
  /// **'Chat with seller'**
  String get product_details_screen_chat_with_seller;

  /// No description provided for @product_details_screen_available.
  ///
  /// In en, this message translates to:
  /// **'available'**
  String get product_details_screen_available;

  /// No description provided for @product_details_screen_button_add_to_cart.
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get product_details_screen_button_add_to_cart;

  /// No description provided for @product_details_screen_button_buy_now.
  ///
  /// In en, this message translates to:
  /// **'Buy Now'**
  String get product_details_screen_button_buy_now;

  /// No description provided for @product_details_screen_no_top_selling_product.
  ///
  /// In en, this message translates to:
  /// **'No top selling products from this seller'**
  String get product_details_screen_no_top_selling_product;

  /// No description provided for @product_details_screen_no_related_product.
  ///
  /// In en, this message translates to:
  /// **'No related products'**
  String get product_details_screen_no_related_product;

  /// No description provided for @order_list_screen_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get order_list_screen_all;

  /// No description provided for @order_list_screen_paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get order_list_screen_paid;

  /// No description provided for @order_list_screen_unpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get order_list_screen_unpaid;

  /// No description provided for @order_list_screen_confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get order_list_screen_confirmed;

  /// No description provided for @order_list_screen_on_delivery.
  ///
  /// In en, this message translates to:
  /// **'On Delivery'**
  String get order_list_screen_on_delivery;

  /// No description provided for @order_list_screen_delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get order_list_screen_delivered;

  /// No description provided for @order_list_screen_no_more_orders.
  ///
  /// In en, this message translates to:
  /// **'No More Orders'**
  String get order_list_screen_no_more_orders;

  /// No description provided for @order_list_screen_loading_more_orders.
  ///
  /// In en, this message translates to:
  /// **'Loading More order ...'**
  String get order_list_screen_loading_more_orders;

  /// No description provided for @order_list_screen_purchase_history.
  ///
  /// In en, this message translates to:
  /// **'Purchase History'**
  String get order_list_screen_purchase_history;

  /// No description provided for @order_list_screen_payment_status.
  ///
  /// In en, this message translates to:
  /// **'Payment Status'**
  String get order_list_screen_payment_status;

  /// No description provided for @order_list_screen_delivery_status.
  ///
  /// In en, this message translates to:
  /// **'Delivery Status'**
  String get order_list_screen_delivery_status;

  /// No description provided for @order_details_screen_refund_product_name.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get order_details_screen_refund_product_name;

  /// No description provided for @order_details_screen_refund_order_code.
  ///
  /// In en, this message translates to:
  /// **'Order Code'**
  String get order_details_screen_refund_order_code;

  /// No description provided for @order_details_screen_refund_reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get order_details_screen_refund_reason;

  /// No description provided for @order_details_screen_refund_reason_empty_warning.
  ///
  /// In en, this message translates to:
  /// **'Reason cannot be empty'**
  String get order_details_screen_refund_reason_empty_warning;

  /// No description provided for @order_details_screen_refund_enter_reason.
  ///
  /// In en, this message translates to:
  /// **'Enter Reason'**
  String get order_details_screen_refund_enter_reason;

  /// No description provided for @order_details_screen_refund_snackbar_show_request_list.
  ///
  /// In en, this message translates to:
  /// **'Show Request List'**
  String get order_details_screen_refund_snackbar_show_request_list;

  /// No description provided for @order_details_screen_ordered_product.
  ///
  /// In en, this message translates to:
  /// **'Ordered Product'**
  String get order_details_screen_ordered_product;

  /// No description provided for @order_details_screen_no_item_ordered.
  ///
  /// In en, this message translates to:
  /// **'No items are ordered'**
  String get order_details_screen_no_item_ordered;

  /// No description provided for @order_details_screen_sub_total.
  ///
  /// In en, this message translates to:
  /// **'SUB TOTAL'**
  String get order_details_screen_sub_total;

  /// No description provided for @order_details_screen_tax.
  ///
  /// In en, this message translates to:
  /// **'TAX'**
  String get order_details_screen_tax;

  /// No description provided for @order_details_screen_shipping_cost.
  ///
  /// In en, this message translates to:
  /// **'SHIPPING COST'**
  String get order_details_screen_shipping_cost;

  /// No description provided for @order_details_screen_discount.
  ///
  /// In en, this message translates to:
  /// **'DISCOUNT'**
  String get order_details_screen_discount;

  /// No description provided for @order_details_screen_grand_total.
  ///
  /// In en, this message translates to:
  /// **'GRAND TOTAL'**
  String get order_details_screen_grand_total;

  /// No description provided for @order_details_screen_timeline_tile_order_placed.
  ///
  /// In en, this message translates to:
  /// **'Order placed'**
  String get order_details_screen_timeline_tile_order_placed;

  /// No description provided for @order_details_screen_timeline_tile_confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get order_details_screen_timeline_tile_confirmed;

  /// No description provided for @order_details_screen_timeline_tile_on_delivery.
  ///
  /// In en, this message translates to:
  /// **'On Delivery'**
  String get order_details_screen_timeline_tile_on_delivery;

  /// No description provided for @order_details_screen_timeline_tile_delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get order_details_screen_timeline_tile_delivered;

  /// No description provided for @order_details_screen_order_code.
  ///
  /// In en, this message translates to:
  /// **'Order Code'**
  String get order_details_screen_order_code;

  /// No description provided for @order_details_screen_shipping_method.
  ///
  /// In en, this message translates to:
  /// **'Shipping Method'**
  String get order_details_screen_shipping_method;

  /// No description provided for @order_details_screen_order_date.
  ///
  /// In en, this message translates to:
  /// **'Order Date'**
  String get order_details_screen_order_date;

  /// No description provided for @order_details_screen_payment_method.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get order_details_screen_payment_method;

  /// No description provided for @order_details_screen_payment_status.
  ///
  /// In en, this message translates to:
  /// **'Payment Status'**
  String get order_details_screen_payment_status;

  /// No description provided for @order_details_screen_delivery_status.
  ///
  /// In en, this message translates to:
  /// **'Delivery Status'**
  String get order_details_screen_delivery_status;

  /// No description provided for @order_details_screen_shipping_address.
  ///
  /// In en, this message translates to:
  /// **'Shipping Address'**
  String get order_details_screen_shipping_address;

  /// No description provided for @order_details_screen_total_amount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get order_details_screen_total_amount;

  /// No description provided for @order_details_screen_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get order_details_screen_name;

  /// No description provided for @order_details_screen_email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get order_details_screen_email;

  /// No description provided for @order_details_screen_address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get order_details_screen_address;

  /// No description provided for @order_details_screen_pin_code.
  ///
  /// In en, this message translates to:
  /// **'Pin Code'**
  String get order_details_screen_pin_code;

  /// No description provided for @order_details_screen_city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get order_details_screen_city;

  /// No description provided for @order_details_screen_state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get order_details_screen_state;

  /// No description provided for @order_details_screen_country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get order_details_screen_country;

  /// No description provided for @order_details_screen_phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get order_details_screen_phone;

  /// No description provided for @order_details_screen_postal_code.
  ///
  /// In en, this message translates to:
  /// **'Postal code'**
  String get order_details_screen_postal_code;

  /// No description provided for @order_details_screen_item.
  ///
  /// In en, this message translates to:
  /// **'item'**
  String get order_details_screen_item;

  /// No description provided for @order_details_screen_ask_for_refund.
  ///
  /// In en, this message translates to:
  /// **'Ask For Refund'**
  String get order_details_screen_ask_for_refund;

  /// No description provided for @order_details_screen_refund_status.
  ///
  /// In en, this message translates to:
  /// **'Refund Status'**
  String get order_details_screen_refund_status;

  /// No description provided for @order_details_screen_order_details.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get order_details_screen_order_details;

  /// No description provided for @order_details_screen_make_offline_payment.
  ///
  /// In en, this message translates to:
  /// **'Make Offline Payment'**
  String get order_details_screen_make_offline_payment;

  /// No description provided for @shipping_info_screen_address_choice_warning.
  ///
  /// In en, this message translates to:
  /// **'Choose an address'**
  String get shipping_info_screen_address_choice_warning;

  /// No description provided for @shipping_info_screen_pincode_not_match_warning.
  ///
  /// In en, this message translates to:
  /// **'Choose an address with pincode'**
  String get shipping_info_screen_pincode_not_match_warning;

  /// No description provided for @shipping_info_screen_country_warning.
  ///
  /// In en, this message translates to:
  /// **'Select a country'**
  String get shipping_info_screen_country_warning;

  /// No description provided for @shipping_info_screen_go_to_address.
  ///
  /// In en, this message translates to:
  /// **'To add or edit addresses, Go to address page'**
  String get shipping_info_screen_go_to_address;

  /// No description provided for @shipping_info_screen_address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get shipping_info_screen_address;

  /// No description provided for @shipping_info_screen_city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get shipping_info_screen_city;

  /// No description provided for @shipping_info_screen_enter_city.
  ///
  /// In en, this message translates to:
  /// **'Enter City'**
  String get shipping_info_screen_enter_city;

  /// No description provided for @shipping_info_screen_postal_code.
  ///
  /// In en, this message translates to:
  /// **'Postal Code'**
  String get shipping_info_screen_postal_code;

  /// No description provided for @shipping_info_screen_country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get shipping_info_screen_country;

  /// No description provided for @shipping_info_screen_pincode.
  ///
  /// In en, this message translates to:
  /// **'Pincode'**
  String get shipping_info_screen_pincode;

  /// No description provided for @shipping_info_screen_state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get shipping_info_screen_state;

  /// No description provided for @shipping_info_screen_phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get shipping_info_screen_phone;

  /// No description provided for @shipping_info_screen_shipping_cost.
  ///
  /// In en, this message translates to:
  /// **'Shipping Cost'**
  String get shipping_info_screen_shipping_cost;

  /// No description provided for @shipping_info_screen_btn_proceed_to_checkout.
  ///
  /// In en, this message translates to:
  /// **'PROCEED TO CHECKOUT'**
  String get shipping_info_screen_btn_proceed_to_checkout;

  /// No description provided for @messenger_list_screen_messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messenger_list_screen_messages;

  /// No description provided for @chat_screen_btn_load_more.
  ///
  /// In en, this message translates to:
  /// **'Load More'**
  String get chat_screen_btn_load_more;

  /// No description provided for @chat_screen_type_message_here.
  ///
  /// In en, this message translates to:
  /// **'Type your message here ...'**
  String get chat_screen_type_message_here;

  /// No description provided for @wallet_screen_amount_warning.
  ///
  /// In en, this message translates to:
  /// **'Amount cannot be empty'**
  String get wallet_screen_amount_warning;

  /// No description provided for @wallet_screen_my_wallet.
  ///
  /// In en, this message translates to:
  /// **'My Wallet'**
  String get wallet_screen_my_wallet;

  /// No description provided for @wallet_screen_no_recharges_yet.
  ///
  /// In en, this message translates to:
  /// **'No recharges yet'**
  String get wallet_screen_no_recharges_yet;

  /// No description provided for @wallet_screen_payment_method.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get wallet_screen_payment_method;

  /// No description provided for @wallet_screen_approval_status.
  ///
  /// In en, this message translates to:
  /// **'Approval Status'**
  String get wallet_screen_approval_status;

  /// No description provided for @wallet_screen_wallet_balance.
  ///
  /// In en, this message translates to:
  /// **'Wallet Balance'**
  String get wallet_screen_wallet_balance;

  /// No description provided for @wallet_screen_last_recharged.
  ///
  /// In en, this message translates to:
  /// **'Last recharged'**
  String get wallet_screen_last_recharged;

  /// No description provided for @wallet_screen_wallet_recharge_history.
  ///
  /// In en, this message translates to:
  /// **'Wallet Recharge History'**
  String get wallet_screen_wallet_recharge_history;

  /// No description provided for @wallet_screen_amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get wallet_screen_amount;

  /// No description provided for @wallet_screen_enter_amount.
  ///
  /// In en, this message translates to:
  /// **'Enter Amount'**
  String get wallet_screen_enter_amount;

  /// No description provided for @recharge_wallet_screen_recharge_wallet.
  ///
  /// In en, this message translates to:
  /// **'Recharge Wallet'**
  String get recharge_wallet_screen_recharge_wallet;

  /// No description provided for @checkout_screen_enter_coupon_code.
  ///
  /// In en, this message translates to:
  /// **'Enter coupon code'**
  String get checkout_screen_enter_coupon_code;

  /// No description provided for @checkout_screen_coupon_code_warning.
  ///
  /// In en, this message translates to:
  /// **'Enter coupon code'**
  String get checkout_screen_coupon_code_warning;

  /// No description provided for @checkout_screen_subtotal.
  ///
  /// In en, this message translates to:
  /// **'SUB TOTAL'**
  String get checkout_screen_subtotal;

  /// No description provided for @checkout_screen_tax.
  ///
  /// In en, this message translates to:
  /// **'TAX'**
  String get checkout_screen_tax;

  /// No description provided for @checkout_screen_shipping_cost.
  ///
  /// In en, this message translates to:
  /// **'SHIPPING COST'**
  String get checkout_screen_shipping_cost;

  /// No description provided for @checkout_screen_discount.
  ///
  /// In en, this message translates to:
  /// **'DISCOUNT'**
  String get checkout_screen_discount;

  /// No description provided for @checkout_screen_grand_total.
  ///
  /// In en, this message translates to:
  /// **'GRAND TOTAL'**
  String get checkout_screen_grand_total;

  /// No description provided for @checkout_screen_total_amount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get checkout_screen_total_amount;

  /// No description provided for @checkout_screen_coupon_code.
  ///
  /// In en, this message translates to:
  /// **'Coupon Code'**
  String get checkout_screen_coupon_code;

  /// No description provided for @checkout_screen_apply_coupon.
  ///
  /// In en, this message translates to:
  /// **'APPLY COUPON'**
  String get checkout_screen_apply_coupon;

  /// No description provided for @checkout_screen_place_my_order.
  ///
  /// In en, this message translates to:
  /// **'PLACE MY ORDER'**
  String get checkout_screen_place_my_order;

  /// No description provided for @checkout_screen_remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get checkout_screen_remove;

  /// No description provided for @checkout_screen_checkout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout_screen_checkout;

  /// No description provided for @wishlist_screen_login_warning.
  ///
  /// In en, this message translates to:
  /// **'Please log in to see the wishlist items'**
  String get wishlist_screen_login_warning;

  /// No description provided for @wishlist_screen_my_wishlist.
  ///
  /// In en, this message translates to:
  /// **'My Wishlist'**
  String get wishlist_screen_my_wishlist;

  /// No description provided for @login_screen_email_warning.
  ///
  /// In en, this message translates to:
  /// **'Enter email'**
  String get login_screen_email_warning;

  /// No description provided for @login_screen_phone_warning.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get login_screen_phone_warning;

  /// No description provided for @login_screen_password_warning.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get login_screen_password_warning;

  /// No description provided for @login_screen_login_to.
  ///
  /// In en, this message translates to:
  /// **'Login to'**
  String get login_screen_login_to;

  /// No description provided for @login_screen_or_login_with_phone.
  ///
  /// In en, this message translates to:
  /// **'or, Login with a phone number'**
  String get login_screen_or_login_with_phone;

  /// No description provided for @login_screen_or_login_with_email.
  ///
  /// In en, this message translates to:
  /// **'or, Login with an email'**
  String get login_screen_or_login_with_email;

  /// No description provided for @login_screen_email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get login_screen_email;

  /// No description provided for @login_screen_password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get login_screen_password;

  /// No description provided for @login_screen_phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get login_screen_phone;

  /// No description provided for @login_screen_forgot_password.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get login_screen_forgot_password;

  /// No description provided for @login_screen_log_in.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get login_screen_log_in;

  /// No description provided for @login_screen_or_create_new_account.
  ///
  /// In en, this message translates to:
  /// **'or, create a new account ?'**
  String get login_screen_or_create_new_account;

  /// No description provided for @login_screen_sign_up.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get login_screen_sign_up;

  /// No description provided for @login_screen_login_with.
  ///
  /// In en, this message translates to:
  /// **'Login with'**
  String get login_screen_login_with;

  /// No description provided for @registration_screen_name_warning.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get registration_screen_name_warning;

  /// No description provided for @registration_screen_email_warning.
  ///
  /// In en, this message translates to:
  /// **'Enter email'**
  String get registration_screen_email_warning;

  /// No description provided for @registration_screen_phone_warning.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get registration_screen_phone_warning;

  /// No description provided for @registration_screen_password_warning.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get registration_screen_password_warning;

  /// No description provided for @registration_screen_password_confirm_warning.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get registration_screen_password_confirm_warning;

  /// No description provided for @registration_screen_password_length_warning.
  ///
  /// In en, this message translates to:
  /// **'Password must contain atleast 6 characters'**
  String get registration_screen_password_length_warning;

  /// No description provided for @registration_screen_password_length_recommendation.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least 6 characters'**
  String get registration_screen_password_length_recommendation;

  /// No description provided for @registration_screen_password_match_warning.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get registration_screen_password_match_warning;

  /// No description provided for @registration_screen_join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get registration_screen_join;

  /// No description provided for @registration_screen_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get registration_screen_name;

  /// No description provided for @registration_screen_email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get registration_screen_email;

  /// No description provided for @registration_screen_phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get registration_screen_phone;

  /// No description provided for @registration_screen_password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get registration_screen_password;

  /// No description provided for @registration_screen_retype_password.
  ///
  /// In en, this message translates to:
  /// **'Retype Password'**
  String get registration_screen_retype_password;

  /// No description provided for @registration_screen_or_register_with_phone.
  ///
  /// In en, this message translates to:
  /// **'or, Register with a phone number'**
  String get registration_screen_or_register_with_phone;

  /// No description provided for @registration_screen_or_register_with_email.
  ///
  /// In en, this message translates to:
  /// **'or, Register with an email'**
  String get registration_screen_or_register_with_email;

  /// No description provided for @registration_screen_register_sign_up.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get registration_screen_register_sign_up;

  /// No description provided for @registration_screen_already_have_account.
  ///
  /// In en, this message translates to:
  /// **'Already have an Account ?'**
  String get registration_screen_already_have_account;

  /// No description provided for @registration_screen_log_in.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get registration_screen_log_in;

  /// No description provided for @password_forget_screen_email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get password_forget_screen_email;

  /// No description provided for @password_forget_screen_phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get password_forget_screen_phone;

  /// No description provided for @password_forget_screen_email_warning.
  ///
  /// In en, this message translates to:
  /// **'Enter email'**
  String get password_forget_screen_email_warning;

  /// No description provided for @password_forget_screen_phone_warning.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get password_forget_screen_phone_warning;

  /// No description provided for @password_forget_screen_forget_password.
  ///
  /// In en, this message translates to:
  /// **'Forget Password ?'**
  String get password_forget_screen_forget_password;

  /// No description provided for @password_forget_screen_send_code_via_phone.
  ///
  /// In en, this message translates to:
  /// **'or, send code via phone number'**
  String get password_forget_screen_send_code_via_phone;

  /// No description provided for @password_forget_screen_send_code_via_email.
  ///
  /// In en, this message translates to:
  /// **'or, send code via email'**
  String get password_forget_screen_send_code_via_email;

  /// No description provided for @otp_screen_btn_send_code.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get otp_screen_btn_send_code;

  /// No description provided for @otp_screen_verification_code_warning.
  ///
  /// In en, this message translates to:
  /// **'Enter verification code'**
  String get otp_screen_verification_code_warning;

  /// No description provided for @otp_screen_verify_your.
  ///
  /// In en, this message translates to:
  /// **'Verify your'**
  String get otp_screen_verify_your;

  /// No description provided for @otp_screen_email_account.
  ///
  /// In en, this message translates to:
  /// **'Email Account'**
  String get otp_screen_email_account;

  /// No description provided for @otp_screen_phone_number.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get otp_screen_phone_number;

  /// No description provided for @otp_screen_enter_verification_code_to_email.
  ///
  /// In en, this message translates to:
  /// **'Enter the verification code that sent to your email recently.'**
  String get otp_screen_enter_verification_code_to_email;

  /// No description provided for @otp_screen_enter_verification_code_to_phone.
  ///
  /// In en, this message translates to:
  /// **'Enter the verification code that sent to your phone recently.'**
  String get otp_screen_enter_verification_code_to_phone;

  /// No description provided for @otp_screen_confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get otp_screen_confirm;

  /// No description provided for @otp_screen_resend_code.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get otp_screen_resend_code;

  /// No description provided for @password_otp_screen_code_warning.
  ///
  /// In en, this message translates to:
  /// **'Enter the code'**
  String get password_otp_screen_code_warning;

  /// No description provided for @password_otp_screen_password_warning.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get password_otp_screen_password_warning;

  /// No description provided for @password_otp_screen_password_confirm_warning.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get password_otp_screen_password_confirm_warning;

  /// No description provided for @password_otp_screen_password_length_warning.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least 6 characters'**
  String get password_otp_screen_password_length_warning;

  /// No description provided for @password_otp_screen_password_length_recommendation.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least 6 characters'**
  String get password_otp_screen_password_length_recommendation;

  /// No description provided for @password_otp_screen_password_match_warning.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get password_otp_screen_password_match_warning;

  /// No description provided for @password_otp_screen_enter_the_code_sent.
  ///
  /// In en, this message translates to:
  /// **'Enter the code sent'**
  String get password_otp_screen_enter_the_code_sent;

  /// No description provided for @password_otp_screen_enter_verification_code_to_email.
  ///
  /// In en, this message translates to:
  /// **'Enter the verification code that sent to your email recently.'**
  String get password_otp_screen_enter_verification_code_to_email;

  /// No description provided for @password_otp_screen_enter_verification_code_to_phone.
  ///
  /// In en, this message translates to:
  /// **'Enter the verification code that sent to your phone recently.'**
  String get password_otp_screen_enter_verification_code_to_phone;

  /// No description provided for @password_otp_screen_password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password_otp_screen_password;

  /// No description provided for @password_otp_screen_retype_password.
  ///
  /// In en, this message translates to:
  /// **'Retype Password'**
  String get password_otp_screen_retype_password;

  /// No description provided for @password_otp_screen_confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get password_otp_screen_confirm;

  /// No description provided for @password_otp_screen_resend_code.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get password_otp_screen_resend_code;

  /// No description provided for @address_screen_address_warning.
  ///
  /// In en, this message translates to:
  /// **'Enter Address'**
  String get address_screen_address_warning;

  /// No description provided for @address_screen_phone_warning.
  ///
  /// In en, this message translates to:
  /// **'Enter Phone Number'**
  String get address_screen_phone_warning;

  /// No description provided for @address_screen_back_to_shipping_info.
  ///
  /// In en, this message translates to:
  /// **'Back to shipping info'**
  String get address_screen_back_to_shipping_info;

  /// No description provided for @address_screen_city_warning.
  ///
  /// In en, this message translates to:
  /// **'Select a city'**
  String get address_screen_city_warning;

  /// No description provided for @address_screen_state_warning.
  ///
  /// In en, this message translates to:
  /// **'Select a state'**
  String get address_screen_state_warning;

  /// No description provided for @address_screen_country_warning.
  ///
  /// In en, this message translates to:
  /// **'Select a country'**
  String get address_screen_country_warning;

  /// No description provided for @address_screen_pincode_warning.
  ///
  /// In en, this message translates to:
  /// **'Select a pincode'**
  String get address_screen_pincode_warning;

  /// No description provided for @address_screen_address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address_screen_address;

  /// No description provided for @address_screen_enter_address.
  ///
  /// In en, this message translates to:
  /// **'Enter Address'**
  String get address_screen_enter_address;

  /// No description provided for @address_screen_city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get address_screen_city;

  /// No description provided for @address_screen_select_city.
  ///
  /// In en, this message translates to:
  /// **'Select a city'**
  String get address_screen_select_city;

  /// No description provided for @address_screen_enter_city.
  ///
  /// In en, this message translates to:
  /// **'Enter City'**
  String get address_screen_enter_city;

  /// No description provided for @address_screen_postal_code.
  ///
  /// In en, this message translates to:
  /// **'Postal Code'**
  String get address_screen_postal_code;

  /// No description provided for @address_screen_enter_postal_code.
  ///
  /// In en, this message translates to:
  /// **'Enter Postal Code'**
  String get address_screen_enter_postal_code;

  /// No description provided for @address_screen_pincode.
  ///
  /// In en, this message translates to:
  /// **'Pincode'**
  String get address_screen_pincode;

  /// No description provided for @address_screen_select_pincode.
  ///
  /// In en, this message translates to:
  /// **'Select a pincode'**
  String get address_screen_select_pincode;

  /// No description provided for @address_screen_enter_pincode.
  ///
  /// In en, this message translates to:
  /// **'Enter Pincode'**
  String get address_screen_enter_pincode;

  /// No description provided for @address_screen_country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get address_screen_country;

  /// No description provided for @address_screen_select_country.
  ///
  /// In en, this message translates to:
  /// **'Select a country'**
  String get address_screen_select_country;

  /// No description provided for @address_screen_enter_country.
  ///
  /// In en, this message translates to:
  /// **'Enter Country'**
  String get address_screen_enter_country;

  /// No description provided for @address_screen_state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get address_screen_state;

  /// No description provided for @address_screen_select_state.
  ///
  /// In en, this message translates to:
  /// **'Select a state'**
  String get address_screen_select_state;

  /// No description provided for @address_screen_enter_state.
  ///
  /// In en, this message translates to:
  /// **'Enter State'**
  String get address_screen_enter_state;

  /// No description provided for @address_screen_phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get address_screen_phone;

  /// No description provided for @address_screen_enter_phone.
  ///
  /// In en, this message translates to:
  /// **'Enter Phone'**
  String get address_screen_enter_phone;

  /// No description provided for @address_screen_address_remove_warning.
  ///
  /// In en, this message translates to:
  /// **'Are you sure to remove this address ?'**
  String get address_screen_address_remove_warning;

  /// No description provided for @address_screen_addresses_of_user.
  ///
  /// In en, this message translates to:
  /// **'Addresses of user'**
  String get address_screen_addresses_of_user;

  /// No description provided for @address_screen_addresses_to_make_default.
  ///
  /// In en, this message translates to:
  /// **'Double tap on an address to make it default'**
  String get address_screen_addresses_to_make_default;

  /// No description provided for @address_screen_no_pincode_available.
  ///
  /// In en, this message translates to:
  /// **'No pincode available'**
  String get address_screen_no_pincode_available;

  /// No description provided for @address_screen_no_country_available.
  ///
  /// In en, this message translates to:
  /// **'No country available'**
  String get address_screen_no_country_available;

  /// No description provided for @address_screen_no_state_available.
  ///
  /// In en, this message translates to:
  /// **'No state available'**
  String get address_screen_no_state_available;

  /// No description provided for @address_screen_no_city_available.
  ///
  /// In en, this message translates to:
  /// **'No city available'**
  String get address_screen_no_city_available;

  /// No description provided for @address_screen_loading_countries.
  ///
  /// In en, this message translates to:
  /// **'Loading Countries ...'**
  String get address_screen_loading_countries;

  /// No description provided for @address_screen_loading_states.
  ///
  /// In en, this message translates to:
  /// **'Loading States ...'**
  String get address_screen_loading_states;

  /// No description provided for @address_screen_loading_cities.
  ///
  /// In en, this message translates to:
  /// **'Loading Cities ...'**
  String get address_screen_loading_cities;

  /// No description provided for @address_screen_select_a_country_first.
  ///
  /// In en, this message translates to:
  /// **'Select a country first'**
  String get address_screen_select_a_country_first;

  /// No description provided for @address_screen_select_a_state_first.
  ///
  /// In en, this message translates to:
  /// **'Select a state first'**
  String get address_screen_select_a_state_first;

  /// No description provided for @main_screen_bottom_navigation_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get main_screen_bottom_navigation_home;

  /// No description provided for @main_screen_bottom_navigation_categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get main_screen_bottom_navigation_categories;

  /// No description provided for @main_screen_bottom_navigation_cart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get main_screen_bottom_navigation_cart;

  /// No description provided for @main_screen_bottom_navigation_profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get main_screen_bottom_navigation_profile;

  /// No description provided for @bkash_screen_fetching_bkash_url.
  ///
  /// In en, this message translates to:
  /// **'Fetching bkash url ...'**
  String get bkash_screen_fetching_bkash_url;

  /// No description provided for @bkash_screen_pay_with_bkash.
  ///
  /// In en, this message translates to:
  /// **'Pay with Bkash'**
  String get bkash_screen_pay_with_bkash;

  /// No description provided for @nagad_screen_fetching_nagad_url.
  ///
  /// In en, this message translates to:
  /// **'Fetching nagad url ...'**
  String get nagad_screen_fetching_nagad_url;

  /// No description provided for @nagad_screen_pay_with_nagad.
  ///
  /// In en, this message translates to:
  /// **'Pay with Nagad'**
  String get nagad_screen_pay_with_nagad;

  /// No description provided for @iyzico_screen_pay_with_iyzico.
  ///
  /// In en, this message translates to:
  /// **'Pay with Iyzico'**
  String get iyzico_screen_pay_with_iyzico;

  /// No description provided for @paypal_screen_fetching_paypal_url.
  ///
  /// In en, this message translates to:
  /// **'Fetching paypal url ...'**
  String get paypal_screen_fetching_paypal_url;

  /// No description provided for @paypal_screen_pay_with_paypal.
  ///
  /// In en, this message translates to:
  /// **'Pay with Paypal'**
  String get paypal_screen_pay_with_paypal;

  /// No description provided for @paystack_screen_pay_with_paystack.
  ///
  /// In en, this message translates to:
  /// **'Pay with Paystack'**
  String get paystack_screen_pay_with_paystack;

  /// No description provided for @paytm_screen_pay_with_paytm.
  ///
  /// In en, this message translates to:
  /// **'Pay with Paytm'**
  String get paytm_screen_pay_with_paytm;

  /// No description provided for @razorpay_screen_pay_with_razorpay.
  ///
  /// In en, this message translates to:
  /// **'Pay with Razorpay'**
  String get razorpay_screen_pay_with_razorpay;

  /// No description provided for @sslcommerz_screen_fetching_sslcommerz_url.
  ///
  /// In en, this message translates to:
  /// **'Fetching sslcommerz url ...'**
  String get sslcommerz_screen_fetching_sslcommerz_url;

  /// No description provided for @sslcommerz_screen_pay_with_sslcommerz.
  ///
  /// In en, this message translates to:
  /// **'Pay with Sslcommerz'**
  String get sslcommerz_screen_pay_with_sslcommerz;

  /// No description provided for @stripe_screen_pay_with_stripe.
  ///
  /// In en, this message translates to:
  /// **'Pay with Stripe'**
  String get stripe_screen_pay_with_stripe;

  /// No description provided for @brand_products_screen_search_product_of_brand.
  ///
  /// In en, this message translates to:
  /// **'Search products of brand'**
  String get brand_products_screen_search_product_of_brand;

  /// No description provided for @category_products_screen_search_products_from.
  ///
  /// In en, this message translates to:
  /// **'Search products from'**
  String get category_products_screen_search_products_from;

  /// No description provided for @flash_deal_products_screen_search_products_from.
  ///
  /// In en, this message translates to:
  /// **'Search products from'**
  String get flash_deal_products_screen_search_products_from;

  /// No description provided for @change_language_change_language.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get change_language_change_language;

  /// No description provided for @change_language_no_language_is_added.
  ///
  /// In en, this message translates to:
  /// **'No language is Added'**
  String get change_language_no_language_is_added;

  /// No description provided for @club_point_screen_snackbar_points_converted.
  ///
  /// In en, this message translates to:
  /// **'Points converted to wallet'**
  String get club_point_screen_snackbar_points_converted;

  /// No description provided for @club_point_screen_snackbar_show_wallet.
  ///
  /// In en, this message translates to:
  /// **'SHOW WALLET'**
  String get club_point_screen_snackbar_show_wallet;

  /// No description provided for @club_point_screen_earned_points.
  ///
  /// In en, this message translates to:
  /// **'Earned Points'**
  String get club_point_screen_earned_points;

  /// No description provided for @club_point_screen_converted_question.
  ///
  /// In en, this message translates to:
  /// **'Converted ?'**
  String get club_point_screen_converted_question;

  /// No description provided for @club_point_screen_done.
  ///
  /// In en, this message translates to:
  /// **'DONE'**
  String get club_point_screen_done;

  /// No description provided for @club_point_screen_convert.
  ///
  /// In en, this message translates to:
  /// **'Convert'**
  String get club_point_screen_convert;

  /// No description provided for @map_location_screen_your_delivery_location.
  ///
  /// In en, this message translates to:
  /// **'Your delivery location . . .'**
  String get map_location_screen_your_delivery_location;

  /// No description provided for @map_location_screen_calculating.
  ///
  /// In en, this message translates to:
  /// **'Calculating...'**
  String get map_location_screen_calculating;

  /// No description provided for @map_location_screen_pick_here.
  ///
  /// In en, this message translates to:
  /// **'Pick Here'**
  String get map_location_screen_pick_here;

  /// No description provided for @offline_screen_amount_name_trxid_warning.
  ///
  /// In en, this message translates to:
  /// **'Amount,Name and Transaction Id are necessary'**
  String get offline_screen_amount_name_trxid_warning;

  /// No description provided for @offline_screen_photo_warning.
  ///
  /// In en, this message translates to:
  /// **'Photo proof is necessary'**
  String get offline_screen_photo_warning;

  /// No description provided for @offline_screen_offline_payment.
  ///
  /// In en, this message translates to:
  /// **'Offline Payment'**
  String get offline_screen_offline_payment;

  /// No description provided for @offline_screen_fields_mandatory.
  ///
  /// In en, this message translates to:
  /// **'All * marked fields are mandatory'**
  String get offline_screen_fields_mandatory;

  /// No description provided for @offline_screen_fill_up_necessary_info.
  ///
  /// In en, this message translates to:
  /// **'Correctly fill-up the necessary information. Later you cannot edit or re-submit the form'**
  String get offline_screen_fill_up_necessary_info;

  /// No description provided for @offline_screen_amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get offline_screen_amount;

  /// No description provided for @offline_screen_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get offline_screen_name;

  /// No description provided for @offline_screen_transaction_id.
  ///
  /// In en, this message translates to:
  /// **'Transaction Id'**
  String get offline_screen_transaction_id;

  /// No description provided for @offline_screen_photo_proof.
  ///
  /// In en, this message translates to:
  /// **'Photo Proof'**
  String get offline_screen_photo_proof;

  /// No description provided for @offline_screen_only_image_file_allowed.
  ///
  /// In en, this message translates to:
  /// **'only image file allowed'**
  String get offline_screen_only_image_file_allowed;

  /// No description provided for @product_reviews_screen_type_your_review_here.
  ///
  /// In en, this message translates to:
  /// **'Type your review here ...'**
  String get product_reviews_screen_type_your_review_here;

  /// No description provided for @product_reviews_screen_no_more_reviews.
  ///
  /// In en, this message translates to:
  /// **'No More Reviews'**
  String get product_reviews_screen_no_more_reviews;

  /// No description provided for @product_reviews_screen_loading_more_reviews.
  ///
  /// In en, this message translates to:
  /// **'Loading More Reviews ...'**
  String get product_reviews_screen_loading_more_reviews;

  /// No description provided for @product_reviews_screen_no_reviews_yet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet. Be the first one to review this product'**
  String get product_reviews_screen_no_reviews_yet;

  /// No description provided for @product_reviews_screen_reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get product_reviews_screen_reviews;

  /// No description provided for @product_reviews_screen_login_warning.
  ///
  /// In en, this message translates to:
  /// **'You need to login to give a review'**
  String get product_reviews_screen_login_warning;

  /// No description provided for @product_reviews_screen_review_empty_warning.
  ///
  /// In en, this message translates to:
  /// **'Review cannot be empty'**
  String get product_reviews_screen_review_empty_warning;

  /// No description provided for @product_reviews_screen_star_warning.
  ///
  /// In en, this message translates to:
  /// **'At least one star must be given'**
  String get product_reviews_screen_star_warning;

  /// No description provided for @profile_edit_screen_name_warning.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get profile_edit_screen_name_warning;

  /// No description provided for @profile_edit_screen_email_warning.
  ///
  /// In en, this message translates to:
  /// **'Enter email'**
  String get profile_edit_screen_email_warning;

  /// No description provided for @profile_edit_screen_phone_warning.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get profile_edit_screen_phone_warning;

  /// No description provided for @profile_edit_screen_password_warning.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get profile_edit_screen_password_warning;

  /// No description provided for @profile_edit_screen_password_confirm_warning.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get profile_edit_screen_password_confirm_warning;

  /// No description provided for @profile_edit_screen_password_length_warning.
  ///
  /// In en, this message translates to:
  /// **'Password must contain atleast 6 characters'**
  String get profile_edit_screen_password_length_warning;

  /// No description provided for @profile_edit_screen_password_match_warning.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get profile_edit_screen_password_match_warning;

  /// No description provided for @profile_edit_screen_password_length_recommendation.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least 6 characters'**
  String get profile_edit_screen_password_length_recommendation;

  /// No description provided for @profile_edit_screen_login_warning.
  ///
  /// In en, this message translates to:
  /// **'Please log in to see the profile'**
  String get profile_edit_screen_login_warning;

  /// No description provided for @profile_edit_screen_basic_information.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get profile_edit_screen_basic_information;

  /// No description provided for @profile_edit_screen_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profile_edit_screen_name;

  /// No description provided for @profile_edit_screen_password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get profile_edit_screen_password;

  /// No description provided for @profile_edit_screen_retype_password.
  ///
  /// In en, this message translates to:
  /// **'Retype Password'**
  String get profile_edit_screen_retype_password;

  /// No description provided for @profile_edit_screen_btn_update_profile.
  ///
  /// In en, this message translates to:
  /// **'Update Profile'**
  String get profile_edit_screen_btn_update_profile;

  /// No description provided for @profile_edit_screen_edit_profile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profile_edit_screen_edit_profile;

  /// No description provided for @refund_request_screen_refund_requests.
  ///
  /// In en, this message translates to:
  /// **'Refund Requests'**
  String get refund_request_screen_refund_requests;

  /// No description provided for @refund_request_screen_refund_status.
  ///
  /// In en, this message translates to:
  /// **'Refund Status'**
  String get refund_request_screen_refund_status;

  /// No description provided for @seller_details_screen_top_selling_products.
  ///
  /// In en, this message translates to:
  /// **'Top Selling Products'**
  String get seller_details_screen_top_selling_products;

  /// No description provided for @seller_details_screen_featured_products.
  ///
  /// In en, this message translates to:
  /// **'Featured Products'**
  String get seller_details_screen_featured_products;

  /// No description provided for @seller_details_screen_new_arrivals.
  ///
  /// In en, this message translates to:
  /// **'New Arrivals'**
  String get seller_details_screen_new_arrivals;

  /// No description provided for @seller_details_screen_no_featured_porducts.
  ///
  /// In en, this message translates to:
  /// **'No featured product is available from this seller'**
  String get seller_details_screen_no_featured_porducts;

  /// No description provided for @seller_details_screen_no_top_selling_products.
  ///
  /// In en, this message translates to:
  /// **'No top selling products from this seller'**
  String get seller_details_screen_no_top_selling_products;

  /// No description provided for @seller_details_screen_no_new_arrival.
  ///
  /// In en, this message translates to:
  /// **'No new arrivals'**
  String get seller_details_screen_no_new_arrival;

  /// No description provided for @seller_details_screen_btn_view_all_products.
  ///
  /// In en, this message translates to:
  /// **'View All Products From This Seller'**
  String get seller_details_screen_btn_view_all_products;

  /// No description provided for @seller_products_screen_search_products_of_shop.
  ///
  /// In en, this message translates to:
  /// **'Search products of shop'**
  String get seller_products_screen_search_products_of_shop;

  /// No description provided for @pincode_screen_loading_pincodes.
  ///
  /// In en, this message translates to:
  /// **'Loading Pincodes...'**
  String get pincode_screen_loading_pincodes;

  /// No description provided for @pincode_screen_no_pincode_is_available.
  ///
  /// In en, this message translates to:
  /// **'No pincode is available'**
  String get pincode_screen_no_pincode_is_available;

  /// No description provided for @pincode_screen_enter_pincode.
  ///
  /// In en, this message translates to:
  /// **'Enter Pincode'**
  String get pincode_screen_enter_pincode;

  /// No description provided for @pincode_screen_pincode_long_text.
  ///
  /// In en, this message translates to:
  /// **'Please enter your pincode below'**
  String get pincode_screen_pincode_long_text;

  /// No description provided for @pincode_screen_pincode_set_to.
  ///
  /// In en, this message translates to:
  /// **'Pincode set to'**
  String get pincode_screen_pincode_set_to;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
