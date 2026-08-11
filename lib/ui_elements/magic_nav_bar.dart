import 'package:flutter/material.dart';
import 'package:myn_seller_app/my_theme.dart';
import 'package:myn_seller_app/myn_palette.dart';

class MagicNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const MagicNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// A floating bottom bar where the selected tab grows into a labelled pill and
/// the others stay as bare icons.
///
/// Material's NavigationBar reserves room for every label at once, which on a
/// three-tab bar leaves it looking heavy and static. Here only the active tab
/// spends the width, so the bar reads as one moving element.
class MagicNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<MagicNavItem> items;

  const MagicNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  }) : super(key: key);

  static const Duration _duration = Duration(milliseconds: 300);
  static const Curve _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: MynPalette.cardBorder),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(16, 42, 45, 0.14),
              blurRadius: 22,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (int i = 0; i < items.length; i++) _buildItem(items[i], i),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(MagicNavItem item, int index) {
    final bool selected = index == currentIndex;

    return Flexible(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: AnimatedContainer(
          duration: _duration,
          curve: _curve,
          padding: EdgeInsets.symmetric(
              horizontal: selected ? 16 : 14, vertical: 11),
          decoration: BoxDecoration(
            color: selected
                ? MyTheme.accent_color.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          // AnimatedSize carries the width change when the label appears, so the
          // pill grows instead of snapping.
          child: AnimatedSize(
            duration: _duration,
            curve: _curve,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  duration: _duration,
                  curve: _curve,
                  scale: selected ? 1.0 : 0.92,
                  child: Icon(
                    selected ? item.activeIcon : item.icon,
                    size: 22,
                    color:
                        selected ? MyTheme.accent_color : MynPalette.muted,
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 8),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    softWrap: false,
                    style: TextStyle(
                      color: MyTheme.accent_color,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
