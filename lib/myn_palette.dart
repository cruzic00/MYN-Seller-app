import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Shared tokens for the redesigned seller screens (dashboard, orders, order
/// detail). Tonal pairs â a saturated foreground plus a tinted background â
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

  /// Brand yellow, sampled from the MYN artwork.
  ///
  /// It is a *surface* colour — headers, heroes, the login page — never a
  /// fill behind white text, which it cannot carry (1.7:1). Always pair it with
  /// [onYellow]; teal stays the action colour for buttons and icons.
  static const Color brandYellow = Color(0xFFFDC82D);
  static const Color brandYellowDeep = Color(0xFFF3AD03);
  static const Color onYellow = Color(0xFF4A3600);

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

  /// Grouped to match the web Business Panel ("â¹9,907.96").
  static final NumberFormat _money = NumberFormat("#,##0.00");

  static String money(num v) => "â¹${_money.format(v)}";
}
