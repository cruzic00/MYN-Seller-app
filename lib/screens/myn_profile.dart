import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myn_seller_app/data_model/myn_profile_response.dart';
import 'package:myn_seller_app/my_theme.dart';
import 'package:myn_seller_app/myn_palette.dart';
import 'package:myn_seller_app/repositories/myn_profile_repository.dart';
import 'package:myn_seller_app/ui_elements/skeleton.dart';

/// Seller profile, mirroring the web Business Panel's Profile tab.
///
/// Business fields are editable through POST /api/auth/update-own-profile.
/// Payout details are shown read-only on purpose: the server's editable-field
/// allowlist excludes them, so an editable form here would silently discard
/// the seller's input.
class MynProfileScreen extends StatefulWidget {
  @override
  _MynProfileScreenState createState() => _MynProfileScreenState();
}

class _MynProfileScreenState extends State<MynProfileScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  MynProfile? _profile;

  final _businessName = TextEditingController();
  final _taxId = TextEditingController();
  final _category = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _postalCode = TextEditingController();
  final _mapLocation = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    for (final c in [
      _businessName,
      _taxId,
      _category,
      _email,
      _phone,
      _address,
      _city,
      _state,
      _postalCode,
      _mapLocation
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = await MynProfileRepository().getMyProfile();
      if (!mounted) return;
      _businessName.text = p.businessName;
      _taxId.text = p.taxId;
      _category.text = p.businessCategory;
      _email.text = p.email;
      _phone.text = p.phone;
      _address.text = p.address;
      _city.text = p.city;
      _state.text = p.state;
      _postalCode.text = p.postalCode;
      _mapLocation.text = p.mapLocation;
      setState(() {
        _profile = p;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final ok = await MynProfileRepository().updateOwnProfile({
        "businessName": _businessName.text.trim(),
        "taxId": _taxId.text.trim(),
        "businessCategory": _category.text.trim(),
        "email": _email.text.trim(),
        "phone": _phone.text.trim(),
        "address": _address.text.trim(),
        "city": _city.text.trim(),
        "state": _state.text.trim(),
        "postalCode": _postalCode.text.trim(),
        "mapLocation": _mapLocation.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? "Profile updated" : "Couldn't update profile"),
      ));
      if (ok) _fetch();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed: $e")));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MynPalette.surface,
      appBar: AppBar(
        titleTextStyle: TextStyle(
            fontSize: 19, fontWeight: FontWeight.w700, color: MynPalette.onYellow),
        title: Text("Profile"),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: MynPalette.brandYellow,
        systemOverlayStyle: MynPalette.overlayDark,
        iconTheme: IconThemeData(color: MynPalette.onYellow),
      ),
      body: _error != null
          ? _buildError()
          : RefreshIndicator(
              color: MyTheme.accent_color,
              backgroundColor: Colors.white,
              onRefresh: _fetch,
              child: ListView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 36),
                children: [
                  _buildBannerAndLogo(),
                  const SizedBox(height: 16),
                  _sectionTitle("Business Information"),
                  _card([
                    _field("Business Name", _businessName),
                    _field("GST Number", _taxId),
                    _field("Category", _category),
                    _field("Email ID", _email,
                        keyboard: TextInputType.emailAddress),
                    _field("Mobile Number", _phone,
                        keyboard: TextInputType.phone),
                    _field("Address", _address, maxLines: 2),
                    _field("City", _city),
                    _field("State", _state),
                    _field("Pincode", _postalCode,
                        keyboard: TextInputType.number),
                    _field("Google Map Location", _mapLocation, last: true),
                  ]),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_loading || _saving) ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MyTheme.accent_color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _saving
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text("Update Profile",
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                  _sectionTitle("Payout Details"),
                  _card([
                    _readOnly("Account Holder", _profile?.accountHolderName),
                    _readOnly("Bank Name", _profile?.bankName),
                    _readOnly("Account Number", _profile?.accountNumber),
                    _readOnly("IFSC Code", _profile?.ifscCode),
                    _readOnly("Branch", _profile?.branchName),
                    _readOnly("UPI ID", _profile?.upiId, last: true),
                  ]),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
                    child: Text(
                      "Payout details can only be changed from the web Business Panel.",
                      style:
                          TextStyle(color: MynPalette.muted, fontSize: 11.5),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBannerAndLogo() {
    final banner = _profile?.bannerUrl ?? "";
    final logo = _profile?.logoUrl ?? "";
    final name = _profile?.businessName ?? "";

    return SizedBox(
      height: 210,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 160,
            width: double.infinity,
            color: MyTheme.accent_color,
            child: _loading
                ? const Skeleton(
                    width: double.infinity, height: 160, radius: 0)
                : banner.isEmpty
                    ? Center(
                        child: Icon(Icons.image_outlined,
                            color: Color.fromRGBO(255, 255, 255, 0.6),
                            size: 34),
                      )
                    : CachedNetworkImage(
                        imageUrl: banner,
                        fit: BoxFit.cover,
                        errorWidget: (c, u, e) => Center(
                          child: Icon(Icons.broken_image_outlined,
                              color: Color.fromRGBO(255, 255, 255, 0.6),
                              size: 34),
                        ),
                      ),
          ),
          Positioned(
            left: 20,
            top: 112,
            child: Container(
              height: 84,
              width: 84,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [
                  BoxShadow(
                      color: Color.fromRGBO(16, 42, 45, 0.16),
                      blurRadius: 14,
                      offset: Offset(0, 5)),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: logo.isEmpty
                  ? Container(
                      color: MynPalette.surface,
                      alignment: Alignment.center,
                      child: Text(
                        name.isEmpty ? "?" : name.trim()[0].toUpperCase(),
                        style: TextStyle(
                            color: MyTheme.accent_color,
                            fontSize: 30,
                            fontWeight: FontWeight.w700),
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: logo,
                      fit: BoxFit.cover,
                      errorWidget: (c, u, e) => Container(
                        color: MynPalette.surface,
                        alignment: Alignment.center,
                        child: Text(
                          name.isEmpty ? "?" : name.trim()[0].toUpperCase(),
                          style: TextStyle(
                              color: MyTheme.accent_color,
                              fontSize: 30,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
            ),
          ),
          Positioned(
            left: 118,
            right: 16,
            top: 168,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _loading
                    ? const Skeleton(width: 150, height: 16)
                    : Text(
                        name.isEmpty ? "—" : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: MynPalette.heading,
                            fontSize: 16,
                            fontWeight: FontWeight.w700),
                      ),
                const SizedBox(height: 3),
                _loading
                    ? const Skeleton(width: 110, height: 11)
                    : Text(
                        (_profile?.role ?? "").toUpperCase(),
                        style: TextStyle(
                            color: MynPalette.muted,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
      child: Text(
        text,
        style: TextStyle(
            color: MynPalette.heading,
            fontSize: 16,
            fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
        decoration: MynPalette.card(),
        child: Column(children: children),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller,
      {TextInputType? keyboard, int maxLines = 1, bool last = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 14 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: MynPalette.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          _loading
              ? const Skeleton(width: double.infinity, height: 42, radius: 12)
              : TextField(
                  controller: controller,
                  keyboardType: keyboard,
                  maxLines: maxLines,
                  style: TextStyle(
                      color: MynPalette.heading,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    filled: true,
                    fillColor: MynPalette.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: MynPalette.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: MynPalette.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: MyTheme.accent_color, width: 1.4),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _readOnly(String label, String? value, {bool last = false}) {
    final String v = (value ?? "").trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(label,
                style: TextStyle(
                    color: MynPalette.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            flex: 5,
            child: _loading
                ? const Align(
                    alignment: Alignment.centerRight,
                    child: Skeleton(width: 90, height: 13))
                : Text(
                    v.isEmpty ? "—" : v,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        color: MynPalette.heading,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 48, color: MynPalette.red),
          const SizedBox(height: 14),
          Text("Couldn't load your profile",
              style: TextStyle(
                  color: MynPalette.heading,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(_error ?? "",
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: MynPalette.muted, fontSize: 12)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetch,
            style: ElevatedButton.styleFrom(
              backgroundColor: MyTheme.accent_color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text("Retry"),
          ),
        ],
      ),
    );
  }
}
