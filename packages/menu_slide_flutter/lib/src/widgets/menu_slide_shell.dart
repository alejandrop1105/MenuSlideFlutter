import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../controller/menu_slide_controller.dart';
import '../models/menu_section.dart';
import '../theme/menu_slide_theme_data.dart';
import 'menu_button.dart';
import 'menu_row.dart';
import 'menu_slide_scope.dart';

/// Which side of the shell is currently driving the shared reveal
/// [_MenuSlideShellState._revealController]: the LEFT menu, the RIGHT panel,
/// or neither. The left/right panels and the host [MenuSlideShell.child]
/// each read this to decide which sign/position to render — see
/// [_MenuSlideShellState._onControllerChanged].
enum _RevealSide { none, left, right }

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
    this.rightPanel,
  });

  /// The host's page content, rendered alongside the menu panel.
  final Widget child;

  /// Optional arbitrary content rendered in a RIGHT-side panel, mirroring
  /// the left menu's 3D reveal (opposite tilt/translate direction). Driven
  /// by `controller.isRightOpen`/`openRight()`/`closeRight()`/
  /// `toggleRight()` — typically opened from anywhere in [child]'s subtree
  /// via `MenuSlideScope.of(context).openRight()`.
  ///
  /// Unlike the left panel, this is NOT prescribed to be a menu-items list —
  /// it renders whatever widget the host supplies (notifications, quick
  /// actions, a second navigation surface, anything). When `null` (the
  /// default), the right-panel feature is entirely inactive: no panel is
  /// built, and `isRightOpen` still exists on the controller (mutual
  /// exclusivity with the left menu still applies) but has no visual
  /// effect since there is nothing to reveal.
  final Widget? rightPanel;

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

