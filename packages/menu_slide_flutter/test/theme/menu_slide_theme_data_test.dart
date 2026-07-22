import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menu_slide_flutter/menu_slide_flutter.dart';

void main() {
  group('MenuSlideThemeData.fallback', () {
    test('returns a fully-populated instance with documented defaults', () {
      final theme = MenuSlideThemeData.fallback();

      expect(theme.panelColor, const Color(0xFF17203A));
      expect(theme.selectedRowColor, Colors.blue);
      expect(theme.rowIconColor, const Color(0x99FFFFFF));
      expect(theme.selectedRowIconColor, Colors.white);
      expect(theme.dividerColor, const Color(0x1AFFFFFF));
      expect(theme.badgeColor, const Color(0xFF5E9EFF));
      expect(theme.badgeTextColor, Colors.white);
      expect(theme.rowTextStyle.fontFamily, 'Inter');
      expect(theme.rowTextStyle.fontSize, 17);
      expect(theme.rowTextStyle.fontWeight, FontWeight.w600);
      expect(theme.rowTextStyle.color, Colors.white);
      expect(theme.sectionTitleStyle.fontFamily, 'Inter');
      expect(theme.sectionTitleStyle.fontSize, 15);
      expect(theme.sectionTitleStyle.fontWeight, FontWeight.w600);
      expect(theme.sectionTitleStyle.color, const Color(0xB3FFFFFF));
      expect(theme.panelMaxWidth, 288);
      expect(theme.revealWidth, 265);
      expect(theme.panelRadius, 30);
      expect(theme.rowHeight, 56);
      expect(theme.panelPadding, const EdgeInsets.all(8));
      expect(theme.itemSpacing, 0);
    });

    test('derives reveal geometry constants from panelMaxWidth', () {
      final theme = MenuSlideThemeData.fallback();

      // Ports home.dart's magic literals -300/216/300, all now derived from
      // panelMaxWidth (288) instead of being free-floating literals.
      expect(theme.restTranslateX, -300);
      expect(theme.menuButtonShift, 216);
      expect(theme.navShift, 300);
    });

    test('a custom panelMaxWidth changes the derived geometry accordingly', () {
      final theme = MenuSlideThemeData.fallback().copyWith(panelMaxWidth: 200);

      expect(theme.restTranslateX, -212);
      expect(theme.menuButtonShift, 128);
      expect(theme.navShift, 212);
    });
  });

  group('MenuSlideThemeData.copyWith', () {
    test('overrides only the provided fields and preserves the rest', () {
      final base = MenuSlideThemeData.fallback();

      final copy = base.copyWith(
        panelColor: Colors.red,
        rowHeight: 72,
      );

      expect(copy.panelColor, Colors.red);
      expect(copy.rowHeight, 72);
      // Everything else preserved from base.
      expect(copy.selectedRowColor, base.selectedRowColor);
      expect(copy.rowIconColor, base.rowIconColor);
      expect(copy.selectedRowIconColor, base.selectedRowIconColor);
      expect(copy.dividerColor, base.dividerColor);
      expect(copy.badgeColor, base.badgeColor);
      expect(copy.badgeTextColor, base.badgeTextColor);
      expect(copy.rowTextStyle, base.rowTextStyle);
      expect(copy.sectionTitleStyle, base.sectionTitleStyle);
      expect(copy.panelMaxWidth, base.panelMaxWidth);
      expect(copy.revealWidth, base.revealWidth);
      expect(copy.panelRadius, base.panelRadius);
      expect(copy.panelPadding, base.panelPadding);
      expect(copy.itemSpacing, base.itemSpacing);
    });

    test('with no arguments returns an equivalent instance', () {
      final base = MenuSlideThemeData.fallback();
      final copy = base.copyWith();

      expect(copy.panelColor, base.panelColor);
      expect(copy.rowHeight, base.rowHeight);
      expect(copy.rowTextStyle, base.rowTextStyle);
    });
  });

  group('MenuSlideThemeData.lerp', () {
    test('at t=0 returns values equivalent to this', () {
      final a = MenuSlideThemeData.fallback();
      final b = a.copyWith(panelMaxWidth: 400, panelColor: Colors.black);

      final result = a.lerp(b, 0);

      expect(result.panelMaxWidth, a.panelMaxWidth);
      expect(result.panelColor, a.panelColor);
    });

    test('at t=1 returns values equivalent to other', () {
      final a = MenuSlideThemeData.fallback();
      final b = a.copyWith(panelMaxWidth: 400, panelColor: Colors.black);

      final result = a.lerp(b, 1);

      expect(result.panelMaxWidth, b.panelMaxWidth);
      expect(result.panelColor, b.panelColor);
    });

    test('at t=0.5 interpolates numeric fields to the exact midpoint', () {
      final a = MenuSlideThemeData.fallback().copyWith(panelMaxWidth: 200, rowHeight: 40);
      final b = a.copyWith(panelMaxWidth: 400, rowHeight: 60);

      final result = a.lerp(b, 0.5);

      expect(result.panelMaxWidth, 300);
      expect(result.rowHeight, 50);
    });

    test('at t=0.5 interpolates a Color field via Color.lerp', () {
      final a = MenuSlideThemeData.fallback().copyWith(panelColor: Colors.white);
      final b = a.copyWith(panelColor: Colors.black);

      final result = a.lerp(b, 0.5);

      expect(result.panelColor, Color.lerp(Colors.white, Colors.black, 0.5));
    });

    test('with null other returns this unchanged', () {
      final a = MenuSlideThemeData.fallback();

      final result = a.lerp(null, 0.5);

      expect(identical(result, a), isTrue);
    });

    test('at t=0.5 interpolates text styles and padding to the exact midpoint', () {
      final a = MenuSlideThemeData.fallback().copyWith(
        rowTextStyle: const TextStyle(fontSize: 10),
        sectionTitleStyle: const TextStyle(fontSize: 20),
        panelPadding: const EdgeInsets.all(0),
      );
      final b = a.copyWith(
        rowTextStyle: const TextStyle(fontSize: 30),
        sectionTitleStyle: const TextStyle(fontSize: 40),
        panelPadding: const EdgeInsets.all(20),
      );

      final result = a.lerp(b, 0.5);

      expect(
        result.rowTextStyle.fontSize,
        TextStyle.lerp(a.rowTextStyle, b.rowTextStyle, 0.5)!.fontSize,
      );
      expect(result.rowTextStyle.fontSize, 20);
      expect(
        result.sectionTitleStyle.fontSize,
        TextStyle.lerp(a.sectionTitleStyle, b.sectionTitleStyle, 0.5)!.fontSize,
      );
      expect(result.sectionTitleStyle.fontSize, 30);
      expect(
        result.panelPadding,
        EdgeInsetsGeometry.lerp(a.panelPadding, b.panelPadding, 0.5),
      );
      expect(result.panelPadding, const EdgeInsets.all(10));
    });

    test('ignores a foreign ThemeExtension and returns this unchanged', () {
      final a = MenuSlideThemeData.fallback();
      final rogue = _RogueExtension();

      final result = a.lerp(rogue, 0.5);

      expect(identical(result, a), isTrue);
    });
  });

  group('MenuSlideThemeData equality', () {
    test('two separately-constructed instances with identical fields are equal', () {
      final a = MenuSlideThemeData.fallback().copyWith(rowHeight: 56);
      final b = MenuSlideThemeData.fallback().copyWith(rowHeight: 56);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('ThemeData with equal extensions are equal', () {
      final a = MenuSlideThemeData.fallback().copyWith(rowHeight: 56);
      final b = MenuSlideThemeData.fallback().copyWith(rowHeight: 56);

      expect(ThemeData(extensions: [a]), equals(ThemeData(extensions: [b])));
    });

    test('instances differing in any single field are not equal', () {
      final base = MenuSlideThemeData.fallback();

      expect(base, isNot(equals(base.copyWith(panelColor: Colors.red))));
      expect(base, isNot(equals(base.copyWith(selectedRowColor: Colors.red))));
      expect(base, isNot(equals(base.copyWith(rowIconColor: Colors.red))));
      expect(base, isNot(equals(base.copyWith(selectedRowIconColor: Colors.red))));
      expect(base, isNot(equals(base.copyWith(dividerColor: Colors.red))));
      expect(base, isNot(equals(base.copyWith(badgeColor: Colors.red))));
      expect(base, isNot(equals(base.copyWith(badgeTextColor: Colors.red))));
      expect(base, isNot(equals(base.copyWith(rowTextStyle: const TextStyle(fontSize: 99)))));
      expect(
          base, isNot(equals(base.copyWith(sectionTitleStyle: const TextStyle(fontSize: 99)))));
      expect(base, isNot(equals(base.copyWith(panelMaxWidth: 999))));
      expect(base, isNot(equals(base.copyWith(revealWidth: 999))));
      expect(base, isNot(equals(base.copyWith(panelRadius: 999))));
      expect(base, isNot(equals(base.copyWith(rowHeight: 999))));
      expect(base, isNot(equals(base.copyWith(panelPadding: const EdgeInsets.all(99)))));
      expect(base, isNot(equals(base.copyWith(itemSpacing: 999))));
    });
  });

  group('MenuSlideThemeData.resolve', () {
    testWidgets('returns the override when one is provided', (tester) async {
      const override = MenuSlideThemeData(
        panelColor: Colors.red,
        selectedRowColor: Colors.green,
        rowIconColor: Colors.white,
        selectedRowIconColor: Colors.white,
        dividerColor: Colors.white,
        badgeColor: Colors.white,
        badgeTextColor: Colors.black,
        rowTextStyle: TextStyle(),
        sectionTitleStyle: TextStyle(),
      );
      late MenuSlideThemeData resolved;

      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(extensions: const [
          MenuSlideThemeData(
            panelColor: Colors.blue,
            selectedRowColor: Colors.green,
            rowIconColor: Colors.white,
            selectedRowIconColor: Colors.white,
            dividerColor: Colors.white,
            badgeColor: Colors.white,
            badgeTextColor: Colors.black,
            rowTextStyle: TextStyle(),
            sectionTitleStyle: TextStyle(),
          ),
        ]),
        home: Builder(builder: (context) {
          resolved = MenuSlideThemeData.resolve(context, override);
          return const SizedBox();
        }),
      ));

      expect(resolved.panelColor, Colors.red);
    });

    testWidgets('returns the registered extension when no override is given', (tester) async {
      late MenuSlideThemeData resolved;

      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(extensions: const [
          MenuSlideThemeData(
            panelColor: Colors.purple,
            selectedRowColor: Colors.green,
            rowIconColor: Colors.white,
            selectedRowIconColor: Colors.white,
            dividerColor: Colors.white,
            badgeColor: Colors.white,
            badgeTextColor: Colors.black,
            rowTextStyle: TextStyle(),
            sectionTitleStyle: TextStyle(),
          ),
        ]),
        home: Builder(builder: (context) {
          resolved = MenuSlideThemeData.resolve(context);
          return const SizedBox();
        }),
      ));

      expect(resolved.panelColor, Colors.purple);
    });

    testWidgets('falls back to MenuSlideThemeData.fallback() when none is registered',
        (tester) async {
      late MenuSlideThemeData resolved;

      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(),
        home: Builder(builder: (context) {
          resolved = MenuSlideThemeData.resolve(context);
          return const SizedBox();
        }),
      ));

      expect(resolved.panelColor, MenuSlideThemeData.fallback().panelColor);
      expect(resolved.panelMaxWidth, MenuSlideThemeData.fallback().panelMaxWidth);
    });
  });
}

/// A foreign [ThemeExtension] used to prove [MenuSlideThemeData.lerp]'s
/// `other is! MenuSlideThemeData` guard is reachable and correct: passing
/// an unrelated extension type must return `this` unchanged rather than
/// throwing or attempting to interpolate incompatible fields.
class _RogueExtension extends ThemeExtension<MenuSlideThemeData> {
  @override
  ThemeExtension<MenuSlideThemeData> copyWith() => _RogueExtension();

  @override
  ThemeExtension<MenuSlideThemeData> lerp(
    covariant ThemeExtension<MenuSlideThemeData>? other,
    double t,
  ) =>
      this;
}
