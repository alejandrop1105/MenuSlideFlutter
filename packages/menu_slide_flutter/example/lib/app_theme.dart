import 'package:flutter/material.dart';
import 'package:menu_slide_flutter/menu_slide_flutter.dart';

/// The host app's light and dark `ThemeData`, each registering its own
/// branded [MenuSlideThemeData] via `ThemeData.extensions`.
///
/// This is what makes the menu panel itself rebrand when the app switches
/// between light and dark — not just the host's own pages. Colors are
/// derived from `ColorScheme.fromSeed`, so a single seed color drives a
/// coherent Material 3 palette for both the app and the menu.
class AppTheme {
  const AppTheme._();

  static const _seed = Color(0xFF3D5AFE);

  static ThemeData get light => _themeFor(Brightness.light);

  static ThemeData get dark => _themeFor(Brightness.dark);

  static ThemeData _themeFor(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        indicatorColor: colorScheme.primaryContainer,
      ),
      extensions: [
        MenuSlideThemeData(
          panelColor: colorScheme.surfaceContainerHigh,
          selectedRowColor: colorScheme.primaryContainer,
          rowIconColor: colorScheme.onSurfaceVariant,
          selectedRowIconColor: colorScheme.onPrimaryContainer,
          dividerColor: colorScheme.outlineVariant,
          badgeColor: colorScheme.primary,
          badgeTextColor: colorScheme.onPrimary,
          rowTextStyle: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          sectionTitleStyle: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}
