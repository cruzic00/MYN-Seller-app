import 'dart:convert';

/// Models `GET /api/admin/orders` from the MYN online-shop Node API.
///
/// The controller (server/controllers/admin.controller.js `getOrders`) already
/// flattens each OrderShop document and scopes it to the caller's shop, so the
/// app can render rows straight from `data.orders` without further filtering.
/// Envelope is the standard `{ success, statusCode, message, data, timestamp }`.
MynOrderListResponse mynOrderListResponseFromJson(String str) =>
    MynOrderListResponse.fromJson(json.decode(str));

class MynOrderListResponse {
  final bool success;
  final String message;
  final List<MynOrder> orders;
  final MynOrderTotals totals;
  final int count;

  MynOrderListResponse({
    required this.success,
    required this.message,
    required this.orders,
    required this.totals,
    required this.count,
  });

  factory MynOrderListResponse.fromJson(Map<String, dynamic> json) {
    final data = (json["data"] as Map<String, dynamic>?) ?? const {};
    final rawOrders = (data["orders"] as List?) ?? const [];

    return MynOrderListResponse(
      success: json["success"] == true,
      message: json["message"]?.toString() ?? "",
      orders: rawOrders
          .whereType<Map<String, dynamic>>()
          .map(MynOrder.fromJson)
          .toList(),
      totals: MynOrderTotals.fromJson(
          (data["totals"] as Map<String, dynamic>?) ?? const {}),
      count: _toInt(data["count"]),
    );
  }

  /// The panel's "Total Paid" tile is a sum of the rows; the API's `totals`
  /// block deliberately omits it, so derive it here.
  double get customerPaidTotal =>
      orders.fold<double>(0, (sum, o) => sum + o.customerPaid);
}

class MynOrder {
  final String id;
  final String orderId;
  final String customerName;
  final String shopName;
  final double customerPaid;
  final double sgst;
  final double cgst;
  final double totalTax;
  final double tds;
  final double commission;
  final double platformFee;
  final double dc;
  final double earnings;
  final String status;
  final String payment;
  final DateTime? createdAt;

  MynOrder({
    required this.id,
    required this.orderId,
    required this.customerName,
    required this.shopName,
    required this.customerPaid,
    required this.sgst,
    required this.cgst,
    required this.totalTax,
    required this.tds,
    required this.commission,
    required this.platformFee,
    required this.dc,
    required this.earnings,
    required this.status,
    required this.payment,
    required this.createdAt,
  });

  factory MynOrder.fromJson(Map<String, dynamic> json) => MynOrder(
        id: json["_id"]?.toString() ?? "",
        orderId: json["orderId"]?.toString() ?? "—",
        customerName: json["customerName"]?.toString() ?? "Guest",
        shopName: json["shopName"]?.toString() ?? "—",
        customerPaid: _toDouble(json["customerPaid"]),
        sgst: _toDouble(json["sgst"]),
        cgst: _toDouble(json["cgst"]),
        totalTax: _toDouble(json["totalTax"]),
        tds: _toDouble(json["tds"]),
        commission: _toDouble(json["commission"]),
        platformFee: _toDouble(json["platformFee"]),
        dc: _toDouble(json["dc"]),
        earnings: _toDouble(json["earnings"]),
        status: json["status"]?.toString().toUpperCase() ?? "SUBMITTED",
        payment: json["payment"]?.toString() ?? "—",
        createdAt: _toDate(json["createdAt"]),
      );
}

class MynOrderTotals {
  final double earnings;
  final double sgst;
  final double cgst;
  final double tds;
  final double platformFee;
  final double commission;
  final double dc;
  final double totalGst;

  MynOrderTotals({
    required this.earnings,
    required this.sgst,
    required this.cgst,
    required this.tds,
    required this.platformFee,
    required this.commission,
    required this.dc,
    required this.totalGst,
  });

  factory MynOrderTotals.fromJson(Map<String, dynamic> json) => MynOrderTotals(
        earnings: _toDouble(json["earnings"]),
        sgst: _toDouble(json["sgst"]),
        cgst: _toDouble(json["cgst"]),
        tds: _toDouble(json["tds"]),
        platformFee: _toDouble(json["platformFee"]),
        commission: _toDouble(json["commission"]),
        dc: _toDouble(json["dc"]),
        totalGst: _toDouble(json["totalGst"]),
      );
}

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

DateTime? _toDate(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString())?.toLocal();
}
