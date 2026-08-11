import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:myn_seller_app/helpers/common_utility.dart';
import 'package:myn_seller_app/helpers/shared_value_helper.dart';
import 'package:myn_seller_app/my_theme.dart';
import 'package:myn_seller_app/repositories/auth_repository.dart';
import 'package:myn_seller_app/screens/home.dart';
import 'package:myn_seller_app/screens/login.dart';
import 'package:myn_seller_app/screens/pending.dart';
import 'package:myn_seller_app/screens/productlist.dart';
import 'package:permission_handler/permission_handler.dart';

class Main extends StatefulWidget {
  final int startingIndex;

  Main({this.startingIndex = 0});

  @override
  _MainState createState() => _MainState(startingIndex);
}

class _MainState extends State<Main> {
  int _currentIndex;

  StreamSubscription? _internetConnectionStreamSubscription;

  var _children = [
    Home(),
    Pending(
      index: 2,
    ),
    CategoryProducts()
  ];

  _MainState(this._currentIndex);

  void onTapped(int i) {
    setState(() {
      _currentIndex = i;
    });
  }

  Future<void> fetchShowStatus() async {
    var showStatusResponse = await AuthRepository().getShowStatusResponse();

    if (showStatusResponse == 1) {
      setState(() {
        shop_active.$ = true;
      });
    } else {
      setState(() {
        shop_active.$ = false;
      });
    }
  }

  @override
  void initState() {
    // Reappear status bar in case it was not there in the previous page
    super.initState();
    _internetConnectionStreamSubscription =
        InternetConnection().onStatusChange.listen((event) {
      switch (event) {
        case InternetStatus.connected:
          has_internet.$ = true;
          _hideNoInternetBottomSheet();
          break;
        case InternetStatus.disconnected:
          has_internet.$ = false;
          _showNoInternetBottomSheet();
          break;
        default:
          has_internet.$ = false;
          _showNoInternetBottomSheet();
          break;
      }
    });
    initFunction();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
    fetchShowStatus();
  }

  void initFunction() async {
    showNotificationPermissionRequest.$ =
        await Permission.notification.isDenied;
  }

  void _showNoInternetBottomSheet() {
    if (!has_internet.$) {
      showModalBottomSheet(
        context: context,
        isDismissible: false,
        enableDrag: false,
        builder: (context) {
          return Container(
            padding: EdgeInsets.all(16.0),
            color: Colors.red,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'No Internet Connection',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Please check your internet settings.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  void _hideNoInternetBottomSheet() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    _internetConnectionStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (willpop) => onPopInvoked(willpop, context),
      child: access_token.$!.isNotEmpty
          ? Scaffold(
              extendBody: true,
              body: _children[_currentIndex],
              bottomNavigationBar: NavigationBar(
                elevation: 2,
                selectedIndex: _currentIndex,
                onDestinationSelected: onTapped,
                indicatorColor: MyTheme.accent_color_2,
                backgroundColor: MyTheme.white,
                destinations: [
                  NavigationDestination(
                    icon: Icon(
                      Icons.dashboard_outlined,
                      color: MyTheme.dark_grey,
                    ),
                    selectedIcon: Icon(
                      Icons.dashboard,
                      color: MyTheme.accent_color,
                    ),
                    label: "Dashboard",
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.receipt_long_outlined,
                      color: MyTheme.dark_grey,
                    ),
                    selectedIcon: Icon(
                      Icons.receipt_long,
                      color: MyTheme.accent_color,
                    ),
                    label: "Orders",
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.store_outlined,
                      color: MyTheme.dark_grey,
                    ),
                    selectedIcon: Icon(
                      Icons.store,
                      color: MyTheme.accent_color,
                    ),
                    label: "Products",
                  ),
                ],
              ),
            )
          : Login(),
    );
  }
}
