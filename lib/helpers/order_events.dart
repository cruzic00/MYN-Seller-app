import 'dart:async';

/// Broadcasts "this shop just got an order" to whichever screens are mounted.
///
/// NotificationService raises it from the FCM foreground handler, so the
/// dashboard and the orders list reload the moment a push lands instead of
/// waiting for the seller to pull down. A broadcast stream rather than a
/// callback because main.dart keeps all three tabs alive in an IndexedStack —
/// several listeners are subscribed at once.
class OrderEvents {
  static final StreamController<void> _controller =
      StreamController<void>.broadcast();

  static Stream<void> get stream => _controller.stream;

  /// Called when a `new_order` push arrives while the app is in the foreground.
  static void newOrder() {
    if (!_controller.isClosed) _controller.add(null);
  }
}
