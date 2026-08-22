import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myn_seller_app/app_config.dart';
import 'package:myn_seller_app/my_theme.dart';
import 'package:myn_seller_app/screens/myn_product_detail.dart';
import 'package:myn_seller_app/screens/product_details.dart';
import 'package:toast/toast.dart';

import '../custom/toast_component.dart';
import '../helpers/shared_value_helper.dart';

class ProductCard extends StatefulWidget {
  final int? id;

  /// MongoDB `_id` of the stocklist entry — the identifier the MYN online-shop
  /// API uses for product detail and update calls.
  final String? mongo_id;
  final String? image;

  /// "Pending" while MYN reviews a newly uploaded picture.
  final String? image_status;
  final String? name;
  final String? stroked_price;
  final String? seller_price;
  final bool? has_discount;
  bool? is_active;

  /// Fired after the detail screen reports a save, so the grid the card sits in
  /// can refetch. The card used to carry its own Edit button next to the price;
  /// tapping the card already opens the same editable detail screen, so the
  /// button was a second door to one room — and neither door refreshed the
  /// grid, which is why an edited price kept showing the old value.
  final VoidCallback? onChanged;

  ProductCard(
      {Key? key,
      this.id,
      this.mongo_id,
      this.image,
      this.image_status,
      this.name,
      this.stroked_price,
      this.seller_price,
      this.is_active,
      this.has_discount,
      this.onChanged})
      : super(key: key);

  @override
  _ProductCardState createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool get isImagePending =>
      (widget.image_status ?? "").toLowerCase() == "pending";

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
        })).then((changed) {
          if (changed == true) widget.onChanged?.call();
        });
      },
      child: Card(
        clipBehavior: Clip.antiAliasWithSaveLayer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 3.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Square, to match the web panel's thumbnails. The old card was one
            // tall image with the text laid over a black gradient, so a dish
            // photo shot square arrived stretched and half-covered.
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: MyTheme.light_grey,
                    child: buildThumbnail(),
                  ),
                  if (isImagePending)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: const Color(0xFFD98E22), width: 2.5),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: MyCustomBadge(widget.is_active!),
                  ),
                  if (isImagePending)
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBF1E1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFFD98E22), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule_rounded,
                                size: 12, color: const Color(0xFFD98E22)),
                            const SizedBox(width: 4),
                            Text(
                              "Waiting approval",
                              style: TextStyle(
                                color: const Color(0xFF8A5B0E),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.name ?? "",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: MyTheme.font_grey,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.seller_price != widget.stroked_price)
                                Text(
                                  widget.stroked_price ?? "",
                                  style: TextStyle(
                                    color: MyTheme.medium_grey,
                                    fontSize: 10.5,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              Text(
                                widget.seller_price ?? "",
                                style: TextStyle(
                                  color: MyTheme.accent_color,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
