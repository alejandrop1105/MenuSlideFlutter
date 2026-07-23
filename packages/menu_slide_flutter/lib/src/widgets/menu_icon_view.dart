import 'package:flutter/material.dart';

import '../models/menu_fallback_icon.dart';
import '../models/menu_icon.dart';

/// Renders a [MenuIcon] as a widget, switching exhaustively on its sealed
/// variant.
///
/// - [MenuIconData] renders as an [Icon].
/// - [MenuAssetIcon] renders as an [Image.asset]; when the asset cannot be
///   resolved (missing/unbundled), the documented fallback placeholder
///   renders instead via `errorBuilder` — this NEVER crashes, unlike the
///   original sample's force-unwrapped Rive controller.
/// - [MenuCustomIcon] delegates directly to its `builder`.
///
/// [MenuIconView] is a private implementation detail of the package (not
/// exported via the barrel) — it is consumed by `MenuRow`.
class MenuIconView extends StatelessWidget {
  const MenuIconView({
    super.key,
    required this.icon,
    required this.color,
    required this.size,
  });

  /// The icon to render.
  final MenuIcon icon;

  /// Tint color applied to [MenuIconData] and to the fallback placeholder.
  /// Not applied to [MenuAssetIcon] — raster assets are not tinted by
  /// default.
  final Color color;

  /// Width/height of the rendered icon.
  final double size;

  @override
  Widget build(BuildContext context) {
    return switch (icon) {
      MenuIconData(icon: final iconData) => Icon(iconData, color: color, size: size),
      MenuAssetIcon(assetPath: final assetPath, package: final package) => Image.asset(
          assetPath,
          package: package,
          width: size,
          height: size,
          errorBuilder: (context, error, stackTrace) =>
              _MenuIconFallback(color: color, size: size),
        ),
      MenuCustomIcon(builder: final builder) => builder(context),
    };
  }
}

/// The documented fallback placeholder rendered by [MenuIconView] when a
/// [MenuAssetIcon]'s asset fails to resolve.
///
/// Renders [kMenuFallbackIcon] — the SAME single shared fallback glyph used
/// by [MenuIcon.fallback] at the model layer (spec assumption #4,
/// `sdd/flutter-samples/spec`). There is exactly one fallback glyph across
/// both layers; do not diverge this from [kMenuFallbackIcon].
class _MenuIconFallback extends StatelessWidget {
  const _MenuIconFallback({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(kMenuFallbackIcon, color: color, size: size);
  }
}
