import 'package:flutter/material.dart';
import 'package:menu_slide_flutter/menu_slide_flutter.dart';

import 'pages.dart';

/// The host's menu configuration.
///
/// In a real product these items could be fetched from a backend/CMS and
/// built via `MenuItem.fromJson` — the widget is data-in/data-out. This demo
/// hardcodes the equivalent `MenuItem`/`MenuSection` list so the example has
/// zero network/asset dependencies.
class DemoMenu {
  const DemoMenu._();

  /// Two sections: a "Workspace" group for day-to-day navigation, and an
  /// "Account" group for identity/billing concerns.
  static const sections = [
    MenuSection(id: 'workspace', title: 'Workspace'),
    MenuSection(id: 'account', title: 'Account'),
  ];

  /// Six items across the two sections above. `billing` is `enabled: false`
  /// to showcase the disabled-row state (de-emphasized, non-interactive).
  static const items = [
    MenuItem(
      id: 'dashboard',
      label: 'Dashboard',
      icon: MenuIconData(Icons.dashboard_outlined),
      sectionId: 'workspace',
    ),
    MenuItem(
      id: 'projects',
      label: 'Projects',
      icon: MenuIconData(Icons.folder_outlined),
      sectionId: 'workspace',
    ),
    MenuItem(
      id: 'search',
      label: 'Search',
      icon: MenuIconData(Icons.search),
      sectionId: 'workspace',
    ),
    MenuItem(
      id: 'profile',
      label: 'Profile',
      icon: MenuIconData(Icons.person_outline),
      sectionId: 'account',
    ),
    MenuItem(
      id: 'notifications',
      label: 'Notifications',
      icon: MenuIconData(Icons.notifications_outlined),
      badge: MenuBadge('3'),
      sectionId: 'account',
    ),
    MenuItem(
      id: 'billing',
      label: 'Billing',
      icon: MenuIconData(Icons.credit_card_outlined),
      enabled: false,
      sectionId: 'account',
    ),
    MenuItem(
      id: 'settings',
      label: 'Configuration',
      icon: MenuIconData(Icons.settings_outlined),
      sectionId: 'account',
    ),
  ];

  static const _titles = {
    'dashboard': 'Dashboard',
    'projects': 'Projects',
    'search': 'Search',
    'profile': 'Profile',
    'notifications': 'Notifications',
    'billing': 'Billing',
    'settings': 'Configuration',
  };

  /// Human-readable title for a menu item [id], or `null` when [id] is
  /// `null`/unknown.
  static String? titleForId(String? id) => id == null ? null : _titles[id];

  /// The page widget for a menu item [id], or `null` when [id] is
  /// `null`/unknown. The host — not the package — owns this click-to-page
  /// mapping.
  ///
  /// `settings` is intentionally NOT mapped here: `ConfigurationPage`
  /// requires the live `DemoSettings` instance, which this static method
  /// has no access to — `DemoHome.build` special-cases that id directly.
  static Widget? pageForId(String? id) {
    switch (id) {
      case 'dashboard':
        return const DashboardPage();
      case 'projects':
        return const ProjectsPage();
      case 'search':
        return const SearchPage();
      case 'profile':
        return const ProfilePage();
      case 'notifications':
        return const NotificationsPage();
      case 'billing':
        return const BillingPage();
      default:
        return null;
    }
  }
}
