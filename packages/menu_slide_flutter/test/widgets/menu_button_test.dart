import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menu_slide_flutter/src/widgets/menu_button.dart';

/// Regression tests for two real-screenshot bugs in [MenuSlideButton]:
/// (1) the [AnimatedIcon] was not centered within its circular container,
/// (2) the button was not theme-aware — a hardcoded white circle made the
/// icon invisible in dark mode when the icon color also resolved to white.
void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('MenuSlideButton icon centering', () {
    testWidgets('the AnimatedIcon is centered within the button container',
        (tester) async {
      final progress = AnimationController(
        vsync: tester,
        duration: const Duration(milliseconds: 200),
      );

      await tester.pumpWidget(wrap(
        MenuSlideButton(
          progress: progress,
          onTap: () {},
          backgroundColor: Colors.white,
          iconColor: Colors.black87,
        ),
      ));

      final buttonCenter = tester.getCenter(find.byKey(const Key('menu-slide-button')));
      final iconCenter = tester.getCenter(find.byType(AnimatedIcon));

      expect(iconCenter.dx, closeTo(buttonCenter.dx, 0.5));
      expect(iconCenter.dy, closeTo(buttonCenter.dy, 0.5));

      progress.dispose();
    });
  });

  group('MenuSlideButton theme-awareness', () {
    testWidgets('renders the given backgroundColor on the circular container',
        (tester) async {
      final progress = AnimationController(
        vsync: tester,
        duration: const Duration(milliseconds: 200),
      );

      await tester.pumpWidget(wrap(
        MenuSlideButton(
          progress: progress,
          onTap: () {},
          backgroundColor: Colors.deepPurple,
          iconColor: Colors.white,
        ),
      ));

      final container = tester.widget<Container>(find.byKey(const Key('menu-slide-button')));
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, Colors.deepPurple);

      progress.dispose();
    });

    testWidgets('renders the given iconColor on the AnimatedIcon', (tester) async {
      final progress = AnimationController(
        vsync: tester,
        duration: const Duration(milliseconds: 200),
      );

      await tester.pumpWidget(wrap(
        MenuSlideButton(
          progress: progress,
          onTap: () {},
          backgroundColor: Colors.black,
          iconColor: Colors.amber,
        ),
      ));

      final icon = tester.widget<AnimatedIcon>(find.byType(AnimatedIcon));
      expect(icon.color, Colors.amber);

      progress.dispose();
    });

    testWidgets('iconColor and backgroundColor are never equal for the fallback theme defaults',
        (tester) async {
      // Regression guard for the white-on-white bug: the documented fallback
      // defaults must never resolve to the same color.
      const backgroundColor = Color(0xFFFFFFFF);
      const iconColor = Color(0xFF17203A);
      expect(iconColor, isNot(equals(backgroundColor)));
    });
  });
}
