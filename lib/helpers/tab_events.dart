import 'dart:async';

/// Broadcasts "a bottom-tab was selected" to the screen behind it.
///
/// main.dart keeps all three tabs alive in an IndexedStack, so a tab that was
/// built once never rebuilds and never refetches. That is what makes switching
/// tabs instant, but it also means a change made elsewhere — an image approved
/// in the web panel, a price edited on another device — kept showing the state
/// the tab had loaded on first open. Screens listen here and reload quietly when
/// they come back to the front.
class TabEvents {
  static final StreamController<int> _controller =
      StreamController<int>.broadcast();

  /// Emits the index of the tab that just became visible.
  static Stream<int> get stream => _controller.stream;

  static void selected(int index) {
    if (!_controller.isClosed) _controller.add(index);
  }
}
