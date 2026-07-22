import 'menu_item.dart';

/// Metadata for a group of [MenuItem]s. Items reference a section via
/// [MenuItem.sectionId]; items with a `null` (or dangling/unresolvable)
/// `sectionId` are top-level/ungrouped — see [groupItemsBySection].
class MenuSection {
  const MenuSection({required this.id, required this.title});

  /// Stable identifier, matched against [MenuItem.sectionId].
  final String id;

  /// The section's display title.
  final String title;

  /// Parses a [MenuSection] from its JSON representation. Unknown/extra
  /// keys are ignored.
  factory MenuSection.fromJson(Map<String, dynamic> json) => MenuSection(
        id: json['id'] as String,
        title: json['title'] as String,
      );

  /// Serializes this section to JSON.
  Map<String, dynamic> toJson() => {'id': id, 'title': title};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MenuSection && other.id == id && other.title == title);

  @override
  int get hashCode => Object.hash(id, title);
}

/// Groups [items] by the [MenuSection] each references via
/// [MenuItem.sectionId].
///
/// Ordering contract: the returned map is seeded with every section in
/// [sections], in the same order, each starting with an empty list — so a
/// declared section with no matching items still appears as a key (with an
/// empty list) instead of being silently absent. Items are then distributed
/// into their matching section's list, preserving each item's relative
/// order within that section.
///
/// Items whose `sectionId` is `null`, or whose `sectionId` does not match
/// any [MenuSection] in [sections] (a "dangling" reference), are grouped
/// under the `null` key — never thrown as an error. This keeps rendering
/// resilient to backend data that references a since-removed section. The
/// `null` key is only added on demand (when at least one item needs it) and
/// always appears LAST, after every declared section, because all declared
/// sections are seeded up front. If [sections] contains duplicate ids, the
/// LAST section with a given id wins for item resolution (matches standard
/// last-write-wins map semantics), but every distinct [MenuSection] value in
/// [sections] is still seeded as its own key.
Map<MenuSection?, List<MenuItem>> groupItemsBySection(
  List<MenuItem> items,
  List<MenuSection> sections,
) {
  final sectionsById = {for (final section in sections) section.id: section};
  final grouped = <MenuSection?, List<MenuItem>>{
    for (final section in sections) section: <MenuItem>[],
  };
  for (final item in items) {
    final section = item.sectionId != null ? sectionsById[item.sectionId] : null;
    grouped.putIfAbsent(section, () => []).add(item);
  }
  return grouped;
}
