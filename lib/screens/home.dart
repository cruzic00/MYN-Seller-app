import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:myn_seller_app/data_model/myn_order_response.dart';
import 'package:myn_seller_app/data_model/myn_profile_response.dart';
import 'package:myn_seller_app/helpers/shared_value_helper.dart';
import 'package:myn_seller_app/repositories/myn_profile_repository.dart';
import 'package:myn_seller_app/screens/myn_order_detail.dart';
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
  MynProfile? _profile;
  final Set<String> _packing = {};

  @override
  void initState() {
    super.initState();
    if (is_logged_in.$ == false) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
        return Login();
      }));
    }

    fetchSummary();
    fetchProfile();
  }

  /// Logo and banner are only on the user document, so they need their own
  /// call; a failure here must not blank the dashboard.
  Future<void> fetchProfile() async {
    try {
      final p = await MynProfileRepository().getMyProfile();
      if (!mounted) return;
      setState(() => _profile = p);
    } catch (e) {
      print("Profile fetch failed: $e");
    }
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
                buildNewOrdersSection(context),
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
          fontSize: 20, fontWeight: FontWeight.w700, color: MynPalette.onYellow),
      leading: IconButton(
        onPressed: () {
          _scaffoldKey.currentState!.openDrawer();
        },
        icon: Icon(Icons.menu_rounded, size: 26, color: MynPalette.onYellow),
      ),
      title: Text("Dashboard"),
      elevation: 0.0,
      titleSpacing: 0,
      backgroundColor: MynPalette.brandYellow,
      scrolledUnderElevation: 0.0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      centerTitle: true,
    );
  }

  Widget buildHeroHeader(BuildContext context) {
    final String name = shopName();

    final String banner = _profile?.bannerUrl ?? "";

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [MynPalette.brandYellow, MynPalette.brandYellowDeep],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Stack(
        children: [
          // Shop banner sits behind the gradient scrim so the white text keeps
          // its contrast whatever the artwork looks like.
          if (banner.isNotEmpty)
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: banner,
                fit: BoxFit.cover,
                errorWidget: (c, u, e) => const SizedBox.shrink(),
              ),
            ),
          if (banner.isNotEmpty)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromRGBO(253, 200, 45, 0.93),
                      Color.fromRGBO(243, 173, 3, 0.96),
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildShopLogo(name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hello,",
                      style: TextStyle(
                          color: Color.fromRGBO(74, 54, 0, 0.70),
                          fontSize: 13),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      name.isEmpty ? "Welcome back" : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: MynPalette.onYellow,
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
          ),
        ],
      ),
    );
  }

  /// Prefers the shop's uploaded logo, falling back to a monogram so the
  /// header never shows a broken image box.
  Widget buildShopLogo(String name) {
    final String logo = _profile?.logoUrl ?? "";
    final Widget monogram = Text(
      name.isEmpty ? "?" : name.trim()[0].toUpperCase(),
      style: TextStyle(
          color: MynPalette.onYellow, fontSize: 19, fontWeight: FontWeight.w700),
    );

    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        color: Color.fromRGBO(74, 54, 0, 0.12),
        shape: BoxShape.circle,
        border:
            Border.all(color: Color.fromRGBO(74, 54, 0, 0.22), width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: logo.isEmpty
          ? monogram
          : CachedNetworkImage(
              imageUrl: logo,
              fit: BoxFit.cover,
              width: 44,
              height: 44,
              errorWidget: (c, u, e) => monogram,
            ),
    );
  }

  /// Shop open/closed lives here rather than buried in the drawer, so the
  /// seller can see and flip it without leaving the dashboard.
  Widget buildShopStatusToggle() {
    final bool open = shop_active.$;

    return Material(
      color: Color.fromRGBO(74, 54, 0, open ? 0.14 : 0.08),
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
                  color: open ? Color(0xFF1B7F3B) : Color(0xFFB33A26),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                open ? "Open" : "Closed",
                style: TextStyle(
                    color: MynPalette.onYellow,
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
        color: Color.fromRGBO(74, 54, 0, 0.11),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color.fromRGBO(74, 54, 0, 0.18)),
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
                        size: 17, color: Color.fromRGBO(74, 54, 0, 0.78)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Color.fromRGBO(74, 54, 0, 0.78),
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
                        child: Skeleton.onYellow(width: 108, height: 22),
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

  /// Orders still awaiting the seller. Marking one packed moves it to
  /// "Processing" — the next status in the web panel's vocabulary — after
  /// which it no longer matches [_isOpen] and drops off this list.
  List<MynOrder> get newOrders {
    final orders = _summary?.orders ?? const <MynOrder>[];
    return orders.where((o) => _isOpen(o.status)).toList();
  }

  Future<void> markPacked(MynOrder order) async {
    setState(() => _packing.add(order.id));
    try {
      final ok = await OrderRepository()
          .updateMynOrderStatus(order.id, "Processing");
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't update ${order.orderId}")),
        );
      } else {
        await fetchSummary();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed: $e")));
    } finally {
      if (mounted) setState(() => _packing.remove(order.id));
    }
  }

  Widget buildNewOrdersSection(BuildContext context) {
    final items = newOrders;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionTitle(
            _loading ? "New orders" : "New orders (${items.length})"),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: MynPalette.card(),
            child: _loading
                ? Column(
                    children: List.generate(
                      3,
                      (i) => Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        child: Row(
                          children: const [
                            Expanded(child: Skeleton(width: 120, height: 14)),
                            SizedBox(width: 12),
                            Skeleton(width: 74, height: 30, radius: 16),
                          ],
                        ),
                      ),
                    ),
                  )
                : items.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        child: Column(
                          children: [
                            Icon(Icons.inbox_rounded,
                                size: 34, color: MynPalette.muted),
                            const SizedBox(height: 8),
                            Text(
                              _failed
                                  ? "Couldn't load new orders"
                                  : "No new orders right now",
                              style: TextStyle(
                                  color: MynPalette.muted, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          for (int i = 0; i < items.length; i++) ...[
                            if (i > 0) buildRowDivider(),
                            buildNewOrderRow(items[i]),
                          ],
                        ],
                      ),
          ),
        ),
      ],
    );
  }

  Widget buildNewOrderRow(MynOrder order) {
    final bool busy = _packing.contains(order.id);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return MynOrderDetail(
                orderMongoId: order.id, orderLabel: order.orderId);
          })).then(onPop);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderId,
                      style: TextStyle(
                          color: MynPalette.heading,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${order.customerName}  ·  ${MynPalette.money(order.customerPaid)}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(color: MynPalette.muted, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              busy
                  ? SizedBox(
                      height: 30,
                      width: 74,
                      child: Center(
                        child: SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: MyTheme.accent_color),
                        ),
                      ),
                    )
                  : Material(
                      color: MynPalette.greenTint,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => markPacked(order),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inventory_2_rounded,
                                  size: 14, color: MynPalette.green),
                              const SizedBox(width: 6),
                              Text(
                                "Packed",
                                style: TextStyle(
                                    color: MynPalette.green,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildRowDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Container(height: 1, color: MynPalette.cardBorder),
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
