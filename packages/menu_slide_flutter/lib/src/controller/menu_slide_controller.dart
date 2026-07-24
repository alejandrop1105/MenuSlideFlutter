import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;

import '../models/menu_item.dart';

/// Single source of truth for a menu's selection, open/close intent, and
/// theme-mode command.
///
/// [MenuSlideController] carries the `isOpen`/`isRightOpen` state as an
/// INTENT only — it does NOT own an `AnimationController`/`vsync`. Driving
/// the actual reveal animation from that intent is the shell widget's
/// responsibility (a later slice). Likewise, `themeMode` is a value the host
/// applies to its own `ThemeData`/`MaterialApp.themeMode` — the controller
/// never reads `Theme.of(context)` or applies theming itself.
///
/// The left menu (`isOpen`) and the right panel (`isRightOpen`) are
/// MUTUALLY EXCLUSIVE: only one side can be open at a time. This is because
/// the shell's mirrored 3D reveal tilts the whole page toward one side —
/// there is no visual representation for both sides being revealed at once.
/// Opening one side always closes the other as part of the same operation.
class MenuSlideController extends ChangeNotifier {
  MenuSlideController({
    List<MenuItem> items = const [],
    String? initialSelectedItemId,
    bool isOpen = false,
    bool isRightOpen = false,
    ThemeMode themeMode = ThemeMode.system,
  })  : assert(
          !(isOpen && isRightOpen),
          'MenuSlideController cannot start with both isOpen and isRightOpen '
          'true — the two sides are mutually exclusive.',
        ),
        _items = List.unmodifiable(items),
        _isOpen = isOpen,
        _isRightOpen = isRightOpen,
        _themeMode = themeMode,
        _selectedItemId = initialSelectedItemId != null &&
                _findEnabled(items, initialSelectedItemId) != null
            ? initialSelectedItemId
            : null;

  List<MenuItem> _items;
  bool _isOpen;
  bool _isRightOpen;
  ThemeMode _themeMode;
  String? _selectedItemId;

  /// The items currently known to this controller. Unmodifiable.
  List<MenuItem> get items => _items;

  /// The id of the currently selected item, or `null` if none is selected.
  String? get selectedItemId => _selectedItemId;

  /// Whether the LEFT menu panel should be open. This is an INTENT only —
  /// the shell (a later slice) owns the actual animation driving the
  /// reveal. Mutually exclusive with [isRightOpen]: opening the left side
  /// always closes the right side, and vice versa.
  bool get isOpen => _isOpen;

  /// Whether the RIGHT panel should be open. This is an INTENT only — the
  /// shell (a later slice) owns the actual animation driving the reveal.
  /// Mutually exclusive with [isOpen]: opening the right side always closes
  /// the left side, and vice versa, because the shell's mirrored 3D reveal
  /// tilts the page toward one side at a time.
  bool get isRightOpen => _isRightOpen;

  /// The current theme-mode command. The host applies this to its own
  /// `ThemeData`/`ThemeMode` — the controller never applies theming itself.
  ThemeMode get themeMode => _themeMode;

  /// Returns the enabled item matching [id] in [items], or `null` when no
  /// such item exists, or it exists but is disabled.
  ///
  /// If [items] contains duplicate ids, the FIRST match wins: the search
  /// stops at the first item whose `id == id`, returning it (if enabled) or
  /// `null` (if disabled) without inspecting later duplicates.
  static MenuItem? _findEnabled(List<MenuItem> items, String id) {
    for (final item in items) {
      if (item.id == id) {
        return item.enabled ? item : null;
      }
    }
    return null;
  }

  /// Selects the item with the given [id].
  ///
  /// This is a no-op (no state change, no notification) when [id] does not
  /// match any known item, or matches an item with `enabled == false`. This
  /// is how a row tap is delegated: the shell/widget calls this on tap, and
  /// a disabled row's tap never changes selection.
  ///
  /// Idempotent: re-selecting the already-selected [id] is also a no-op (no
  /// notification), matching the idempotency pattern used by [open]/[close].
  void selectItem(String id) {
    if (_selectedItemId == id) return;
    final match = _findEnabled(_items, id);
    if (match == null) return;
    _selectedItemId = id;
    notifyListeners();
  }

  /// Clears the current selection, if any.
  ///
  /// Idempotent: a no-op (no notification) when there is no selection to
  /// clear, matching the idempotency pattern used by [selectItem]/[open]/
  /// [close].
  void clearSelection() {
    if (_selectedItemId == null) return;
    _selectedItemId = null;
    notifyListeners();
  }

  /// Opens the LEFT menu panel intent. Idempotent: a no-op (no
  /// notification, no exception) when the left is already open.
  ///
  /// Enforces mutual exclusivity with the right panel: if [isRightOpen] is
  /// true, it is closed as part of this same operation, with a single
  /// [notifyListeners] call covering both state changes.
  void open() {
    if (_isOpen) return;
    _isOpen = true;
    _isRightOpen = false;
    notifyListeners();
  }

  /// Closes the LEFT menu panel intent. Idempotent: a no-op (no
  /// notification, no exception) when already closed.
  void close() {
    if (!_isOpen) return;
    _isOpen = false;
    notifyListeners();
  }

  /// Flips the LEFT open/closed intent. Opening via [toggle] also enforces
  /// mutual exclusivity with the right panel (see [open]).
  void toggle() {
    if (_isOpen) {
      close();
    } else {
      open();
    }
  }

  /// Opens the RIGHT panel intent. Idempotent: a no-op (no notification, no
  /// exception) when the right is already open.
  ///
  /// Enforces mutual exclusivity with the left menu: if [isOpen] is true,
  /// it is closed as part of this same operation, with a single
  /// [notifyListeners] call covering both state changes.
  void openRight() {
    if (_isRightOpen) return;
    _isRightOpen = true;
    _isOpen = false;
    notifyListeners();
  }

  /// Closes the RIGHT panel intent. Idempotent: a no-op (no notification,
  /// no exception) when already closed.
  void closeRight() {
    if (!_isRightOpen) return;
    _isRightOpen = false;
    notifyListeners();
  }

  /// Flips the RIGHT open/closed intent. Opening via [toggleRight] also
  /// enforces mutual exclusivity with the left menu (see [openRight]).
  void toggleRight() {
    if (_isRightOpen) {
      closeRight();
    } else {
      openRight();
    }
  }

  /// Sets the theme-mode command and notifies listeners. The host is
  /// responsible for applying this value to its own `ThemeData`/
  /// `MaterialApp.themeMode` — the controller never applies theming itself.
  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }

  /// Cycles the theme-mode command between [ThemeMode.light] and
  /// [ThemeMode.dark]. Starting from [ThemeMode.system], this moves to
  /// [ThemeMode.dark].
  void toggleTheme() {
    setThemeMode(_themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }

  /// Replaces the known [items] and notifies listeners.
  ///
  /// If the currently selected item's id is absent from [items], or is
  /// present but now has `enabled == false`, the selection is cleared to
  /// `null`.
  void updateItems(List<MenuItem> items) {
    _items = List.unmodifiable(items);
    if (_selectedItemId != null && _findEnabled(_items, _selectedItemId!) == null) {
      _selectedItemId = null;
    }
    notifyListeners();
  }
}
