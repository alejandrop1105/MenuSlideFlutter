import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menu_slide_flutter/src/models/menu_fallback_icon.dart';
import 'package:menu_slide_flutter/src/models/menu_icon.dart';
import 'package:menu_slide_flutter/src/widgets/menu_icon_view.dart';

void main() {
  group('MenuIconView', () {
    testWidgets('MenuIconData renders an Icon with the given IconData/color/size',
        (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MenuIconView(
            icon: MenuIconData(Icons.home),
            color: Colors.red,
            size: 24,
          ),
        ),
      );

      final iconWidget = tester.widget<Icon>(find.byType(Icon));
      expect(iconWidget.icon, Icons.home);
      expect(iconWidget.color, Colors.red);
      expect(iconWidget.size, 24);
    });

    testWidgets('MenuAssetIcon renders an Image with the given asset', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MenuIconView(
            icon: MenuAssetIcon('assets/icons/does_not_exist.png'),
            color: Colors.blue,
            size: 32,
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets(
        'MenuAssetIcon falls back to the documented placeholder when the asset '
        'fails to load', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MenuIconView(
            icon: MenuAssetIcon('assets/icons/does_not_exist.png'),
            color: Colors.blue,
            size: 32,
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.errorBuilder, isNotNull,
          reason: 'MenuIconView must supply an errorBuilder so a missing '
              'asset degrades gracefully instead of crashing.');

      // Invoke the widget's own errorBuilder directly with a synthetic
      // load failure — this is exactly the path Flutter's Image widget
      // takes internally once the real (engine-level) asset load rejects,
      // so this asserts our fallback contract deterministically without
      // depending on real native asset-loading I/O timing inside the test
      // harness.
      final fallback = image.errorBuilder!(
        tester.element(find.byType(Image)),
        Exception('synthetic asset load failure'),
        StackTrace.empty,
      );
      await tester.pumpWidget(
        Directionality(textDirection: TextDirection.ltr, child: fallback),
      );

      // The widget-layer fallback must use the SAME single shared glyph as
      // the model-layer fallback (MenuIcon.fallback) — spec assumption #4.
      expect(find.byIcon(kMenuFallbackIcon), findsOneWidget);
    });

    testWidgets("MenuCustomIcon renders the builder's widget", (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MenuIconView(
            icon: MenuCustomIcon(
              (context) => const Icon(Icons.star, key: Key('custom-icon')),
            ),
            color: Colors.green,
            size: 20,
          ),
        ),
      );

      expect(find.byKey(const Key('custom-icon')), findsOneWidget);
    });
  });
}
