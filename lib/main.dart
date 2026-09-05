import 'dart:developer';
import 'package:myn_seller_app/myn_palette.dart';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myn_seller_app/app_config.dart';
import 'package:myn_seller_app/app_localizations.dart';
import 'package:myn_seller_app/firebase_options.dart';
import 'package:myn_seller_app/helpers/session_manager.dart';
import 'package:myn_seller_app/helpers/shared_value_helper.dart';
import 'package:myn_seller_app/my_theme.dart';
import 'package:myn_seller_app/repositories/auth_repository.dart';
import 'package:myn_seller_app/screens/splash.dart';
import 'package:myn_seller_app/ui_elements/notification_card.dart';
import 'package:one_context/one_context.dart';
import 'package:shared_value/shared_value.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Background Message Has Come ${message.data}");

  // MYN order pushes carry a `notification` block, so Android draws the tray
  // entry itself while the app is backgrounded or killed. Drawing a second one
  // here would show the seller the same order twice.
  if (message.data['type'] == 'new_order') return;

  NotificationService.showCustomNotification(message.data);
}

main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    FirebaseApp app = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Initialized default app $app');
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Refreshes the cached profile from the session token.
  //
  // POST /get-user-by-access_token is a legacy Laravel route the MYN API does
  // not have — it answers 404 with an HTML page, parsing that throws, and the
  // throw escaped as an unhandled exception on every cold start. Wrapped so it
  // cannot, and deliberately NOT calling clearUserData() on a failure: a 404 or
  // a dead network is not proof the session expired, and signing the seller out
  // over one is worse than showing the details login already persisted.
  fetch_user() async {
    try {
      var userByTokenResponse = await AuthRepository().getUserByTokenResponse();

      if (userByTokenResponse.result == true) {
        is_logged_in.$ = true;
        user_id.$ = userByTokenResponse.id;
        user_name.$ = userByTokenResponse.name;
        user_email.$ = userByTokenResponse.email;
        user_phone.$ = userByTokenResponse.phone;
        avatar_original.$ = userByTokenResponse.avatar_original;
      }
    } catch (e) {
      log("Profile refresh skipped: $e");
    }
  }

  is_logged_in.load();
  user_id.load();
  user_name.load();
  user_email.load();
  user_phone.load();
  showNotificationPermissionRequest.load();

  // MYN online-shop seller identity. Without these the API calls that key off
  // :uid are built with an empty identifier after a cold start.
  seller_mongo_id.load();
  seller_uid.load();
  seller_username.load();
  seller_role.load();
  seller_business_category.load();

  print('is login ${is_logged_in.$}');
  // Deliberately not awaited: SharedValue.load() calls setState, which throws
  // "SharedValue was not initalized" until wrapApp has run — so nothing here may
  // block runApp below. The session is renewed inside the callback instead,
  // which lands after the first frame.
  access_token.load().whenComplete(() async {
    await refresh_token.load();
    // The access token expires in a couple of hours. Without this an app
    // reopened the next morning ran every request with a dead token and painted
    // errors on every card.
    await SessionManager.ensureFresh();
    fetch_user();
  });
  //set dummy login data -- end

  // Draw under the status and navigation bars. Without this the gesture bar
  // stayed an opaque strip the page could not reach, so every screen ended in a
  // black band above the home indicator instead of running to the bottom edge.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(MynPalette.overlayDark);
  runApp(
    SharedValue.wrapApp(
      MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return MaterialApp(
      builder: OneContext().builder,
      navigatorKey: OneContext().key,
      title: AppConfig.app_name,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: MyTheme.white,
        navigationBarTheme: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.all(
            TextStyle(
                fontWeight: FontWeight.w800,
                color: MyTheme.dark_grey,
                fontSize: 12),
          ),
        ),
        primaryColor: MyTheme.accent_color,
        dialogBackgroundColor: MyTheme.white,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: GoogleFonts.robotoTextTheme(textTheme).copyWith(
          bodyLarge: GoogleFonts.roboto(textStyle: textTheme.bodyLarge!),
          bodyMedium: GoogleFonts.roboto(textStyle: textTheme.bodyMedium!),
          bodySmall: GoogleFonts.roboto(textStyle: textTheme.bodySmall!),
        ),
        colorScheme:
            ColorScheme.fromSwatch().copyWith(secondary: MyTheme.accent_color),
      ),
      home: Splash(),
    );
  }
}
