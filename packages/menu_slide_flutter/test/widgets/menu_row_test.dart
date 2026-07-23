import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menu_slide_flutter/menu_slide_flutter.dart';
import 'package:menu_slide_flutter/src/widgets/menu_row.dart';

void main() {
  final theme = MenuSlideThemeData.fallback();

  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('MenuRow', () {
    testWidgets('renders the item label and icon', (tester) async {
      const item = MenuItem(id: 'home', label: 'Home', icon: MenuIconData(Icons.home));

      await tester.pumpWidget(wrap(MenuRow(item: item, isSelected: false, theme: theme)));

      expect(find.text('Home'), findsOneWidget);
      expect(find.byIcon(Icons.home), findsOneWidget);
    });

    testWidgets('renders the badge when item.badge is not null', (tester) async {
      const item = MenuItem(
        id: 'inbox',
        label: 'Inbox',
        icon: MenuIconData(Icons.inbox),
        badge: MenuBadge('3'),
      );

      await tester.pumpWidget(wrap(MenuRow(item: item, isSelected: false, theme: theme)));

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('renders no badge when item.badge is null', (tester) async {
      const item = MenuItem(id: 'home', label: 'Home', icon: MenuIconData(Icons.home));

      await tester.pumpWidget(wrap(MenuRow(item: item, isSelected: false, theme: theme)));

      // Only the label Text is present — no extra badge Text widget.
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('selected row applies the selected icon color', (tester) async {
      const item = MenuItem(id: 'home', label: 'Home', icon: MenuIconData(Icons.home));

      await tester.pumpWidget(wrap(MenuRow(item: item, isSelected: true, theme: theme)));

      final icon = tester.widget<Icon>(find.byIcon(Icons.home));
      expect(icon.color, theme.selectedRowIconColor);
    });

    testWidgets('unselected row applies the non-selected icon color', (tester) async {
      const item = MenuItem(id: 'home', label: 'Home', icon: MenuIconData(Icons.home));

      await tester.pumpWidget(wrap(MenuRow(item: item, isSelected: false, theme: theme)));

      final icon = tester.widget<Icon>(find.byIcon(Icons.home));
      expect(icon.color, theme.rowIconColor);
    });

    testWidgets('disabled row does not invoke onTap when tapped', (tester) async {
      const item =
          MenuItem(id: 'home', label: 'Home', icon: MenuIconData(Icons.home), enabled: false);
      var tapped = false;

      await tester.pumpWidget(wrap(MenuRow(
        item: item,
        isSelected: false,
        theme: theme,
        onTap: () => tapped = true,
      )));

      await tester.tap(find.byType(MenuRow));
      await tester.pump();

      expect(tapped, isFalse);
    });

    testWidgets('disabled row is visually de-emphasized (reduced opacity)', (tester) async {
      const item =
          MenuItem(id: 'home', label: 'Home', icon: MenuIconData(Icons.home), enabled: false);

      await tester.pumpWidget(wrap(MenuRow(item: item, isSelected: false, theme: theme)));

      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, lessThan(1.0));
    });

    testWidgets('enabled row is fully opaque', (tester) async {
      const item = MenuItem(id: 'home', label: 'Home', icon: MenuIconData(Icons.home));

      await tester.pumpWidget(wrap(MenuRow(item: item, isSelected: false, theme: theme)));

      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, 1.0);
    });

    testWidgets('enabled row invokes onTap exactly once when tapped', (tester) async {
      const item = MenuItem(id: 'home', label: 'Home', icon: MenuIconData(Icons.home));
      var tapCount = 0;

      await tester.pumpWidget(wrap(MenuRow(
        item: item,
        isSelected: false,
        theme: theme,
        onTap: () => tapCount++,
      )));

      await tester.tap(find.byType(MenuRow));
      await tester.pump();

      expect(tapCount, 1);
    });

    testWidgets('a very long badge label does not overflow the row', (tester) async {
      const item = MenuItem(
        id: 'inbox',
        label: 'Inbox',
        icon: MenuIconData(Icons.inbox),
        badge: MenuBadge('999999999999999999'),
      );

      await tester.pumpWidget(wrap(
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 200,
            child: MenuRow(item: item, isSelected: false, theme: theme),
          ),
        ),
      ));

      // No RenderFlex/overflow exception should be thrown.
      expect(tester.takeException(), isNull);
    });

    testWidgets('a long item label clips with an ellipsis instead of bleeding',
        (tester) async {
      const item = MenuItem(
        id: 'long',
        label:
            'This is an extremely long menu item label that would never fit on one line',
        icon: MenuIconData(Icons.home),
      );

      await tester.pumpWidget(wrap(
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 160,
            child: MenuRow(item: item, isSelected: false, theme: theme),
          ),
        ),
      ));

      final text = tester.widget<Text>(find.text(item.label));
      expect(text.overflow, TextOverflow.ellipsis);
      expect(text.maxLines, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'selected row recolors BOTH the icon and the label with distinct '
        'selected colors from a probe theme', (tester) async {
      final probeTheme = theme.copyWith(
        rowIconColor: const Color(0xFF111111),
        selectedRowIconColor: const Color(0xFFFF00FF),
        rowTextStyle: const TextStyle(color: Color(0xFF222222)),
      );
      const item = MenuItem(id: 'home', label: 'Home', icon: MenuIconData(Icons.home));

      await tester.pumpWidget(wrap(
        MenuRow(item: item, isSelected: true, theme: probeTheme),
      ));

      final icon = tester.widget<Icon>(find.byIcon(Icons.home));
      final text = tester.widget<Text>(find.text('Home'));

      expect(icon.color, probeTheme.selectedRowIconColor);
      expect(text.style!.color, probeTheme.selectedRowIconColor);
      expect(icon.color, isNot(probeTheme.rowIconColor));
      expect(text.style!.color, isNot(probeTheme.rowTextStyle.color));
    });

    testWidgets('badge chip uses theme.badgeColor when badge.color is null',
        (tester) async {
      const item = MenuItem(
        id: 'inbox',
        label: 'Inbox',
        icon: MenuIconData(Icons.inbox),
        badge: MenuBadge('3'),
      );

      await tester.pumpWidget(wrap(MenuRow(item: item, isSelected: false, theme: theme)));

      final container = tester.widget<Container>(
        find.ancestor(of: find.text('3'), matching: find.byType(Container)).first,
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, theme.badgeColor);
    });

    testWidgets('badge chip uses badge.color when explicitly set', (tester) async {
      const explicitColor = Color(0xFF00FF00);
      const item = MenuItem(
        id: 'inbox',
        label: 'Inbox',
        icon: MenuIconData(Icons.inbox),
        badge: MenuBadge('3', color: explicitColor),
      );

      await tester.pumpWidget(wrap(MenuRow(item: item, isSelected: false, theme: theme)));

      final container = tester.widget<Container>(
        find.ancestor(of: find.text('3'), matching: find.byType(Container)).first,
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, explicitColor);
    });

    // Documentation test: MenuRow performs no defensive check for the
    // disabled+selected combination. Intended visual is the disabled
    // (dimmed/reduced-opacity) treatment layered on top of the selected
    // treatment (selected background/icon/text colors still applied) — the
    // row renders without error rather than the parent needing to special
    // case this combination.
    testWidgets('disabled AND selected renders without error (dimmed + selected treatment)',
        (tester) async {
      const item = MenuItem(
        id: 'home',
        label: 'Home',
        icon: MenuIconData(Icons.home),
        enabled: false,
      );

      await tester.pumpWidget(wrap(MenuRow(item: item, isSelected: true, theme: theme)));

      expect(tester.takeException(), isNull);

      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, lessThan(1.0));

      final icon = tester.widget<Icon>(find.byIcon(Icons.home));
      expect(icon.color, theme.selectedRowIconColor);
    });

    testWidgets('RTL flips the horizontal order of icon, label, and badge',
        (tester) async {
      const item = MenuItem(
        id: 'inbox',
        label: 'Inbox',
        icon: MenuIconData(Icons.inbox),
        badge: MenuBadge('3'),
      );

      Widget wrapRtl(Widget child) => MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(body: child),
            ),
          );

      // LTR order.
      await tester.pumpWidget(wrap(MenuRow(item: item, isSelected: false, theme: theme)));
      final ltrIconX = tester.getCenter(find.byIcon(Icons.inbox)).dx;
      final ltrLabelX = tester.getCenter(find.text('Inbox')).dx;
      final ltrBadgeX = tester.getCenter(find.text('3')).dx;
      expect(ltrIconX, lessThan(ltrLabelX));
      expect(ltrLabelX, lessThan(ltrBadgeX));

      // RTL order should flip.
      await tester.pumpWidget(wrapRtl(MenuRow(item: item, isSelected: false, theme: theme)));
      final rtlIconX = tester.getCenter(find.byIcon(Icons.inbox)).dx;
      final rtlLabelX = tester.getCenter(find.text('Inbox')).dx;
      final rtlBadgeX = tester.getCenter(find.text('3')).dx;
      expect(rtlIconX, greaterThan(rtlLabelX));
      expect(rtlLabelX, greaterThan(rtlBadgeX));
    });
  });
}