class _MenuSlideShellState extends State<MenuSlideShell>
    with SingleTickerProviderStateMixin {
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

  /// Tracks the last `controller.isRightOpen` value this shell reacted to —
  /// the RIGHT-side counterpart of [_lastIsOpen], used the same way to
  /// detect an isRightOpen TRANSITION in [_onControllerChanged].
  late bool _lastIsRightOpen;

  /// Which side ([_RevealSide.left]/[_RevealSide.right]/[_RevealSide.none])
  /// is currently driving the shared [_revealController]. Because the left
  /// menu and the right panel are MUTUALLY EXCLUSIVE (enforced by
  /// [MenuSlideController]) but share ONE reveal animation, this flag is
  /// what lets [build] apply the correct sign/position to each side: it is
  /// set to the newly-opened side the instant a transition starts, and only
  /// reset to [_RevealSide.none] once the CLOSING animation fully reaches
  /// `0` (see [_onRevealStatusChanged]) — so a close-out animation keeps
  /// animating in its original direction instead of snapping to neutral.
  late _RevealSide _activeSide;

  @override
  void initState() {
    super.initState();
    _lastIsOpen = widget.controller.isOpen;
    _lastIsRightOpen = widget.controller.isRightOpen;
    _activeSide = _lastIsOpen
        ? _RevealSide.left
        : (_lastIsRightOpen ? _RevealSide.right : _RevealSide.none);
    widget.controller.addListener(_onControllerChanged);
    _revealController = AnimationController(
      duration: _revealDuration,
      upperBound: 1,
      vsync: this,
    );
    _revealController.addStatusListener(_onRevealStatusChanged);
    if (_lastIsOpen || _lastIsRightOpen) {
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
      final isRightOpen = widget.controller.isRightOpen;
      if (isOpen != _lastIsOpen || isRightOpen != _lastIsRightOpen) {
        _lastIsOpen = isOpen;
        _lastIsRightOpen = isRightOpen;
        _activeSide = isOpen
            ? _RevealSide.left
            : (isRightOpen ? _RevealSide.right : _RevealSide.none);
        _revealController.value = (isOpen || isRightOpen) ? 1 : 0;
      }
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _revealController.removeStatusListener(_onRevealStatusChanged);
    _revealController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    final isOpen = widget.controller.isOpen;
    final isRightOpen = widget.controller.isRightOpen;
    if (isOpen != _lastIsOpen || isRightOpen != _lastIsRightOpen) {
      _lastIsOpen = isOpen;
      _lastIsRightOpen = isRightOpen;
      if (isOpen || isRightOpen) {
        // Mutual exclusivity guarantees at most one of these is true.
        _activeSide = isOpen ? _RevealSide.left : _RevealSide.right;
        // The reveal `value` means "how open" (0..1); the SIGN (which side)
        // is applied separately via `_activeSide` above. So a side flip
        // must NEVER restart the value from 0 — that would snap the page
        // visually back to closed for a frame before re-animating. Two
        // cases where the value must stay untouched (skip `animateWith`
        // entirely):
        //  - `completed`: the reveal is ALREADY fully open (e.g. flipping
        //    directly from the left menu to the right panel or vice versa)
        //    — `_activeSide` above already flips which side the transforms
        //    treat as active, producing an instant "flip" of the host
        //    child to the opposite direction with nothing left to animate.
        //  - `forward`: the reveal is mid-flight opening the OTHER side
        //    (e.g. flipping left->right mid-open) — the sign flip above
        //    already mirrors the page instantly; restarting the spring
        //    from 0 here would discard the in-flight progress and snap
        //    through ~0.
        // Only when the controller is NOT already heading open (dismissed
        // or reverse) do we (re)start the forward spring — and it starts
        // FROM THE CURRENT VALUE, not 0, so a genuine open-from-closed
        // transition still springs continuously from wherever the value
        // currently sits (0 in the common case).
        if (_revealController.status != AnimationStatus.forward &&
            _revealController.status != AnimationStatus.completed) {
          _revealController.animateWith(SpringSimulation(
              _springDescription, _revealController.value, 1, 0));
        }
      } else {
        _revealController.reverse();
      }
    }
    setState(() {});
  }

  /// Resets [_activeSide] back to [_RevealSide.none] once the CLOSING
  /// animation actually reaches `0` — not the instant `close()`/
  /// `closeRight()` is called. This keeps the closing animation traveling in
  /// its original direction (the side that was open) all the way to rest,
  /// instead of snapping to a neutral sign mid-animation.
  void _onRevealStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.dismissed &&
        _activeSide != _RevealSide.none) {
      setState(() => _activeSide = _RevealSide.none);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = MenuSlideThemeData.resolve(context, widget.theme);
    final Animation<double> anim = _revealController.view;

    // The panel width is clamped to the available viewport width via
    // LayoutBuilder so the panel never renders wider than a narrow
    // viewport (e.g. a viewport narrower than the default 288
    // panelMaxWidth).
    //
    // The whole shell is wrapped in `MenuSlideScope` so ANY descendant of
    // `child` (or of the panels) can reach `widget.controller` via
    // `MenuSlideScope.of(context)` — e.g. to call `openRight()` from a
    // button buried deep in host page content, without the host having to
    // thread the controller through its own widget tree.
    return MenuSlideScope(
      controller: widget.controller,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final panelWidth =
              math.min(theme.panelMaxWidth, constraints.maxWidth);
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
                    // Gated by `_activeSide` — see the matching comment on the
                    // RIGHT panel layer below for why: both panels share the
                    // same `anim`, so without this gate opening the RIGHT
                    // panel would also reveal this one.
                    final leftAnim =
                        _activeSide == _RevealSide.left ? anim.value : 0.0;
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(((1 - leftAnim) * -30) * math.pi / 180)
                        ..translateByDouble(
                            (1 - leftAnim) * theme.restTranslateX, 0, 0, 1),
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
                        ? (panelWidth +
                                theme.revealWidthFactor! *
                                    (constraints.maxWidth - panelWidth))
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
                    // SIGNED direction: the LEFT menu pushes the page to the
                    // right (positive translate, positive rotateY — the
                    // original, unmirrored behavior); the RIGHT panel pushes
                    // it to the LEFT instead (both negated), producing the
                    // MIRRORED 3D reveal. Scale stays symmetric (unsigned) —
                    // shrinking is identical regardless of which side opened.
                    // When `_activeSide` is `none` (fully closed, `anim.value
                    // == 0`), the sign is irrelevant since it multiplies a
                    // zero offset/angle either way.
                    final sign = _activeSide == _RevealSide.right ? -1.0 : 1.0;
                    return Transform.scale(
                      key: const Key('menu-slide-reveal-scale'),
                      scale: 1 - anim.value * 0.1 * depth,
                      child: Transform.translate(
                        key: const Key('menu-slide-reveal-translate'),
                        offset: Offset(anim.value * reveal * sign, 0),
                        child: Transform(
                          key: const Key('menu-slide-reveal-rotate'),
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY(
                                (anim.value * theme.revealTiltDegrees * sign) *
                                    math.pi /
                                    180),
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: widget.child,
                ),
              ),
              // RIGHT panel layer: the mirror image of the PANEL layer above
              // — parked off-canvas to the RIGHT at rest, rotates/translates
              // in from there and fades in as `anim` goes 0 -> 1, using the
              // OPPOSITE rotateY sign and the OPPOSITE (positive) translate
              // magnitude so it enters from the right edge instead of the
              // left. Entirely opt-in: only built when `widget.rightPanel` is
              // supplied — when `null`, this whole subtree is omitted, same
              // pattern as `showMenuButton` below.
              if (widget.rightPanel != null)
                RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: anim,
                    builder: (context, child) {
                      // Gated by `_activeSide`: the LEFT and RIGHT panels
                      // share the SAME `anim` (one `_revealController` drives
                      // both, since only one side can ever be open — see
                      // `MenuSlideController`'s mutual-exclusivity doc
                      // comment). Without this gate, opening the LEFT menu
                      // would also drive this panel's transform to `anim.value
                      // == 1` and reveal it at the same time. When this side
                      // is not the active one, it stays fully parked
                      // regardless of `anim.value`.
                      final rightAnim =
                          _activeSide == _RevealSide.right ? anim.value : 0.0;
                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(((1 - rightAnim) * 30) * math.pi / 180)
                          ..translateByDouble(
                              (1 - rightAnim) * -theme.restTranslateX, 0, 0, 1),
                        child: child,
                      );
                    },
                    child: FadeTransition(
                      opacity: anim,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          width: panelWidth,
                          child: _RightPanel(
                              theme: theme, child: widget.rightPanel!),
                        ),
                      ),
                    ),
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
      ),
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

/// Renders the RIGHT panel's frame: a [theme.panelColor]-filled container,
/// [theme.panelPadding] applied around the content, a [SafeArea] (so content
/// clears system insets the same way the left panel's rows do), and a
/// [SingleChildScrollView] so [child] scrolls internally instead of
/// overflowing when it is taller than the panel. Private — assembled only by
/// [MenuSlideShell].
///
/// Unlike [_MenuPanel], this does NOT prescribe any structure for [child] —
/// it is arbitrary, entirely host-built content (see
/// [MenuSlideShell.rightPanel]'s doc comment).
class _RightPanel extends StatelessWidget {
  const _RightPanel({required this.theme, required this.child});

  final MenuSlideThemeData theme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('menu-slide-right-panel'),
      color: theme.panelColor,
      padding: theme.panelPadding,
      child: SafeArea(
        child: SingleChildScrollView(child: child),
      ),
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
