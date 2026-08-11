import 'package:flutter/material.dart';
import 'package:myn_seller_app/myn_palette.dart';
import 'package:shimmer/shimmer.dart';

/// A single shimmering placeholder bar.
///
/// Only the values that are actually being fetched get wrapped in one — the
/// surrounding labels, icons and card chrome stay painted, so the screen keeps
/// its shape while loading instead of collapsing to a spinner.
class Skeleton extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  /// Defaults suit the light cards; pass the `.onDark` pair inside the teal hero.
  final Color? baseColor;
  final Color? highlightColor;

  const Skeleton({
    Key? key,
    this.width = 60,
    this.height = 14,
    this.radius = 6,
    this.baseColor,
    this.highlightColor,
  }) : super(key: key);

  static const Color _base = Color(0xFFE2EAEB);
  static const Color _highlight = Color(0xFFF3F8F9);
  static const Color onDarkBase = Color.fromRGBO(255, 255, 255, 0.22);
  static const Color onDarkHighlight = Color.fromRGBO(255, 255, 255, 0.42);

  const Skeleton.onDark({
    Key? key,
    this.width = 90,
    this.height = 20,
    this.radius = 6,
  })  : baseColor = onDarkBase,
        highlightColor = onDarkHighlight,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? _base,
      highlightColor: highlightColor ?? _highlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// Placeholder shaped like one order row in the Orders list.
class OrderCardSkeleton extends StatelessWidget {
  const OrderCardSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: MynPalette.card(),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Skeleton(width: 110, height: 15),
                      SizedBox(height: 8),
                      Skeleton(width: 160, height: 11),
                    ],
                  ),
                ),
                const Skeleton(width: 66, height: 22, radius: 20),
              ],
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: MynPalette.cardBorder),
            const SizedBox(height: 12),
            Row(
              children: const [
                Expanded(child: Skeleton(width: 70, height: 13)),
                Expanded(child: Skeleton(width: 70, height: 13)),
                Expanded(child: Skeleton(width: 70, height: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
