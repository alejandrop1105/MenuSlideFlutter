import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menu_slide_flutter/menu_slide_flutter.dart';

void main() {
  group('MenuIconData', () {
    test('holds the given IconData', () {
      const icon = MenuIconData(Icons.home);

      expect(icon.icon, Icons.home);
    });

    test('round-trips through toJson/fromJson', () {
      const original = MenuIconData(Icons.home);

      final json = original.toJson();
      final parsed = MenuIcon.fromJson(json);

      expect(parsed, isA<MenuIconData>());
      expect(parsed, original);
    });

    test('toJson carries the "iconData" type discriminator', () {
      const icon = MenuIconData(Icons.home);

      final json = icon.toJson();

      expect(json['type'], 'iconData');
    });

    test('round-trips a directional icon preserving matchTextDirection', () {
      const original = MenuIconData(Icons.arrow_back);

      final json = original.toJson();
      final parsed = MenuIcon.fromJson(json);

      expect(parsed, isA<MenuIconData>());
      expect(parsed, original);
      expect((parsed as MenuIconData).icon.matchTextDirection, isTrue);
    });

    test('round-trips full IconData fidelity: fontPackage, '
        'matchTextDirection, fontFamilyFallback', () {
      const original = MenuIconData(
        IconData(
          0xe000,
          fontFamily: 'X',
          fontPackage: 'p',
          matchTextDirection: true,
          fontFamilyFallback: ['A', 'B'],
        ),
      );

      final json = original.toJson();
      final parsed = MenuIcon.fromJson(json);

      expect(parsed, original);
    });
  });

  group('MenuAssetIcon', () {
    test('holds the given asset path and optional package', () {
      const icon = MenuAssetIcon('assets/icons/home.png', package: 'my_pkg');

      expect(icon.assetPath, 'assets/icons/home.png');
      expect(icon.package, 'my_pkg');
    });

    test('package defaults to null when not provided', () {
      const icon = MenuAssetIcon('assets/icons/home.png');

      expect(icon.package, isNull);
    });

    test('round-trips through toJson/fromJson', () {
      const original = MenuAssetIcon('assets/icons/home.png', package: 'my_pkg');

      final json = original.toJson();
      final parsed = MenuIcon.fromJson(json);

      expect(parsed, isA<MenuAssetIcon>());
      expect(parsed, original);
    });

    test('round-trips without a package', () {
      const original = MenuAssetIcon('assets/icons/home.png');

      final json = original.toJson();
      final parsed = MenuIcon.fromJson(json);

      expect(parsed, original);
    });

    test('toJson carries the "asset" type discriminator', () {
      const icon = MenuAssetIcon('assets/icons/home.png');

      final json = icon.toJson();

      expect(json['type'], 'asset');
    });
  });

  group('MenuCustomIcon', () {
    test('holds the given builder', () {
      Widget builder(BuildContext context) => const SizedBox();
      final icon = MenuCustomIcon(builder);

      expect(icon.builder, builder);
    });

    test('toJson throws UnsupportedError', () {
      final icon = MenuCustomIcon((context) => const SizedBox());

      expect(() => icon.toJson(), throwsUnsupportedError);
    });
  });

  group('MenuIcon.fromJson — type discriminator', () {
    test('type "iconData" returns a MenuIconData instance', () {
      final parsed = MenuIcon.fromJson(const {
        'type': 'iconData',
        'codePoint': 0xe318,
        'fontFamily': 'MaterialIcons',
      });

      expect(parsed, isA<MenuIconData>());
    });

    test('type "asset" returns a MenuAssetIcon instance', () {
      final parsed = MenuIcon.fromJson(const {
        'type': 'asset',
        'assetPath': 'assets/icons/home.png',
      });

      expect(parsed, isA<MenuAssetIcon>());
    });
  });

  group('MenuIcon.fromJson — graceful degradation (no-crash contract)', () {
    test('type "custom" does not attempt WidgetBuilder reconstruction and '
        'returns the documented fallback', () {
      final parsed = MenuIcon.fromJson(const {'type': 'custom'});

      expect(parsed, MenuIcon.fallback);
    });

    test('unknown/unrecognized type returns the documented fallback', () {
      final parsed = MenuIcon.fromJson(const {'type': 'not-a-real-type'});

      expect(parsed, MenuIcon.fallback);
    });

    test('missing type returns the documented fallback', () {
      final parsed = MenuIcon.fromJson(const <String, dynamic>{});

      expect(parsed, MenuIcon.fallback);
    });

    test('malformed iconData (non-int codePoint) returns the documented '
        'fallback instead of throwing', () {
      final parsed = MenuIcon.fromJson(const {
        'type': 'iconData',
        'codePoint': 'not-an-int',
      });

      expect(parsed, MenuIcon.fallback);
    });

    test('malformed asset (missing assetPath) returns the documented '
        'fallback instead of throwing', () {
      final parsed = MenuIcon.fromJson(const <String, dynamic>{'type': 'asset'});

      expect(parsed, MenuIcon.fallback);
    });

    test('null input returns the documented fallback instead of throwing', () {
      final parsed = MenuIcon.fromJson(null);

      expect(parsed, MenuIcon.fallback);
    });

    test('non-Map String input returns the documented fallback instead of '
        'throwing', () {
      final parsed = MenuIcon.fromJson('not a map');

      expect(parsed, MenuIcon.fallback);
    });

    test('non-Map int input returns the documented fallback instead of '
        'throwing', () {
      final parsed = MenuIcon.fromJson(42);

      expect(parsed, MenuIcon.fallback);
    });

    test('missing key lookup on an outer map (json["icon"] is null) returns '
        'the documented fallback instead of throwing', () {
      final outer = <String, dynamic>{'label': 'x'};

      final parsed = MenuIcon.fromJson(outer['icon']);

      expect(parsed, MenuIcon.fallback);
    });
  });

  group('MenuIcon — collection semantics (Set/Map key)', () {
    test('MenuIconData dedupes equal icons and distinguishes different ones '
        'as Set members', () {
      final icons = <MenuIcon>{}
        ..add(const MenuIconData(Icons.home))
        ..add(MenuIcon.fromJson(const MenuIconData(Icons.home).toJson()))
        ..add(const MenuIconData(Icons.settings));

      expect(icons.length, 2);
      expect(icons, contains(const MenuIconData(Icons.home)));
      expect(icons, contains(const MenuIconData(Icons.settings)));
    });

    test('MenuAssetIcon dedupes equal icons and distinguishes different ones '
        'as Set members', () {
      const home = MenuAssetIcon('assets/icons/home.png', package: 'my_pkg');
      final icons = <MenuIcon>{}
        ..add(home)
        ..add(MenuIcon.fromJson(home.toJson()))
        ..add(const MenuAssetIcon('assets/icons/settings.png', package: 'my_pkg'));

      expect(icons.length, 2);
    });
  });

  group('MenuAssetIcon — additional round-trip coverage', () {
    test('round-trips with a non-null package', () {
      const original = MenuAssetIcon('assets/icons/home.png', package: 'my_pkg');

      final json = original.toJson();
      final parsed = MenuIcon.fromJson(json);

      expect(parsed, isA<MenuAssetIcon>());
      expect(parsed, original);
      expect((parsed as MenuAssetIcon).package, 'my_pkg');
    });
  });
}
