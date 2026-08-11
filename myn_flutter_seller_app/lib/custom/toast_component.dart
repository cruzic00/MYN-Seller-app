import 'package:flutter/material.dart';
import 'package:motion_toast/motion_toast.dart';
import 'package:one_context/one_context.dart';

class ToastComponent {
  static showDialog(String? msg, {duration = 0, gravity = 0, isError = false}) {
    isError
        ? MotionToast.error(
            title: Text(
              "Error",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            description: Text(msg!, style: TextStyle(fontSize: 15)),
            toastDuration: Duration(seconds: duration),
            position: MotionToastPosition.top,
            animationType: AnimationType.fromTop,
            iconSize: 33,
            width: 900,
            height: 100,
            contentPadding: EdgeInsets.all(15),
            borderRadius: 20,
          ).show(OneContext().context!)
        : MotionToast.success(
            title: Text(
              "Success",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            description: Text(msg!, style: TextStyle(fontSize: 15)),
            toastDuration: Duration(seconds: duration),
            position: MotionToastPosition.top,
            animationType: AnimationType.fromTop,
            iconSize: 33,
            width: 900,
            height: 100,
            contentPadding: EdgeInsets.all(15),
            borderRadius: 20,
          ).show(OneContext().context!);
  }
}
