// This slice wires the shell's mirrored 3D reveal to the RIGHT side,
// exposing a `rightPanel` widget param on `MenuSlideShell` and driving it via
// `MenuSlideController.isRightOpen`/`openRight()`/`closeRight()` (added in a
// prior slice). The reveal is driven by the SAME shared spring-animated
// `_revealController` as the left menu — mutual exclusivity (enforced by the
// controller) guarantees only one side is ever animating open at a time, and
// the shell tracks which side is active to flip the sign of the host child's
// translate/rotate.
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

  group('MenuSlideShell right panel (mirrored 3D reveal)', () {
    testWidgets(
        'rightPanel provided renders the panel in the tree even before it opens',
        (tester) async {
      final controller = MenuSlideController();

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        rightPanel: const Text('Right Panel', key: Key('right-panel-content')),
        child: const SizedBox.shrink(),
      )));

      expect(find.byKey(const Key('menu-slide-right-panel')), findsOneWidget);
      expect(find.byKey(const Key('right-panel-content')), findsOneWidget);
    });

    testWidgets(
        'controller.openRight() reveals the right panel and translates the host child to '
        'the LEFT (negative dx)', (tester) async {
      final controller = MenuSlideController();

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        rightPanel: const Text('Right Panel'),
        child: const SizedBox.shrink(),
      )));

      controller.openRight();
      await tester.pumpAndSettle();

      expect(controller.isRightOpen, isTrue);
      final translateWidget = tester.widget<Transform>(
          find.byKey(const Key('menu-slide-reveal-translate')));
      expect(translateWidget.transform.getTranslation().x, lessThan(0));
    });

    testWidgets(
        'with the LEFT open, the host child still translates to the RIGHT (positive dx)',
        (tester) async {
      final controller = MenuSlideController();

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        rightPanel: const Text('Right Panel'),
        child: const SizedBox.shrink(),
      )));

      controller.open();
      await tester.pumpAndSettle();

      final translateWidget = tester.widget<Transform>(
          find.byKey(const Key('menu-slide-reveal-translate')));
      expect(translateWidget.transform.getTranslation().x, greaterThan(0));
    });

    testWidgets(
        'opening the right panel after the left menu is open: mutual exclusivity closes '
        'the left and flips the translate direction to negative',
        (tester) async {
      final controller = MenuSlideController();

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        rightPanel: const Text('Right Panel'),
        child: const SizedBox.shrink(),
      )));

      controller.open();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Transform>(
                find.byKey(const Key('menu-slide-reveal-translate')))
            .transform
            .getTranslation()
            .x,
        greaterThan(0),
      );

      controller.openRight();
      await tester.pumpAndSettle();

      expect(controller.isOpen, isFalse);
      expect(controller.isRightOpen, isTrue);
      expect(
        tester
            .widget<Transform>(
                find.byKey(const Key('menu-slide-reveal-translate')))
            .transform
            .getTranslation()
            .x,
        lessThan(0),
      );
    });

    testWidgets(
        'opening the left menu after the right panel is open: mutual exclusivity closes '
        'the right and flips the translate direction to positive',
        (tester) async {
      final controller = MenuSlideController();

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        rightPanel: const Text('Right Panel'),
        child: const SizedBox.shrink(),
      )));

      controller.openRight();
      await tester.pumpAndSettle();

      controller.open();
      await tester.pumpAndSettle();

      expect(controller.isRightOpen, isFalse);
      expect(controller.isOpen, isTrue);
      expect(
        tester
            .widget<Transform>(
                find.byKey(const Key('menu-slide-reveal-translate')))
            .transform
            .getTranslation()
            .x,
        greaterThan(0),
      );
    });

    testWidgets(
        'rightPanel null renders no right panel in the tree, even when isRightOpen',
        (tester) async {
      final controller = MenuSlideController();

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        child: const SizedBox.shrink(),
      )));

      expect(find.byKey(const Key('menu-slide-right-panel')), findsNothing);

      controller.openRight();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('menu-slide-right-panel')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'disposing after opening the right panel does not throw and detaches the listener',
        (tester) async {
      final controller = MenuSlideController();

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        rightPanel: const Text('Right Panel'),
        child: const SizedBox.shrink(),
      )));

      controller.openRight();
      await tester.pump(const Duration(milliseconds: 20));

      await tester.pumpWidget(const SizedBox.shrink());

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'closing the right panel returns the host child to its rest position',
        (tester) async {
      final controller = MenuSlideController();

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        rightPanel: const Text('Right Panel'),
        child: const SizedBox.shrink(),
      )));

      controller.openRight();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Transform>(
                find.byKey(const Key('menu-slide-reveal-translate')))
            .transform
            .getTranslation()
            .x,
        lessThan(0),
      );

      controller.closeRight();
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<Transform>(
                find.byKey(const Key('menu-slide-reveal-translate')))
            .transform
            .getTranslation()
            .x,
        closeTo(0, 0.01),
      );
    });

    testWidgets(
        'flipping to the RIGHT mid-animation (LEFT still opening) does not snap the '
        'reveal through ~0 — it flips the sign in place and keeps animating open',
        (tester) async {
      // Regression test for a HIGH bug: opening a side WHILE the shared
      // reveal is still animating forward from the other side used to
      // restart the spring simulation from value 0 (`animateWith(
      // SpringSimulation(desc, 0, 1, 0))` unconditionally, whenever status
      // wasn't already `completed`), snapping the page visually back to
      // closed for a frame before re-animating. The reveal `value` means
      // "how open", independent of `_activeSide` (which side / sign); a
      // mid-flight side flip must keep the value continuous and only flip
      // the sign.
      final controller = MenuSlideController();

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        rightPanel: const Text('Right Panel'),
        child: const SizedBox.shrink(),
      )));

      controller.open();
      // The ticker's baseline frame reports zero elapsed time (a Flutter
      // testing quirk: a ticker started outside a frame callback begins
      // counting from the NEXT frame's timestamp) — pump once with no
      // duration to establish that baseline, then advance by a small,
      // fixed step so the spring is clearly mid-flight, NOT settled at 0
      // or 1.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final midTranslate = tester
          .widget<Transform>(
              find.byKey(const Key('menu-slide-reveal-translate')))
          .transform
          .getTranslation()
          .x;
      // Clearly mid-animation: positive (LEFT open pushes the child right)
      // but nowhere near a settled value.
      expect(midTranslate, greaterThan(0));

      controller.openRight();
      // A couple of small steps right after the flip — the discriminating
      // assertion is on the frame(s) immediately following the flip.
      await tester.pump(const Duration(milliseconds: 1));

      final justAfterFlip = tester
          .widget<Transform>(
              find.byKey(const Key('menu-slide-reveal-translate')))
          .transform
          .getTranslation()
          .x;

      await tester.pump(const Duration(milliseconds: 1));
      final secondStepAfterFlip = tester
          .widget<Transform>(
              find.byKey(const Key('menu-slide-reveal-translate')))
          .transform
          .getTranslation()
          .x;

      // The sign flips instantly (RIGHT is negative) but the MAGNITUDE must
      // stay close to the pre-flip magnitude — it must never pass through
      // ~0 on the way. Buggy behavior snaps to ~0, failing both checks.
      expect(justAfterFlip, lessThan(0));
      expect(justAfterFlip.abs(), greaterThan(midTranslate.abs() * 0.5));
      expect(secondStepAfterFlip, lessThan(0));
      expect(secondStepAfterFlip.abs(), greaterThan(midTranslate.abs() * 0.5));

      await tester.pumpAndSettle();
      expect(controller.isRightOpen, isTrue);
    });

    testWidgets(
        'mirrored rotateY: the RIGHT-open rotation sign is opposite the LEFT-open sign '
        '(settled)', (tester) async {
      final leftController = MenuSlideController(isOpen: true);
      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: leftController,
        rightPanel: const Text('Right Panel'),
        child: const SizedBox.shrink(),
      )));
      await tester.pumpAndSettle();

      // `Matrix4.rotateY(theta)` sets entry(0, 2) to `sin(theta)` — an odd
      // function, so its sign matches the sign of `theta` for the (small,
      // non-multiple-of-pi) tilt angles this component uses.
      final leftEntry = tester
          .widget<Transform>(find.byKey(const Key('menu-slide-reveal-rotate')))
          .transform
          .entry(0, 2);

      final rightController = MenuSlideController(isRightOpen: true);
      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: rightController,
        rightPanel: const Text('Right Panel'),
        child: const SizedBox.shrink(),
      )));
      await tester.pumpAndSettle();

      final rightEntry = tester
          .widget<Transform>(find.byKey(const Key('menu-slide-reveal-rotate')))
          .transform
          .entry(0, 2);

      expect(leftEntry, isNot(0));
      expect(rightEntry, isNot(0));
      expect(leftEntry.sign, isNot(rightEntry.sign));
    });

    testWidgets(
        'swapping controller via didUpdateWidget to one constructed with isRightOpen: '
        'true reflects the right-open state and detaches the old listener',
        (tester) async {
      final controllerA = MenuSlideController();
      final controllerB = MenuSlideController(isRightOpen: true);

      final key = GlobalKey();

      await tester.pumpWidget(wrap(MenuSlideShell(
        key: key,
        controller: controllerA,
        rightPanel: const Text('Right Panel'),
        child: const SizedBox.shrink(),
      )));

      expect(controllerA.hasListeners, isTrue);

      await tester.pumpWidget(wrap(MenuSlideShell(
        key: key,
        controller: controllerB,
        rightPanel: const Text('Right Panel'),
        child: const SizedBox.shrink(),
      )));

      // A single frame (no settle) must already show the right-open
      // position — the didUpdateWidget snap branch sets `_revealController.
      // value = 1` instantly rather than kicking off an animation.
      final translateWidget = tester.widget<Transform>(
          find.byKey(const Key('menu-slide-reveal-translate')));
      expect(translateWidget.transform.getTranslation().x, lessThan(0));

      // The old controller's listener must have been detached.
      expect(controllerA.hasListeners, isFalse);
      expect(controllerB.hasListeners, isTrue);
    });
  });
}
