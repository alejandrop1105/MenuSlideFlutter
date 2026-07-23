import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menu_slide_flutter/menu_slide_flutter.dart';

/// End-to-end theming tests exercising `MenuSlideThemeData` registered on a
/// host `ThemeData.extensions` list — as opposed to
/// `menu_slide_shell_test.dart`'s `theme override applies a distinct panel
/// color` test, which only exercises the per-instance `theme:` override
/// param directly. This file proves `MenuSlideThemeData.resolve` end to end:
/// registered extension applies, two hosts brand independently with no
/// shared state leak, and no registered extension falls back to the
/// documented default without crashing.
void main() {
  const home = MenuItem(id: 'home', label: 'Home', icon: MenuIconData(Icons.home));

  Widget wrapWithTheme(Widget child, {MenuSlideThemeData? extension}) {
    return MaterialApp(
      theme: extension == null
          ? ThemeData.light()
          : ThemeData.light().copyWith(extensions: [extension]),
      home: Scaffold(body: child),
    );
  }

  group('MenuSlideShell theming', () {
    testWidgets('registered ThemeData extension colors the panel', (tester) async {
      final controller = MenuSlideController(items: const [home]);
      final branded = MenuSlideThemeData.fallback().copyWith(panelColor: Colors.deepPurple);

      await tester.pumpWidget(wrapWithTheme(
        MenuSlideShell(controller: controller, child: const SizedBox.shrink()),
        extension: branded,
      ));

      final panel = tester.widget<Container>(find.byKey(const Key('menu-slide-panel')));
      expect(panel.color, Colors.deepPurple);
    });

    testWidgets(
        'two hosts with distinct registered themes brand independently, no shared state leak',
        (tester) async {
      final controllerA = MenuSlideController(items: const [home]);
      final controllerB = MenuSlideController(items: const [home]);
      final themeA = MenuSlideThemeData.fallback().copyWith(panelColor: Colors.red);
      final themeB = MenuSlideThemeData.fallback().copyWith(panelColor: Colors.green);

      await tester.pumpWidget(wrapWithTheme(
        MenuSlideShell(controller: controllerA, child: const SizedBox.shrink()),
        extension: themeA,
      ));
      final panelA = tester.widget<Container>(find.byKey(const Key('menu-slide-panel')));
      expect(panelA.color, Colors.red);

      // Fully unmount host A before mounting host B — pumping directly from
      // one MaterialApp tree to another of identical shape would let
      // Flutter's element-reuse diffing update host A's elements in place
      // rather than truly mounting a second, independent host. An explicit
      // teardown pump forces a clean remount so this test actually proves
      // two SEPARATE hosts brand independently, not just that one host's
      // theme can be swapped.
      await tester.pumpWidget(const SizedBox.shrink());

      // Pumping a distinct tree (second host) must not leak the first
      // host's registered extension — MenuSlideThemeData is resolved from
      // each host's own Theme.of(context), not a shared/static value.
      await tester.pumpWidget(wrapWithTheme(
        MenuSlideShell(controller: controllerB, child: const SizedBox.shrink()),
        extension: themeB,
      ));
      final panelB = tester.widget<Container>(find.byKey(const Key('menu-slide-panel')));
      expect(panelB.color, Colors.green);
      expect(panelB.color, isNot(Colors.red));
    });

    testWidgets('no extension registered falls back to the documented default, no crash',
        (tester) async {
      final controller = MenuSlideController(items: const [home]);

      await tester.pumpWidget(wrapWithTheme(
        MenuSlideShell(controller: controller, child: const SizedBox.shrink()),
      ));

      expect(tester.takeException(), isNull);
      final panel = tester.widget<Container>(find.byKey(const Key('menu-slide-panel')));
      expect(panel.color, MenuSlideThemeData.fallback().panelColor);
    });

    testWidgets('a per-instance theme override wins over a registered ThemeData extension',
        (tester) async {
      final controller = MenuSlideController(items: const [home]);
      final registered = MenuSlideThemeData.fallback().copyWith(panelColor: Colors.green);
      final override = MenuSlideThemeData.fallback().copyWith(panelColor: Colors.orange);

      await tester.pumpWidget(wrapWithTheme(
        MenuSlideShell(controller: controller, theme: override, child: const SizedBox.shrink()),
        extension: registered,
      ));

      final panel = tester.widget<Container>(find.byKey(const Key('menu-slide-panel')));
      expect(panel.color, Colors.orange);
    });
  });
}
