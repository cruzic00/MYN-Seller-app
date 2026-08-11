// To parse this JSON data, do
//
//     final earningOrCollectionResponse = earningOrCollectionResponseFromJson(jsonString);

import 'dart:convert';

import 'package:myn_seller_app/data_model/download_report_response.dart';

EarningOrCollectionResponse earningOrCollectionResponseFromJson(String str) =>
    EarningOrCollectionResponse.fromJson(json.decode(str));

String earningOrCollectionResponseToJson(EarningOrCollectionResponse data) =>
    json.encode(data.toJson());

class EarningOrCollectionResponse {
  EarningOrCollectionResponse({
    this.data,
    this.links,
    this.meta,
    this.success,
    this.status,
  });

  List<Datum>? data;
  Links? links;
  Meta? meta;
  bool? success;
  int? status;

  factory EarningOrCollectionResponse.fromJson(Map<String, dynamic> json) =>
      EarningOrCollectionResponse(
        data: json["data"] == null
            ? null
            : List<Datum>.from(json["data"].map((x) => Datum.fromJson(x))),
        links: json["links"] == null ? null : Links.fromJson(json["links"]),
        meta: json["meta"] == null ? null : Meta.fromJson(json["meta"]),
        success: json["success"],
        status: json["status"],
      );

  Map<String, dynamic> toJson() => {
        "data": data == null
            ? null
            : List<dynamic>.from(data!.map((x) => x.toJson())),
        "links": links?.toJson(),
        "meta": meta?.toJson(),
        "success": success,
        "status": status,
      };
}

class Datum {
  Datum({
    this.id,
    this.deliveryBoyId,
    this.orderId,
    this.orderCode,
    this.productInfo,
    this.totalTax,
    this.totalSellerPrice,
    this.deliveryStatus,
    this.earning,
    this.collection,
    this.paymentType,
    this.purchaseDate,
  });

  int? id;
  int? deliveryBoyId;
  int? orderId;
  String? orderCode;
  List<ProductInfo>? productInfo;
  double? totalTax;
  String? totalSellerPrice;
  String? deliveryStatus;
  String? earning;
  String? collection;
  String? paymentType;
  String? purchaseDate;

  factory Datum.fromJson(Map<String, dynamic> json) {
    String formatModeOfPayment(String input) {
      return input.split('_').map((word) => word.capitalize()).join(' ');
    }

    return Datum(
        id: json["id"],
        deliveryBoyId: json["delivery_boy_id"],
        orderId: json["order_id"],
        orderCode: json["order_code"],
        productInfo: json["product_info"] == null
            ? null
            : List<ProductInfo>.from(
                json["product_info"].map((x) => ProductInfo.fromJson(x))),
        totalTax: json["total_tax"]?.toDouble(),
        totalSellerPrice: json["total_seller_price"].toString(),
        deliveryStatus: json["delivery_status"],
        earning: json["earning"],
        collection: json["collection"],
        paymentType: formatModeOfPayment(json["payment_type"]),
        purchaseDate: json["purchase_date"]);
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "delivery_boy_id": deliveryBoyId,
        "order_id": orderId,
        "order_code": orderCode,
        "product_info": productInfo == null
            ? null
            : List<dynamic>.from(productInfo!.map((x) => x.toJson())),
        "total_tax": totalTax,
        "total_seller_price": totalSellerPrice,
        "delivery_status": deliveryStatus,
        "earning": earning,
        "collection": collection,
        "payment_type": paymentType,
        "purchase_date": purchaseDate,
      };
}

class ProductInfo {
  ProductInfo({
    this.name,
    this.price,
    this.priceMrp,
    this.priceSeller,
    this.quantity,
    this.tax,
  });

  String? name;
  double? price;
  double? priceMrp;
  double? priceSeller;
  double? quantity;
  double? tax;

  factory ProductInfo.fromJson(Map<String, dynamic> json) => ProductInfo(
        name: json["name"],
        price: json["price"]?.toDouble(),
        priceMrp: json["price_mrp"]?.toDouble(),
        priceSeller: json["price_seller"]?.toDouble(),
        quantity: json["quantity"]?.toDouble(),
        tax: json["tax"]?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "price": price,
        "price_mrp": priceMrp,
        "price_seller": priceSeller,
        "quantity": quantity,
        "tax": tax,
      };
}

class Links {
  Links({
    this.first,
    this.last,
    this.prev,
    this.next,
  });

  String? first;
  String? last;
  dynamic prev;
  dynamic next;

  factory Links.fromJson(Map<String, dynamic> json) => Links(
        first: json["first"],
        last: json["last"],
        prev: json["prev"],
        next: json["next"],
      );

  Map<String, dynamic> toJson() => {
        "first": first,
        "last": last,
        "prev": prev,
        "next": next,
      };
}

class Meta {
  Meta({
    this.currentPage,
    this.from,
    this.lastPage,
    this.links,
    this.path,
    this.perPage,
    this.to,
    this.total,
  });

  int? currentPage;
  int? from;
  int? lastPage;
  List<Link>? links;
  String? path;
  int? perPage;
  int? to;
  int? total;

  factory Meta.fromJson(Map<String, dynamic> json) => Meta(
        currentPage: json["current_page"],
        from: json["from"],
        lastPage: json["last_page"],
        links: json["links"] == null
            ? null
            : List<Link>.from(json["links"].map((x) => Link.fromJson(x))),
        path: json["path"],
        perPage: json["per_page"],
        to: json["to"],
        total: json["total"],
      );

  Map<String, dynamic> toJson() => {
        "current_page": currentPage,
        "from": from,
        "last_page": lastPage,
        "links": links == null
            ? null
            : List<dynamic>.from(links!.map((x) => x.toJson())),
        "path": path,
        "per_page": perPage,
        "to": to,
        "total": total,
      };
}

class Link {
  Link({
    this.url,
    this.label,
    this.active,
  });

  String? url;
  String? label;
  bool? active;

  factory Link.fromJson(Map<String, dynamic> json) => Link(
        url: json["url"],
        label: json["label"],
        active: json["active"],
      );

  Map<String, dynamic> toJson() => {
        "url": url,
        "label": label,
        "active": active,
      };
}
