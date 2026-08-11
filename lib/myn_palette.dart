import 'package:flutter/material.dart';

/// Shared tokens for the redesigned seller screens (dashboard, orders, order
/// detail). Tonal pairs — a saturated foreground plus a tinted background —
/// keep the accent colours from competing with the brand teal in MyTheme.
class MynPalette {
  static const Color surface = Color(0xFFF3F6F7);
  static const Color cardBorder = Color(0xFFE6EDEE);
  static const Color heading = Color(0xFF16292B);
  static const Color muted = Color(0xFF7C8D8F);

  static const Color green = Color(0xFF2E9E5B);
  static const Color greenTint = Color(0xFFE6F5EC);
  static const Color amber = Color(0xFFD98E22);
  static const Color amberTint = Color(0xFFFBF1E1);
  static const Color red = Color(0xFFDC5A44);
  static const Color redTint = Color(0xFFFBEAE7);
  static const Color blue = Color(0xFF3F79CD);
  static const Color blueTint = Color(0xFFE7EEFA);

  static const Color accentDark = Color(0xFF2C6A70);

  static BoxDecoration card() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(16, 42, 45, 0.05),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      );

  /// Order status -> (foreground, tint). Statuses come from the API upper-cased
  /// (CREATED / SUBMITTED / FAILED / DELIVERED / CANCELLED ...).
  static List<Color> statusColors(String status) {
    switch (status.toUpperCase()) {
      case 'DELIVERED':
      case 'COMPLETED':
      case 'SUCCESS':
        return const [green, greenTint];
      case 'FAILED':
      case 'CANCELLED':
      case 'REJECTED':
        return const [red, redTint];
      case 'CREATED':
      case 'SUBMITTED':
      case 'PENDING':
        return const [blue, blueTint];
      default:
        return const [amber, amberTint];
    }
  }

  static String money(num v) => "₹${v.toStringAsFixed(2)}";
}
