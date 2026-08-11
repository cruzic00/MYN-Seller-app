import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:myn_seller_app/app_config.dart';
import 'package:myn_seller_app/custom/toast_component.dart';
import 'package:myn_seller_app/helpers/auth_helper.dart';
import 'package:myn_seller_app/helpers/shared_value_helper.dart';
import 'package:myn_seller_app/my_theme.dart';
import 'package:myn_seller_app/myn_palette.dart';
import 'package:myn_seller_app/repositories/auth_repository.dart';
import 'package:myn_seller_app/screens/collection.dart';
import 'package:myn_seller_app/screens/download_report.dart';
import 'package:myn_seller_app/screens/login.dart';
import 'package:myn_seller_app/screens/myn_orders.dart';
import 'package:myn_seller_app/screens/productlist.dart';
import 'package:myn_seller_app/screens/profile_edit.dart';
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

  String _avatarUrl() {
    final String raw = (avatar_original.$ ?? "").trim();
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
        title: 'My Collection',
        icon: Icons.account_balance_wallet_rounded,
        color: MynPalette.amber,
        tint: MynPalette.amberTint,
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
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
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
                  onTap: () => _navigateTo(
                      context, ProfileEdit(show_back_button: true)),
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
      case 'My Collection':
        return Collection(show_back_button: true);
      case 'Download Report':
        return DownloadReportScreen();
    }
    return null;
  }

  Widget buildHeader(BuildContext context) {
    final String name = _shopName();
    final String contact = _contact();
    final String avatar = _avatarUrl();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 22, 20, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [MyTheme.accent_color, MynPalette.accentDark],
        ),
        borderRadius: const BorderRadius.only(
            bottomRight: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(255, 255, 255, 0.18),
              shape: BoxShape.circle,
              border: Border.all(
                  color: const Color.fromRGBO(255, 255, 255, 0.30), width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            child: avatar.isEmpty
                ? Text(
                    name.isEmpty ? "?" : name.trim()[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700),
                  )
                : CachedNetworkImage(
                    imageUrl: avatar,
                    fit: BoxFit.cover,
                    width: 58,
                    height: 58,
                    errorWidget: (c, u, e) => Text(
                      name.isEmpty ? "?" : name.trim()[0].toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          Text(
            name.isEmpty ? "Not logged in" : name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          if (contact.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              contact,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Color.fromRGBO(255, 255, 255, 0.75), fontSize: 13),
            ),
          ],
          if ((seller_role.$ ?? "").trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 255, 255, 0.16),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                (seller_role.$ ?? "").toUpperCase(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4),
              ),
            ),
          ],
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
