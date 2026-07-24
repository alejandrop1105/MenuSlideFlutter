// `MenuSlideScope` is an `InheritedNotifier<MenuSlideController>` so ANY
// descendant widget of `MenuSlideShell` (the host child, panels, pages) can
// reach the controller without the host threading it through constructors —
// e.g. `MenuSlideScope.of(context).openRight()` from a plain button deep in
// the page tree.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menu_slide_flutter/menu_slide_flutter.dart';

void main() {
  group('MenuSlideScope', () {
    testWidgets(
        'of() resolves the shell\'s controller from a descendant widget and openRight() '
        'opens the right panel', (tester) async {
      final controller = MenuSlideController();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MenuSlideShell(
            controller: controller,
            rightPanel: const Text('Right Panel'),
            child: Builder(
              builder: (context) => ElevatedButton(
                key: const Key('open-right-from-child'),
                onPressed: () => MenuSlideScope.of(context).openRight(),
                child: const Text('Open right'),
              ),
            ),
          ),
        ),
      ));

      expect(controller.isRightOpen, isFalse);

      await tester.tap(find.byKey(const Key('open-right-from-child')));
      await tester.pump();

      expect(controller.isRightOpen, isTrue);
    });

    testWidgets(
        'of() resolves the SAME controller instance passed to the shell',
        (tester) async {
      final controller = MenuSlideController();
      MenuSlideController? resolved;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MenuSlideShell(
            controller: controller,
            child: Builder(
              builder: (context) {
                resolved = MenuSlideScope.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ));

      expect(resolved, same(controller));
    });

    testWidgets('maybeOf() returns null outside a MenuSlideShell',
        (tester) async {
      MenuSlideController? resolved;

      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) {
            resolved = MenuSlideScope.maybeOf(context);
            return const SizedBox.shrink();
          },
        ),
      ));

      expect(resolved, isNull);
    });

    testWidgets('maybeOf() resolves the controller inside a MenuSlideShell',
        (tester) async {
      final controller = MenuSlideController();
      MenuSlideController? resolved;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MenuSlideShell(
            controller: controller,
            child: Builder(
              builder: (context) {
                resolved = MenuSlideScope.maybeOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ));

      expect(resolved, same(controller));
    });
  });
}
