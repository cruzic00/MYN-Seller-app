import 'dart:convert';
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
  final String? image;
  final String? name;
  final String? stroked_price;
  final String? seller_price;
  final bool? has_discount;
  bool? is_active;

  ProductCard(
      {Key? key,
      this.id,
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

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return ProductDetails(
            id: widget.id,
          );
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
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(
                        AppConfig.BASE_IMAGE_PATH + widget.image!,
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
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
                              onPressed: ToggleIsActive,
                              child: Text(
                                widget.is_active! ? 'Hide' : 'Show',
                                style: TextStyle(color: Colors.black),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            TextButton(
                              onPressed: () {
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) {
                                  return ProductEdit(
                                    id: widget.id,
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
