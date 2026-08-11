import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myn_seller_app/app_config.dart';
import 'package:myn_seller_app/my_theme.dart';
import 'package:myn_seller_app/myn_palette.dart';
import 'package:myn_seller_app/repositories/order_repository.dart';

/// Detail view for one business order, backed by GET /api/admin/orders/:id.
///
/// The endpoint returns the raw OrderShop document, whose optional blocks
/// (products[], shopTaxBreakdown[], addressInputModel, paymentDetails) vary by
/// business category — every section below is rendered defensively so a missing
/// block hides itself instead of throwing.
class MynOrderDetail extends StatefulWidget {
  final String orderMongoId;
  final String orderLabel;

  MynOrderDetail({required this.orderMongoId, this.orderLabel = "Order"});

  @override
  _MynOrderDetailState createState() => _MynOrderDetailState();
}

class _MynOrderDetailState extends State<MynOrderDetail> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _order;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res =
          await OrderRepository().getMynOrderDetail(widget.orderMongoId);
      if (!mounted) return;
      setState(() {
        _order = res;
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

  double _num(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  String _str(dynamic v, [String fallback = "—"]) {
    final s = v?.toString().trim() ?? "";
    return s.isEmpty ? fallback : s;
  }

  double _tax(String name) {
    final list = (_order?["shopTaxBreakdown"] as List?) ?? const [];
    for (final t in list) {
      if (t is Map && t["taxName"]?.toString().toUpperCase() == name) {
        return _num(t["taxAmount"]);
      }
    }
    return 0;
  }

  String _imageUrl(dynamic raw) {
    final url = raw?.toString() ?? "";
    if (url.isEmpty) return "";
    if (url.startsWith("http")) return url;
    if (url.startsWith("/")) return "${AppConfig.RAW_BASE_URL}$url";
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MynPalette.surface,
      appBar: AppBar(
        titleTextStyle: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
        title: Text(widget.orderLabel),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: MyTheme.accent_color,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: MyTheme.accent_color))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  color: MyTheme.accent_color,
                  backgroundColor: Colors.white,
                  onRefresh: _fetch,
                  child: ListView(
                    physics: AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      _buildStatusCard(),
                      const SizedBox(height: 16),
                      _buildItemsCard(),
                      const SizedBox(height: 16),
                      _buildBreakdownCard(),
                      const SizedBox(height: 16),
                      _buildCustomerCard(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatusCard() {
    final status = _str(_order?["status"], "SUBMITTED").toUpperCase();
    final colors = MynPalette.statusColors(status);
    final billno = _str(_order?["billno"] ?? _order?["ParentBillNo"]);
    final created = _order?["updatedAt"] ?? _order?["createdAt"];
    final date = DateTime.tryParse(created?.toString() ?? "")?.toLocal();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MynPalette.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  billno,
                  style: TextStyle(
                      color: MynPalette.heading,
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colors[1],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                      color: colors[0],
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.storefront_rounded,
                  size: 16, color: MynPalette.muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(_str(_order?["shopName"]),
                    style:
                        TextStyle(color: MynPalette.muted, fontSize: 13)),
              ),
            ],
          ),
          if (date != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.schedule_rounded,
                    size: 16, color: MynPalette.muted),
                const SizedBox(width: 6),
                Text(
                  "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}  ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}",
                  style: TextStyle(color: MynPalette.muted, fontSize: 13),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsCard() {
    final products = (_order?["products"] as List?) ?? const [];
    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel("Items (${products.length})"),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: MynPalette.card(),
          child: Column(
            children: List.generate(products.length, (i) {
              final p = products[i] as Map? ?? const {};
              final img = _imageUrl(p["imageUrl"]);
              final qty = _num(p["quantity"]).toStringAsFixed(0);
              final unit = _str(p["variantUnit"], "");

              return Column(
                children: [
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 74),
                      child:
                          Container(height: 1, color: MynPalette.cardBorder),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            height: 46,
                            width: 46,
                            color: MynPalette.surface,
                            child: img.isEmpty
                                ? Icon(Icons.fastfood_rounded,
                                    color: MynPalette.muted, size: 20)
                                : CachedNetworkImage(
                                    imageUrl: img,
                                    fit: BoxFit.cover,
                                    errorWidget: (c, u, e) => Icon(
                                        Icons.fastfood_rounded,
                                        color: MynPalette.muted,
                                        size: 20),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _str(p["productName"]),
                                style: TextStyle(
                                    color: MynPalette.heading,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                unit.isEmpty
                                    ? "Qty $qty"
                                    : "Qty $qty  ·  $unit",
                                style: TextStyle(
                                    color: MynPalette.muted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          MynPalette.money(
                              _num(p["itemTotal"] ?? p["subTotal"])),
                          style: TextStyle(
                              color: MynPalette.heading,
                              fontSize: 14,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownCard() {
    final cgst = _tax("CGST");
    final sgst = _tax("SGST");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel("Payment breakdown"),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: MynPalette.card(),
          child: Column(
            children: [
              _row("Customer Paid", _num(_order?["customerPaid"] ?? _order?["totalAmount"]),
                  bold: true),
              _divider(),
              _row("CGST", cgst),
              _row("SGST", sgst),
              _row("Total Tax", _num(_order?["totalTax"])),
              _divider(),
              _row("TDS", _num(_order?["tds"])),
              _row("MYN Commission", _num(_order?["mynCommissionAmount"]),
                  valueColor: MynPalette.red),
              _row("Platform Fee", _num(_order?["platformPrice"])),
              _row("Delivery Charge", _num(_order?["deliveryCharge"])),
              _divider(),
              _row("Net Earnings", _num(_order?["earnings"]),
                  bold: true, valueColor: MynPalette.green),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerCard() {
    final addr = (_order?["addressInputModel"] as Map?) ?? const {};
    final payment = (_order?["paymentDetails"] as Map?) ?? const {};

    final parts = <String>[
      _str(addr["houseName"], ""),
      _str(addr["street"], ""),
      _str(addr["formattedAddress"], ""),
      _str(addr["district"], ""),
      _str(addr["state"], ""),
      _str(addr["postalCode"], ""),
    ].where((e) => e.isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel("Customer"),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: MynPalette.card(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow(Icons.person_rounded, _str(_order?["customerName"])),
              if (_str(_order?["customerMobile"], "").isNotEmpty)
                _infoRow(Icons.phone_rounded,
                    _str(_order?["customerMobile"])),
              if (parts.isNotEmpty)
                _infoRow(Icons.location_on_rounded, parts.join(", ")),
              if (_str(payment["method"], "").isNotEmpty)
                _infoRow(Icons.credit_card_rounded,
                    _str(payment["method"]).toUpperCase()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: MynPalette.muted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  color: MynPalette.heading, fontSize: 13.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Text(
        text,
        style: TextStyle(
            color: MynPalette.heading,
            fontSize: 16,
            fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _divider() => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(vertical: 6),
        color: MynPalette.cardBorder,
      );

  Widget _row(String label, double value,
      {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: bold ? MynPalette.heading : MynPalette.muted,
                fontSize: 13.5,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            MynPalette.money(value),
            style: TextStyle(
              color: valueColor ?? MynPalette.heading,
              fontSize: bold ? 15.5 : 13.5,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
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
          Text("Couldn't load this order",
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
