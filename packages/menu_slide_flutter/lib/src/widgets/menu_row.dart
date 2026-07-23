import 'package:flutter/material.dart';

import '../models/menu_badge.dart';
import '../models/menu_item.dart';
import '../theme/menu_slide_theme_data.dart';
import 'menu_icon_view.dart';

/// A single presentational row in the menu panel: icon, label, and an
/// optional badge.
///
/// [MenuRow] is purely presentational — it has NO dependency on
/// `MenuSlideController`. The parent (`MenuSlideShell`, wired in a later
/// slice) owns selection state and tap delegation; it passes [isSelected]
/// and [onTap] in.
///
/// A disabled item (`item.enabled == false`) renders de-emphasized (reduced
/// opacity) and is non-interactive: [onTap] is never invoked for a disabled
/// row, no matter what callback is passed in — see the "malformed menu item
/// degrades to disabled+visible" business rule (disabled items must never
/// trigger a selection/navigation).
class MenuRow extends StatelessWidget {
  const MenuRow({
    super.key,
    required this.item,
    required this.isSelected,
    required this.theme,
    this.onTap,
  });

  /// The item this row renders.
  final MenuItem item;

  /// Whether this row is the currently-selected item. Purely presentational
  /// — the parent computes this by comparing `item.id` against its own
  /// notion of selection (e.g. `controller.selectedItemId`).
  final bool isSelected;

  /// Styling tokens for the row (colors, text styles, height).
  final MenuSlideThemeData theme;

  /// Invoked when an enabled row is tapped. Ignored entirely when
  /// `item.enabled == false`.
  final VoidCallback? onTap;

  static const double _iconSize = 22;
  static const double _disabledOpacity = 0.4;

  /// Upper bound on the badge chip's width so a very long/unbounded badge
  /// label (e.g. backend-driven data) can never push the row into a
  /// horizontal overflow. The chip's own [Text] ellipsizes within this
  /// bound (see [_MenuBadgeChip]).
  static const double _maxBadgeWidth = 96;

  @override
  Widget build(BuildContext context) {
    final iconColor = isSelected ? theme.selectedRowIconColor : theme.rowIconColor;
    final textStyle =
        isSelected ? theme.rowTextStyle.copyWith(color: theme.selectedRowIconColor) : theme.rowTextStyle;

    return Opacity(
      opacity: item.enabled ? 1.0 : _disabledOpacity,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: item.enabled ? onTap : null,
        child: Container(
          height: theme.rowHeight,
          color: isSelected ? theme.selectedRowColor : null,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              MenuIconView(icon: item.icon, color: iconColor, size: _iconSize),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: textStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
              if (item.badge != null)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxBadgeWidth),
                  child: _MenuBadgeChip(badge: item.badge!, theme: theme),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small colored chip rendering a [MenuBadge]'s label.
class _MenuBadgeChip extends StatelessWidget {
  const _MenuBadgeChip({required this.badge, required this.theme});

  final MenuBadge badge;
  final MenuSlideThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: badge.color ?? theme.badgeColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        badge.label,
        style: TextStyle(color: theme.badgeTextColor, fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
