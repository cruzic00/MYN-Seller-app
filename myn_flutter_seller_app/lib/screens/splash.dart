import 'dart:async';

import 'package:myn_seller_app/app_config.dart';
import 'package:myn_seller_app/my_theme.dart';
import 'package:myn_seller_app/screens/main.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class Splash extends StatefulWidget {
  @override
  _SplashState createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  PackageInfo _packageInfo = PackageInfo(
    appName: AppConfig.app_name,
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
  );

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initPackageInfo() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  Future<Widget> loadFromFuture() async {
    // <fetch data from server. ex. login>

    return Future.value(Main());
  }

  @override
  Widget build(BuildContext context) {
    return CustomSplashScreen(
      //comment this
      seconds: 5,
      //comment this
      navigateAfterSeconds: Main(),
      // navigateAfterFuture: loadFromFuture(), //uncomment this
      // title: Text(
      //   "V " + _packageInfo.version,
      //   style: TextStyle(
      //       fontWeight: FontWeight.bold,
      //       fontSize: 16.0,
      //       color: MyTheme.dark_grey),
      // ),
      useLoader: false,
      loadingText: Text(
        AppConfig.copyright_text,
        style: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 14.0,
          color: Colors.white,
        ),
      ),
      backgroundImage: Image.asset(
        "assets/splashscreen.gif",
        fit: BoxFit.cover,
      ),
    );
  }
}

class CustomSplashScreen extends StatefulWidget {
  final int? seconds;
  final Text? title;
  final Color? backgroundColor;
  final TextStyle? styleTextUnderTheLoader;
  final dynamic navigateAfterSeconds;
  final double? photoSize;
  final double? backgroundPhotoSize;
  final dynamic onClick;
  final Color? loaderColor;
  final Image? image;
  final Image? backgroundImage;
  final Text? loadingText;
  final ImageProvider? imageBackground;
  final Gradient? gradientBackground;
  final bool? useLoader;
  final Route? pageRoute;
  final String? routeName;
  final Future<dynamic>? navigateAfterFuture;

  CustomSplashScreen({
    this.loaderColor,
    this.navigateAfterFuture,
    this.seconds,
    this.photoSize,
    this.backgroundPhotoSize,
    this.pageRoute,
    this.onClick,
    this.navigateAfterSeconds,
    this.title = const Text(''),
    this.backgroundColor = Colors.white,
    this.styleTextUnderTheLoader = const TextStyle(
      fontSize: 18.0,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
    this.image,
    this.backgroundImage,
    this.loadingText = const Text(""),
    this.imageBackground,
    this.gradientBackground,
    this.useLoader = true,
    this.routeName,
  });

  factory CustomSplashScreen.timer({
    required int seconds,
    Color? loaderColor,
    Color? backgroundColor,
    double? photoSize,
    Text? loadingText,
    Image? image,
    Route? pageRoute,
    dynamic onClick,
    dynamic navigateAfterSeconds,
    Text? title,
    TextStyle? styleTextUnderTheLoader,
    ImageProvider? imageBackground,
    Gradient? gradientBackground,
    bool? useLoader,
    String? routeName,
  }) =>
      CustomSplashScreen(
        loaderColor: loaderColor,
        seconds: seconds,
        photoSize: photoSize,
        loadingText: loadingText,
        backgroundColor: backgroundColor,
        image: image,
        pageRoute: pageRoute,
        onClick: onClick,
        navigateAfterSeconds: navigateAfterSeconds,
        title: title,
        styleTextUnderTheLoader: styleTextUnderTheLoader,
        imageBackground: imageBackground,
        gradientBackground: gradientBackground,
        useLoader: useLoader,
        routeName: routeName,
      );

  factory CustomSplashScreen.network({
    required Future<dynamic> navigateAfterFuture,
    Color? loaderColor,
    Color? backgroundColor,
    double? photoSize,
    double? backgroundPhotoSize,
    Text? loadingText,
    Image? image,
    Route? pageRoute,
    dynamic onClick,
    dynamic navigateAfterSeconds,
    Text? title,
    TextStyle? styleTextUnderTheLoader,
    ImageProvider? imageBackground,
    Gradient? gradientBackground,
    bool? useLoader,
    String? routeName,
  }) =>
      CustomSplashScreen(
        loaderColor: loaderColor,
        navigateAfterFuture: navigateAfterFuture,
        photoSize: photoSize,
        backgroundPhotoSize: backgroundPhotoSize,
        loadingText: loadingText,
        backgroundColor: backgroundColor,
        image: image,
        pageRoute: pageRoute,
        onClick: onClick,
        navigateAfterSeconds: navigateAfterSeconds,
        title: title,
        styleTextUnderTheLoader: styleTextUnderTheLoader,
        imageBackground: imageBackground,
        gradientBackground: gradientBackground,
        useLoader: useLoader,
        routeName: routeName,
      );

  @override
  _CustomSplashScreenState createState() => _CustomSplashScreenState();
}

class _CustomSplashScreenState extends State<CustomSplashScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.navigateAfterFuture == null) {
      Timer(Duration(seconds: widget.seconds!), () {
        if (widget.navigateAfterSeconds is String) {
          Navigator.of(context)
              .pushReplacementNamed(widget.navigateAfterSeconds);
        } else if (widget.navigateAfterSeconds is Widget) {
          Navigator.of(context).pushReplacement(
            widget.pageRoute != null
                ? widget.pageRoute!
                : MaterialPageRoute(builder: (BuildContext context) {
                    return Scaffold(body: widget.navigateAfterSeconds);
                  }),
          );
        } else {
          throw ArgumentError(
              'widget.navigateAfterSeconds must either be a String or Widget');
        }
      });
    } else {
      widget.navigateAfterFuture!.then((navigateTo) {
        if (navigateTo is String) {
          Navigator.of(context).pushReplacementNamed(navigateTo);
        } else if (navigateTo is Widget) {
          Navigator.of(context).pushReplacement(
            widget.pageRoute != null
                ? widget.pageRoute!
                : MaterialPageRoute(builder: (BuildContext context) {
                    return Scaffold(body: navigateTo);
                  }),
          );
        } else {
          throw ArgumentError(
              'widget.navigateAfterFuture must either be a String or Widget');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: widget.backgroundImage != null
                ? Image.asset(
                    "assets/splashscreen.gif",
                    fit: BoxFit.cover,
                  )
                : Container(),
          ),
          Positioned.fill(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: MediaQuery.of(context).size.height / 4.5),
              Text(
                "The Seller",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 46.0,
                    color: MyTheme.accent_color),
              ),
              widget.title!,
              widget.image != null
                  ? Hero(
                      tag: "splashscreenImage",
                      child: Container(child: widget.image),
                    )
                  : Container(),
            ],
          )),
          Positioned.fill(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                SizedBox(height: 20),
                widget.loadingText!,
                SizedBox(height: 10),
              ]))
        ],
      ),
    );
  }
}
