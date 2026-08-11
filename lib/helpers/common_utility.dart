import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myn_seller_app/my_theme.dart';

Future<bool> _showExitConfirmationDialog(BuildContext context) async {
  return await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Exit App'),
          content: Text('Do you want to exit the app?'),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: MyTheme.red),
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('No', style: TextStyle(color: MyTheme.white)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: MyTheme.accent_color),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text('Yes', style: TextStyle(color: MyTheme.white)),
            ),
          ],
        ),
      ) ??
      false;
}

void onPopInvoked(bool willPop, BuildContext context) async {
  bool shouldExit = await _showExitConfirmationDialog(context);
  if (shouldExit) {
    SystemChannels.platform.invokeMethod('SystemNavigator.pop');
  }
}
