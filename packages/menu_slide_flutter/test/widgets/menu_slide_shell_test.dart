// `ChangeNotifier.hasListeners` is @protected in production code, but it is
// a standard, supported way to assert subscription/unsubscription behavior
// from widget tests — hence the file-level ignore below.
// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menu_slide_flutter/menu_slide_flutter.dart';

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
      final controller = MenuSlideController(items: const [home, inbox]);

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
      final controller = MenuSlideController(items: const [home, settings]);

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        child: const SizedBox.shrink(),
      )));

      await tester.tap(find.text('Settings'));
      await tester.pump();

      expect(controller.selectedItemId, isNull);
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
      final controller = MenuSlideController(items: const [dupDisabled, dupEnabled]);

      await tester.pumpWidget(wrap(MenuSlideShell(
        controller: controller,
        child: const SizedBox.shrink(),
      )));

      await tester.tap(find.text('Dup Enabled'));
      await tester.pump();

      expect(controller.selectedItemId, isNull);
    });
  });
}
