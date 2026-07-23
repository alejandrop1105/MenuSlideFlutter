import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../controller/menu_slide_controller.dart';
import '../models/menu_section.dart';
import '../theme/menu_slide_theme_data.dart';
import 'menu_row.dart';

/// The primary public widget of `menu_slide_flutter`: a shell that wraps a
/// host page ([child]) with a menu panel driven by a [MenuSlideController].
///
/// This slice (PR5b+PR6) assembles the FUNCTIONAL structure: it groups
/// `controller.items` by [sections] via `groupItemsBySection`, renders each
/// group as a section title (when the section has one) followed by its
/// [MenuRow]s, wires row taps to `controller.selectItem`, and reflects the
/// current selection. The panel is a fixed [headerBuilder] slot, then the
/// scrollable item list, then a fixed [footerBuilder] slot — both optional
/// and host-built (identity/branding/theme-toggle content, never
/// prescribed by this package; navigation stays host-owned). It
/// deliberately does NOT yet implement the diagonal 3D reveal animation —
/// `controller.isOpen` is not yet wired to a transform, see the seam
/// comment in [build]. That lands in PR7 (see `sdd/flutter-samples/tasks`).
class MenuSlideShell extends StatefulWidget {
  const MenuSlideShell({
    super.key,
    required this.child,
    required this.controller,
    this.sections = const [],
    this.theme,
    this.headerBuilder,
    this.footerBuilder,
  });

  /// The host's page content, rendered alongside the menu panel.
  final Widget child;

  /// Owns selection, open/close intent, and theme-mode command for this
  /// shell. The shell subscribes to it in [State.initState] and rebuilds on
  /// every notification.
  final MenuSlideController controller;

  /// Optional section metadata used to group `controller.items` — see
  /// `groupItemsBySection`. Items with no matching section render
  /// ungrouped, after every declared section, in declaration order.
  final List<MenuSection> sections;

  /// Per-instance theme override. When `null`, resolves via
  /// `MenuSlideThemeData.resolve` (a registered `ThemeData` extension, then
  /// `MenuSlideThemeData.fallback()`).
  final MenuSlideThemeData? theme;

  /// Optional builder rendered at the FIXED top of the panel, above the
  /// scrollable item list (e.g. a profile/identity card). When `null`, no
  /// header widget and no reserved placeholder space is rendered — the
  /// panel starts directly at the item list. The component does not
  /// prescribe the header's content; it is entirely host-built.
  final WidgetBuilder? headerBuilder;

  /// Optional builder rendered at the FIXED bottom of the panel, below the
  /// scrollable item list (e.g. a dark-mode toggle or version label). When
  /// `null`, no footer widget and no reserved placeholder space is
  /// rendered. The component does not prescribe the footer's content; it is
  /// entirely host-built.
  final WidgetBuilder? footerBuilder;

  @override
  State<MenuSlideShell> createState() => _MenuSlideShellState();
}

class _MenuSlideShellState extends State<MenuSlideShell> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant MenuSlideShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final theme = MenuSlideThemeData.resolve(context, widget.theme);

    // PR7 wires `widget.controller.isOpen` to the diagonal reveal
    // animation (AnimationController + Matrix4 transform, design #623
    // section 3) and replaces this plain Row with an animated Stack. This
    // slice keeps the panel and host child laid out side by side,
    // unanimated, so both remain independently hit-testable.
    //
    // The panel width is clamped to the available viewport width via
    // LayoutBuilder so this Row can never overflow on narrow viewports
    // (e.g. a viewport narrower than the default 288 panelMaxWidth). On an
    // ultra-narrow screen the clamp can leave the host `child` 0 width —
    // acceptable for this transitional, non-animated slice; PR7's Stack
    // overlay removes this side-by-side width contention entirely.
    return LayoutBuilder(
      builder: (context, constraints) {
        final panelWidth = math.min(theme.panelMaxWidth, constraints.maxWidth);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: panelWidth,
              child: _MenuPanel(
                controller: widget.controller,
                sections: widget.sections,
                theme: theme,
                headerBuilder: widget.headerBuilder,
                footerBuilder: widget.footerBuilder,
              ),
            ),
            Expanded(child: widget.child),
          ],
        );
      },
    );
  }
}

/// Renders the panel as a fixed [headerBuilder] slot, then `controller.items`
/// grouped by [sections] as a SCROLLABLE list of section titles and
/// [MenuRow]s, then a fixed [footerBuilder] slot. Private — assembled only
/// by [MenuSlideShell].
///
/// The header and footer are plain host-built `WidgetBuilder`s: this widget
/// does not prescribe their content (identity, branding, a theme toggle,
/// etc. are all host territory — see design decision #618/#623). When a
/// slot is `null`, nothing is rendered for it and no placeholder space is
/// reserved — only the item list (and an optional divider adjacent to a
/// present slot) occupies the panel.
class _MenuPanel extends StatelessWidget {
  const _MenuPanel({
    required this.controller,
    required this.sections,
    required this.theme,
    this.headerBuilder,
    this.footerBuilder,
  });

  final MenuSlideController controller;
  final List<MenuSection> sections;
  final MenuSlideThemeData theme;
  final WidgetBuilder? headerBuilder;
  final WidgetBuilder? footerBuilder;

  @override
  Widget build(BuildContext context) {
    final grouped = groupItemsBySection(controller.items, sections);

    final rows = <Widget>[];
    for (final entry in grouped.entries) {
      final section = entry.key;
      if (section != null) {
        rows.add(Padding(
          padding: EdgeInsets.symmetric(vertical: theme.itemSpacing / 2),
          child: Text(section.title, style: theme.sectionTitleStyle),
        ));
      }
      for (final item in entry.value) {
        rows.add(MenuRow(
          item: item,
          isSelected: controller.selectedItemId == item.id,
          theme: theme,
          onTap: () => controller.selectItem(item.id),
        ));
      }
    }

    return Container(
      key: const Key('menu-slide-panel'),
      color: theme.panelColor,
      padding: theme.panelPadding,
      // The header and footer slots are host-built and can be arbitrarily
      // tall (e.g. a multi-line profile card, or a large accessibility text
      // scale). LayoutBuilder caps each slot to a fraction of the available
      // panel height and wraps it in a SingleChildScrollView so that
      // oversized content scrolls INTERNALLY within its cap instead of
      // overflowing this Column. Small slots (the common case) render at
      // their natural size and never scroll, so normal-case layout is
      // unchanged. The middle item list always keeps the remaining space via
      // Expanded.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slotCap = constraints.hasBoundedHeight
              ? constraints.maxHeight * 0.45
              : double.infinity;

          Widget capSlot(Widget slot) {
            return ConstrainedBox(
              constraints: BoxConstraints(maxHeight: slotCap),
              child: SingleChildScrollView(child: slot),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (headerBuilder != null) capSlot(headerBuilder!(context)),
              if (headerBuilder != null)
                Divider(color: theme.dividerColor, height: 1, thickness: 1),
              Expanded(child: ListView(children: rows)),
              if (footerBuilder != null)
                Divider(color: theme.dividerColor, height: 1, thickness: 1),
              if (footerBuilder != null) capSlot(footerBuilder!(context)),
            ],
          );
        },
      ),
    );
  }
}
