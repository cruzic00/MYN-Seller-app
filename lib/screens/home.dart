import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myn_seller_app/data_model/myn_order_response.dart';
import 'package:myn_seller_app/helpers/shared_value_helper.dart';
import 'package:myn_seller_app/my_theme.dart';
import 'package:myn_seller_app/myn_palette.dart';
import 'package:myn_seller_app/repositories/auth_repository.dart';
import 'package:myn_seller_app/repositories/order_repository.dart';
import 'package:myn_seller_app/screens/login.dart';
import 'package:myn_seller_app/screens/myn_orders.dart';
import 'package:myn_seller_app/ui_elements/notification_card.dart';
import 'package:myn_seller_app/ui_elements/skeleton.dart';
import 'package:myn_seller_app/ui_sections/drawer.dart';
import 'package:permission_handler/permission_handler.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  ScrollController _mainScrollController = ScrollController();

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  bool _loading = true;
  bool _failed = false;
  MynOrderListResponse? _summary;

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

  /// The dashboard is derived from the same business-orders endpoint the web
  /// panel uses (GET /api/admin/orders), which already scopes to this seller
  /// and returns pre-computed `totals`.
  Future<void> fetchSummary() async {
    try {
      final res = await OrderRepository().getMynOrders();
      if (!mounted) return;
      setState(() {
        _summary = res;
        _failed = false;
        _loading = false;
      });
    } catch (e) {
      print("Dashboard summary failed: $e");
      if (!mounted) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  Future<void> _onPageRefresh() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    await fetchSummary();
  }

  onPop(value) {
    _onPageRefresh();
  }

  /// `user_name` is populated from the login payload's `businessName`
  /// (see login_response.dart), which is the shop's trading name — the same
  /// label the web Business Panel shows. Falls back to the username's local
  /// part when a seller has no business name set.
  String shopName() {
    final String business = (user_name.$ ?? "").trim();
    if (business.isNotEmpty) return business;

    final String raw = (seller_username.$ ?? "").trim();
    if (raw.isEmpty) return "";
    final String name = raw.contains("@") ? raw.split("@").first : raw;
    if (name.isEmpty) return "";
    return name[0].toUpperCase() + name.substring(1);
  }

  Future<void> toggleShopStatus(bool value) async {
    setState(() => shop_active.$ = value);
    final result = await AuthRepository().changeStatusResponse(shop_active.$);
    if (!mounted) return;
    setState(() => shop_active.$ = result);
  }

  int _countWhere(bool Function(String status) test) {
    final orders = _summary?.orders ?? const <MynOrder>[];
    return orders.where((o) => test(o.status)).length;
  }

  String _count(bool Function(String status) test) {
    if (_failed || _summary == null) return "—";
    return _countWhere(test).toString();
  }

  String _money(double? v) {
    if (_failed || v == null) return "—";
    return MynPalette.money(v);
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

  void _openOrders() {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return MynOrders(show_back_button: true);
    })).then(onPop);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: MynPalette.surface,
      body: RefreshIndicator(
        color: MyTheme.accent_color,
        backgroundColor: Colors.white,
        onRefresh: _onPageRefresh,
        child: CustomScrollView(
          controller: _mainScrollController,
          physics: AlwaysScrollableScrollPhysics(),
          slivers: [
            if (showNotificationPermissionRequest.$)
              SliverToBoxAdapter(child: buildNotificationPermissionRequest()),
            if (!is_updated_version.$)
              SliverToBoxAdapter(child: updateAppNotification()),
            SliverList(
              delegate: SliverChildListDelegate([
                buildHeroHeader(context),
                if (_failed) buildSummaryError(),
                buildOrdersSection(context),
                buildDeductionsSection(context),
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

  Widget buildHeroHeader(BuildContext context) {
    final String name = shopName();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [MyTheme.accent_color, MynPalette.accentDark],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: Color.fromRGBO(255, 255, 255, 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Color.fromRGBO(255, 255, 255, 0.28), width: 1),
                ),
                alignment: Alignment.center,
                child: Text(
                  name.isEmpty ? "?" : name.trim()[0].toUpperCase(),
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hello,",
                      style: TextStyle(
                          color: Color.fromRGBO(255, 255, 255, 0.75),
                          fontSize: 13),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      name.isEmpty ? "Welcome back" : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              buildShopStatusToggle(),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: buildMoneyTile(
                  "Total Collected",
                  _money(_summary?.customerPaidTotal),
                  Icons.account_balance_wallet_rounded,
                  _openOrders,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildMoneyTile(
                  "Net Earnings",
                  _money(_summary?.totals.earnings),
                  Icons.trending_up_rounded,
                  _openOrders,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Shop open/closed lives here rather than buried in the drawer, so the
  /// seller can see and flip it without leaving the dashboard.
  Widget buildShopStatusToggle() {
    final bool open = shop_active.$;

    return Material(
      color: Color.fromRGBO(255, 255, 255, open ? 0.18 : 0.10),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => toggleShopStatus(!open),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 7, 12, 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 8,
                width: 8,
                decoration: BoxDecoration(
                  color: open ? Color(0xFF7BE495) : Color(0xFFFFB4A2),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                open ? "Open" : "Closed",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildMoneyTile(
      String label, String value, IconData icon, VoidCallback? onTap) {
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
                _loading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Skeleton.onDark(width: 108, height: 22),
                      )
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
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

  Widget buildSummaryError() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: MynPalette.redTint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Color.fromRGBO(220, 90, 68, 0.28)),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, color: MynPalette.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Couldn't load your summary. Pull down to retry.",
              style: TextStyle(
                  color: MynPalette.heading, fontSize: 13, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
      child: Text(
        text,
        style: TextStyle(
            color: MynPalette.heading,
            fontSize: 16,
            fontWeight: FontWeight.w700),
      ),
    );
  }

  bool _isDone(String s) =>
      s == "DELIVERED" || s == "COMPLETED" || s == "SUCCESS";
  bool _isOpen(String s) =>
      s == "CREATED" || s == "SUBMITTED" || s == "PENDING";
  bool _isDead(String s) =>
      s == "FAILED" || s == "CANCELLED" || s == "REJECTED";

  Widget buildOrdersSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionTitle("Orders"),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: MynPalette.card(),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  buildStatCell(
                      "Completed",
                      _count(_isDone),
                      Icons.check_circle_rounded,
                      MynPalette.green,
                      MynPalette.greenTint,
                      _openOrders),
                  buildCellDivider(),
                  buildStatCell(
                      "Open",
                      _count(_isOpen),
                      Icons.schedule_rounded,
                      MynPalette.blue,
                      MynPalette.blueTint,
                      _openOrders),
                  buildCellDivider(),
                  buildStatCell(
                      "Failed",
                      _count(_isDead),
                      Icons.cancel_rounded,
                      MynPalette.red,
                      MynPalette.redTint,
                      _openOrders),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildCellDivider() {
    return Container(width: 1, color: MynPalette.cardBorder);
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
                _loading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 5),
                        child: Skeleton(width: 34, height: 20),
                      )
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          value,
                          style: TextStyle(
                              color: MynPalette.heading,
                              fontSize: 22,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                const SizedBox(height: 2),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: MynPalette.muted,
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

  /// Mirrors the deductions the web Business Panel breaks out between
  /// "Total Paid" and "Net Earnings".
  Widget buildDeductionsSection(BuildContext context) {
    final t = _summary?.totals;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionTitle("Deductions"),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: MynPalette.card(),
            child: Column(
              children: [
                buildDeductionRow("GST (CGST + SGST)", _money(t?.totalGst),
                    Icons.receipt_rounded, MynPalette.amber,
                    MynPalette.amberTint),
                buildRowDivider(),
                buildDeductionRow("MYN Commission", _money(t?.commission),
                    Icons.percent_rounded, MynPalette.red, MynPalette.redTint),
                buildRowDivider(),
                buildDeductionRow("Platform Fee", _money(t?.platformFee),
                    Icons.apps_rounded, MynPalette.blue, MynPalette.blueTint),
                buildRowDivider(),
                buildDeductionRow("TDS", _money(t?.tds),
                    Icons.account_balance_rounded, MynPalette.muted,
                    MynPalette.surface),
                buildRowDivider(),
                buildDeductionRow("Delivery Charge", _money(t?.dc),
                    Icons.local_shipping_rounded, MynPalette.green,
                    MynPalette.greenTint),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildRowDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 46),
      child: Container(height: 1, color: MynPalette.cardBorder),
    );
  }

  Widget buildDeductionRow(
      String label, String value, IconData icon, Color color, Color tint) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                  color: MynPalette.heading,
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
            ),
          ),
          _loading
              ? const Skeleton(width: 68, height: 14)
              : Text(
                  value,
                  style: TextStyle(
                      color: MynPalette.heading,
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                ),
        ],
      ),
    );
  }

  Widget updateAppNotification() {
    return buildBanner(
      message:
          "A newer version of the app is available. Please update for a better experience.",
      actionLabel: "Update",
      color: MynPalette.amber,
      tint: MynPalette.amberTint,
      onPressed: requestNotificationPermission,
    );
  }

  Widget buildNotificationPermissionRequest() {
    return buildBanner(
      message: "Allow notifications for smooth app functioning",
      actionLabel: "Allow",
      color: MynPalette.red,
      tint: MynPalette.redTint,
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
                  color: MynPalette.heading, fontSize: 13, height: 1.35),
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
