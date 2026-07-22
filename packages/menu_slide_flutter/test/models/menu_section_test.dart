import 'package:flutter/material.dart' show Icons;
import 'package:flutter_test/flutter_test.dart';
import 'package:menu_slide_flutter/menu_slide_flutter.dart';

void main() {
  group('MenuSection construction', () {
    test('holds the given id and title', () {
      const section = MenuSection(id: 'main', title: 'Main');

      expect(section.id, 'main');
      expect(section.title, 'Main');
    });
  });

  group('MenuSection JSON round-trip', () {
    test('round-trips through toJson/fromJson', () {
      const original = MenuSection(id: 'main', title: 'Main');

      final json = original.toJson();
      final parsed = MenuSection.fromJson(json);

      expect(parsed, original);
    });

    test('fromJson ignores unknown/extra keys', () {
      final parsed = MenuSection.fromJson(const {
        'id': 'main',
        'title': 'Main',
        'unknownField': 'ignored',
      });

      expect(parsed, const MenuSection(id: 'main', title: 'Main'));
    });
  });

  group('MenuSection equality', () {
    test('two sections with equal fields are equal and share hashCode', () {
      const a = MenuSection(id: 'main', title: 'Main');
      const b = MenuSection(id: 'main', title: 'Main');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('sections with different ids are not equal', () {
      const a = MenuSection(id: 'main', title: 'Main');
      const b = MenuSection(id: 'secondary', title: 'Main');

      expect(a, isNot(b));
    });
  });

  group('groupItemsBySection', () {
    const main = MenuSection(id: 'main', title: 'Main');
    const secondary = MenuSection(id: 'secondary', title: 'Secondary');

    const home = MenuItem(
      id: 'home',
      label: 'Home',
      icon: MenuIconData(Icons.home),
      sectionId: 'main',
    );
    const settings = MenuItem(
      id: 'settings',
      label: 'Settings',
      icon: MenuIconData(Icons.settings),
      sectionId: 'secondary',
    );
    const profile = MenuItem(
      id: 'profile',
      label: 'Profile',
      icon: MenuIconData(Icons.person),
      sectionId: 'main',
    );

    test('groups items by their valid sectionId', () {
      final grouped = groupItemsBySection([home, settings, profile], [main, secondary]);

      expect(grouped[main], [home, profile]);
      expect(grouped[secondary], [settings]);
    });

    test('an item with no sectionId is ungrouped (top-level)', () {
      const ungrouped = MenuItem(
        id: 'help',
        label: 'Help',
        icon: MenuIconData(Icons.help),
      );

      final grouped = groupItemsBySection([ungrouped], [main]);

      expect(grouped[null], [ungrouped]);
    });

    test('a dangling sectionId (no matching MenuSection) does not crash and '
        'is treated as ungrouped', () {
      const danglingItem = MenuItem(
        id: 'ghost',
        label: 'Ghost',
        icon: MenuIconData(Icons.home),
        sectionId: 'does-not-exist',
      );

      final grouped = groupItemsBySection([danglingItem], [main]);

      expect(grouped[null], [danglingItem]);
      // `main` is a declared section, so it is still seeded as a key (with
      // an empty list) even though no item resolves to it.
      expect(grouped.containsKey(main), isTrue);
      expect(grouped[main], isEmpty);
    });

    test('a declared section with no matching items still appears as a key '
        'with an empty list', () {
      final grouped = groupItemsBySection([], [main, secondary]);

      expect(grouped.containsKey(main), isTrue);
      expect(grouped[main], isEmpty);
      expect(grouped.containsKey(secondary), isTrue);
      expect(grouped[secondary], isEmpty);
    });

    test('key order follows the declared sections order, not the order '
        'items are encountered', () {
      final grouped = groupItemsBySection([settings, home], [main, secondary]);

      expect(grouped.keys.toList(), [main, secondary]);
    });

    test('the ungrouped (null) bucket key always appears last, after every '
        'declared section', () {
      const ungrouped = MenuItem(
        id: 'help',
        label: 'Help',
        icon: MenuIconData(Icons.help),
      );

      final grouped = groupItemsBySection([ungrouped, home, settings], [main, secondary]);

      expect(grouped.keys.toList(), [main, secondary, null]);
    });

    test('item order within a section is preserved', () {
      final grouped = groupItemsBySection([profile, home], [main]);

      expect(grouped[main], [profile, home]);
    });

    test('duplicate section ids: the LAST section with that id wins for '
        'item resolution, but every declared section still appears as a '
        'key (documents current behavior, does not throw)', () {
      const mainV1 = MenuSection(id: 'main', title: 'Main');
      const mainV2 = MenuSection(id: 'main', title: 'Main Updated');

      final grouped = groupItemsBySection([home], [mainV1, mainV2]);

      expect(grouped.containsKey(mainV1), isTrue);
      expect(grouped[mainV1], isEmpty);
      expect(grouped[mainV2], [home]);
    });
  });
}
