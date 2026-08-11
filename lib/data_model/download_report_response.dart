
class Order {
  final String datePurchase;
  final String customerName;
  final int orderId;
  final String orderCode;
  final String status;
  final String modePayment;
  final double sellerPrice;
  final double taxAmount;
  final double totalPrice;

  Order({
    required this.datePurchase,
    required this.customerName,
    required this.orderId,
    required this.status,
    required this.orderCode,
    required this.modePayment,
    required this.sellerPrice,
    required this.taxAmount,
    required this.totalPrice,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    String formatModeOfPayment(String input) {
      return input.split('_').map((word) => word.capitalize()).join(' ');
    }

    return Order(
      datePurchase: json['date_purchase'],
      customerName: json['customer_name'].toString().toUpperCase(),
      orderId: json['order_id'],
      orderCode: json['order_code'],
      status: json['status'],
      modePayment: formatModeOfPayment(json['mode_payment']),
      sellerPrice: json['seller_price'].toDouble(),
      taxAmount: json['tax_amount'].toDouble(),
      totalPrice: json['total_price'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date_purchase': datePurchase,
      'customer_name': customerName,
      'order_id': orderId,
      'order_code': orderCode,
      'status': status,
      'mode_payment': modePayment,
      'seller_price': sellerPrice,
      'tax_amount': taxAmount,
      'total_price': totalPrice,
    };
  }
}

class ApiResponse {
  final List<Order> data;
  final bool result;
  final String message;

  ApiResponse({
    required this.data,
    required this.result,
    required this.message,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    var dataList = json['data'] as List;
    List<Order> orderList =
        dataList.map((orderJson) => Order.fromJson(orderJson)).toList();

    return ApiResponse(
      data: orderList,
      result: json['result'],
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((order) => order.toJson()).toList(),
      'result': result,
      'message': message,
    };
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
