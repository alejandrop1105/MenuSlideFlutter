import 'package:flutter/material.dart';

/// Styling and geometry tokens for the `menu_slide_flutter` panel, rows, and
/// diagonal reveal.
///
/// Hosts brand the menu by registering an instance on
/// `ThemeData(extensions: [MenuSlideThemeData(...)])`. When no extension is
/// registered, [MenuSlideThemeData.fallback] supplies the documented
/// default so the shell never crashes or renders unstyled.
///
/// The reveal-geometry magic numbers found in the original sample's
/// diagonal-reveal transform (`home.dart`) are named here and derived from
/// [panelMaxWidth] — see [restTranslateX], [menuButtonShift], and
/// [navShift] — instead of being free-floating literals scattered across
/// widget code.
class MenuSlideThemeData extends ThemeExtension<MenuSlideThemeData> {
  const MenuSlideThemeData({
    required this.panelColor,
    required this.selectedRowColor,
    required this.rowIconColor,
    required this.selectedRowIconColor,
    required this.dividerColor,
    required this.badgeColor,
    required this.badgeTextColor,
    required this.rowTextStyle,
    required this.sectionTitleStyle,
    this.panelMaxWidth = 288,
    this.revealWidth = 265,
    this.panelRadius = 30,
    this.rowHeight = 56,
    this.panelPadding = const EdgeInsets.all(8),
    this.itemSpacing = 0,
  });

  /// Background color of the menu panel.
  final Color panelColor;

  /// Highlight color shown behind the currently-selected row.
  final Color selectedRowColor;

  /// Icon color for non-selected rows.
  final Color rowIconColor;

  /// Icon color for the selected row.
  final Color selectedRowIconColor;

  /// Divider color drawn between rows.
  final Color dividerColor;

  /// Background color of a badge indicator.
  final Color badgeColor;

  /// Text color of a badge indicator's label.
  final Color badgeTextColor;

  /// Text style applied to a row's label.
  final TextStyle rowTextStyle;

  /// Text style applied to a section title.
  final TextStyle sectionTitleStyle;

  /// Maximum width of the menu panel. Also the basis for every derived
  /// reveal-geometry constant below (replaces the sample's magic literal
  /// `288`).
  final double panelMaxWidth;

  /// How far the host page/`child` content shifts horizontally to the right
  /// as the panel opens (`0` when closed, `revealWidth` at fully open).
  /// Applied to the page content being revealed, not the panel itself
  /// (replaces the sample's magic literal `265`).
  final double revealWidth;

  /// Corner radius of the menu panel (replaces the sample's magic literal
  /// `30`).
  final double panelRadius;

  /// Height of a single menu row (replaces the sample's magic literal `56`).
  final double rowHeight;

  /// Padding applied around the panel's content.
  final EdgeInsetsGeometry panelPadding;

  /// Spacing between consecutive rows/sections.
  final double itemSpacing;

  /// The menu **panel**'s own horizontal translation at rest (panel fully
  /// parked off-screen to the left, menu closed). Slides to `0` as the
  /// panel opens. Derived from [panelMaxWidth] so the parked position
  /// always clears the panel; replaces the sample's magic literal `-300`
  /// (`-(288 + 12)`).
  double get restTranslateX => -(panelMaxWidth + 12);

  /// Horizontal shift (spacer width) applied within the menu-button row as
  /// the panel opens (`0` when closed, `menuButtonShift` at fully open).
  /// Derived from [panelMaxWidth]; replaces the sample's magic literal `216`
  /// (`288 - 72`).
  double get menuButtonShift => panelMaxWidth - 72;

  /// Vertical downward shift applied to the bottom navigation bar as the
  /// panel opens (`0` when closed, `navShift` at fully open). Derived from
  /// [panelMaxWidth]; replaces the sample's magic literal `300`
  /// (`288 + 12`).
  double get navShift => panelMaxWidth + 12;

