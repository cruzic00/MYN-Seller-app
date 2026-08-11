import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myn_seller_app/helpers/shared_value_helper.dart';
import 'package:myn_seller_app/my_theme.dart';
import 'package:myn_seller_app/repositories/dashboard_repository.dart';
import 'package:myn_seller_app/screens/cancelled_delivery.dart';
import 'package:myn_seller_app/screens/collection.dart';
import 'package:myn_seller_app/screens/completed_delivery.dart';
import 'package:myn_seller_app/screens/login.dart';
import 'package:myn_seller_app/screens/main.dart';
import 'package:myn_seller_app/screens/pending.dart';
import 'package:myn_seller_app/ui_elements/notification_card.dart';
import 'package:myn_seller_app/ui_sections/drawer.dart';
import 'package:permission_handler/permission_handler.dart';

class MenuItem {
  final int index;
  final String? title;
  final String? assetPath;
  final Color? backgroundColor;
  final Color? textColor;
  final VoidCallback onPushPage;

  MenuItem({
    required this.index,
    this.title,
    this.assetPath,
    this.backgroundColor,
    this.textColor,
    required this.onPushPage,
  });
}

class GridItem {
  final String? title;
  final Color? backgroundcolor;
  final Color? color;
  final Icon? icon;
  final String? displayText;
  final VoidCallback? onTap;

  GridItem({
    this.title,
    this.backgroundcolor,
    this.color,
    this.icon,
    this.displayText,
    this.onTap,
  });
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  ScrollController _mainScrollController = ScrollController();

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  String _completed_delivery = ". . .";
  String _pending_delivery = ". . .";
  String? _total_collection = ". . .";
  String? _total_earning = ". . .";
  String _cancelled = ". . .";
  String _on_the_way = ". . .";
  String _picked = ". . .";
  String _assigned = ". . .";

