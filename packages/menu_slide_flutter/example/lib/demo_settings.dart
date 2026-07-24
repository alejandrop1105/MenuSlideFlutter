import 'package:flutter/material.dart';

/// Live, host-owned overrides for the demo's menu theming and layout,
/// driven entirely by [ConfigurationPage]'s controls and observed by
/// `DemoApp`/`DemoHome` to rebuild with the new values.
///
/// [menuColor]/[backdropColor] start as `null` ("no override yet"), so
/// switching between `AppTheme.light`/`AppTheme.dark` keeps auto-rebranding
/// the menu panel exactly as it did before this feature existed — an
/// override only takes effect once the host explicitly picks a color on the
/// Configuration page, and it then sticks across light/dark toggles because
/// an explicit choice wins over the mode default.
class DemoSettings extends ChangeNotifier {
  Color? _menuColor;

  /// Explicit menu-panel color override, or `null` to use the active app
  /// theme's mode-appropriate panel color.
  Color? get menuColor => _menuColor;

  set menuColor(Color? value) {
    if (value == _menuColor) return;
    _menuColor = value;
    notifyListeners();
  }

  Color? _backdropColor;

  /// Explicit shell-backdrop color override, or `null` to use the active
  /// app theme's mode-appropriate backdrop color.
  Color? get backdropColor => _backdropColor;

  set backdropColor(Color? value) {
    if (value == _backdropColor) return;
    _backdropColor = value;
    notifyListeners();
  }

  bool _fullScreenMenu = false;

  /// When `true`, the bottom `NavigationBar` is composed INSIDE the menu
  /// shell's `child` so the diagonal reveal covers the full screen height.
  /// When `false` (default), the bar stays outside as
  /// `Scaffold.bottomNavigationBar`, bounding the menu above it.
  bool get fullScreenMenu => _fullScreenMenu;

  set fullScreenMenu(bool value) {
    if (value == _fullScreenMenu) return;
    _fullScreenMenu = value;
    notifyListeners();
  }

  String? _backdropImageAsset;

  /// Asset path (bundled under `assets/backdrops/`, this app's own package —
  /// no `package:` prefix needed) painted on the shell backdrop, or `null`
  /// (the default) for no image.
  String? get backdropImageAsset => _backdropImageAsset;

  set backdropImageAsset(String? value) {
    if (value == _backdropImageAsset) return;
    _backdropImageAsset = value;
    notifyListeners();
  }

  double _backdropBlur = 0;

  /// Gaussian blur sigma (0..20) applied to the shell backdrop.
  double get backdropBlur => _backdropBlur;

  set backdropBlur(double value) {
    if (value == _backdropBlur) return;
    _backdropBlur = value;
    notifyListeners();
  }

  double _backdropOpacity = 1;

  /// Opacity (0..1) applied to the shell backdrop.
  double get backdropOpacity => _backdropOpacity;

  set backdropOpacity(double value) {
    if (value == _backdropOpacity) return;
    _backdropOpacity = value;
    notifyListeners();
  }

  double _revealFactor = 0.6;

  /// Percentage (0.3..0.9) of the viewport width the host page shifts by
  /// while the menu is open — a RESPONSIVE (percentage-based) menu/page
  /// separation, applied via `MenuSlideThemeData.revealWidthFactor`.
  double get revealFactor => _revealFactor;

  set revealFactor(double value) {
    if (value == _revealFactor) return;
    _revealFactor = value;
    notifyListeners();
  }
}
