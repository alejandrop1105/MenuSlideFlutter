import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../controller/menu_slide_controller.dart';
import '../models/menu_section.dart';
import '../theme/menu_slide_theme_data.dart';
import 'menu_button.dart';
import 'menu_row.dart';

/// The primary public widget of `menu_slide_flutter`: a shell that wraps a
/// host page ([child]) with a menu panel driven by a [MenuSlideController].
///
/// This slice (PR5b+PR6+PR7) assembles the FULL structure: it groups
/// `controller.items` by [sections] via `groupItemsBySection`, renders each
/// group as a section title (when the section has one) followed by its
/// [MenuRow]s, wires row taps to `controller.selectItem`, and reflects the
/// current selection. The panel is a fixed [headerBuilder] slot, then the
/// scrollable item list, then a fixed [footerBuilder] slot — both optional
/// and host-built (identity/branding/theme-toggle content, never
/// prescribed by this package; navigation stays host-owned). It also owns
/// the DIAGONAL 3D REVEAL: `_MenuSlideShellState` drives an
/// `AnimationController` from `controller.isOpen`'s intent (see
/// [_onControllerChanged]) and applies the reveal transform ported
/// verbatim from the original sample (`home.dart`) to both the panel and
/// [child]. [showMenuButton] controls the shell's built-in floating
/// toggle button.
class MenuSlideShell extends StatefulWidget {
  const MenuSlideShell({
    super.key,
    required this.child,
    required this.controller,
    this.sections = const [],
    this.theme,
    this.headerBuilder,
    this.footerBuilder,
    this.showMenuButton = true,
    this.closeOnSelect = true,
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

  /// Whether the shell renders its own built-in floating toggle button (an
  /// [AnimatedIcon] morphing between hamburger/close, wired to
  /// `controller.toggle()`). Defaults to `true`. Set to `false` when the
  /// host wants to drive `controller.open()`/`close()`/`toggle()` from its
  /// own UI instead (e.g. an AppBar leading icon) — the reveal animation
  /// itself is unaffected either way.
  final bool showMenuButton;

  /// Whether tapping an enabled menu row closes the menu, in addition to
  /// selecting it. Defaults to `true`.
  ///
  /// This fires on every enabled-row tap, regardless of whether the tapped
  /// item was already the current selection — `MenuSlideController.
  /// selectItem` is idempotent (no notification when re-selecting the same
  /// id), so a host that only closed the menu in reaction to a selection
  /// CHANGE would leave the menu open when the user re-taps the already-
  /// selected row (a "dead click"). Closing on tap is component (shell)
  /// behavior; navigation in response to a selection stays entirely
  /// host-owned. Set to `false` to opt out and drive `controller.close()`
  /// from the host instead.
  final bool closeOnSelect;

  @override
  State<MenuSlideShell> createState() => _MenuSlideShellState();
}

class _MenuSlideShellState extends State<MenuSlideShell> with SingleTickerProviderStateMixin {
  /// Spring physics driving the OPEN transition — ported verbatim from the
  /// original sample (`home.dart`'s `springDesc`) to preserve the exact
  /// feel. The CLOSE transition uses a plain [AnimationController.reverse]
  /// (also matching the original).
  static const SpringDescription _springDescription = SpringDescription(
    mass: 0.1,
    stiffness: 40,
    damping: 5,
  );

  static const Duration _revealDuration = Duration(milliseconds: 200);

  /// Owns the vsync/ticker for the reveal — `MenuSlideController.isOpen` is
  /// an INTENT only (see its doc comment); this shell is the sole owner of
  /// the actual animation driving the diagonal reveal transform.
  late final AnimationController _revealController;

  /// Tracks the last `controller.isOpen` value this shell reacted to, so
  /// [_onControllerChanged] can tell an isOpen TRANSITION (drive the
  /// animation) apart from any other notification (selection/items change
  /// — rebuild only).
  late bool _lastIsOpen;

  @override
  void initState() {
    super.initState();
    _lastIsOpen = widget.controller.isOpen;
    widget.controller.addListener(_onControllerChanged);
    _revealController = AnimationController(
      duration: _revealDuration,
      upperBound: 1,
      vsync: this,
    );
    if (_lastIsOpen) {
      _revealController.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant MenuSlideShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
      // A controller swap is not an animated transition — snap the reveal
      // to match the new controller's current intent instantly.
      final isOpen = widget.controller.isOpen;
      if (isOpen != _lastIsOpen) {
        _lastIsOpen = isOpen;
        _revealController.value = isOpen ? 1 : 0;
      }
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _revealController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    final isOpen = widget.controller.isOpen;
    if (isOpen != _lastIsOpen) {
      _lastIsOpen = isOpen;
      if (isOpen) {
        _revealController.animateWith(SpringSimulation(_springDescription, 0, 1, 0));
      } else {
        _revealController.reverse();
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = MenuSlideThemeData.resolve(context, widget.theme);
    final Animation<double> anim = _revealController.view;

    // The panel width is clamped to the available viewport width via
    // LayoutBuilder so the panel never renders wider than a narrow
    // viewport (e.g. a viewport narrower than the default 288
    // panelMaxWidth).
    return LayoutBuilder(
      builder: (context, constraints) {
        final panelWidth = math.min(theme.panelMaxWidth, constraints.maxWidth);
        return Stack(
          fit: StackFit.expand,
          children: [
            // BACKDROP layer: a non-interactive fill occupying the shell's
            // full bounds, painted BEHIND the panel and the transformed
            // child. `IgnorePointer` keeps it out of the hit-test tree
            // regardless of what's painted on it (color, image, blur), so
            // it never intercepts taps meant for the panel or child layers
            // above it.
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: theme.backdropOpacity,
                  child: _maybeBlur(
                    theme.backdropBlurSigma,
                    DecoratedBox(
                      key: const Key('menu-slide-backdrop'),
                      decoration: BoxDecoration(
                        color: theme.backdropColor,
                        image: theme.backdropImage,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // PANEL layer: rotates/translates in from off-canvas-left and
            // fades in as `anim` goes 0 -> 1. Transform math ported
            // verbatim from `home.dart`'s sidebar `AnimatedBuilder`.
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: anim,
                builder: (context, child) {
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(((1 - anim.value) * -30) * math.pi / 180)
                      ..translateByDouble((1 - anim.value) * theme.restTranslateX, 0, 0, 1),
                    child: child,
                  );
                },
                child: FadeTransition(
                  opacity: anim,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: panelWidth,
                      child: _MenuPanel(
                        controller: widget.controller,
                        sections: widget.sections,
                        theme: theme,
                        headerBuilder: widget.headerBuilder,
                        footerBuilder: widget.footerBuilder,
                        closeOnSelect: widget.closeOnSelect,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // HOST CHILD layer: shrinks, slides right by the effective
            // reveal width, and rotates as `anim` goes 0 -> 1 — ported
            // verbatim from `home.dart`'s page-body `AnimatedBuilder`. The
            // reveal width is either the fixed `theme.revealWidth` pixel
            // value, or — when `theme.revealWidthFactor` is set — a
            // PERCENTAGE of the viewport's available width, computed from
            // this LayoutBuilder's `constraints`, making the menu/page
            // separation responsive across viewport sizes.
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: anim,
                builder: (context, child) {
                  // When `revealWidthFactor` is set, the factor is the
                  // ADDITIONAL separation beyond the panel's own width, as a
                  // fraction of the remaining viewport width — NOT a
                  // fraction of the full viewport. At factor 0, the page
                  // sits flush with the panel's right edge (`panelWidth`,
                  // the same effective clamped width used for the panel
                  // itself above); at factor 1, the page is pushed all the
                  // way to `constraints.maxWidth`. This keeps the menu
                  // fully revealed (zero gap) at the 0% default instead of
                  // the page covering the menu at x=0.
                  final reveal = theme.revealWidthFactor != null
                      ? (panelWidth + theme.revealWidthFactor! * (constraints.maxWidth - panelWidth))
                          .clamp(0.0, constraints.maxWidth)
                      : theme.revealWidth;
                  // The center-anchored SCALE is coupled to
                  // `revealWidthFactor` so the page is flat & flush against
                  // the menu at 0% separation: a center-anchored scale
                  // shrinks a widget from its own center, which pushes the
                  // visible left edge to the RIGHT of the translate offset —
                  // at factor 0 that would reopen a gap between the menu and
                  // the page even though `reveal == panelWidth`. Scaling the
                  // depth by the same factor makes depth 0 at 0% (flat,
                  // flush) and the full depth effect at 100% separation.
                  // When `revealWidthFactor` is null (the fixed-px
                  // `revealWidth` fallback path), `depth` is 1.0, preserving
                  // the original constants unchanged.
                  //
                  // The rotateY TILT is intentionally NOT multiplied by
                  // `depth`/`revealWidthFactor` — `theme.revealTiltDegrees`
                  // is an independent, host-configurable opening angle, so
                  // the 3D effect stays visible (and exaggeratable) even at
                  // 0% separation, where `depth` (and therefore the scale)
                  // is 0.
                  final depth = theme.revealWidthFactor ?? 1.0;
                  return Transform.scale(
                    key: const Key('menu-slide-reveal-scale'),
                    scale: 1 - anim.value * 0.1 * depth,
                    child: Transform.translate(
                      key: const Key('menu-slide-reveal-translate'),
                      offset: Offset(anim.value * reveal, 0),
                      child: Transform(
                        key: const Key('menu-slide-reveal-rotate'),
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY((anim.value * theme.revealTiltDegrees) * math.pi / 180),
                        child: child,
                      ),
                    ),
                  );
                },
                child: widget.child,
              ),
            ),
            // Built-in floating toggle button, opt-out via
            // `showMenuButton: false`. Shifts right by `menuButtonShift` as
            // `anim` goes 0 -> 1, mirroring `home.dart`'s
            // `SizedBox(width: anim * 216)` row trick — implemented here
            // via `Positioned.left` instead, which sidesteps the
            // Transform-based-touch-area quirk that trick worked around.
            if (widget.showMenuButton)
              AnimatedBuilder(
                animation: anim,
                builder: (context, child) {
                  return Positioned(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: MediaQuery.of(context).padding.left +
                        16 +
                        anim.value * theme.menuButtonShift,
                    child: child!,
                  );
                },
                child: MenuSlideButton(
                  progress: anim,
                  onTap: widget.controller.toggle,
                  backgroundColor: theme.menuButtonColor,
                  iconColor: theme.menuButtonIconColor,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Wraps [child] in an [ImageFiltered] gaussian blur when [sigma] is
/// positive; returns [child] unchanged when `sigma <= 0` so the shell never
/// pays for a blur filter layer it does not need.
Widget _maybeBlur(double sigma, Widget child) {
  if (sigma <= 0) return child;
  return ImageFiltered(
    imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
    child: child,
  );
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
    required this.closeOnSelect,
  });

  final MenuSlideController controller;
  final List<MenuSection> sections;
  final MenuSlideThemeData theme;
  final WidgetBuilder? headerBuilder;
  final WidgetBuilder? footerBuilder;
  final bool closeOnSelect;

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
          onTap: () {
            // Select first, then close (if enabled) — order matters so a
            // host listener reacting to the selection notification always
            // observes the new selection before/alongside the close
            // notification. `selectItem` is idempotent (no notification
            // when re-selecting the current id), so closing must NOT be
            // gated on that notification firing — see `closeOnSelect`'s
            // doc comment for the "dead click" scenario this avoids. Both
            // calls happen synchronously from this tap callback, outside
            // any controller notify cycle, so no reentrancy guard is
            // needed here.
            controller.selectItem(item.id);
            if (closeOnSelect) {
              controller.close();
            }
          },
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
