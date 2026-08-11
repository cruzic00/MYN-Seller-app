import 'dart:async';

import 'package:flutter/material.dart';
import 'package:myn_seller_app/myn_palette.dart';
import 'package:one_context/one_context.dart';

/// A small floating toast.
///
/// This used to be a MotionToast sized 900x100 with a hardcoded "Error" /
/// "Success" heading, which on a phone became a full-width slab across the top
/// of the screen covering the logo — and the heading said nothing the message
/// did not. One compact pill, one line, no heading.
///
/// The call signature is unchanged so every existing caller keeps working.
class ToastComponent {
  static OverlayEntry? _entry;

  static showDialog(String? msg, {duration = 0, gravity = 0, isError = false}) {
    final text = (msg ?? "").trim();
    if (text.isEmpty) return;

    final context = OneContext().context;
    if (context == null) return;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    // A second message should replace the first rather than stack on top of it.
    _dismiss();

    // Callers pass Toast.lengthShort / lengthLong (1 and 2); keep a floor so a
    // caller that passes nothing still gets something readable.
    final int seconds = (duration is int && duration > 0) ? duration + 1 : 2;

    final entry = OverlayEntry(
      builder: (_) => _ToastView(
        message: text,
        isError: isError,
        visibleFor: Duration(seconds: seconds),
        onDone: _dismiss,
      ),
    );
    _entry = entry;
    overlay.insert(entry);
  }

  static void _dismiss() {
    _entry?.remove();
    _entry = null;
  }
}

class _ToastView extends StatefulWidget {
  final String message;
  final bool isError;
  final Duration visibleFor;
  final VoidCallback onDone;

  const _ToastView({
    required this.message,
    required this.isError,
    required this.visibleFor,
    required this.onDone,
  });

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _timer = Timer(widget.visibleFor, () async {
      if (!mounted) return;
      await _controller.reverse();
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = widget.isError ? MynPalette.red : MynPalette.green;
    final Color tint = widget.isError ? MynPalette.redTint : MynPalette.greenTint;

    final curved =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.55),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(
          opacity: curved,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: MynPalette.cardBorder),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(16, 42, 45, 0.16),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: tint,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      widget.isError
                          ? Icons.error_outline_rounded
                          : Icons.check_rounded,
                      size: 18,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      widget.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: MynPalette.heading,
                        fontSize: 13.5,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