  @override
  void initState() {
    super.initState();
    if (is_logged_in.$ == false) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
        return Login();
      }));
    }

    fetchSummary();
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
    super.dispose();
  }

  Future<void> fetchSummary() async {
    var dashboardSummaryResponse =
        await DashboardRepository().getDashboardSummaryResponse();

    _completed_delivery =
        dashboardSummaryResponse.completed_delivery.toString();
    _pending_delivery = dashboardSummaryResponse.pending_delivery.toString();
    _total_collection = dashboardSummaryResponse.total_collection;
    _total_earning = dashboardSummaryResponse.total_earning;
    _cancelled = dashboardSummaryResponse.cancelled.toString();
    _on_the_way = dashboardSummaryResponse.on_the_way.toString();
    _picked = dashboardSummaryResponse.picked.toString();
    _assigned = dashboardSummaryResponse.assigned.toString();
    setState(() {});
  }

  Future<void> _onPageRefresh() async {
    reset();
    fetchSummary();
  }

  reset() {
    _completed_delivery = ". . .";
    _pending_delivery = ". . .";
    _total_collection = ". . .";
    _total_earning = ". . .";
    _cancelled = ". . .";
    _on_the_way = ". . .";
    _picked = ". . .";
    _assigned = ". . .";

    setState(() {});
  }

  onPop(value) {
    reset();
    fetchSummary();
  }

  Future<void> initializeNotifications() async {
    await NotificationService.initialize();
    if (showNotificationPermissionRequest.$) {
      checkNotificationPermission();
    }
  }

  Future<void> checkNotificationPermission() async {
    bool isAllowed = await NotificationService.isNotificationAllowed();
    setState(() {
      showNotificationPermissionRequest.$ = !isAllowed;
    });
  }

  Future<void> requestNotificationPermission() async {
    await NotificationService.requestNotificationPermission();
    bool granted = await Permission.notification.isGranted;

    setState(() {
      if (granted) showNotificationPermissionRequest.$ = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: RefreshIndicator(
        color: MyTheme.accent_color,
        backgroundColor: Colors.white,
        onRefresh: _onPageRefresh,
        child: Container(
          child: CustomScrollView(
            controller: _mainScrollController,
            physics: AlwaysScrollableScrollPhysics(),
            slivers: [
              if (showNotificationPermissionRequest.$)
                SliverToBoxAdapter(
                  child: buildNotificationPermissionRequest(),
                ),
              if (!is_updated_version.$)
                SliverToBoxAdapter(
                  child: updateAppNotification(),
                ),
              SliverList(
                delegate: SliverChildListDelegate([
                  buildTopContainer(context, onPop, _completed_delivery,
                      _pending_delivery, _total_collection, _total_earning),
                  buildSecondContainer(context, _cancelled),
                  buildHomeMenuRow(
                      context, onPop, _on_the_way, _picked, _assigned),
                ]),
              ),
            ],
          ),
        ),
      ),
      appBar: buildAppBar(context, _scaffoldKey),
      drawer: MainDrawer(),
      drawerEdgeDragWidth: MediaQuery.of(context).size.width,
    );
  }

  AppBar buildAppBar(
      BuildContext context, GlobalKey<ScaffoldState> _scaffoldKey) {
    return AppBar(
      titleTextStyle: TextStyle(
          fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
      leading: GestureDetector(
        onTap: () {
          _scaffoldKey.currentState!.openDrawer();
        },
        child: Builder(
          builder: (context) => Container(
            child: Icon(
              Icons.menu,
              size: 25,
              color: Colors.white,
            ),
          ),
        ),
      ),
      title: Text(
        "Dashboard",
      ),
      elevation: 0.0,
      titleSpacing: 0,
      backgroundColor: MyTheme.accent_color,
      scrolledUnderElevation: 4.0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      centerTitle: true,
    );
  }

  buildTopContainer(
      BuildContext context,
      Function onPop,
      String _completed_delivery,
      String _pending_delivery,
      String? _total_collection,
      String? _total_earning) {
    List<GridItem> generateGridItems(BuildContext context, Function onPop) {
      return [
        GridItem(
          title: 'Completed Orders',
          backgroundcolor: Colors.lightGreen,
          color: MyTheme.light_grey,
          icon: Icon(Icons.check_circle, color: MyTheme.light_grey, size: 45),
          displayText: _completed_delivery,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return CompletedDelivery(show_back_button: true);
            })).then((value) {
              onPop(value);
            });
          },
        ),
        GridItem(
          title: 'Pending Orders',
          backgroundcolor: Colors.pink,
          color: MyTheme.light_grey,
          icon:
              Icon(Icons.pending_actions, color: MyTheme.light_grey, size: 45),
          displayText: _pending_delivery,
          // Example number for pending deliveries
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return Main(startingIndex: 1);
            })).then((value) {
              onPop(value);
            });
          },
        ),
        GridItem(
          title: 'Total Collected',
          backgroundcolor: Colors.orange,
          color: MyTheme.light_grey,
          icon: Icon(Icons.attach_money, color: MyTheme.light_grey, size: 45),
          displayText: _total_collection,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return Collection(show_back_button: true);
            })).then((value) {
              onPop(value);
            });
          },
        ),
        GridItem(
          title: 'Earnings',
          backgroundcolor: Colors.lightBlue,
          color: MyTheme.light_grey,
          icon:
              Icon(Icons.monetization_on, color: MyTheme.light_grey, size: 45),
          displayText: _total_earning,
          onTap: () {},
        ),
      ];
    }

    return Container(
      color: MyTheme.accent_color,
      padding:
          const EdgeInsets.only(top: 8.0, bottom: 16.0, left: 8.0, right: 8.0),
      child: GridView(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            mainAxisExtent: 130),
        shrinkWrap: true,
        padding: EdgeInsets.all(0),
        physics: NeverScrollableScrollPhysics(),
        children: generateGridItems(context, onPop)
            .map((item) => InkWell(
                  onTap: item.onTap,
                  child: Container(
                    decoration: BoxDecoration(
                        color: item.backgroundcolor,
                        borderRadius: BorderRadius.all(Radius.circular(12))),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          child: item.icon!,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            item.title!,
                            style: TextStyle(
                                color: item.color,
                                fontSize: 15,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            item.displayText!,
                            style: TextStyle(
                                color: item.color,
                                fontSize: 28,
                                fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  buildSecondContainer(BuildContext context, String _cancelled) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return CancelledDelivery(show_back_button: true);
        }));
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        width: double.infinity,
        height: 70,
        color: MyTheme.red,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  child: Icon(
                    Icons.cancel,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                SizedBox(width: 8.0),
                Text(
                  "Cancelled Orders",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            Text(
              _cancelled,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600),
            )
          ],
        ),
      ),
    );
  }

  Widget updateAppNotification() {
    return Container(
      color: Colors.orange,
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "A Newer version of the app is available. Please update for better experience",
              style: TextStyle(color: Colors.white),
            ),
          ),
          ElevatedButton(
            onPressed: requestNotificationPermission,
            child: Text("Update"),
            style:
                ElevatedButton.styleFrom(foregroundColor: Colors.orangeAccent),
          ),
        ],
      ),
    );
  }

  Widget buildNotificationPermissionRequest() {
    return Container(
      color: Colors.red,
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "Allow notifications for smooth app functioning",
              style: TextStyle(color: Colors.white),
            ),
          ),
          ElevatedButton(
            onPressed: requestNotificationPermission,
            child: Text("Allow"),
            style: ElevatedButton.styleFrom(foregroundColor: MyTheme.red),
          ),
        ],
      ),
    );
  }

  buildHomeMenuRow(BuildContext context, Function onPop, String onTheWay,
      String picked, String assigned) {
    final List<MenuItem> menuItems = [
      MenuItem(
        index: 0,
        title: 'On The Way ($onTheWay)',
        assetPath: 'assets/human_run.png',
        backgroundColor: MyTheme.parrot_green_disabled,
        textColor: Colors.green,
        onPushPage: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => Pending(
                      index: 0,
                      show_back_button: true,
                    )),
          ).then((value) {
            onPop(value);
          });
        },
      ),
      MenuItem(
        index: 1,
        title: 'Confirmed ($picked)',
        assetPath: 'assets/press.png',
        backgroundColor: MyTheme.yellow_disabled,
        textColor: MyTheme.yellow,
        onPushPage: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => Pending(
                      index: 1,
                      show_back_button: true,
                    )),
          ).then((value) {
            onPop(value);
          });
        },
      ),
      MenuItem(
        index: 2,
        title: 'Assigned ($assigned)',
        assetPath: 'assets/sandclock.png',
        backgroundColor: MyTheme.red_disabled,
        textColor: MyTheme.red,
        onPushPage: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => Pending(
                      index: 2,
                      show_back_button: true,
                    )),
          ).then((value) {
            onPop(value);
          });
        },
      ),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 24.0, left: 16.0, right: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: menuItems.map((item) {
          return InkWell(
            onTap: item.onPushPage,
            child: Column(
              children: [
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: item.backgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Image.asset(item.assetPath!, color: item.textColor),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    item.title!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: item.textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
