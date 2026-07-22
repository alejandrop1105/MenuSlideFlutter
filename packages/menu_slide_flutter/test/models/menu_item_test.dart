import 'package:flutter/material.dart' show Color, Icons;
import 'package:flutter_test/flutter_test.dart';
import 'package:menu_slide_flutter/menu_slide_flutter.dart';

void main() {
  group('MenuItem construction defaults', () {
    test('enabled defaults to true, badge and sectionId default to null', () {
      const item = MenuItem(
        id: 'home',
        label: 'Home',
        icon: MenuIconData(Icons.home),
      );

      expect(item.enabled, isTrue);
      expect(item.badge, isNull);
      expect(item.sectionId, isNull);
    });

    test('holds the given id, label and icon', () {
      const item = MenuItem(
        id: 'home',
        label: 'Home',
        icon: MenuIconData(Icons.home),
      );

      expect(item.id, 'home');
      expect(item.label, 'Home');
      expect(item.icon, const MenuIconData(Icons.home));
    });
  });

  group('MenuItem JSON round-trip', () {
    test('round-trips with an iconData icon', () {
      const original = MenuItem(
        id: 'home',
        label: 'Home',
        icon: MenuIconData(Icons.home),
      );

      final json = original.toJson();
      final parsed = MenuItem.fromJson(json);

      expect(parsed, original);
    });

    test('round-trips with an asset icon', () {
      const original = MenuItem(
        id: 'settings',
        label: 'Settings',
        icon: MenuAssetIcon('assets/icons/settings.png'),
      );

      final json = original.toJson();
      final parsed = MenuItem.fromJson(json);

      expect(parsed, original);
    });

    test('round-trips a disabled item', () {
      const original = MenuItem(
        id: 'locked',
        label: 'Locked',
        icon: MenuIconData(Icons.lock),
        enabled: false,
      );

      final json = original.toJson();
      final parsed = MenuItem.fromJson(json);

      expect(parsed.enabled, isFalse);
      expect(parsed, original);
    });

    test('round-trips a non-null sectionId', () {
      const original = MenuItem(
        id: 'home',
        label: 'Home',
        icon: MenuIconData(Icons.home),
        sectionId: 'main',
      );

      final json = original.toJson();
      final parsed = MenuItem.fromJson(json);

      expect(parsed.sectionId, 'main');
      expect(parsed, original);
    });

    test('round-trips with a badge present', () {
      const original = MenuItem(
        id: 'inbox',
        label: 'Inbox',
        icon: MenuIconData(Icons.inbox),
        badge: MenuBadge('3', color: Color(0xFFFF0000)),
      );

      final json = original.toJson();
      final parsed = MenuItem.fromJson(json);

      expect(parsed.badge, const MenuBadge('3', color: Color(0xFFFF0000)));
      expect(parsed, original);
    });

    test('round-trips with no badge (omitted from JSON)', () {
      const original = MenuItem(
        id: 'home',
        label: 'Home',
        icon: MenuIconData(Icons.home),
      );

      final json = original.toJson();

      expect(json.containsKey('badge'), isFalse);
      expect(MenuItem.fromJson(json).badge, isNull);
    });

    test('fromJson degrades gracefully when optional keys are missing', () {
      final parsed = MenuItem.fromJson(const {
        'id': 'home',
        'label': 'Home',
        'icon': {'type': 'iconData', 'codePoint': 0xe318},
      });

      expect(parsed.enabled, isTrue);
      expect(parsed.badge, isNull);
      expect(parsed.sectionId, isNull);
    });

    test('fromJson yields the fallback icon when the icon key is missing '
        'instead of throwing', () {
      final parsed = MenuItem.fromJson(const {
        'id': 'home',
        'label': 'Home',
      });

      expect(parsed.icon, MenuIcon.fallback);
    });

    test('fromJson yields the fallback icon when the icon JSON is '
        'malformed instead of throwing', () {
      final parsed = MenuItem.fromJson(const {
        'id': 'home',
        'label': 'Home',
        'icon': {'type': 'not-a-real-type'},
      });

      expect(parsed.icon, MenuIcon.fallback);
    });

    test('fromJson ignores unknown/extra top-level keys', () {
      final parsed = MenuItem.fromJson(const {
        'id': 'home',
        'label': 'Home',
        'icon': {'type': 'iconData', 'codePoint': 0xe318},
        'unknownField': 'ignored',
      });

      expect(parsed.id, 'home');
      expect(parsed.label, 'Home');
    });
  });

  group('MenuItem.fromJson malformed/degraded input handling', () {
    test('an empty map degrades to a disabled item instead of throwing', () {
      final parsed = MenuItem.fromJson(const <String, dynamic>{});

      expect(parsed.enabled, isFalse);
    });

    test('a missing id degrades to disabled while preserving the label', () {
      final parsed = MenuItem.fromJson(const {
        'label': 'Home',
        'icon': {'type': 'iconData', 'codePoint': 0xe318},
      });

      expect(parsed.enabled, isFalse);
      expect(parsed.label, 'Home');
    });

    test('a missing label degrades to disabled', () {
      final parsed = MenuItem.fromJson(const {'id': 'home'});

      expect(parsed.enabled, isFalse);
    });

    test('a wrong-typed id (not a non-empty String) degrades to disabled', () {
      final parsed = MenuItem.fromJson(const {'id': 123, 'label': 'X'});

      expect(parsed.enabled, isFalse);
    });

    test('an empty-string id degrades to disabled', () {
      final parsed = MenuItem.fromJson(const {'id': '', 'label': 'X'});

      expect(parsed.enabled, isFalse);
    });

    test('a wrong-typed enabled value does not throw and defaults to true '
        'on an otherwise-valid item', () {
      final parsed = MenuItem.fromJson(const {
        'id': 'a',
        'label': 'b',
        'enabled': 'yes',
      });

      expect(parsed.enabled, isTrue);
    });

    test('a fully valid item still parses with enabled true by default and '
        'all fields intact', () {
      final parsed = MenuItem.fromJson(const {
        'id': 'home',
        'label': 'Home',
        'icon': {'type': 'iconData', 'codePoint': 0xe318},
      });

      expect(parsed.enabled, isTrue);
      expect(parsed.id, 'home');
      expect(parsed.label, 'Home');
    });

    test('a wrong-typed badge degrades badge to null without throwing', () {
      final parsed = MenuItem.fromJson(const {
        'id': 'home',
        'label': 'Home',
        'badge': 'not-a-map',
      });

      expect(parsed.badge, isNull);
    });

    test('fromJson never throws and never returns null for any malformed '
        'combination of required fields', () {
      expect(() => MenuItem.fromJson(const <String, dynamic>{}), returnsNormally);
      expect(
        () => MenuItem.fromJson(const {'id': 42, 'label': 7}),
        returnsNormally,
      );
    });
  });

  group('MenuItem equality', () {
    test('two items with equal fields are equal and share hashCode', () {
      const a = MenuItem(id: 'home', label: 'Home', icon: MenuIconData(Icons.home));
      const b = MenuItem(id: 'home', label: 'Home', icon: MenuIconData(Icons.home));

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('items with different ids are not equal', () {
      const a = MenuItem(id: 'home', label: 'Home', icon: MenuIconData(Icons.home));
      const b = MenuItem(id: 'settings', label: 'Home', icon: MenuIconData(Icons.home));

      expect(a, isNot(b));
    });
  });
}
