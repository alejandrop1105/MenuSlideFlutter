import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../controller/menu_slide_controller.dart';
import '../models/menu_section.dart';
import '../theme/menu_slide_theme_data.dart';
import 'menu_row.dart';

/// The primary public widget of `menu_slide_flutter`: a shell that wraps a
/// host page ([child]) with a menu panel driven by a [MenuSlideController].
///
/// This slice (PR5b) assembles the FUNCTIONAL structure only: it groups
/// `controller.items` by [sections] via `groupItemsBySection`, renders each
/// group as a section title (when the section has one) followed by its
/// [MenuRow]s, wires row taps to `controller.selectItem`, and reflects the
/// current selection. It deliberately does NOT implement the diagonal 3D
/// reveal animation — `controller.isOpen` is not yet wired to a transform,
/// see the seam comment in [build] — or the `headerBuilder`/`footerBuilder`
/// slots. Those land in PR7 and PR6 respectively (see
/// `sdd/flutter-samples/tasks`).
class MenuSlideShell extends StatefulWidget {
  const MenuSlideShell({
    super.key,
    required this.child,
    required this.controller,
    this.sections = const [],
    this.theme,
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
              ),
            ),
            Expanded(child: widget.child),
          ],
        );
      },
    );
  }
}

/// Renders `controller.items` grouped by [sections] as a scrollable list of
/// section titles and [MenuRow]s. Private — assembled only by
/// [MenuSlideShell].
class _MenuPanel extends StatelessWidget {
  const _MenuPanel({
    required this.controller,
    required this.sections,
    required this.theme,
  });

  final MenuSlideController controller;
  final List<MenuSection> sections;
  final MenuSlideThemeData theme;

  @override
  Widget build(BuildContext context) {
    final grouped = groupItemsBySection(controller.items, sections);

    final children = <Widget>[];
    for (final entry in grouped.entries) {
      final section = entry.key;
      if (section != null) {
        children.add(Padding(
          padding: EdgeInsets.symmetric(vertical: theme.itemSpacing / 2),
          child: Text(section.title, style: theme.sectionTitleStyle),
        ));
      }
      for (final item in entry.value) {
        children.add(MenuRow(
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
      child: ListView(children: children),
    );
  }
}
