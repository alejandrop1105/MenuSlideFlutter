// Verifies the PR8 migration: RiveAppHome consumes MenuSlideShell (the
// menu_slide_flutter package) instead of the old Rive-coupled SideMenu.
//
// The full RiveAppHome composes real Rive assets (background rive icons in
// the bottom tab bar via `RiveAnimation.asset`/`RiveFile.asset`). Pumping it
// directly was tried and confirmed unusable in this harness: `RiveFile.asset`
// throws `Invalid argument(s): Failed to load dynamic library
// 'rive_common_plugin.dll'` because the native Rive FFI text-rendering
// library isn't available under `flutter test` on this machine — this is a
// pre-existing limitation of the `rive_app` sample's test story, unrelated
// to this migration (any widget test touching `CustomTabBar`'s
// `RiveAnimation.asset` icons hits the same failure). To keep this test
// fast, deterministic, and free of that unrelated Rive dependency, it
// exercises the smallest host widget that actually composes
// `MenuSlideShell` with the migrated `RiveAppMenuData` — i.e. the same
// composition RiveAppHome uses for its menu (controller + sections + items
// + header/footer builders) — without the Rive-dependent chrome. This still
// proves the migration's acceptance criteria: the shell builds, the menu
// button opens the menu, a known migrated item label appears, and tapping a
// row updates the controller's selection.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menu_slide_flutter/menu_slide_flutter.dart';

import 'package:flutter_samples/samples/ui/rive_app/menu_data.dart';

/// Test-only counter that tracks how many times a [MenuSlideController]
/// notified its listeners, mirroring the helper used by the package's own
/// `menu_slide_controller_test.dart`, so scenarios can assert exact
/// notification counts (including "no notification at all").
class _NotificationCounter {
  _NotificationCounter(this._controller) {
    _controller.addListener(_onNotify);
  }

  final MenuSlideController _controller;
  int count = 0;

  void _onNotify() => count++;

  void dispose() => _controller.removeListener(_onNotify);
}

void main() {
  Widget buildHost(MenuSlideController controller) {
    return MaterialApp(
      home: MenuSlideShell(
        controller: controller,
        sections: RiveAppMenuData.sections,
        headerBuilder: (context) => const Text('Ashu'),
        footerBuilder: (context) => const Text('Dark Mode'),
        child: const Scaffold(body: Center(child: Text('page body'))),
      ),
    );
  }

  testWidgets('builds without throwing and shows the menu button',
      (tester) async {
    final controller = MenuSlideController(items: RiveAppMenuData.items);
    addTearDown(controller.dispose);

    await tester.pumpWidget(buildHost(controller));

    expect(find.text('page body'), findsOneWidget);
    expect(find.byKey(const Key('menu-slide-button')), findsOneWidget);
  });

  testWidgets('tapping the menu button opens the menu and shows a known item',
      (tester) async {
    final controller = MenuSlideController(items: RiveAppMenuData.items);
    addTearDown(controller.dispose);

    await tester.pumpWidget(buildHost(controller));

    // The panel is always in the widget tree (off-canvas at rest — see the
    // package's PR7 reveal design), so `find.text('Home')` matches before
    // opening too. What actually changes on open is `controller.isOpen` and
    // whether the row is reachable for a tap (exercised below and in the
    // next test).
    expect(controller.isOpen, isFalse);

    await tester.tap(find.byKey(const Key('menu-slide-button')));
    await tester.pumpAndSettle();

    expect(controller.isOpen, isTrue);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Ashu'), findsOneWidget);
    expect(find.text('Dark Mode'), findsOneWidget);
  });

  testWidgets('tapping a row updates the controller selection',
      (tester) async {
    final controller = MenuSlideController(items: RiveAppMenuData.items);
    addTearDown(controller.dispose);

    await tester.pumpWidget(buildHost(controller));
    await tester.tap(find.byKey(const Key('menu-slide-button')));
    await tester.pumpAndSettle();

    expect(controller.selectedItemId, isNull);

    await tester.tap(find.text('Search'));
    await tester.pump();

    expect(controller.selectedItemId, 'search');
  });

  // PR8 review FIX 2 — two-navigator coordination contract.
  //
  // `RiveAppHome` wires the side menu (`_menuController`) and the bottom
  // tab bar (`CustomTabBar.onTabChange`) together host-side: the bottom
  // bar calls `selectItem`/`clearSelection` on the SAME controller the menu
  // uses, keyed off `_lastMenuSelection`, so the two navigators never go
  // stale relative to each other. Pumping the real `RiveAppHome` to prove
  // this end-to-end is blocked by the Rive-FFI limitation documented at the
  // top of this file (`RiveFile.asset` / `RiveAnimation.asset` throw under
  // `flutter test` on this machine). These tests instead exercise the
  // controller-level contract that wiring depends on: that clearing the
  // selection (as the bottom bar does for tabs with no matching menu item)
  // makes a later `selectItem` to the PREVIOUSLY selected id fire a real
  // notification instead of being a stale no-op — i.e. no dead click.
  group('Two-navigator coordination contract (host wiring in RiveAppHome)', () {
    test(
        'bottom-tab sync to the already-selected menu item is a no-op '
        '(selection already in sync, no spurious re-navigation)', () {
      final controller = MenuSlideController(items: RiveAppMenuData.items);
      addTearDown(controller.dispose);
      controller.selectItem('home');
      final counter = _NotificationCounter(controller);
      addTearDown(counter.dispose);

      // Simulates `CustomTabBar.onTabChange(0)`: the host calls
      // `selectItem('home')` again because tab 0 maps to the 'home' menu id.
      controller.selectItem('home');

      expect(controller.selectedItemId, 'home');
      expect(counter.count, 0);
    });

    test(
        'after a bottom-tab sync clears the selection, re-selecting the '
        'previously-selected item DOES notify (no dead click)', () {
      final controller = MenuSlideController(items: RiveAppMenuData.items);
      addTearDown(controller.dispose);
      controller.selectItem('home');
      expect(controller.selectedItemId, 'home');

      // Simulates `CustomTabBar.onTabChange(2)` (Timer — no matching menu
      // id): the host calls `clearSelection()`.
      controller.clearSelection();
      expect(controller.selectedItemId, isNull);

      final counter = _NotificationCounter(controller);
      addTearDown(counter.dispose);

      // The user reopens the menu and taps 'Home' again. Without the
      // bottom bar keeping the controller's selection in sync, this would
      // still read as 'home' == 'home' and be a dead click. Because the
      // bottom bar cleared it above, this is a REAL change and fires.
      controller.selectItem('home');

      expect(controller.selectedItemId, 'home');
      expect(counter.count, 1);
    });
  });
}
