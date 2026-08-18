import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myn_seller_app/app_config.dart';
import 'package:myn_seller_app/my_theme.dart';
import 'package:myn_seller_app/screens/product_details.dart';
import 'package:myn_seller_app/screens/productedit.dart';
import 'package:toast/toast.dart';

import '../custom/toast_component.dart';
import '../helpers/shared_value_helper.dart';

class ProductCard extends StatefulWidget {
  final int? id;

  /// MongoDB `_id` of the stocklist entry — the identifier the MYN online-shop
  /// API uses for product detail and update calls.
  final String? mongo_id;
  final String? image;
  final String? name;
  final String? stroked_price;
  final String? seller_price;
  final bool? has_discount;
  bool? is_active;

  ProductCard(
      {Key? key,
      this.id,
      this.mongo_id,
      this.image,
      this.name,
      this.stroked_price,
      this.seller_price,
      this.is_active,
      this.has_discount})
      : super(key: key);

  @override
  _ProductCardState createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  ToggleIsActive() async {
    var post_body = jsonEncode({
      "productId": widget.id,
      "status": !widget.is_active!,
    });

    final response = await http.post(
        Uri.parse("${AppConfig.BASE_URL}/product/change-status"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${access_token.$}"
        },
        body: post_body);

    var dataUser = json.decode(response.body);

    ToastComponent.showDialog(dataUser['message'],
        gravity: Toast.center, duration: Toast.lengthLong);

    setState(() {
      widget.is_active = !widget.is_active!;
    });
  }

  /// `thumbnail_image` arrives already absolute for MYN stocklist items
  /// (`https://safesmilez.com/api/images/...`) but as a bare S3 key for legacy
  /// Laravel products. Prefixing the bucket unconditionally produced
  /// `https://<bucket>/https://safesmilez.com/...`, so every card rendered a
  /// blank tile.
  String imageUrl() {
    final String raw = widget.image ?? "";
    if (raw.isEmpty) return "";
    if (raw.startsWith("http")) return raw;
    if (raw.startsWith("/")) return "${AppConfig.RAW_BASE_URL}$raw";
    return AppConfig.BASE_IMAGE_PATH + raw;
  }

  Widget buildFallbackIcon() {
    return Center(
      child: Icon(Icons.image_not_supported_outlined,
          color: MyTheme.medium_grey, size: 38),
    );
  }

  Widget buildThumbnail() {
    final String url = imageUrl();
    if (url.isEmpty) return buildFallbackIcon();

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: 400,
      placeholder: (context, _) => Center(
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: MyTheme.accent_color),
        ),
      ),
      errorWidget: (context, _, __) => buildFallbackIcon(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // MYN stocklist rows are keyed by Mongo _id and have no integer id, so
        // the legacy ProductDetails screen (which fetches /api/v2/products/{int})
        // could never load one — it just spun. Route those to the MYN screen and
        // leave the legacy path for rows that still carry an integer id.
        final String mongoId = (widget.mongo_id ?? "").trim();

        Navigator.push(context, MaterialPageRoute(builder: (context) {
          if (mongoId.isNotEmpty) {
            return MynProductDetail(
              productId: mongoId,
              fallbackName: widget.name,
            );
          }
          return ProductDetails(id: widget.id);
        }));
      },
      child: Stack(
        children: [
          Card(
            clipBehavior: Clip.antiAliasWithSaveLayer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            elevation: 6.0,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 400,
                  color: MyTheme.light_grey,
                  child: buildThumbnail(),
                ),
                Container(
                  width: double.infinity,
                  height: 400,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.center,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black26,
                        Colors.black,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 10,
                  right: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        widget.name!,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      widget.seller_price != widget.stroked_price
                          ? Text(
                              "MRP: ${widget.stroked_price}",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            )
                          : Container(),
                      Text(
                        widget.seller_price!,
                        style: TextStyle(
                          color: MyTheme.parrot_green,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        height: 30,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) {
                                  return ProductEdit(
                                    id: widget.id,
                                    mongo_id: widget.mongo_id,
                                  );
                                }));
                              },
                              child: Text('Edit',
                                  style: TextStyle(color: Colors.black)),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 18,
            right: 15,
            child: MyCustomBadge(widget.is_active!),
          ),
        ],
      ),
    );
  }
}

MyCustomBadge(bool is_active) {
  return is_active
      ? Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Active',
            style: TextStyle(
              color: Color.fromARGB(255, 232, 252, 232),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        )
      : Container(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Inactive',
            style: TextStyle(
              color: Color.fromARGB(255, 248, 218, 218),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
}
