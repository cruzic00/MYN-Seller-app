import 'dart:developer';
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
import 'package:myn_seller_app/helpers/auth_helper.dart';
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

  fetch_user() async {
    var userByTokenResponse = await AuthRepository().getUserByTokenResponse();

    if (userByTokenResponse.result == true) {
      is_logged_in.$ = true;
      user_id.$ = userByTokenResponse.id;
      user_name.$ = userByTokenResponse.name;
      user_email.$ = userByTokenResponse.email;
      user_phone.$ = userByTokenResponse.phone;
      avatar_original.$ = userByTokenResponse.avatar_original;
    } else {
      AuthHelper().clearUserData();
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

  print('is login ${is_logged_in.$}');
  access_token.load().whenComplete(() {
    fetch_user();
  });
  //set dummy login data -- end

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));
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
