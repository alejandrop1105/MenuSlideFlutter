import 'menu_badge.dart';
import 'menu_icon.dart';

/// A single row in a menu: label, icon, and optional badge/grouping/enabled
/// state.
///
/// [MenuItem] deliberately does NOT expose any `onTap`/route/navigation
/// field — navigation stays host-owned. The host observes selection via the
/// menu's controller (see the shell/controller slice) and decides what to do
/// when an item is selected.
class MenuItem {
  const MenuItem({
    required this.id,
    required this.label,
    required this.icon,
    this.badge,
    this.enabled = true,
    this.sectionId,
  });

  /// Stable identifier for this item, used for selection and grouping.
  final String id;

  /// The row's display label.
  final String label;

  /// The row's leading icon.
  final MenuIcon icon;

  /// Optional badge indicator (e.g. an unread count).
  final MenuBadge? badge;

  /// Whether the row can be selected. Defaults to `true`.
  final bool enabled;

  /// The id of the [MenuSection] this item belongs to, or `null` for a
  /// top-level/ungrouped item.
  final String? sectionId;

  /// Placeholder id/label used by [fromJson] when a REQUIRED field is
  /// missing or malformed. Kept as a constant (never random/time-based) so
  /// degraded output stays deterministic and testable.
  static const _invalidPlaceholder = 'invalid';

  /// Parses a [MenuItem] from its JSON representation.
  ///
  /// [fromJson] ALWAYS returns a [MenuItem] — it never throws and never
  /// returns `null`. If a REQUIRED field (`id` or `label`) is missing or of
  /// the wrong type, the item degrades to a DISABLED (`enabled: false`) but
  /// still-visible placeholder instead of throwing or being dropped: a
  /// disabled row is safe to render (non-interactive, so it can never
  /// trigger a selection/load) and is better UX than a silent gap. A
  /// missing/invalid `id` (not a non-empty [String]) is replaced with
  /// [_invalidPlaceholder], combined with the label when one is available;
  /// a missing/invalid `label` falls back to the (possibly-placeholder)
  /// `id`, or `'Unavailable'` if neither is usable. [icon] already degrades
  /// gracefully via [MenuIcon.fromJson]. Optional keys (`badge`, `enabled`,
  /// `sectionId`) fall back to their documented defaults when absent or of
  /// the wrong type — a wrong-typed `enabled` on an otherwise-valid item
  /// simply defaults to `true`; it does NOT by itself force the item into
  /// the degraded/disabled state. Unknown/extra keys are ignored.
  factory MenuItem.fromJson(Map<String, dynamic> json) {
    final idJson = json['id'];
    final labelJson = json['label'];
    final badgeJson = json['badge'];
    final enabledJson = json['enabled'];
    final sectionIdJson = json['sectionId'];

    final hasValidId = idJson is String && idJson.isNotEmpty;
    final hasValidLabel = labelJson is String;
    final degraded = !hasValidId || !hasValidLabel;

    final label = labelJson is String
        ? labelJson
        : (idJson is String && idJson.isNotEmpty ? idJson : 'Unavailable');
    final id = idJson is String && idJson.isNotEmpty
        ? idJson
        : (labelJson is String ? '$_invalidPlaceholder-$labelJson' : _invalidPlaceholder);

    return MenuItem(
      id: id,
      label: label,
      icon: MenuIcon.fromJson(json['icon']),
      badge: badgeJson is Map<String, dynamic> ? MenuBadge.fromJson(badgeJson) : null,
      enabled: degraded ? false : (enabledJson is bool ? enabledJson : true),
      sectionId: sectionIdJson is String ? sectionIdJson : null,
    );
  }

  /// Serializes this item to JSON. Omits `badge`/`sectionId` when `null`.
  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'icon': icon.toJson(),
        if (badge != null) 'badge': badge!.toJson(),
        'enabled': enabled,
        if (sectionId != null) 'sectionId': sectionId,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MenuItem &&
          other.id == id &&
          other.label == label &&
          other.icon == icon &&
          other.badge == badge &&
          other.enabled == enabled &&
          other.sectionId == sectionId);

  @override
  int get hashCode => Object.hash(id, label, icon, badge, enabled, sectionId);
}
