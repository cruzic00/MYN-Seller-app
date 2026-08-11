import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:myn_seller_app/helpers/common_utility.dart';
import 'package:myn_seller_app/helpers/shared_value_helper.dart';
import 'package:myn_seller_app/repositories/auth_repository.dart';
import 'package:myn_seller_app/ui_elements/magic_nav_bar.dart';
import 'package:myn_seller_app/screens/home.dart';
import 'package:myn_seller_app/screens/login.dart';
import 'package:myn_seller_app/screens/myn_orders.dart';
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

  /// Guards against stacking a second sheet when the connection flaps, and
  /// tells _hideNoInternetBottomSheet whether there is anything to close.
  bool _noInternetSheetOpen = false;

  final List<Widget> _children = [
    Home(),
    MynOrders(),
    CategoryProducts(),
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
    if (!has_internet.$ && !_noInternetSheetOpen && mounted) {
      _noInternetSheetOpen = true;
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

  /// Closes only the sheet this class opened.
  ///
  /// This used to popUntil(isFirst), which threw the seller out of whatever
  /// screen they were on the moment the connection came back — mid-order,
  /// mid-scan, anywhere. The flag tracks our own sheet so nothing else is
  /// touched.
  void _hideNoInternetBottomSheet() {
    if (!_noInternetSheetOpen || !mounted) return;
    _noInternetSheetOpen = false;
    Navigator.of(context).pop();
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
              // IndexedStack, not _children[_currentIndex]: indexing tore the
              // other two tabs out of the tree, so every switch disposed their
              // state and re-ran their network fetch. Keeping all three mounted
              // makes tab changes instant and stops the refetch on each tap.
              body: IndexedStack(index: _currentIndex, children: _children),
              bottomNavigationBar: MagicNavBar(
                currentIndex: _currentIndex,
                onTap: onTapped,
                items: const [
                  MagicNavItem(
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard_rounded,
                    label: "Dashboard",
                  ),
                  MagicNavItem(
                    icon: Icons.receipt_long_outlined,
                    activeIcon: Icons.receipt_long_rounded,
                    label: "Orders",
                  ),
                  MagicNavItem(
                    icon: Icons.storefront_outlined,
                    activeIcon: Icons.storefront_rounded,
                    label: "Products",
                  ),
                ],
              ),
            )
          : Login(),
    );
  }
}
