import 'package:myn_seller_app/ui_elements/notification_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:myn_seller_app/app_config.dart';
import 'package:myn_seller_app/custom/toast_component.dart';
import 'package:myn_seller_app/helpers/auth_helper.dart';
import 'package:myn_seller_app/helpers/shared_value_helper.dart';
import 'package:myn_seller_app/my_theme.dart';
import 'package:myn_seller_app/myn_palette.dart';
import 'package:myn_seller_app/screens/download_report.dart';
import 'package:myn_seller_app/screens/login.dart';
import 'package:myn_seller_app/screens/myn_orders.dart';
import 'package:myn_seller_app/screens/myn_profile.dart';
import 'package:myn_seller_app/screens/productlist.dart';
import 'package:toast/toast.dart';

class _DrawerEntry {
  final String title;
  final IconData icon;
  final Color color;
  final Color tint;
  final Widget? page;
  final bool isLogout;

  const _DrawerEntry({
    required this.title,
    required this.icon,
    required this.color,
    required this.tint,
    this.page,
    this.isLogout = false,
  });
}

class MainDrawer extends StatefulWidget {
  const MainDrawer({Key? key}) : super(key: key);

  @override
  _MainDrawerState createState() => _MainDrawerState();
}

class _MainDrawerState extends State<MainDrawer> {
  void _navigateTo(BuildContext context, Widget? page) {
    if (page == null) return;
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  /// Signing out is entirely local.
  ///
  /// This used to GET `${BASE_URL}/auth/logout`, a legacy Laravel route the MYN
  /// API does not have. It answered with a 404 page, parsing that as JSON threw,
  /// and because the throw happened before clearUserData() the seller was left
  /// signed in with nothing on screen to explain why. The token is a JWT held
  /// only on the device, so dropping it here is the whole job.
  Future<void> _onTapLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text("Sign out?",
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: MynPalette.heading)),
        content: Text(
          "You'll need your username and password to get back in.",
          style: TextStyle(
              fontSize: 13.5, height: 1.4, color: MynPalette.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Cancel", style: TextStyle(color: MynPalette.muted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: MynPalette.red,
              foregroundColor: Colors.white,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text("Sign out"),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Must run before clearUserData(), which wipes the access token the
    // request authenticates with. Awaited so the phone is off the shop's
    // device list before the session goes — otherwise it keeps ringing for
    // orders belonging to a shop nobody is signed into here any more.
    await NotificationService.unregisterDevice();

    AuthHelper().clearUserData();

    ToastComponent.showDialog("Signed out",
        gravity: Toast.center, duration: Toast.lengthShort);

    // Wipe the stack: without this the back button walked straight back into
    // the signed-in screens that are still mounted behind the login page.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => Login()),
      (route) => false,
    );
  }

  String _shopName() {
    final String business = (user_name.$ ?? "").trim();
    if (business.isNotEmpty) return business;
    final String raw = (seller_username.$ ?? "").trim();
    return raw.contains("@") ? raw.split("@").first : raw;
  }

  String _contact() {
    final String email = (user_email.$ ?? "").trim();
    if (email.isNotEmpty) return email;
    final String username = (seller_username.$ ?? "").trim();
    if (username.isNotEmpty) return username;
    return (user_phone.$ ?? "").trim();
  }

  /// The shop's logo, then the legacy avatar as a fallback.
  ///
  /// avatar_original is an Active-eCommerce field the MYN API never sets, so on
  /// its own it always resolved to "" and every seller saw the monogram. The
  /// real picture is the businessName's logoUrl, cached by the dashboard.
  String _logoUrl() =>
      _absolute(seller_logo_url.$).isNotEmpty
          ? _absolute(seller_logo_url.$)
          : _absolute(avatar_original.$);

  String _bannerUrl() => _absolute(seller_banner_url.$);

  String _absolute(String? value) {
    final String raw = (value ?? "").trim();
    if (raw.isEmpty) return "";
    if (raw.startsWith("http")) return raw;
    if (raw.startsWith("/")) return "${AppConfig.RAW_BASE_URL}$raw";
    return AppConfig.BASE_PATH + raw;
  }

