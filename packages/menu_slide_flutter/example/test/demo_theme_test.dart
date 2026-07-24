import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menu_slide_flutter/menu_slide_flutter.dart';
import 'package:menu_slide_flutter_example/config_page.dart';
import 'package:menu_slide_flutter_example/main.dart';

void main() {
  /// The panel is off-canvas (not hit-testable) while closed — open it via
  /// the shell's built-in toggle button first, matching real drawer UX.
  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('menu-slide-button')));
    await tester.pumpAndSettle();
  }

  MaterialApp materialApp(WidgetTester tester) =>
      tester.widget<MaterialApp>(find.byType(MaterialApp));

  group('DemoApp global theming', () {
    testWidgets(
        'toggling dark mode in the menu drives MaterialApp.themeMode for the whole app',
        (tester) async {
      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();

      expect(materialApp(tester).themeMode, ThemeMode.light);

      await openMenu(tester);

      final themeSwitch = find.byKey(const Key('theme-toggle-switch'));
      expect(themeSwitch, findsOneWidget);
      expect(tester.widget<SwitchListTile>(themeSwitch).value, isFalse);

      await tester.tap(themeSwitch);
      await tester.pumpAndSettle();

      expect(materialApp(tester).themeMode, ThemeMode.dark);
      expect(tester.widget<SwitchListTile>(themeSwitch).value, isTrue);

      // Flip back — proves the loop is a genuine two-way toggle, not a
      // one-shot flag.
      await tester.tap(themeSwitch);
      await tester.pumpAndSettle();

      expect(materialApp(tester).themeMode, ThemeMode.light);
    });
  });

  group('DemoApp smoke', () {
    testWidgets('builds and shows the initial Dashboard page', (tester) async {
      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('page-dashboard')), findsOneWidget);
    });

    testWidgets('the menu button opens the menu panel', (tester) async {
      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();

      final panelBefore = tester.getTopLeft(find.byKey(const Key('menu-slide-panel')));
      expect(panelBefore.dx, lessThan(0)); // parked off-canvas while closed

      await openMenu(tester);

      final panelAfter = tester.getTopLeft(find.byKey(const Key('menu-slide-panel')));
      // The spring-driven reveal settles just shy of its exact target, so
      // assert it slid substantially on-screen rather than to an exact
      // pixel.
      expect(panelAfter.dx, greaterThan(panelBefore.dx + 200));
    });

    testWidgets('tapping a menu item navigates to its page and closes the menu',
        (tester) async {
      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();

      await openMenu(tester);

      final projectsRow = find.descendant(
        of: find.byKey(const Key('menu-slide-panel')),
        matching: find.text('Projects'),
      );
      expect(projectsRow, findsOneWidget);

      await tester.tap(projectsRow);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('page-projects')), findsOneWidget);
      expect(find.byKey(const Key('page-dashboard')), findsNothing);

      // closeOnSelect (shell default) parked the panel back off-canvas.
      final panelAfterSelect = tester.getTopLeft(find.byKey(const Key('menu-slide-panel')));
      expect(panelAfterSelect.dx, lessThan(0));
    });

    testWidgets('the bottom nav stays in sync with the menu selection', (tester) async {
      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();

      // Tap the bottom-nav "Search" destination directly.
      await tester.tap(find.widgetWithText(NavigationDestination, 'Search'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('page-search')), findsOneWidget);

      // The menu must reflect the same selection — no stale highlight.
      await openMenu(tester);
      final searchRow = tester.widget<Container>(
        find
            .ancestor(
              of: find.descendant(
                of: find.byKey(const Key('menu-slide-panel')),
                matching: find.text('Search'),
              ),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(searchRow.color, isNotNull); // highlighted (selected row color)
    });
  });

  group('Configuration page live updates', () {
    Future<void> openConfigurationPage(WidgetTester tester) async {
      // 'Configuration' is the last row in the scrollable item list and
      // would sit below the fold at the default test viewport height —
      // grow the surface so every row is visible without needing to
      // simulate a scroll gesture.
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await openMenu(tester);
      final configRow = find.descendant(
        of: find.byKey(const Key('menu-slide-panel')),
        matching: find.text('Configuration'),
      );
      expect(configRow, findsOneWidget);
      await tester.tap(configRow);
      await tester.pumpAndSettle();
    }

    testWidgets('selecting Configuration in the menu shows the Configuration page',
        (tester) async {
      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();

      await openConfigurationPage(tester);

      expect(find.byKey(const Key('page-settings')), findsOneWidget);
    });

    testWidgets('tapping a menu-background swatch updates the live panel color',
        (tester) async {
      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();

      await openConfigurationPage(tester);

      // Pick a swatch distinct from the app theme's default panel color.
      const swatchIndex = 4;
      await tester.tap(find.byKey(Key('config-menu-swatch-$swatchIndex')));
      await tester.pumpAndSettle();

      await openMenu(tester);

      final panel = tester.widget<Container>(find.byKey(const Key('menu-slide-panel')));
      expect(panel.color, demoColorPalette[swatchIndex]);
    });

    testWidgets('tapping a backdrop swatch updates the live shell backdrop color',
        (tester) async {
      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();

      await openConfigurationPage(tester);

      const swatchIndex = 3;
      await tester.tap(find.byKey(Key('config-backdrop-swatch-$swatchIndex')));
      await tester.pumpAndSettle();

      final backdrop = tester.widget<ColoredBox>(find.byKey(const Key('menu-slide-backdrop')));
      expect(backdrop.color, demoColorPalette[swatchIndex]);
    });

    testWidgets('toggling full-screen menu composes the bottom nav inside the shell',
        (tester) async {
      await tester.pumpWidget(const DemoApp());
      await tester.pumpAndSettle();

      final scaffoldBefore = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffoldBefore.bottomNavigationBar, isNotNull);
      expect(
        find.descendant(of: find.byType(MenuSlideShell), matching: find.byType(NavigationBar)),
        findsNothing,
      );

      await openConfigurationPage(tester);

      await tester.tap(find.byKey(const Key('config-fullscreen-switch')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final scaffoldAfter = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffoldAfter.bottomNavigationBar, isNull);
      expect(
        find.descendant(of: find.byType(MenuSlideShell), matching: find.byType(NavigationBar)),
        findsOneWidget,
      );

      // Flip back — the bar returns to Scaffold.bottomNavigationBar and out
      // of the shell, proving this is a genuine two-way composition toggle.
      await tester.tap(find.byKey(const Key('config-fullscreen-switch')));
      await tester.pumpAndSettle();

      final scaffoldReverted = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffoldReverted.bottomNavigationBar, isNotNull);
      expect(
        find.descendant(of: find.byType(MenuSlideShell), matching: find.byType(NavigationBar)),
        findsNothing,
      );
    });
  });
}