  /// The documented default theme, used when no [MenuSlideThemeData] is
  /// registered on the host `ThemeData.extensions`. Values are ported from
  /// the original `rive_app` sample (`RiveAppTheme`, `side_menu.dart`,
  /// `menu_row.dart`) so the menu looks reasonable out of the box.
  factory MenuSlideThemeData.fallback() => const MenuSlideThemeData(
        panelColor: Color(0xFF17203A),
        selectedRowColor: Colors.blue,
        rowIconColor: Color(0x99FFFFFF),
        selectedRowIconColor: Colors.white,
        dividerColor: Color(0x1AFFFFFF),
        badgeColor: Color(0xFF5E9EFF),
        badgeTextColor: Colors.white,
        rowTextStyle: TextStyle(
          color: Colors.white,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 17,
        ),
        sectionTitleStyle: TextStyle(
          color: Color(0xB3FFFFFF),
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      );

  /// Resolves the effective theme for [context]: an explicit per-instance
  /// [override] wins, then a registered `ThemeData.extensions` entry, then
  /// [MenuSlideThemeData.fallback]. Never returns null and never throws.
  static MenuSlideThemeData resolve(BuildContext context, [MenuSlideThemeData? override]) {
    return override ??
        Theme.of(context).extension<MenuSlideThemeData>() ??
        MenuSlideThemeData.fallback();
  }

  @override
  MenuSlideThemeData copyWith({
    Color? panelColor,
    Color? selectedRowColor,
    Color? rowIconColor,
    Color? selectedRowIconColor,
    Color? dividerColor,
    Color? badgeColor,
    Color? badgeTextColor,
    TextStyle? rowTextStyle,
    TextStyle? sectionTitleStyle,
    double? panelMaxWidth,
    double? revealWidth,
    double? panelRadius,
    double? rowHeight,
    EdgeInsetsGeometry? panelPadding,
    double? itemSpacing,
  }) {
    return MenuSlideThemeData(
      panelColor: panelColor ?? this.panelColor,
      selectedRowColor: selectedRowColor ?? this.selectedRowColor,
      rowIconColor: rowIconColor ?? this.rowIconColor,
      selectedRowIconColor: selectedRowIconColor ?? this.selectedRowIconColor,
      dividerColor: dividerColor ?? this.dividerColor,
      badgeColor: badgeColor ?? this.badgeColor,
      badgeTextColor: badgeTextColor ?? this.badgeTextColor,
      rowTextStyle: rowTextStyle ?? this.rowTextStyle,
      sectionTitleStyle: sectionTitleStyle ?? this.sectionTitleStyle,
      panelMaxWidth: panelMaxWidth ?? this.panelMaxWidth,
      revealWidth: revealWidth ?? this.revealWidth,
      panelRadius: panelRadius ?? this.panelRadius,
      rowHeight: rowHeight ?? this.rowHeight,
      panelPadding: panelPadding ?? this.panelPadding,
      itemSpacing: itemSpacing ?? this.itemSpacing,
    );
  }

  @override
  MenuSlideThemeData lerp(ThemeExtension<MenuSlideThemeData>? other, double t) {
    if (other is! MenuSlideThemeData) return this;
    return MenuSlideThemeData(
      panelColor: Color.lerp(panelColor, other.panelColor, t)!,
      selectedRowColor: Color.lerp(selectedRowColor, other.selectedRowColor, t)!,
      rowIconColor: Color.lerp(rowIconColor, other.rowIconColor, t)!,
      selectedRowIconColor: Color.lerp(selectedRowIconColor, other.selectedRowIconColor, t)!,
      dividerColor: Color.lerp(dividerColor, other.dividerColor, t)!,
      badgeColor: Color.lerp(badgeColor, other.badgeColor, t)!,
      badgeTextColor: Color.lerp(badgeTextColor, other.badgeTextColor, t)!,
      rowTextStyle: TextStyle.lerp(rowTextStyle, other.rowTextStyle, t)!,
      sectionTitleStyle: TextStyle.lerp(sectionTitleStyle, other.sectionTitleStyle, t)!,
      panelMaxWidth: _lerpDouble(panelMaxWidth, other.panelMaxWidth, t),
      revealWidth: _lerpDouble(revealWidth, other.revealWidth, t),
      panelRadius: _lerpDouble(panelRadius, other.panelRadius, t),
      rowHeight: _lerpDouble(rowHeight, other.rowHeight, t),
      panelPadding: EdgeInsetsGeometry.lerp(panelPadding, other.panelPadding, t)!,
      itemSpacing: _lerpDouble(itemSpacing, other.itemSpacing, t),
    );
  }

  static double _lerpDouble(double a, double b, double t) => a + (b - a) * t;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MenuSlideThemeData &&
        other.panelColor == panelColor &&
        other.selectedRowColor == selectedRowColor &&
        other.rowIconColor == rowIconColor &&
        other.selectedRowIconColor == selectedRowIconColor &&
        other.dividerColor == dividerColor &&
        other.badgeColor == badgeColor &&
        other.badgeTextColor == badgeTextColor &&
        other.rowTextStyle == rowTextStyle &&
        other.sectionTitleStyle == sectionTitleStyle &&
        other.panelMaxWidth == panelMaxWidth &&
        other.revealWidth == revealWidth &&
        other.panelRadius == panelRadius &&
        other.rowHeight == rowHeight &&
        other.panelPadding == panelPadding &&
        other.itemSpacing == itemSpacing;
  }

  @override
  int get hashCode => Object.hash(
        panelColor,
        selectedRowColor,
        rowIconColor,
        selectedRowIconColor,
        dividerColor,
        badgeColor,
        badgeTextColor,
        rowTextStyle,
        sectionTitleStyle,
        panelMaxWidth,
        revealWidth,
        panelRadius,
        rowHeight,
        panelPadding,
        itemSpacing,
      );
}