  @override
  Widget build(BuildContext context) {
    const List<_DrawerEntry> items = [
      _DrawerEntry(
        title: 'Orders',
        icon: Icons.receipt_long_rounded,
        color: MynPalette.blue,
        tint: MynPalette.blueTint,
      ),
      _DrawerEntry(
        title: 'Product List',
        icon: Icons.inventory_2_rounded,
        color: MynPalette.green,
        tint: MynPalette.greenTint,
      ),
      _DrawerEntry(
        title: 'Download Report',
        icon: Icons.download_rounded,
        color: MynPalette.blue,
        tint: MynPalette.blueTint,
      ),
    ];

    return Drawer(
      backgroundColor: MynPalette.surface,
      child: Column(
        children: [
          buildHeader(context),
          Expanded(
            child: ListView(
              // Clears the gesture bar: the panel now draws edge-to-edge, so a
              // fixed bottom pad left Logout half under the home indicator.
              padding: EdgeInsets.fromLTRB(
                  12, 16, 12, 12 + MediaQuery.of(context).padding.bottom),
              children: [
                sectionLabel("Manage"),
                for (final item in items)
                  buildTile(
                    context,
                    item,
                    onTap: () => _navigateTo(context, pageFor(item.title)),
                  ),
                const SizedBox(height: 18),
                sectionLabel("Account"),
                buildTile(
                  context,
                  const _DrawerEntry(
                    title: 'Profile',
                    icon: Icons.person_rounded,
                    color: MynPalette.muted,
                    tint: Color(0xFFEDF2F3),
                  ),
                  onTap: () => _navigateTo(context, MynProfileScreen()),
                ),
                buildTile(
                  context,
                  const _DrawerEntry(
                    title: 'Logout',
                    icon: Icons.logout_rounded,
                    color: MynPalette.red,
                    tint: MynPalette.redTint,
                    isLogout: true,
                  ),
                  onTap: () => _onTapLogout(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The delivery-boy screens the old drawer linked to (Completed/Cancelled
  /// Delivery) read from the retired /api/v2/delivery-boy endpoints, so the
  /// order entries now point at the MYN-backed Orders screen instead.
  Widget? pageFor(String title) {
    switch (title) {
      case 'Orders':
        return MynOrders(show_back_button: true);
      case 'Product List':
        return CategoryProducts(show_back_button: true);
      case 'Download Report':
        return DownloadReportScreen();
    }
    return null;
  }

  Widget buildHeader(BuildContext context) {
    final String name = _shopName();
    final String contact = _contact();
    final String logo = _logoUrl();
    final String banner = _bannerUrl();

    final Widget monogram = Text(
      name.isEmpty ? "?" : name.trim()[0].toUpperCase(),
      style: const TextStyle(
          color: MynPalette.onYellow, fontSize: 24, fontWeight: FontWeight.w700),
    );

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [MynPalette.brandYellow, MynPalette.brandYellowDeep],
        ),
        borderRadius:
            const BorderRadius.only(bottomRight: Radius.circular(28)),
      ),
      child: Stack(
        children: [
          // The shop's banner behind everything, with the brand gradient still
          // painted underneath — a banner that fails to load, or a shop that has
          // none, leaves the header exactly as it was rather than a grey hole.
          if (banner.isNotEmpty)
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: banner,
                fit: BoxFit.cover,
                placeholder: (c, u) => const SizedBox.shrink(),
                errorWidget: (c, u, e) => const SizedBox.shrink(),
              ),
            ),
          // A scrim over the banner. Without it the shop name — dark text chosen
          // for the yellow gradient — lands on whatever colours the photo
          // happens to have there and stops being readable.
          if (banner.isNotEmpty)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color.fromRGBO(255, 199, 44, 0.72),
                      const Color.fromRGBO(240, 176, 20, 0.92),
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 22, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 58,
                  width: 58,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(74, 54, 0, 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color.fromRGBO(74, 54, 0, 0.22),
                        width: 1.5),
                  ),
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.center,
                  child: logo.isEmpty
                      ? monogram
                      : CachedNetworkImage(
                          imageUrl: logo,
                          fit: BoxFit.cover,
                          width: 58,
                          height: 58,
                          placeholder: (c, u) => monogram,
                          errorWidget: (c, u, e) => monogram,
                        ),
                ),
                const SizedBox(height: 14),
                Text(
                  name.isEmpty ? "Not logged in" : name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: MynPalette.onYellow,
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
                ),
                if (contact.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    contact,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Color.fromRGBO(74, 54, 0, 0.70), fontSize: 13),
                  ),
                ],
                if ((seller_role.$ ?? "").trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(74, 54, 0, 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      (seller_role.$ ?? "").toUpperCase(),
                      style: const TextStyle(
                          color: MynPalette.onYellow,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
            color: MynPalette.muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8),
      ),
    );
  }

  Widget buildTile(BuildContext context, _DrawerEntry item,
      {required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  height: 34,
                  width: 34,
                  decoration:
                      BoxDecoration(color: item.tint, shape: BoxShape.circle),
                  child: Icon(item.icon, size: 18, color: item.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      color: item.isLogout
                          ? MynPalette.red
                          : MynPalette.heading,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (!item.isLogout)
                  const Icon(Icons.chevron_right_rounded,
                      color: MynPalette.muted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
