// PR7: diagonal 3D reveal animation + built-in AnimatedIcon menu button.
//
// These tests exercise the NEW behavior introduced in this slice:
// `controller.isOpen` now drives a real `AnimationController` (owned by
// `_MenuSlideShellState`) that animates the host `child` and the panel via
// the diagonal reveal transform ported from `home.dart`, and the shell
// renders a built-in floating toggle button.
//
// Animation-testing technique: the OPEN transition uses a `SpringSimulation`
// (mass: 0.1, stiffness: 40, damping: 5) rather than a fixed-duration curve.
// In practice `tester.pumpAndSettle()` reliably settles this spring (it
// decays quickly under these constants) so it is used directly for
// open/close assertions below. The one exception is the "mid-animation does
// not throw" test, which deliberately uses a single fixed `tester.pump`
// step instead of `pumpAndSettle` so it can assert during an IN-FLIGHT
// animation frame.
//
// `ChangeNotifier.hasListeners` is @protected in production code, but it is
// a standard, supported way to assert subscription/unsubscription behavior
// from widget tests — hence the file-level ignore below.
// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menu_slide_flutter/menu_slide_flutter.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  Widget hostChild() => const Align(
        alignment: Alignment.topLeft,
        child: SizedBox(key: Key('host-child'), width: 10, height: 10),
      );

  group('MenuSlideShell diagonal reveal', () {
    testWidgets(
        'closed state: host child sits at its rest position and the menu button is present',
        (tester) async {
      final controller = MenuSlideController();

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        child: hostChild(),
      )));

      final dx = tester.getTopLeft(find.byKey(const Key('host-child'))).dx;
      expect(dx, closeTo(0, 1));
      expect(find.byKey(const Key('menu-slide-button')), findsOneWidget);
      expect(find.byType(AnimatedIcon), findsOneWidget);
    });

    testWidgets('opening: the host child shifts right and the panel reveals from rest',
        (tester) async {
      final controller = MenuSlideController();

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        child: hostChild(),
      )));

      final closedPanelDx = tester.getTopLeft(find.byKey(const Key('menu-slide-panel'))).dx;
      // At rest the panel is translated fully off-canvas to the left.
      expect(closedPanelDx, lessThan(-50));

      controller.open();
      await tester.pumpAndSettle();

      final openDx = tester.getTopLeft(find.byKey(const Key('host-child'))).dx;
      expect(openDx, greaterThan(100));

      final openPanelDx = tester.getTopLeft(find.byKey(const Key('menu-slide-panel'))).dx;
      expect(openPanelDx, greaterThan(closedPanelDx));
    });

    testWidgets('closing: the host child returns to its rest position', (tester) async {
      final controller = MenuSlideController();

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        child: hostChild(),
      )));

      controller.open();
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byKey(const Key('host-child'))).dx, greaterThan(100));

      controller.close();
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byKey(const Key('host-child'))).dx, closeTo(0, 1));
    });

    testWidgets('tapping the menu button toggles the controller open state', (tester) async {
      final controller = MenuSlideController();

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        child: const SizedBox.shrink(),
      )));

      expect(controller.isOpen, isFalse);

      await tester.tap(find.byKey(const Key('menu-slide-button')));
      await tester.pump();
      expect(controller.isOpen, isTrue);

      await tester.tap(find.byKey(const Key('menu-slide-button')));
      await tester.pump();
      expect(controller.isOpen, isFalse);

      // Settle so no pending spring-driven frames leak into the next test.
      await tester.pumpAndSettle();
    });

    testWidgets('a partial pump mid-animation does not throw', (tester) async {
      final controller = MenuSlideController();

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        child: const SizedBox.shrink(),
      )));

      controller.open();
      // Deliberately a single fixed-duration pump (NOT pumpAndSettle) so
      // this asserts mid-flight, before the spring has settled.
      await tester.pump(const Duration(milliseconds: 40));

      expect(tester.takeException(), isNull);

      await tester.pumpAndSettle();
    });

    testWidgets('disposing the shell mid-animation does not throw', (tester) async {
      final controller = MenuSlideController();

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        child: const SizedBox.shrink(),
      )));

      controller.open();
      await tester.pump(const Duration(milliseconds: 20));

      // Replace the tree entirely — the shell's State (and its
      // AnimationController + controller listener) must dispose cleanly.
      await tester.pumpWidget(const SizedBox.shrink());

      expect(tester.takeException(), isNull);
    });

    testWidgets('showMenuButton: false hides the built-in button but the reveal still animates',
        (tester) async {
      final controller = MenuSlideController();

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        showMenuButton: false,
        child: hostChild(),
      )));

      expect(find.byKey(const Key('menu-slide-button')), findsNothing);
      expect(find.byType(AnimatedIcon), findsNothing);

      controller.open();
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(find.byKey(const Key('host-child'))).dx, greaterThan(100));
    });

    testWidgets('menu button position accounts for a left safe-area inset', (tester) async {
      final controller = MenuSlideController();

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(padding: EdgeInsets.only(left: 40)),
            child: Scaffold(
              body: MenuSlideShell(
                controller: controller,
                child: hostChild(),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final positioned = tester.widget<Positioned>(
        find
            .ancestor(
              of: find.byKey(const Key('menu-slide-button')),
              matching: find.byType(Positioned),
            )
            .first,
      );
      expect(positioned.left, closeTo(40 + 16, 0.01));
    });

    testWidgets(
        'existing behavior preserved: rows render, tap selects when open, header/footer '
        'slots still work', (tester) async {
      const home = MenuItem(id: 'home', label: 'Home', icon: MenuIconData(Icons.home));
      const inbox = MenuItem(id: 'inbox', label: 'Inbox', icon: MenuIconData(Icons.inbox));
      // The panel is only reachable once opened now that it genuinely
      // reveals/hides off-canvas — this mirrors a real drawer's UX.
      final controller = MenuSlideController(items: const [home, inbox], isOpen: true);

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        headerBuilder: (context) => const Text('Header', key: Key('menu-header')),
        footerBuilder: (context) => const Text('Footer', key: Key('menu-footer')),
        child: const SizedBox.shrink(),
      )));

      expect(find.byKey(const Key('menu-header')), findsOneWidget);
      expect(find.byKey(const Key('menu-footer')), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Inbox'), findsOneWidget);

      await tester.tap(find.text('Inbox'));
      await tester.pump();

      expect(controller.selectedItemId, 'inbox');
    });

    testWidgets(
        'controller starts already open: the host child is at the open position on the '
        'very first pump, with no animation from closed', (tester) async {
      final controller = MenuSlideController(isOpen: true);

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        child: hostChild(),
      )));

      // No extra pump beyond the one pumpWidget performs: initState must
      // have synced `_revealController.value = 1` synchronously, so the
      // very first frame already renders fully open.
      final dx = tester.getTopLeft(find.byKey(const Key('host-child'))).dx;
      expect(dx, greaterThan(100));
    });

    testWidgets(
        'rapid open->close->open before settling does not throw and ends fully open',
        (tester) async {
      final controller = MenuSlideController();

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        child: hostChild(),
      )));

      controller.open();
      await tester.pump(const Duration(milliseconds: 10));
      controller.close();
      await tester.pump(const Duration(milliseconds: 10));
      controller.open();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(controller.isOpen, isTrue);
      expect(tester.getTopLeft(find.byKey(const Key('host-child'))).dx, greaterThan(100));
    });

    testWidgets(
        'didUpdateWidget snap branch: swapping to a controller with a differing isOpen '
        'snaps the reveal instantly (no animation) on the very next frame', (tester) async {
      final controllerA = MenuSlideController(isOpen: false);
      final controllerB = MenuSlideController(isOpen: true);

      final key = GlobalKey();

      await tester.pumpWidget(wrap(MenuSlideShell(
        key: key,
        controller: controllerA,
        child: hostChild(),
      )));

      expect(tester.getTopLeft(find.byKey(const Key('host-child'))).dx, closeTo(0, 1));

      await tester.pumpWidget(wrap(MenuSlideShell(
        key: key,
        controller: controllerB,
        child: hostChild(),
      )));

      // A single frame (no settle) must already show the open position —
      // proving the didUpdateWidget snap branch set `_revealController.value
      // = 1` instantly rather than kicking off an animation.
      expect(tester.getTopLeft(find.byKey(const Key('host-child'))).dx, greaterThan(100));
      expect(controllerA.hasListeners, isFalse);
      expect(controllerB.hasListeners, isTrue);
    });

    testWidgets(
        'tapping a row while open with a realistic full-bleed child does not intercept '
        'the tap', (tester) async {
      const home = MenuItem(id: 'home', label: 'Home', icon: MenuIconData(Icons.home));
      const inbox = MenuItem(id: 'inbox', label: 'Inbox', icon: MenuIconData(Icons.inbox));
      final controller = MenuSlideController(items: const [home, inbox], isOpen: true);

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        child: Container(color: const Color(0xFFFF0000)),
      )));

      await tester.pumpAndSettle();

      await tester.tap(find.text('Inbox'));
      await tester.pump();

      expect(controller.selectedItemId, 'inbox');
    });
  });
}
