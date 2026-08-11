import 'package:flutter/material.dart';
import 'package:myn_seller_app/app_config.dart';
import 'package:myn_seller_app/custom/toast_component.dart';
import 'package:myn_seller_app/helpers/auth_helper.dart';
import 'package:myn_seller_app/helpers/shared_value_helper.dart';
import 'package:myn_seller_app/my_theme.dart';
import 'package:myn_seller_app/repositories/auth_repository.dart';
import 'package:myn_seller_app/screens/cancelled_delivery.dart';
import 'package:myn_seller_app/screens/collection.dart';
import 'package:myn_seller_app/screens/completed_delivery.dart';
import 'package:myn_seller_app/screens/download_report.dart';
import 'package:myn_seller_app/screens/login.dart';
import 'package:myn_seller_app/screens/productlist.dart';
import 'package:myn_seller_app/screens/profile_edit.dart';
import 'package:toast/toast.dart';

class MainDrawer extends StatefulWidget {
  const MainDrawer({Key? key}) : super(key: key);

  @override
  _MainDrawerState createState() => _MainDrawerState();
}

class _MainDrawerState extends State<MainDrawer> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> changeStatus() async {
    var showStatusResponse =
        await AuthRepository().changeStatusResponse(shop_active.$);

    setState(() {
      shop_active.$ = showStatusResponse;
    });
  }

  void _navigateTo(BuildContext context, Widget? page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page!));
  }

  void _onTapLogout(BuildContext context) async {
    var logoutResponse = await AuthRepository().getLogoutResponse();
    AuthHelper().clearUserData();
    if (logoutResponse.result == null) {
      ToastComponent.showDialog(logoutResponse.message,
          gravity: Toast.center, duration: Toast.lengthLong);
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return Login();
      }));
    } else {
      ToastComponent.showDialog(logoutResponse.message,
          gravity: Toast.center, duration: Toast.lengthLong, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define list of drawer items
    final drawerItems = [
      {
        'title': 'Completed Orders',
        'icon': Icons.check_circle,
        'page': CompletedDelivery(show_back_button: true),
        'requiresLogin': true,
      },
      {
        'title': 'Cancelled Orders',
        'icon': Icons.cancel,
        'page': CancelledDelivery(show_back_button: true),
        'requiresLogin': true,
      },
      {
        'title': 'Product List',
        'icon': Icons.local_shipping,
        'page': CategoryProducts(show_back_button: true),
        'requiresLogin': true,
      },
      {
        'title': 'My Collection',
        'icon': Icons.attach_money,
        'page': Collection(show_back_button: true),
        'requiresLogin': true,
      },
      // {
      //   'title': 'My Earnigs',
      //   'icon': Icons.wallet,
      //   'page': Earnings(show_back_button: true),
      //   'requiresLogin': true,
      // },
      {
        'title': 'Download Report',
        'icon': Icons.download,
        'page': DownloadReportScreen(),
        'requiresLogin': true,
      },
    ];

    final profileItems = [
      {
        'title': 'Profile',
        'icon': Icons.person,
        'page': ProfileEdit(show_back_button: true),
        'requiresLogin': true,
      },
      {
        'title': 'Logout',
        'icon': Icons.logout,
        'requiresLogin': true,
        'action': 'logout',
      },
    ];

    return SafeArea(
      child: Drawer(
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(vertical: 5),
              child: is_logged_in.$ == true
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(
                              AppConfig.BASE_PATH + "${avatar_original.$}",
                            ),
                          ),
                          title: Text("${user_name.$}"),
                          subtitle: user_email.$ != "" && user_email.$ != null
                              ? Text("${user_email.$}")
                              : Text("${user_phone.$}"),
                        ),
                        SizedBox(height: 10),
                        // is Shop active or not button switch
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              shop_active.$ = !shop_active.$;
                            });
                            changeStatus();
                          },
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Text('Shop Open',
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold)),
                                Switch(
                                  value: shop_active.$,
                                  onChanged: (value) {
                                    setState(() {
                                      shop_active.$ = value;
                                    });
                                    changeStatus();
                                  },
                                  activeTrackColor: MyTheme.soft_accent_color,
                                  activeColor: MyTheme.accent_color,
                                  inactiveTrackColor:
                                      MyTheme.soft_accent_color_2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'Not logged in',
                      style: TextStyle(color: Colors.black, fontSize: 14),
                    ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: is_logged_in.$
                    ? drawerItems.length + profileItems.length + 1
                    : drawerItems.length + 1,
                itemBuilder: (context, index) {
                  if (index == drawerItems.length) {
                    return Divider();
                  }

                  if (index < drawerItems.length) {
                    final item = drawerItems[index];
                    if (item['requiresLogin'] as bool && !is_logged_in.$) {
                      return SizedBox.shrink();
                    }
                    return ListTile(
                      leading: Icon(item['icon'] as IconData?,
                          size: 25, color: Colors.black),
                      title: Text(
                        item['title'] as String,
                        style: TextStyle(color: Colors.black, fontSize: 14),
                      ),
                      onTap: () =>
                          _navigateTo(context, item['page'] as Widget?),
                    );
                  }

                  final item = profileItems[index - drawerItems.length - 1];
                  if (item['action'] != null && item['action'] == 'logout') {
                    return ListTile(
                      leading: Icon(item['icon'] as IconData?,
                          size: 25, color: Colors.black),
                      title: Text(
                        item['title'] as String,
                        style: TextStyle(color: Colors.black, fontSize: 14),
                      ),
                      onTap: () => {_onTapLogout(context)},
                    );
                  } else {
                    return ListTile(
                      leading: Icon(item['icon'] as IconData?,
                          size: 25, color: Colors.black),
                      title: Text(
                        item['title'] as String,
                        style: TextStyle(color: Colors.black, fontSize: 14),
                      ),
                      onTap: () =>
                          _navigateTo(context, item['page'] as Widget?),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
