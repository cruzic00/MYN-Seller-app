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

// Dashboard palette. Tonal pairs (foreground + tinted background) instead of
// saturated fills, so the cards sit under the brand teal without fighting it.
const Color _surface = Color(0xFFF3F6F7);
const Color _cardBorder = Color(0xFFE6EDEE);
const Color _headingColor = Color(0xFF16292B);
const Color _mutedColor = Color(0xFF7C8D8F);

const Color _green = Color(0xFF2E9E5B);
const Color _greenTint = Color(0xFFE6F5EC);
const Color _amber = Color(0xFFD98E22);
const Color _amberTint = Color(0xFFFBF1E1);
const Color _red = Color(0xFFDC5A44);
const Color _redTint = Color(0xFFFBEAE7);

const Color _accentDark = Color(0xFF2C6A70);

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
      backgroundColor: _surface,
      body: RefreshIndicator(
        color: MyTheme.accent_color,
        backgroundColor: Colors.white,
        onRefresh: _onPageRefresh,
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
                buildHeroHeader(context),
                buildOrdersSection(context),
                buildInProgressSection(context),
                SizedBox(height: 28),
              ]),
            ),
          ],
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
          fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
      leading: IconButton(
        onPressed: () {
          _scaffoldKey.currentState!.openDrawer();
        },
        icon: Icon(Icons.menu_rounded, size: 26, color: Colors.white),
      ),
      title: Text("Dashboard"),
      elevation: 0.0,
      titleSpacing: 0,
      backgroundColor: MyTheme.accent_color,
      scrolledUnderElevation: 0.0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      centerTitle: true,
    );
  }

  // Teal hero that continues the app bar colour, then curves into the light
  // body. Money lives here; counts live in the cards below.
  Widget buildHeroHeader(BuildContext context) {
    final String name = (seller_username.$ ?? user_name.$ ?? "").trim();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [MyTheme.accent_color, _accentDark],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name.isEmpty ? "Welcome back" : "Hello, $name",
            style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          Text(
            "Here's how your store is doing",
            style: TextStyle(
                color: Color.fromRGBO(255, 255, 255, 0.78), fontSize: 13),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: buildMoneyTile(
                  "Total Collected",
                  _total_collection,
                  Icons.account_balance_wallet_rounded,
                  () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return Collection(show_back_button: true);
                    })).then((value) {
                      onPop(value);
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildMoneyTile(
                  "Earnings",
                  _total_earning,
                  Icons.trending_up_rounded,
                  null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildMoneyTile(
      String label, String? value, IconData icon, VoidCallback? onTap) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Color.fromRGBO(255, 255, 255, 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color.fromRGBO(255, 255, 255, 0.20)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon,
                        size: 17, color: Color.fromRGBO(255, 255, 255, 0.85)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Color.fromRGBO(255, 255, 255, 0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value ?? ". . .",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
      child: Text(
        text,
        style: TextStyle(
            color: _headingColor, fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }

  BoxDecoration buildCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _cardBorder),
      boxShadow: [
        BoxShadow(
          color: Color.fromRGBO(16, 42, 45, 0.05),
          blurRadius: 14,
          offset: Offset(0, 6),
        ),
      ],
    );
  }

  // One grouped card of three counts reads as a single unit, which the old
  // full-bleed "Cancelled" bar never did.
  Widget buildOrdersSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionTitle("Orders"),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: buildCardDecoration(),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  buildStatCell(
                    "Completed",
                    _completed_delivery,
                    Icons.check_circle_rounded,
                    _green,
                    _greenTint,
                    () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return CompletedDelivery(show_back_button: true);
                      })).then((value) {
                        onPop(value);
                      });
                    },
                  ),
                  buildCellDivider(),
                  buildStatCell(
                    "Pending",
                    _pending_delivery,
                    Icons.schedule_rounded,
                    _amber,
                    _amberTint,
                    () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return Main(startingIndex: 1);
                      })).then((value) {
                        onPop(value);
                      });
                    },
                  ),
                  buildCellDivider(),
                  buildStatCell(
                    "Cancelled",
                    _cancelled,
                    Icons.cancel_rounded,
                    _red,
                    _redTint,
                    () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return CancelledDelivery(show_back_button: true);
                      })).then((value) {
                        onPop(value);
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildCellDivider() {
    return Container(width: 1, color: _cardBorder);
  }

  Widget buildStatCell(String label, String value, IconData icon, Color color,
      Color tint, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                        color: _headingColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: _mutedColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildInProgressSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionTitle("In progress"),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: buildCardDecoration(),
            child: Column(
              children: [
                buildProgressRow(
                  "On The Way",
                  _on_the_way,
                  'assets/human_run.png',
                  _green,
                  _greenTint,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              Pending(index: 0, show_back_button: true)),
                    ).then((value) {
                      onPop(value);
                    });
                  },
                ),
                buildRowDivider(),
                buildProgressRow(
                  "Confirmed",
                  _picked,
                  'assets/press.png',
                  _amber,
                  _amberTint,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              Pending(index: 1, show_back_button: true)),
                    ).then((value) {
                      onPop(value);
                    });
                  },
                ),
                buildRowDivider(),
                buildProgressRow(
                  "Assigned",
                  _assigned,
                  'assets/sandclock.png',
                  _red,
                  _redTint,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              Pending(index: 2, show_back_button: true)),
                    ).then((value) {
                      onPop(value);
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildRowDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 68),
      child: Container(height: 1, color: _cardBorder),
    );
  }

  Widget buildProgressRow(String label, String value, String assetPath,
      Color color, Color tint, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
                padding: const EdgeInsets.all(9),
                child: Image.asset(assetPath, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                      color: _headingColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                      color: color, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: _mutedColor, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget updateAppNotification() {
    return buildBanner(
      message:
          "A newer version of the app is available. Please update for a better experience.",
      actionLabel: "Update",
      color: _amber,
      tint: _amberTint,
      onPressed: requestNotificationPermission,
    );
  }

  Widget buildNotificationPermissionRequest() {
    return buildBanner(
      message: "Allow notifications for smooth app functioning",
      actionLabel: "Allow",
      color: _red,
      tint: _redTint,
      onPressed: requestNotificationPermission,
    );
  }

  Widget buildBanner({
    required String message,
    required String actionLabel,
    required Color color,
    required Color tint,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                  color: _headingColor, fontSize: 13, height: 1.35),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(actionLabel,
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
