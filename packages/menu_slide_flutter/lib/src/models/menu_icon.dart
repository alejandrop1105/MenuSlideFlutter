import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

/// Describes how a menu row's leading icon should be built.
///
/// [MenuIcon] is a sealed type with exactly three variants:
/// - [MenuIconData]: a Material [IconData] icon.
/// - [MenuAssetIcon]: an image asset bundled by the host app.
/// - [MenuCustomIcon]: a host-provided [WidgetBuilder] escape hatch.
///
/// [MenuIconData] and [MenuAssetIcon] are JSON-serializable via [toJson] and
/// [MenuIcon.fromJson]. [MenuCustomIcon] is NOT serializable: its [toJson]
/// throws [UnsupportedError] — attempting to persist a host-only widget
/// builder is a programmer error and should fail loudly. In the other
/// direction, [MenuIcon.fromJson] NEVER throws: a `type` discriminator that
/// is missing, malformed, unrecognized, or equal to `"custom"` degrades
/// gracefully to [MenuIcon.fallback], because inbound JSON may originate
/// from an untrusted backend and must not crash the host app.
sealed class MenuIcon {
  const MenuIcon();

  /// The documented placeholder icon returned by [MenuIcon.fromJson] when
  /// the `type` discriminator cannot be resolved to a serializable variant.
  static const MenuIcon fallback = MenuIconData(Icons.help_outline);

  /// Parses a [MenuIcon] from its JSON representation.
  ///
  /// Accepts `Object?` rather than `Map<String, dynamic>` because inbound
  /// data from an untrusted backend may be `null`, malformed, or of an
  /// unexpected runtime type (e.g. a caller doing `MenuIcon.fromJson(
  /// json['icon'])` where the `icon` key is absent). Any non-`Map` value —
  /// including `null` — degrades to [fallback] instead of throwing on an
  /// implicit downcast.
  ///
  /// Reads the `type` discriminator: `"iconData"` builds a [MenuIconData],
  /// `"asset"` builds a [MenuAssetIcon]. Any other value — including
  /// `"custom"` (the non-serializable variant), a missing `type`, or
  /// malformed field values — returns [fallback] instead of throwing.
  factory MenuIcon.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return fallback;
    switch (json['type']) {
      case 'iconData':
        final codePoint = json['codePoint'];
        if (codePoint is! int) return fallback;
        final fontFamily = json['fontFamily'];
        final fontPackage = json['fontPackage'];
        final matchTextDirection = json['matchTextDirection'];
        final fontFamilyFallback = json['fontFamilyFallback'];
        return MenuIconData(
          IconData(
            codePoint,
            fontFamily: fontFamily is String ? fontFamily : null,
            fontPackage: fontPackage is String ? fontPackage : null,
            matchTextDirection: matchTextDirection is bool ? matchTextDirection : false,
            fontFamilyFallback: fontFamilyFallback is List
                ? fontFamilyFallback.cast<String>()
                : null,
          ),
        );
      case 'asset':
        final assetPath = json['assetPath'];
        if (assetPath is! String) return fallback;
        final package = json['package'];
        return MenuAssetIcon(
          assetPath,
          package: package is String ? package : null,
        );
      default:
        // Covers a missing type, an unrecognized type, and "custom" — the
        // non-serializable variant is never reconstructed from JSON.
        return fallback;
    }
  }

  /// Serializes this icon to JSON.
  ///
  /// Throws [UnsupportedError] for [MenuCustomIcon], which wraps a
  /// [WidgetBuilder] closure with no JSON representation.
  Map<String, dynamic> toJson();
}

/// A [MenuIcon] variant backed by a Material [IconData] icon.
///
/// Backend/JSON-driven icons — whose `codePoint` is only known at runtime,
/// e.g. via [MenuIcon.fromJson] — are invisible to Flutter's icon
/// tree-shaker, because the tree-shaker can only see `IconData` constant
/// literals in source code. Release builds (`flutter build`) that serve such
/// icons MUST pass `--no-tree-shake-icons`, otherwise the tree-shaker will
/// strip the font glyphs and the icons will render as missing-glyph boxes.
/// Prefer [MenuAssetIcon] for backend-driven icons when tree-shaking is
/// required.
final class MenuIconData extends MenuIcon {
  const MenuIconData(this.icon);

  /// The Material icon to render.
  final IconData icon;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'iconData',
        'codePoint': icon.codePoint,
        'fontFamily': icon.fontFamily,
        'fontPackage': icon.fontPackage,
        'matchTextDirection': icon.matchTextDirection,
        if (icon.fontFamilyFallback != null)
          'fontFamilyFallback': icon.fontFamilyFallback,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is MenuIconData && other.icon == icon);

  @override
  int get hashCode => icon.hashCode;
}

/// A [MenuIcon] variant backed by an image asset bundled by the host app.
final class MenuAssetIcon extends MenuIcon {
  const MenuAssetIcon(this.assetPath, {this.package});

  /// The asset path passed to [Image.asset].
  final String assetPath;

  /// The package the asset is bundled in, if any.
  final String? package;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'asset',
        'assetPath': assetPath,
        if (package != null) 'package': package,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MenuAssetIcon &&
          other.assetPath == assetPath &&
          other.package == package);

  @override
  int get hashCode => Object.hash(assetPath, package);
}

/// A [MenuIcon] variant that delegates icon rendering to a host-provided
/// [WidgetBuilder]. Host-only escape hatch: NOT serializable.
final class MenuCustomIcon extends MenuIcon {
  const MenuCustomIcon(this.builder);

  /// Builds the icon widget for this menu row.
  final WidgetBuilder builder;

  @override
  Map<String, dynamic> toJson() {
    throw UnsupportedError(
      'MenuCustomIcon cannot be serialized to JSON: it wraps a WidgetBuilder '
      'closure, which has no JSON representation. MenuCustomIcon is a '
      'host-only escape hatch — never construct it from backend/inbound '
      'data, and never attempt to persist it.',
    );
  }
}
