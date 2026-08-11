import 'package:myn_seller_app/my_theme.dart';
import 'package:flutter/material.dart';

class InputDecorations {
  static InputDecoration buildInputDecoration_1({hint_text = ""}) {
    return InputDecoration(
        hintText: hint_text,
        hintStyle: TextStyle(fontSize: 14.0, color: MyTheme.dark_grey),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: MyTheme.accent_color_2, width: 1),
          borderRadius: const BorderRadius.all(
            const Radius.circular(5.0),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: MyTheme.accent_color, width: 1.5),
          borderRadius: const BorderRadius.all(
            const Radius.circular(5.0),
          ),
        ),
        contentPadding: EdgeInsets.only(left: 16.0));
  }

  static InputDecoration buildInputDecoration_phone({hint_text = ""}) {
    return InputDecoration(
        hintText: hint_text,
        hintStyle: TextStyle(fontSize: 14.0, color: MyTheme.dark_grey),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: MyTheme.accent_color_2, width: 1),
          borderRadius: BorderRadius.only(
              topRight: Radius.circular(5.0),
              bottomRight: Radius.circular(5.0)),
        ),
        focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: MyTheme.accent_color, width: 1.5),
            borderRadius: BorderRadius.only(
                topRight: Radius.circular(5.0),
                bottomRight: Radius.circular(5.0))),
        contentPadding: EdgeInsets.only(left: 16.0));
  }
}
