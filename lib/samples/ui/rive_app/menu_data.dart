import 'package:flutter/material.dart';
import 'package:menu_slide_flutter/menu_slide_flutter.dart';

/// Host-owned menu content for the `rive_app` sample.
///
/// Converted from the original hardcoded `MenuItemModel.menuItems` /
/// `menuItems2` / `menuItems3` lists (Rive-icon rows, see the deleted
/// `models/menu_item.dart`) into the `menu_slide_flutter` package's
/// JSON-serializable [MenuItem]/[MenuSection] model. Rive icons are
/// replaced with Material [IconData] icons per design decision #618 (Rive
/// dropped, the package has zero third-party dependencies) — the app keeps
/// its own `rive` dependency for everything else (background, tab bar
/// icons, onboarding).
///
/// This data lives in the app (host), not the package: `menu_slide_flutter`
/// only defines the reusable shell/model types, never concrete menu
/// content (design decision #618/#623).
class RiveAppMenuData {
  RiveAppMenuData._();

  static const String browseSectionId = 'browse';
  static const String historySectionId = 'history';

  /// Section metadata. Was two visually separated groups in the original
  /// `SideMenu` ("BROWSE" from `menuItems`, "HISTORY" from `menuItems2`).
  static const List<MenuSection> sections = [
    MenuSection(id: browseSectionId, title: 'BROWSE'),
    MenuSection(id: historySectionId, title: 'HISTORY'),
  ];

  /// Menu rows. Was `MenuItemModel.menuItems` (Home/Search/Favorites/Help)
  /// + `MenuItemModel.menuItems2` (History/Notification). The original
  /// `menuItems3` ("Dark Mode") is NOT a row here — it is now the
  /// `RiveAppHome` footer's theme-mode toggle, ported directly, since it
  /// was never a selectable/navigable row in the original UI either.
  static const List<MenuItem> items = [
    MenuItem(
      id: 'home',
      label: 'Home',
      icon: MenuIconData(Icons.home_outlined),
      sectionId: browseSectionId,
    ),
    MenuItem(
      id: 'search',
      label: 'Search',
      icon: MenuIconData(Icons.search),
      sectionId: browseSectionId,
    ),
    MenuItem(
      id: 'favorites',
      label: 'Favorites',
      icon: MenuIconData(Icons.star_border),
      sectionId: browseSectionId,
    ),
    MenuItem(
      id: 'help',
      label: 'Help',
      icon: MenuIconData(Icons.chat_bubble_outline),
      sectionId: browseSectionId,
    ),
    MenuItem(
      id: 'history',
      label: 'History',
      icon: MenuIconData(Icons.access_time),
      sectionId: historySectionId,
    ),
    MenuItem(
      id: 'notifications',
      label: 'Notifications',
      icon: MenuIconData(Icons.notifications_none),
      sectionId: historySectionId,
    ),
  ];
}
