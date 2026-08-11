import 'dart:math' show Random;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:myn_seller_app/custom/toast_component.dart';
import 'package:myn_seller_app/helpers/shared_value_helper.dart';
import 'package:myn_seller_app/my_theme.dart';
import 'package:myn_seller_app/repositories/delivery_repository.dart';
import 'package:myn_seller_app/repositories/order_repository.dart';
import 'package:myn_seller_app/repositories/profile_repositories.dart';
import 'package:myn_seller_app/screens/pending.dart';
import 'package:one_context/one_context.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:toast/toast.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    await _initializeLocalNotifications();
    await _setupFirebaseMessaging();
  }

  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );
  }

  static Future<void> _setupFirebaseMessaging() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');

      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        showNotificationToken.$ = token;
        print('FCM Token: $token');
        await _updateFcmToken(token);
      }

      FirebaseMessaging.instance.onTokenRefresh.listen(_updateFcmToken);
    } else {
      print('User declined or has not accepted permission');
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.data['message'] != null) {
        print(
            'Message also contained a notification: ${message.data['message']}');
        fetchOrderedItems(message.data);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      // Navigate to relevant screen based on the message
    });
  }

  static Future<void> _updateFcmToken(String token) async {
    if (showNotificationPermissionRequest.$ ||
        token != showNotificationToken.$) {
      print("Updating FCM token: $token");
      await ProfileRepository()
          .getDeviceTokenUpdateLoginResponse(user_id.$.toString(), token);
    }
  }

  static Future<bool> isNotificationAllowed() async {
    // For Android
    if (Theme.of(OneContext().context!).platform == TargetPlatform.android) {
      final bool? granted = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled();
      return granted ?? false;
    }
    // For iOS
    else if (Theme.of(OneContext().context!).platform == TargetPlatform.iOS) {
      final bool? granted = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return granted ?? false;
    }
    return false;
  }

  static Future<void> requestNotificationPermission() async {
    if (Theme.of(OneContext().context!).platform == TargetPlatform.android) {
      PermissionStatus status = await Permission.notification.status;

      if (status.isDenied) {
        // Request permission
        status = await Permission.notification.request();
        if (status.isDenied) {
          // Permission denied, show a dialog explaining why notifications are important
          _showPermissionExplanationDialog();
        }
      } else if (status.isPermanentlyDenied) {
        // Permission permanently denied, open app settings
        _openAppSettings();
      }
    } else if (Theme.of(OneContext().context!).platform == TargetPlatform.iOS) {
      final NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        _showPermissionExplanationDialog();
      }
    }
  }

  static void _showPermissionExplanationDialog() {
    OneContext().showDialog(
      builder: (BuildContext context) => AlertDialog(
        title: Text('Notification Permission'),
        content: Text(
            'Notifications are important for receiving new order alerts. Please grant permission in the app settings.'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('Open App Settings'),
            onPressed: () {
              Navigator.of(context).pop();
              _openAppSettings();
            },
          ),
        ],
      ),
    );
  }

  static void _openAppSettings() async {
    await openAppSettings();
  }

  static CustomPopup(orderItemResponse, order_id) async {
    var result = await OneContext().showDialog<String>(
        barrierColor: MyTheme.dark_grey.withOpacity(0.5),
        builder: (context) => AlertDialog(
              title: new Text("Order Details"),
              content: popupBody(context, orderItemResponse),
              actions: <Widget>[
                new TextButton(
                    style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all<Color>(
                            Colors.green.shade400)),
                    child: new Text("Confirm",
                        style: TextStyle(color: Colors.white, fontSize: 14)),
                    onPressed: () => {
                          NotificationSound(true),
                          OneContext().popDialog("CONFIRM"),
                        }),
                new TextButton(
                    style: ButtonStyle(
                        backgroundColor:
                            WidgetStateProperty.all<Color>(MyTheme.red)),
                    child: new Text("Cancel",
                        style: TextStyle(color: Colors.white, fontSize: 14)),
                    onPressed: () => {
                          NotificationSound(true),
                          OneContext().popDialog("CANCEL"),
                        }),
              ],
            ));
    if (result == "CONFIRM") {
      onPressMarkPickedPopup(OneContext().context, order_id);
    } else if (result == "CANCEL") {
      DoubleAlertCancellationPopup(OneContext().context, order_id);
    }
  }

  static void NotificationSound(bool stop) {
// Call on 'onPressed' to play a specific sound.
    if (stop) {
      FlutterRingtonePlayer().stop();
      return;
    }
    FlutterRingtonePlayer().play(
      android: AndroidSounds.notification,
      ios: IosSounds.glass,
      looping: true,
      // Android only - API >= 28
      volume: 0.9,
      // Android only - API >= 28
      asAlarm: false, // Android only - all APIs
    );
  }

  static popupBody(BuildContext context, orderedItemList) {
    return InkWell(
      onTap: () {
        OneContext().popDialog();
        OneContext().push(MaterialPageRoute(
            builder: (_) => Pending(
                  index: 2,
                )));
      },
      child: Card(
        shape: RoundedRectangleBorder(
          side: new BorderSide(color: MyTheme.light_grey, width: 1.0),
          borderRadius: BorderRadius.circular(8.0),
        ),
        elevation: 0.0,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  orderedItemList.product_name,
                  maxLines: 2,
                  style: TextStyle(
                    color: MyTheme.font_grey,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Text(
                      orderedItemList.quantity.toString() + " x ",
                      style: TextStyle(
                          color: MyTheme.font_grey,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                    orderedItemList.variation != "" &&
                            orderedItemList.variation != null
                        ? Text(
                            orderedItemList.variation,
                            style: TextStyle(
                                color: MyTheme.font_grey,
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                          )
                        : Text(
                            "item",
                            style: TextStyle(
                                color: MyTheme.font_grey,
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                          ),
                    Spacer(),
                    Text(
                      orderedItemList.price.toString(),
                      style: TextStyle(
                          color: MyTheme.font_grey,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static fetchOrderedItems(message) async {
    RegExp regExp = RegExp(r'\d+');
    var matches = regExp.allMatches("${message['message']}");
    print(matches.first.group(0));
    var id = int.tryParse(matches.first.group(0) as String);
    if (id != null) {
      var orderItemResponse = await OrderRepository().getOrderItems(id: id);
      NotificationSound(false);
      CustomPopup(orderItemResponse.ordered_items![0], id);
    }
  }

  static DoubleAlertCancellationPopup(context, order_id) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              contentPadding: EdgeInsets.only(
                  top: 16.0, left: 2.0, right: 2.0, bottom: 2.0),
              content: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Text(
                  "Are you sure to cancel this order ?",
                  maxLines: 3,
                  style: TextStyle(color: MyTheme.font_grey, fontSize: 14),
                ),
              ),
              actions: [
                MaterialButton(
                  child: Text(
                    "Close",
                    style: TextStyle(color: MyTheme.medium_grey),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                MaterialButton(
                    color: MyTheme.red,
                    child: Text(
                      "Confirm",
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                                contentPadding: EdgeInsets.only(
                                    top: 16.0,
                                    left: 2.0,
                                    right: 2.0,
                                    bottom: 2.0),
                                content: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 16.0),
                                  child: Text(
                                    "Are you sure to cancel this order ? (Double Confirmation)",
                                    maxLines: 3,
                                    style: TextStyle(
                                        color: MyTheme.font_grey, fontSize: 14),
                                  ),
                                ),
                                actions: [
                                  MaterialButton(
                                    child: Text(
                                      "Close",
                                      style: TextStyle(
                                          color: MyTheme.parrot_green),
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  MaterialButton(
                                      color: MyTheme.red,
                                      child: Text(
                                        "Confirm",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        onConfirmCancelPopup(context, order_id);
                                      }),
                                ],
                              ));
                    }),
              ],
            ));
  }

  static onConfirmCancelPopup(context, order_id) async {
    var cancelRequestResponse = await DeliveryRepository()
        .getDeliveryStatusChangeResponse(
            status: "cancelled", orderId: order_id);

    if (cancelRequestResponse.result == true) {
      ToastComponent.showDialog(cancelRequestResponse.message,
          gravity: Toast.center, duration: Toast.lengthLong);
    } else {
      ToastComponent.showDialog(cancelRequestResponse.message,
          gravity: Toast.center, duration: Toast.lengthLong, isError: true);
    }
  }

  static onPressMarkPickedPopup(context, order_id) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              contentPadding: EdgeInsets.only(
                  top: 16.0, left: 2.0, right: 2.0, bottom: 2.0),
              content: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Text(
                  "Are you sure to confirm this order ?",
                  maxLines: 3,
                  style: TextStyle(color: MyTheme.font_grey, fontSize: 14),
                ),
              ),
              actions: [
                MaterialButton(
                  child: Text(
                    "Close",
                    style: TextStyle(color: MyTheme.medium_grey),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                MaterialButton(
                  color: MyTheme.red,
                  child: Text(
                    "Confirm",
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onConfirmMarkPickedPopup(context, order_id);
                  },
                ),
              ],
            ));
  }

  static onConfirmMarkPickedPopup(context, order_id) async {
    print(order_id);
    var deliveryStatusChangeResponse = await DeliveryRepository()
        .getDeliveryStatusChangeResponse(
            status: "confirmed", orderId: order_id);

    if (deliveryStatusChangeResponse.result == true) {
      ToastComponent.showDialog(deliveryStatusChangeResponse.message,
          gravity: Toast.center, duration: Toast.lengthLong);
    } else {
      ToastComponent.showDialog(deliveryStatusChangeResponse.message,
          gravity: Toast.center, duration: Toast.lengthLong, isError: true);
    }
  }

  static Future<void> showCustomNotification(
      Map<String, dynamic> message) async {
    RegExp regExp = RegExp(r'\d+');
    var matches = regExp.allMatches(message['message']);
    print(matches.first.group(0));
    var id = int.tryParse(matches.first.group(0) as String);
    if (id != null) {
      var orderItemResponse = await OrderRepository().getOrderItems(id: id);

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'instant_notification',
        'Basic Instant Notification',
        channelDescription:
            'Notification channel that can trigger notification instantly.',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: false,
      );
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await _flutterLocalNotificationsPlugin.show(
        Random().nextInt(100),
        'New Order Received',
        'Order ID: ${id}, ${orderItemResponse.ordered_items![0].product_name} x ${orderItemResponse.ordered_items![0].quantity}',
        platformChannelSpecifics,
        payload: id.toString(),
      );
    }
  }

  static Future<void> _onDidReceiveNotificationResponse(
      NotificationResponse response) async {
    final String? payload = response.payload;
    if (payload != null) {
      print('notification payload: $payload');
      final context = OneContext().context;
      if (context != null) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => Pending(index: 2),
        ));
      }
    }
  }
}
