// `ChangeNotifier.hasListeners` is @protected in production code, but it is
// a standard, supported way to assert subscription/unsubscription behavior
// from widget tests — hence the file-level ignore below.
// ignore_for_file: invalid_use_of_protected_member

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menu_slide_flutter/menu_slide_flutter.dart';

/// A minimal valid 1x1 transparent PNG, used to build a real [MemoryImage]
/// for backdrop-image tests without adding an asset/network dependency.
final Uint8List _tinyPngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  const home = MenuItem(id: 'home', label: 'Home', icon: MenuIconData(Icons.home));
  const inbox = MenuItem(id: 'inbox', label: 'Inbox', icon: MenuIconData(Icons.inbox));
  const settings = MenuItem(
    id: 'settings',
    label: 'Settings',
    icon: MenuIconData(Icons.settings),
    enabled: false,
  );

  group('MenuSlideShell', () {
    testWidgets('renders the host child', (tester) async {
      final controller = MenuSlideController();

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        child: const Text('Host Page', key: Key('host-page')),
      )));

      expect(find.byKey(const Key('host-page')), findsOneWidget);
      expect(find.text('Host Page'), findsOneWidget);
    });

    testWidgets('renders a MenuRow-backed row per controller item', (tester) async {
      final controller = MenuSlideController(items: const [home, inbox]);

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        child: const SizedBox.shrink(),
      )));

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Inbox'), findsOneWidget);
    });

    testWidgets('renders section titles for sections that have titles, ungrouped last',
        (tester) async {
      const sectionA = MenuSection(id: 'a', title: 'Section A');
      const sectionB = MenuSection(id: 'b', title: 'Section B');
      const itemA = MenuItem(
        id: 'a-item',
        label: 'A Item',
        icon: MenuIconData(Icons.star),
        sectionId: 'a',
      );
      const itemB = MenuItem(
        id: 'b-item',
        label: 'B Item',
        icon: MenuIconData(Icons.star_border),
        sectionId: 'b',
      );
      const ungrouped = MenuItem(id: 'top', label: 'Top Level', icon: MenuIconData(Icons.home));
      final controller = MenuSlideController(items: const [ungrouped, itemA, itemB]);

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        sections: const [sectionA, sectionB],
        child: const SizedBox.shrink(),
      )));

      expect(find.text('Section A'), findsOneWidget);
      expect(find.text('Section B'), findsOneWidget);
      expect(find.text('A Item'), findsOneWidget);
      expect(find.text('B Item'), findsOneWidget);
      expect(find.text('Top Level'), findsOneWidget);

      // Order: Section A header, its item, Section B header, its item, then
      // the ungrouped item last — matches groupItemsBySection's contract.
      final order = [
        'Section A',
        'A Item',
        'Section B',
        'B Item',
        'Top Level',
      ].map((label) => tester.getTopLeft(find.text(label)).dy).toList();
      for (var i = 1; i < order.length; i++) {
        expect(order[i], greaterThan(order[i - 1]));
      }
    });

    testWidgets('tapping an enabled row selects it via the controller', (tester) async {
      // PR7 made the panel a genuine off-canvas reveal — it is not
      // hit-testable at rest (matches real drawer UX; see
      // sdd/flutter-samples/apply-progress PR7 section). Open it first so
      // this row-tap assertion still exercises the real gesture path.
      final controller = MenuSlideController(items: const [home, inbox], isOpen: true);

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        child: const SizedBox.shrink(),
      )));

      expect(controller.selectedItemId, isNull);

      await tester.tap(find.text('Inbox'));
      await tester.pump();

      expect(controller.selectedItemId, 'inbox');
    });

    testWidgets('tapping a disabled row does not change the controller selection',
        (tester) async {
      // Open — see the comment on the duplicate-id test below (PR7
      // off-canvas reveal): otherwise this tap would miss for the wrong
      // reason instead of genuinely exercising the disabled-row no-op.
      final controller = MenuSlideController(items: const [home, settings], isOpen: true);

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        child: const SizedBox.shrink(),
      )));

      await tester.tap(find.text('Settings'));
      await tester.pump();

      expect(controller.selectedItemId, isNull);
    });

    testWidgets('tapping an enabled row closes the menu by default (closeOnSelect)',
        (tester) async {
      final controller = MenuSlideController(items: const [home, inbox], isOpen: true);

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        child: const SizedBox.shrink(),
      )));

      expect(controller.isOpen, isTrue);

      await tester.tap(find.text('Inbox'));
      await tester.pump();

      expect(controller.isOpen, isFalse);
      expect(controller.selectedItemId, 'inbox');
    });

    testWidgets(
        'tapping the already-selected row still closes the menu (no dead click)',
        (tester) async {
      // Regression test: MenuSlideController.selectItem is idempotent — a
      // no-op (no notification) when re-selecting the current id. Closing
      // on tap must NOT depend on that notification firing: tapping a row
      // that is ALREADY selected must still close the menu.
      final controller = MenuSlideController(items: const [home, inbox]);
      controller.selectItem('home');
      controller.open();

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        child: const SizedBox.shrink(),
      )));

      expect(controller.selectedItemId, 'home');
      expect(controller.isOpen, isTrue);

      await tester.tap(find.text('Home'));
      await tester.pump();

      expect(controller.isOpen, isFalse);
      expect(controller.selectedItemId, 'home');
    });

    testWidgets(
        'closeOnSelect false keeps the menu open on tap but still updates selection',
        (tester) async {
      final controller = MenuSlideController(items: const [home, inbox], isOpen: true);

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        closeOnSelect: false,
        child: const SizedBox.shrink(),
      )));

      await tester.tap(find.text('Inbox'));
      await tester.pump();

      expect(controller.isOpen, isTrue);
      expect(controller.selectedItemId, 'inbox');
    });

    testWidgets('reacts to controller changes after updateItems', (tester) async {
      final controller = MenuSlideController(items: const [home]);

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        child: const SizedBox.shrink(),
      )));

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Inbox'), findsNothing);

      controller.updateItems(const [inbox]);
      await tester.pump();

      expect(find.text('Home'), findsNothing);
      expect(find.text('Inbox'), findsOneWidget);
    });

    testWidgets('empty items and empty sections render without crashing', (tester) async {
      final controller = MenuSlideController();

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        child: const SizedBox.shrink(),
      )));

      expect(tester.takeException(), isNull);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('does not overflow when the viewport is narrower than panelMaxWidth',
        (tester) async {
      final controller = MenuSlideController(items: const [home, inbox]);

      // Default panelMaxWidth is 288 — a 200-wide viewport is narrower than
      // the fixed-width panel, which historically overflowed the Row.
      await tester.pumpWidget(wrap(
        SizedBox(
          width: 200,
          height: 600,
          child: MenuSlideShell(
            controller: controller,
            child: const SizedBox.shrink(),
          ),
        ),
      ));

      expect(tester.takeException(), isNull);
    });

    testWidgets('theme override applies a distinct panel color', (tester) async {
      final controller = MenuSlideController();
      final customTheme = MenuSlideThemeData.fallback().copyWith(panelColor: Colors.pink);

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        theme: customTheme,
        child: const SizedBox.shrink(),
      )));

      final panel = tester.widget<Container>(find.byKey(const Key('menu-slide-panel')));
      expect(panel.color, Colors.pink);
    });

    testWidgets('backdropColor renders a full-shell background layer behind panel and child',
        (tester) async {
      final controller = MenuSlideController();
      final customTheme =
          MenuSlideThemeData.fallback().copyWith(backdropColor: const Color(0xFF00FF00));

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        theme: customTheme,
        child: const SizedBox.shrink(),
      )));

      final backdrop =
          tester.widget<DecoratedBox>(find.byKey(const Key('menu-slide-backdrop')));
      final decoration = backdrop.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFF00FF00));
    });

    testWidgets('disposing after pumping does not throw and detaches the listener',
        (tester) async {
      final controller = MenuSlideController(items: const [home]);

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        child: const SizedBox.shrink(),
      )));

      expect(controller.hasListeners, isTrue);

      await tester.pumpWidget(const SizedBox.shrink());

      expect(tester.takeException(), isNull);
      // The disposed shell must have detached its listener — otherwise a
      // later notification would try to setState() on a defunct State.
      expect(controller.hasListeners, isFalse);

      // Driving a notification on the still-alive controller after the
      // shell is disposed must not throw "setState() called after
      // dispose()" — this only stays safe because the listener was
      // actually removed above, not merely because nothing happened to
      // fire.
      controller.selectItem('home');
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('swapping controller via didUpdateWidget re-subscribes listeners',
        (tester) async {
      final controllerA = MenuSlideController(items: const [home]);
      final controllerB = MenuSlideController(items: const [inbox]);

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controllerA,
        child: const SizedBox.shrink(),
      )));

      expect(controllerA.hasListeners, isTrue);

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controllerB,
        child: const SizedBox.shrink(),
      )));

      // Subscription must have moved from A to B. This is the discriminating
      // assertion: it fails if didUpdateWidget stops removing/adding
      // listeners correctly, even though build() still reads
      // controller.items directly and would otherwise mask the bug.
      expect(controllerA.hasListeners, isFalse);
      expect(controllerB.hasListeners, isTrue);

      // Old controller's notifications must no longer rebuild this shell.
      controllerA.selectItem('home');
      await tester.pump();
      expect(find.text('Home'), findsNothing);

      // New controller's notifications must be reflected — and, crucially,
      // a NOTIFICATION-only change (selection, not a new items list) must
      // reach the shell. Since build() always re-reads controller.items on
      // any rebuild, asserting on rendered items alone would pass even if
      // the shell weren't listening to B; asserting the selection highlight
      // only appears through an actual notifyListeners() subscription.
      controllerB.selectItem('inbox');
      await tester.pump();
      final inboxContainer = tester.widget<Container>(
        find.ancestor(of: find.text('Inbox'), matching: find.byType(Container)).first,
      );
      expect(inboxContainer.color, Colors.blue);
    });

    testWidgets('updateItems removing the selected item clears the selection highlight',
        (tester) async {
      final controller = MenuSlideController(items: const [home, inbox]);

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        child: const SizedBox.shrink(),
      )));

      controller.selectItem('home');
      await tester.pump();

      final selectedHomeContainer = tester.widget<Container>(
        find.ancestor(of: find.text('Home'), matching: find.byType(Container)).first,
      );
      expect(selectedHomeContainer.color, Colors.blue);

      // Remove the selected item ('home') via updateItems.
      controller.updateItems(const [inbox]);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(controller.selectedItemId, isNull);
      expect(find.text('Home'), findsNothing);

      final inboxContainerAfterUpdate = tester.widget<Container>(
        find.ancestor(of: find.text('Inbox'), matching: find.byType(Container)).first,
      );
      expect(inboxContainerAfterUpdate.color, isNot(Colors.blue));
    });

    testWidgets(
        'documents known behavior: duplicate ids hit the first (disabled) match '
        '— duplicate ids are a host-side contract violation', (tester) async {
      // MenuSlideController._findEnabled stops at the FIRST item whose id
      // matches. With a duplicate id where the first match is disabled, the
      // second (enabled) row's tap is a no-op — selection stays null. This
      // test documents that intentional, unchanged behavior rather than
      // asserting it is desirable; hosts MUST supply unique ids.
      const dupDisabled = MenuItem(
        id: 'dup',
        label: 'Dup Disabled',
        icon: MenuIconData(Icons.block),
        enabled: false,
      );
      const dupEnabled = MenuItem(
        id: 'dup',
        label: 'Dup Enabled',
        icon: MenuIconData(Icons.check),
      );
      // Open — otherwise the tap below would miss the off-canvas panel
      // entirely (PR7) and this test would pass for the wrong reason
      // instead of genuinely exercising the duplicate-id quirk.
      final controller =
          MenuSlideController(items: const [dupDisabled, dupEnabled], isOpen: true);

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        child: const SizedBox.shrink(),
      )));

      await tester.tap(find.text('Dup Enabled'));
      await tester.pump();

      expect(controller.selectedItemId, isNull);
    });
  });

  group('MenuSlideShell backdrop styling', () {
    testWidgets('backdropImage renders a non-null image on the backdrop DecoratedBox',
        (tester) async {
      final controller = MenuSlideController();
      final image = DecorationImage(image: MemoryImage(_tinyPngBytes));
      final customTheme = MenuSlideThemeData.fallback().copyWith(backdropImage: image);

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        theme: customTheme,
        child: const SizedBox.shrink(),
      )));

      final backdrop =
          tester.widget<DecoratedBox>(find.byKey(const Key('menu-slide-backdrop')));
      final decoration = backdrop.decoration as BoxDecoration;
      expect(decoration.image, isNotNull);
      expect(decoration.image, image);
    });

    testWidgets('backdropBlurSigma greater than 0 wraps the backdrop in an ImageFiltered',
        (tester) async {
      final controller = MenuSlideController();
      final customTheme = MenuSlideThemeData.fallback().copyWith(backdropBlurSigma: 8);

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        theme: customTheme,
        child: const SizedBox.shrink(),
      )));

      expect(find.byType(ImageFiltered), findsOneWidget);
    });

    testWidgets('backdropBlurSigma of 0 (the default) renders no ImageFiltered',
        (tester) async {
      final controller = MenuSlideController();

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        child: const SizedBox.shrink(),
      )));

      expect(find.byType(ImageFiltered), findsNothing);
    });

    testWidgets('backdropOpacity is applied to an Opacity widget wrapping the backdrop',
        (tester) async {
      final controller = MenuSlideController();
      final customTheme = MenuSlideThemeData.fallback().copyWith(backdropOpacity: 0.4);

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        theme: customTheme,
        child: const SizedBox.shrink(),
      )));

      final opacityWidget = tester.widget<Opacity>(
        find
            .ancestor(
              of: find.byKey(const Key('menu-slide-backdrop')),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(opacityWidget.opacity, 0.4);
    });

    testWidgets('the backdrop layer stays non-interactive (IgnorePointer) with image+blur',
        (tester) async {
      final controller = MenuSlideController();
      final customTheme = MenuSlideThemeData.fallback().copyWith(
        backdropImage: DecorationImage(image: MemoryImage(_tinyPngBytes)),
        backdropBlurSigma: 5,
      );

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        theme: customTheme,
        child: const SizedBox.shrink(),
      )));

      final ignorePointer = tester.widget<IgnorePointer>(
        find
            .ancestor(
              of: find.byKey(const Key('menu-slide-backdrop')),
              matching: find.byType(IgnorePointer),
            )
            .first,
      );
      expect(ignorePointer.ignoring, isTrue);
      expect(tester.takeException(), isNull);
    });
  });

  group('MenuSlideShell responsive reveal', () {
    // Default panelMaxWidth is 288, so the effective clamped panel width for
    // a 400/500-wide viewport (both wider than 288) is 288 unclamped.
    testWidgets(
        'revealWidthFactor 0.0 puts the child translate flush with the effective panel width',
        (tester) async {
      final controller = MenuSlideController(isOpen: true);
      final customTheme = MenuSlideThemeData.fallback().copyWith(revealWidthFactor: 0.0);

      await tester.pumpWidget(wrap(
        SizedBox(
          width: 400,
          height: 600,
          child: MenuSlideShell(
            controller: controller,
            theme: customTheme,
            child: const SizedBox.shrink(),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final translateWidget = tester
          .widget<Transform>(find.byKey(const Key('menu-slide-reveal-translate')));
      // At factor 0, the page sits flush with the menu's right edge (the
      // effective clamped panel width — min(panelMaxWidth, viewport)) —
      // NOT at 0, which would leave the page under the menu.
      expect(translateWidget.transform.getTranslation().x, closeTo(288, 0.01));
    });

    testWidgets('revealWidthFactor 1.0 puts the child translate at the full viewport width',
        (tester) async {
      final controller = MenuSlideController(isOpen: true);
      final customTheme = MenuSlideThemeData.fallback().copyWith(revealWidthFactor: 1.0);

      await tester.pumpWidget(wrap(
        SizedBox(
          width: 400,
          height: 600,
          child: MenuSlideShell(
            controller: controller,
            theme: customTheme,
            child: const SizedBox.shrink(),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final translateWidget = tester
          .widget<Transform>(find.byKey(const Key('menu-slide-reveal-translate')));
      expect(translateWidget.transform.getTranslation().x, closeTo(400, 0.01));
    });

    testWidgets(
        'revealWidthFactor between 0 and 1 interpolates between the panel width and the '
        'viewport width', (tester) async {
      final controller = MenuSlideController(isOpen: true);
      final customTheme = MenuSlideThemeData.fallback().copyWith(revealWidthFactor: 0.5);

      await tester.pumpWidget(wrap(
        SizedBox(
          width: 400,
          height: 600,
          child: MenuSlideShell(
            controller: controller,
            theme: customTheme,
            child: const SizedBox.shrink(),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final translateWidget = tester
          .widget<Transform>(find.byKey(const Key('menu-slide-reveal-translate')));
      // panelWidth(288) + 0.5 * (400 - 288) == 344.
      expect(translateWidget.transform.getTranslation().x, closeTo(344, 0.01));
    });

    testWidgets('the interpolation stays proportional across a different viewport width',
        (tester) async {
      final controller = MenuSlideController(isOpen: true);
      final customTheme = MenuSlideThemeData.fallback().copyWith(revealWidthFactor: 0.5);

      await tester.pumpWidget(wrap(
        SizedBox(
          width: 500,
          height: 600,
          child: MenuSlideShell(
            controller: controller,
            theme: customTheme,
            child: const SizedBox.shrink(),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final translateWidget = tester
          .widget<Transform>(find.byKey(const Key('menu-slide-reveal-translate')));
      // panelWidth(288) + 0.5 * (500 - 288) == 394.
      expect(translateWidget.transform.getTranslation().x, closeTo(394, 0.01));
    });

    testWidgets('revealWidthFactor null falls back to the fixed revealWidth pixel value',
        (tester) async {
      final controller = MenuSlideController(isOpen: true);
      // Default theme has revealWidthFactor: null, revealWidth: 265.
      final customTheme = MenuSlideThemeData.fallback();

      await tester.pumpWidget(wrap(
        SizedBox(
          width: 400,
          height: 600,
          child: MenuSlideShell(
            controller: controller,
            theme: customTheme,
            child: const SizedBox.shrink(),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final translateWidget = tester
          .widget<Transform>(find.byKey(const Key('menu-slide-reveal-translate')));
      expect(translateWidget.transform.getTranslation().x, closeTo(265, 0.01));
    });

    testWidgets(
        'revealWidthFactor 0.0 keeps the child flat & flush — no shrink, no rotation, at the '
        'panel edge', (tester) async {
      final controller = MenuSlideController(isOpen: true);
      final customTheme = MenuSlideThemeData.fallback().copyWith(revealWidthFactor: 0.0);

      await tester.pumpWidget(wrap(
        SizedBox(
          width: 400,
          height: 600,
          child: MenuSlideShell(
            controller: controller,
            theme: customTheme,
            child: const SizedBox.shrink(),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final scaleWidget =
          tester.widget<Transform>(find.byKey(const Key('menu-slide-reveal-scale')));
      // At factor 0, the depth effect (scale + rotation) is fully coupled to
      // the separation: zero separation means zero depth, so the page must
      // render at its natural scale (no shrink) — otherwise the
      // center-anchored scale would push the page's visible left edge past
      // the translate position, reopening the gap this fix closes.
      //
      // `Transform.scale` builds `Matrix4.diagonal3Values(scale, scale,
      // 1.0)`, so `entry(0, 0)` reads the exact x-axis scale factor we set —
      // unlike `getMaxScaleOnAxis()`, which is always dominated by the
      // unused z-axis entry (always `1.0`) whenever the intended scale is
      // below 1.0, making it unusable here.
      expect(scaleWidget.transform.entry(0, 0), closeTo(1.0, 0.001));

      final translateWidget = tester
          .widget<Transform>(find.byKey(const Key('menu-slide-reveal-translate')));
      expect(translateWidget.transform.getTranslation().x, closeTo(288, 0.01));
    });

    testWidgets('revealWidthFactor 1.0 keeps the full depth effect — scale ~0.9 at open',
        (tester) async {
      final controller = MenuSlideController(isOpen: true);
      final customTheme = MenuSlideThemeData.fallback().copyWith(revealWidthFactor: 1.0);

      await tester.pumpWidget(wrap(
        SizedBox(
          width: 400,
          height: 600,
          child: MenuSlideShell(
            controller: controller,
            theme: customTheme,
            child: const SizedBox.shrink(),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final scaleWidget =
          tester.widget<Transform>(find.byKey(const Key('menu-slide-reveal-scale')));
      expect(scaleWidget.transform.entry(0, 0), closeTo(0.9, 0.001));
    });

    testWidgets('revealWidthFactor 0.5 scales the depth effect proportionally — scale ~0.95',
        (tester) async {
      final controller = MenuSlideController(isOpen: true);
      final customTheme = MenuSlideThemeData.fallback().copyWith(revealWidthFactor: 0.5);

      await tester.pumpWidget(wrap(
        SizedBox(
          width: 400,
          height: 600,
          child: MenuSlideShell(
            controller: controller,
            theme: customTheme,
            child: const SizedBox.shrink(),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final scaleWidget =
          tester.widget<Transform>(find.byKey(const Key('menu-slide-reveal-scale')));
      // 1 - 0.1 * 0.5 == 0.95.
      expect(scaleWidget.transform.entry(0, 0), closeTo(0.95, 0.001));
    });

    testWidgets(
        'revealWidthFactor null falls back to the fixed revealWidth path and keeps the '
        'original depth effect unchanged (scale ~0.9 at open)', (tester) async {
      final controller = MenuSlideController(isOpen: true);
      // Default theme has revealWidthFactor: null.
      final customTheme = MenuSlideThemeData.fallback();

      await tester.pumpWidget(wrap(
        SizedBox(
          width: 400,
          height: 600,
          child: MenuSlideShell(
            controller: controller,
            theme: customTheme,
            child: const SizedBox.shrink(),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final scaleWidget =
          tester.widget<Transform>(find.byKey(const Key('menu-slide-reveal-scale')));
      expect(scaleWidget.transform.entry(0, 0), closeTo(0.9, 0.001));
    });
  });

  group('MenuSlideShell reveal tilt angle (revealTiltDegrees)', () {
    // `Matrix4.rotateY` builds a rotation matrix whose `entry(0, 0)` is
    // `cos(theta)` — since every angle under test here is within 0..90
    // degrees (where cosine is monotonic), `acos` recovers `theta`
    // unambiguously from that entry.
    double rotationDegrees(Matrix4 m) => math.acos(m.entry(0, 0)) * 180 / math.pi;

    testWidgets(
        'revealWidthFactor 0.0 with revealTiltDegrees 45: scale stays flush (1.0) but the '
        'tilt is still ~45deg — the angle is independent of the separation factor',
        (tester) async {
      final controller = MenuSlideController(isOpen: true);
      final customTheme = MenuSlideThemeData.fallback()
          .copyWith(revealWidthFactor: 0.0, revealTiltDegrees: 45);

      await tester.pumpWidget(wrap(
        SizedBox(
          width: 400,
          height: 600,
          child: MenuSlideShell(
            controller: controller,
            theme: customTheme,
            child: const SizedBox.shrink(),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final scaleWidget =
          tester.widget<Transform>(find.byKey(const Key('menu-slide-reveal-scale')));
      expect(scaleWidget.transform.entry(0, 0), closeTo(1.0, 0.001));

      final rotateWidget =
          tester.widget<Transform>(find.byKey(const Key('menu-slide-reveal-rotate')));
      expect(rotationDegrees(rotateWidget.transform), closeTo(45, 0.5));
    });

    testWidgets('revealTiltDegrees 0 renders a perfectly flat (identity) rotation at open',
        (tester) async {
      final controller = MenuSlideController(isOpen: true);
      final customTheme = MenuSlideThemeData.fallback().copyWith(revealTiltDegrees: 0);

      await tester.pumpWidget(wrap(
        SizedBox(
          width: 400,
          height: 600,
          child: MenuSlideShell(
            controller: controller,
            theme: customTheme,
            child: const SizedBox.shrink(),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final rotateWidget =
          tester.widget<Transform>(find.byKey(const Key('menu-slide-reveal-rotate')));
      expect(rotationDegrees(rotateWidget.transform), closeTo(0, 0.5));
    });

    testWidgets('a larger revealTiltDegrees yields a proportionally larger open angle',
        (tester) async {
      final controllerSmall = MenuSlideController(isOpen: true);
      final smallTiltTheme = MenuSlideThemeData.fallback().copyWith(revealTiltDegrees: 20);

      await tester.pumpWidget(wrap(
        SizedBox(
          width: 400,
          height: 600,
          child: MenuSlideShell(
            controller: controllerSmall,
            theme: smallTiltTheme,
            child: const SizedBox.shrink(),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final smallAngle = rotationDegrees(tester
          .widget<Transform>(find.byKey(const Key('menu-slide-reveal-rotate')))
          .transform);

      final controllerLarge = MenuSlideController(isOpen: true);
      final largeTiltTheme = MenuSlideThemeData.fallback().copyWith(revealTiltDegrees: 60);

      await tester.pumpWidget(wrap(
        SizedBox(
          width: 400,
          height: 600,
          child: MenuSlideShell(
            controller: controllerLarge,
            theme: largeTiltTheme,
            child: const SizedBox.shrink(),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final largeAngle = rotationDegrees(tester
          .widget<Transform>(find.byKey(const Key('menu-slide-reveal-rotate')))
          .transform);

      expect(smallAngle, closeTo(20, 0.5));
      expect(largeAngle, closeTo(60, 0.5));
      expect(largeAngle, greaterThan(smallAngle));
    });

    testWidgets(
        'the fixed-px fallback path (revealWidthFactor null) still renders the original '
        '30deg tilt at open, unchanged', (tester) async {
      final controller = MenuSlideController(isOpen: true);
      // Default theme: revealWidthFactor null, revealTiltDegrees 30 (fallback default).
      final customTheme = MenuSlideThemeData.fallback();

      await tester.pumpWidget(wrap(
        SizedBox(
          width: 400,
          height: 600,
          child: MenuSlideShell(
            controller: controller,
            theme: customTheme,
            child: const SizedBox.shrink(),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final rotateWidget =
          tester.widget<Transform>(find.byKey(const Key('menu-slide-reveal-rotate')));
      expect(rotationDegrees(rotateWidget.transform), closeTo(30, 0.5));
    });
  });

  group('MenuSlideShell header/footer slots', () {
    testWidgets('headerBuilder renders above the first row', (tester) async {
      final controller = MenuSlideController(items: const [home, inbox]);

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        headerBuilder: (context) => const Text('Header', key: Key('menu-header')),
        child: const SizedBox.shrink(),
      )));

      expect(find.byKey(const Key('menu-header')), findsOneWidget);
      final headerY = tester.getTopLeft(find.byKey(const Key('menu-header'))).dy;
      final firstRowY = tester.getTopLeft(find.text('Home')).dy;
      expect(headerY, lessThan(firstRowY));
    });

    testWidgets('headerBuilder null renders no header and no error', (tester) async {
      final controller = MenuSlideController(items: const [home]);

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        child: const SizedBox.shrink(),
      )));

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('menu-header')), findsNothing);
    });

    testWidgets('footerBuilder renders below the last row', (tester) async {
      final controller = MenuSlideController(items: const [home, inbox]);

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        footerBuilder: (context) => const Text('Footer', key: Key('menu-footer')),
        child: const SizedBox.shrink(),
      )));

      expect(find.byKey(const Key('menu-footer')), findsOneWidget);
      final footerY = tester.getTopLeft(find.byKey(const Key('menu-footer'))).dy;
      final lastRowY = tester.getTopLeft(find.text('Inbox')).dy;
      expect(footerY, greaterThan(lastRowY));
    });

    testWidgets('footerBuilder null renders no footer and no error', (tester) async {
      final controller = MenuSlideController(items: const [home]);

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        child: const SizedBox.shrink(),
      )));

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('menu-footer')), findsNothing);
    });

    testWidgets('header and footer stay present while the item list scrolls', (tester) async {
      final items = List.generate(
        30,
        (i) => MenuItem(id: 'item-$i', label: 'Item $i', icon: const MenuIconData(Icons.star)),
      );
      final controller = MenuSlideController(items: items);

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        headerBuilder: (context) => const Text('Header', key: Key('menu-header')),
        footerBuilder: (context) => const Text('Footer', key: Key('menu-footer')),
        child: const SizedBox.shrink(),
      )));

      expect(find.byKey(const Key('menu-header')), findsOneWidget);
      expect(find.byKey(const Key('menu-footer')), findsOneWidget);
      // 30 rows at the default rowHeight (56) far exceed the default test
      // viewport height — the last row starts off-screen because the
      // MIDDLE list is the scrollable region, while header/footer are fixed.
      expect(find.text('Item 29'), findsNothing);
    });

    testWidgets('tapping an enabled row still selects it with header/footer present',
        (tester) async {
      // Open — see the comment on the equivalent test above (PR7 off-canvas
      // reveal).
      final controller = MenuSlideController(items: const [home, inbox], isOpen: true);

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        headerBuilder: (context) => const Text('Header'),
        footerBuilder: (context) => const Text('Footer'),
        child: const SizedBox.shrink(),
      )));

      expect(controller.selectedItemId, isNull);

      await tester.tap(find.text('Inbox'));
      await tester.pump();

      expect(controller.selectedItemId, 'inbox');
    });

    testWidgets('headerBuilder receives a usable BuildContext', (tester) async {
      final controller = MenuSlideController(items: const [home]);

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        headerBuilder: (context) {
          // Must not throw — proves the context can resolve inherited
          // widgets (Theme, MediaQuery) the same way any other descendant
          // of the shell's subtree can.
          final theme = Theme.of(context);
          final mediaQuery = MediaQuery.of(context);
          return Text(
            '${theme.runtimeType}-${mediaQuery.size.width}',
            key: const Key('menu-header'),
          );
        },
        child: const SizedBox.shrink(),
      )));

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('menu-header')), findsOneWidget);
    });

    testWidgets('a tall headerBuilder in a short panel never overflows', (tester) async {
      final controller = MenuSlideController(items: const [home, inbox]);

      // A 5000px-tall header inside a panel constrained to ~200px must be
      // capped/scrolled internally rather than overflowing the panel Column.
      await tester.pumpWidget(wrap(
        SizedBox(
          height: 200,
          child: MenuSlideShell(
            controller: controller,
            headerBuilder: (context) => Container(height: 5000, color: Colors.red),
            child: const SizedBox.shrink(),
          ),
        ),
      ));

      expect(tester.takeException(), isNull);
    });

    testWidgets('tall header and footer together in a short panel never overflow',
        (tester) async {
      final controller = MenuSlideController(items: const [home, inbox]);

      await tester.pumpWidget(wrap(
        SizedBox(
          height: 300,
          child: MenuSlideShell(
            controller: controller,
            headerBuilder: (context) => Container(height: 250, color: Colors.red),
            footerBuilder: (context) => Container(height: 250, color: Colors.blue),
            child: const SizedBox.shrink(),
          ),
        ),
      ));

      expect(tester.takeException(), isNull);
    });

    testWidgets('large text scale header/footer in a short panel never overflow',
        (tester) async {
      final controller = MenuSlideController(items: const [home, inbox]);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(4.0)),
            child: Scaffold(
              body: SizedBox(
                height: 200,
                child: MenuSlideShell(
                  controller: controller,
                  headerBuilder: (context) => const Text('Header', style: TextStyle(fontSize: 40)),
                  footerBuilder: (context) => const Text('Footer', style: TextStyle(fontSize: 40)),
                  child: const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'normal case unchanged: small header stays above first row in a tall panel',
        (tester) async {
      final controller = MenuSlideController(items: const [home, inbox]);

      await tester.pumpWidget(wrap(
        SizedBox(
          height: 600,
          child: MenuSlideShell(
            controller: controller,
            headerBuilder: (context) => const SizedBox(
              height: 60,
              child: Text('Header', key: Key('menu-header')),
            ),
            child: const SizedBox.shrink(),
          ),
        ),
      ));

      expect(tester.takeException(), isNull);
      final headerY = tester.getTopLeft(find.byKey(const Key('menu-header'))).dy;
      final firstRowY = tester.getTopLeft(find.text('Home')).dy;
      expect(headerY, lessThan(firstRowY));
    });
  });
}
