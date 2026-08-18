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
import 'package:myn_seller_app/repositories/myn_device_token_repository.dart';
import 'package:myn_seller_app/screens/myn_orders.dart';
import 'package:myn_seller_app/screens/pending.dart';
import 'package:one_context/one_context.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:toast/toast.dart';

class NotificationService {
  /// Must match the `channelId` services/push.service.js sends, otherwise
  /// Android drops a backgrounded order alert into the low-importance default
  /// channel and it arrives silently.
  static const String _orderChannelId = 'new_order';

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
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    // Registered up front so a push that arrives while the app is killed —
    // drawn by Android itself, not by this plugin — still lands on a
    // high-importance channel and makes a sound.
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _orderChannelId,
            'New orders',
            description:
                'Alerts the shop when a customer places an order.',
            importance: Importance.max,
          ),
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
      print('Foreground message: ${message.data}');

      if (message.data['type'] == 'new_order') {
        showCustomNotification(message.data);
        return;
      }

      // Legacy Laravel push, kept so an old backend still works.
      if (message.data['message'] != null) {
        fetchOrderedItems(message.data);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification tapped: ${message.data}');
      _openOrders();
    });
  }

  /// Sends the seller to their orders list. Used both when a tray notification
  /// is tapped and when the app is already open.
  static void _openOrders() {
    final context = OneContext().context;
    if (context == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MynOrders(show_back_button: true)),
    );
  }

  static Future<void> _updateFcmToken(String token) async {
    // Registered unconditionally rather than only on change: the server holds
    // tokens as a set, and skipping the call when the token looks unchanged
    // left sellers unreachable whenever a registration had failed earlier.
    print("Registering FCM token: $token");
    await MynDeviceTokenRepository().register(token);
  }

  /// Drops this phone from the shop's device list. Called on sign-out so a
  /// handed-over or resold phone stops receiving that shop's orders.
  static Future<void> unregisterDevice() async {
    final token = showNotificationToken.$;
    if (token.isEmpty) return;
    await MynDeviceTokenRepository().unregister(token);
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
    // Guarded: a payload with no digits in it used to throw on `matches.first`
    // and take down the rest of the message handler with it.
    if (matches.isEmpty) return;
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
    // MYN push. Everything the tray entry needs is already in the payload, so
    // there is no server round-trip here — this also runs in the background
    // isolate, where no navigator or auth state is available.
    if (message['type'] == 'new_order') {
      final bill = (message['billNo'] ?? '').toString();
      final items = (message['items'] ?? '').toString();
      final amount = (message['amount'] ?? '').toString();
      final currency =
          (message['currency'] ?? 'INR').toString() == 'INR' ? '₹' : '';

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        _orderChannelId,
        'New orders',
        channelDescription: 'Alerts the shop when a customer places an order.',
        importance: Importance.max,
        priority: Priority.high,
      );

      await _flutterLocalNotificationsPlugin.show(
        id: Random().nextInt(100000),
        title: 'New order',
        body: [
          if (bill.isNotEmpty) 'Bill $bill',
          if (items.isNotEmpty) '$items item${items == "1" ? "" : "s"}',
          if (amount.isNotEmpty) '$currency$amount',
        ].join('  ·  '),
        notificationDetails:
            const NotificationDetails(android: androidDetails),
        payload: 'new_order',
      );

      NotificationSound(false);
      return;
    }

    // Legacy Laravel push: the order id is embedded in a sentence. Guarded
    // because a payload without a number used to throw on `matches.first`.
    final text = (message['message'] ?? '').toString();
    final matches = RegExp(r'\d+').allMatches(text);
    if (matches.isEmpty) return;

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
        id: Random().nextInt(100),
        title: 'New Order Received',
        body:
            'Order ID: ${id}, ${orderItemResponse.ordered_items![0].product_name} x ${orderItemResponse.ordered_items![0].quantity}',
        notificationDetails: platformChannelSpecifics,
        payload: id.toString(),
      );
    }
  }

  static Future<void> _onDidReceiveNotificationResponse(
      NotificationResponse response) async {
    final String? payload = response.payload;
    if (payload == null) return;

    print('notification payload: $payload');

    if (payload == 'new_order') {
      _openOrders();
      return;
    }

    final context = OneContext().context;
    if (context != null) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => Pending(index: 2),
      ));
    }
  }
}
