import 'package:flutter/material.dart' show IconData, Icons;

/// The single, package-wide documented fallback/placeholder icon.
///
/// Per the "Icon Fallback (no-crash contract)" spec requirement (spec
/// assumption #4, `sdd/flutter-samples/spec`), there is exactly ONE shared
/// fallback glyph — never a second/different placeholder — used by both:
/// - [MenuIcon.fallback] (model layer): returned by [MenuIcon.fromJson] when
///   the `type` discriminator is missing, malformed, unrecognized, or
///   `"custom"`.
/// - `MenuIconView`'s asset `errorBuilder` (widget layer): rendered when a
///   [MenuAssetIcon]'s asset fails to resolve at runtime.
///
/// Kept as a single top-level constant so both layers reference exactly one
/// source of truth instead of independently hardcoding an icon.
const IconData kMenuFallbackIcon = Icons.help_outline;
