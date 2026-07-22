import 'package:flutter/material.dart' show Icons, ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:menu_slide_flutter/menu_slide_flutter.dart';

/// Test-only counter that tracks how many times a [MenuSlideController]
/// notified its listeners, so scenarios can assert exact notification
/// counts (including "no notification at all").
class _NotificationCounter {
  _NotificationCounter(this._controller) {
    _controller.addListener(_onNotify);
  }

  final MenuSlideController _controller;
  int count = 0;

  void _onNotify() => count++;

  void dispose() => _controller.removeListener(_onNotify);
}

const _home = MenuItem(id: 'home', label: 'Home', icon: MenuIconData(Icons.home));
const _settings = MenuItem(id: 'settings', label: 'Settings', icon: MenuIconData(Icons.settings));
const _disabled = MenuItem(
  id: 'disabled',
  label: 'Disabled',
  icon: MenuIconData(Icons.block),
  enabled: false,
);

void main() {
  group('MenuSlideController default state', () {
    test('selectedItemId is null, isOpen is false, themeMode is system when unset', () {
      final controller = MenuSlideController();

      expect(controller.selectedItemId, isNull);
      expect(controller.isOpen, isFalse);
      expect(controller.themeMode, ThemeMode.system);
      expect(controller.items, isEmpty);
    });

    test('honors initialSelectedItemId when it maps to an existing enabled item', () {
      final controller = MenuSlideController(
        items: const [_home, _settings],
        initialSelectedItemId: 'settings',
      );

      expect(controller.selectedItemId, 'settings');
    });

    test('ignores initialSelectedItemId that does not match any item', () {
      final controller = MenuSlideController(
        items: const [_home, _settings],
        initialSelectedItemId: 'does-not-exist',
      );

      expect(controller.selectedItemId, isNull);
    });

    test('ignores initialSelectedItemId that maps to a disabled item', () {
      final controller = MenuSlideController(
        items: const [_home, _disabled],
        initialSelectedItemId: 'disabled',
      );

      expect(controller.selectedItemId, isNull);
    });

    test('honors an explicit initial isOpen and themeMode', () {
      final controller = MenuSlideController(isOpen: true, themeMode: ThemeMode.dark);

      expect(controller.isOpen, isTrue);
      expect(controller.themeMode, ThemeMode.dark);
    });

    test('items getter is unmodifiable: mutating it throws UnsupportedError', () {
      final controller = MenuSlideController(items: const [_home, _settings]);

      expect(() => controller.items.add(_disabled), throwsUnsupportedError);
    });

    test('defensive copy: mutating the original list after construction does not affect items', () {
      final original = [_home, _settings];
      final controller = MenuSlideController(items: original);

      original.add(_disabled);

      expect(controller.items, const [_home, _settings]);
    });
  });

  group('MenuSlideController.selectItem', () {
    test('valid enabled selection updates selectedItemId and notifies exactly once', () {
      final controller = MenuSlideController(items: const [_home, _settings]);
      final counter = _NotificationCounter(controller);

      controller.selectItem('home');

      expect(controller.selectedItemId, 'home');
      expect(counter.count, 1);
    });

    test('unknown id is a no-op: selection unchanged, no notification', () {
      final controller = MenuSlideController(items: const [_home, _settings]);
      final counter = _NotificationCounter(controller);

      controller.selectItem('does-not-exist');

      expect(controller.selectedItemId, isNull);
      expect(counter.count, 0);
    });

    test('disabled item selection is a no-op: selection unchanged, no notification', () {
      final controller = MenuSlideController(items: const [_home, _disabled]);
      final counter = _NotificationCounter(controller);

      controller.selectItem('disabled');

      expect(controller.selectedItemId, isNull);
      expect(counter.count, 0);
    });

    test('re-selecting the already-selected id is idempotent: no notification', () {
      final controller = MenuSlideController(items: const [_home, _settings]);
      controller.selectItem('home');
      final counter = _NotificationCounter(controller);

      controller.selectItem('home');

      expect(controller.selectedItemId, 'home');
      expect(counter.count, 0);
    });

    test('empty-string id is a no-op: no match, no notification', () {
      final controller = MenuSlideController(items: const [_home, _settings]);
      final counter = _NotificationCounter(controller);

      controller.selectItem('');

      expect(controller.selectedItemId, isNull);
      expect(counter.count, 0);
    });

    test('duplicate ids: first match wins for selection', () {
      const firstHome = MenuItem(id: 'home', label: 'First Home', icon: MenuIconData(Icons.home));
      const secondHome = MenuItem(id: 'home', label: 'Second Home', icon: MenuIconData(Icons.home));
      final controller = MenuSlideController(items: const [firstHome, secondHome]);

      controller.selectItem('home');

      expect(controller.selectedItemId, 'home');
    });

    test('duplicate ids where both are disabled: selection is not made', () {
      const firstDisabled = MenuItem(
        id: 'home',
        label: 'First Home',
        icon: MenuIconData(Icons.home),
        enabled: false,
      );
      const secondDisabled = MenuItem(
        id: 'home',
        label: 'Second Home',
        icon: MenuIconData(Icons.home),
        enabled: false,
      );
      final controller = MenuSlideController(items: const [firstDisabled, secondDisabled]);
      final counter = _NotificationCounter(controller);

      controller.selectItem('home');

      expect(controller.selectedItemId, isNull);
      expect(counter.count, 0);
    });
  });

  group('MenuSlideController open/close/toggle', () {
    test('open() from closed sets isOpen true and notifies', () {
      final controller = MenuSlideController();
      final counter = _NotificationCounter(controller);

      controller.open();

      expect(controller.isOpen, isTrue);
      expect(counter.count, 1);
    });

    test('close() from open sets isOpen false and notifies', () {
      final controller = MenuSlideController(isOpen: true);
      final counter = _NotificationCounter(controller);

      controller.close();

      expect(controller.isOpen, isFalse);
      expect(counter.count, 1);
    });

    test('open() is idempotent when already open: no exception, no notification', () {
      final controller = MenuSlideController(isOpen: true);
      final counter = _NotificationCounter(controller);

      expect(() => controller.open(), returnsNormally);

      expect(controller.isOpen, isTrue);
      expect(counter.count, 0);
    });

    test('close() is idempotent when already closed: no exception, no notification', () {
      final controller = MenuSlideController();
      final counter = _NotificationCounter(controller);

      expect(() => controller.close(), returnsNormally);

      expect(controller.isOpen, isFalse);
      expect(counter.count, 0);
    });

    test('toggle() flips isOpen true then false, notifying each time', () {
      final controller = MenuSlideController();
      final counter = _NotificationCounter(controller);

      controller.toggle();
      expect(controller.isOpen, isTrue);

      controller.toggle();
      expect(controller.isOpen, isFalse);

      expect(counter.count, 2);
    });
  });

  group('MenuSlideController theme-mode command', () {
    test('setThemeMode updates themeMode and notifies', () {
      final controller = MenuSlideController();
      final counter = _NotificationCounter(controller);

      controller.setThemeMode(ThemeMode.dark);

      expect(controller.themeMode, ThemeMode.dark);
      expect(counter.count, 1);
    });

    test('toggleTheme cycles from system to dark and notifies', () {
      final controller = MenuSlideController();
      final counter = _NotificationCounter(controller);

      controller.toggleTheme();

      expect(controller.themeMode, ThemeMode.dark);
      expect(counter.count, 1);
    });

    test('toggleTheme flips dark to light and notifies', () {
      final controller = MenuSlideController(themeMode: ThemeMode.dark);
      final counter = _NotificationCounter(controller);

      controller.toggleTheme();

      expect(controller.themeMode, ThemeMode.light);
      expect(counter.count, 1);
    });
  });

  group('MenuSlideController.updateItems', () {
    test('replaces the items list and notifies', () {
      final controller = MenuSlideController(items: const [_home]);
      final counter = _NotificationCounter(controller);

      controller.updateItems(const [_home, _settings]);

      expect(controller.items, const [_home, _settings]);
      expect(counter.count, 1);
    });

    test('clears selection when the selected item disappears from the new list', () {
      final controller = MenuSlideController(items: const [_home, _settings]);
      controller.selectItem('home');
      final counter = _NotificationCounter(controller);

      controller.updateItems(const [_settings]);

      expect(controller.selectedItemId, isNull);
      expect(counter.count, 1);
    });

    test('clears selection when the selected item becomes disabled in the new list', () {
      final controller = MenuSlideController(items: const [_home, _settings]);
      controller.selectItem('home');
      final counter = _NotificationCounter(controller);

      const disabledHome = MenuItem(
        id: 'home',
        label: 'Home',
        icon: MenuIconData(Icons.home),
        enabled: false,
      );
      controller.updateItems(const [disabledHome, _settings]);

      expect(controller.selectedItemId, isNull);
      expect(counter.count, 1);
    });

    test('keeps selection when the selected item is still present and enabled', () {
      final controller = MenuSlideController(items: const [_home, _settings]);
      controller.selectItem('home');
      final counter = _NotificationCounter(controller);

      controller.updateItems(const [_home, _settings]);

      expect(controller.selectedItemId, 'home');
      expect(counter.count, 1);
    });

    test('empty new list while a selection existed clears selection and notifies exactly once', () {
      final controller = MenuSlideController(items: const [_home, _settings]);
      controller.selectItem('home');
      final counter = _NotificationCounter(controller);

      controller.updateItems(const []);

      expect(controller.items, isEmpty);
      expect(controller.selectedItemId, isNull);
      expect(counter.count, 1);
    });

    test('defensive copy: mutating the original list after updateItems does not affect items', () {
      final controller = MenuSlideController(items: const [_home]);
      final replacement = [_settings];

      controller.updateItems(replacement);
      replacement.add(_disabled);

      expect(controller.items, const [_settings]);
    });
  });
}
