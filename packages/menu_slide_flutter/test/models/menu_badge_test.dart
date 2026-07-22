import 'package:flutter/material.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:menu_slide_flutter/menu_slide_flutter.dart';

void main() {
  group('MenuBadge construction', () {
    test('holds the given label', () {
      const badge = MenuBadge('3');

      expect(badge.label, '3');
    });

    test('color defaults to null when not provided', () {
      const badge = MenuBadge('New');

      expect(badge.color, isNull);
    });

    test('holds the given color when provided', () {
      const badge = MenuBadge('New', color: Color(0xFFFF0000));

      expect(badge.color, const Color(0xFFFF0000));
    });
  });

  group('MenuBadge JSON round-trip', () {
    test('round-trips label only (no color)', () {
      const original = MenuBadge('3');

      final json = original.toJson();
      final parsed = MenuBadge.fromJson(json);

      expect(parsed, original);
    });

    test('round-trips label with color', () {
      const original = MenuBadge('New', color: Color(0xFFFF0000));

      final json = original.toJson();
      final parsed = MenuBadge.fromJson(json);

      expect(parsed, original);
    });

    test('toJson omits color key when color is null', () {
      const badge = MenuBadge('3');

      final json = badge.toJson();

      expect(json.containsKey('color'), isFalse);
    });

    test('fromJson ignores unknown/extra keys', () {
      final parsed = MenuBadge.fromJson(const {
        'label': '3',
        'unknownField': 'ignored',
      });

      expect(parsed, const MenuBadge('3'));
    });

    test('fromJson accepts a color encoded as a double and does not '
        'silently drop it to null', () {
      final parsed = MenuBadge.fromJson(const {
        'label': 'x',
        'color': 4278190335.0,
      });

      expect(parsed.color, isNotNull);
    });
  });

  group('MenuBadge equality', () {
    test('two badges with equal fields are equal and share hashCode', () {
      const a = MenuBadge('3', color: Color(0xFFFF0000));
      const b = MenuBadge('3', color: Color(0xFFFF0000));

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('badges with different labels are not equal', () {
      const a = MenuBadge('3');
      const b = MenuBadge('4');

      expect(a, isNot(b));
    });
  });
}
