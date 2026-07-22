import 'package:flutter/widgets.dart' show Color;

/// A small, optional indicator shown on a [MenuItem] row, e.g. an unread
/// count ("3") or a status label ("New").
///
/// Kept intentionally minimal — a display [label] plus an optional [color] —
/// so hosts can render counts, dots, or short text without the package
/// dictating a specific visual style. Extend with new optional fields as
/// real use cases emerge, keeping backward-compatible JSON.
class MenuBadge {
  const MenuBadge(this.label, {this.color});

  /// The text to display in the badge (e.g. an unread count or short label).
  final String label;

  /// Optional accent color for the badge. When `null`, the host/theme
  /// decides the default badge color.
  ///
  /// `color` is serialized as a 32-bit ARGB [int] via [Color.toARGB32] (see
  /// [toJson]). Colors constructed from the newer float-component [Color]
  /// API (e.g. `Color.from(alpha: ..., red: ..., green: ..., blue: ...)`)
  /// with channel values that are not aligned to 8-bit boundaries will
  /// round-trip to their NEAREST 8-bit value, not bit-for-bit exactly.
  /// Colors constructed from a hex/int literal (e.g. `Color(0xFFFF0000)`)
  /// always round-trip exactly.
  final Color? color;

  /// Parses a [MenuBadge] from its JSON representation.
  ///
  /// Unknown/extra keys are ignored. `color`, when present, is read as the
  /// 32-bit ARGB value produced by [Color.toARGB32]. Accepts any [num] (not
  /// just [int]) so a `color` encoded as a JSON double (e.g. from a backend
  /// that always emits floating-point numbers) is coerced via `.toInt()`
  /// instead of silently becoming `null`.
  factory MenuBadge.fromJson(Map<String, dynamic> json) {
    final color = json['color'];
    return MenuBadge(
      json['label'] as String,
      color: color is num ? Color(color.toInt()) : null,
    );
  }

  /// Serializes this badge to JSON. Omits the `color` key entirely when
  /// [color] is `null`.
  Map<String, dynamic> toJson() => {
        'label': label,
        if (color != null) 'color': color!.toARGB32(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MenuBadge && other.label == label && other.color == color);

  @override
  int get hashCode => Object.hash(label, color);
}
