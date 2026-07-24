// Demonstrates `MenuSlideShell.rightPanel` + `MenuSlideScope` wired into the
// reference example: a "Quick actions" panel opened from a plain
// notifications `IconButton` living inside the shell's host content (proving
// "open from anywhere", not just the shell's own built-in button), and
// closed either via its own close button or the left menu's mutual
// exclusivity.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menu_slide_flutter/menu_slide_flutter.dart';
import 'package:menu_slide_flutter_example/main.dart';

void main() {
  group('DemoApp right panel', () {
    testWidgets('the right panel is present in the tree, closed by default',
        (tester) async {
      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('menu-slide-right-panel')), findsOneWidget);
      final translateWidget = tester.widget<Transform>(
          find.byKey(const Key('menu-slide-reveal-translate')));
      expect(translateWidget.transform.getTranslation().x, closeTo(0, 0.01));
    });

    testWidgets(
        'tapping the notifications button (in host content) opens the right panel and '
        'translates the page to the left', (tester) async {
      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('demo-open-right-button')));
      await tester.pumpAndSettle();

      final translateWidget = tester.widget<Transform>(
          find.byKey(const Key('menu-slide-reveal-translate')));
      expect(translateWidget.transform.getTranslation().x, lessThan(0));
    });

    testWidgets('the close button on the right panel closes it',
        (tester) async {
      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('demo-open-right-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('demo-close-right-button')));
      await tester.pumpAndSettle();

      final translateWidget = tester.widget<Transform>(
          find.byKey(const Key('menu-slide-reveal-translate')));
      expect(translateWidget.transform.getTranslation().x, closeTo(0, 0.01));
    });

    testWidgets(
        'opening the left menu after the right panel closes the right panel',
        (tester) async {
      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('demo-open-right-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('menu-slide-button')));
      await tester.pumpAndSettle();

      final translateWidget = tester.widget<Transform>(
          find.byKey(const Key('menu-slide-reveal-translate')));
      expect(translateWidget.transform.getTranslation().x, greaterThan(0));
    });

    testWidgets(
        'opening the right panel after the left menu closes the left menu',
        (tester) async {
      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('menu-slide-button')));
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

      // The notifications button is part of the shell's `child` subtree —
      // while the left menu is open, `child` (button included) is shifted
      // off-screen along with the rest of the page, so it is not reachable
      // via a real tap (this mirrors the shell's existing off-canvas
      // hit-testing behavior for the left panel itself). Driving the
      // transition via the controller directly still exercises the SAME
      // end-to-end mutual-exclusivity wiring in this exact demo
      // configuration (real theme, real controller instance).
      final controller =
          tester.widget<MenuSlideShell>(find.byType(MenuSlideShell)).controller;
      controller.openRight();
      await tester.pumpAndSettle();

      final translateWidget = tester.widget<Transform>(
          find.byKey(const Key('menu-slide-reveal-translate')));
      expect(translateWidget.transform.getTranslation().x, lessThan(0));
    });
  });
}
