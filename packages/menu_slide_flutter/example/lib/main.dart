import 'package:flutter/material.dart';
import 'package:menu_slide_flutter/menu_slide_flutter.dart';

import 'app_theme.dart';
import 'demo_menu.dart';
import 'pages.dart';

void main() => runApp(const DemoApp());

/// The reference host wiring for `menu_slide_flutter`.
///
/// `DemoApp` owns the single [MenuSlideController] instance for the whole
/// app — the package never creates or owns a controller itself; the host
/// constructs it and passes it down. Anything that needs to react to the
/// controller (the menu shell, the theme-toggle switch, the bottom nav) is
/// driven from THIS controller, never a copy of its state.
class DemoApp extends StatefulWidget {
  const DemoApp({super.key});

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  late final MenuSlideController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MenuSlideController(
      items: DemoMenu.items,
      initialSelectedItemId: 'dashboard',
      themeMode: ThemeMode.light,
    );
    // The controller notifies on EVERY change it owns: selection, open/close
    // intent, and theme-mode. Rebuilding unconditionally here is what makes
    // a theme-mode change — fired from the footer switch in `DemoHome` — flow
    // all the way up into `MaterialApp.themeMode` below.
    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'menu_slide_flutter example',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // THIS is the line that makes the menu's theme toggle drive the WHOLE
      // app: `MenuSlideController.themeMode` is just a value the host reads
      // and applies to `MaterialApp.themeMode` — the package itself never
      // touches `Theme.of(context)` or paints anything outside its own panel.
      themeMode: _controller.themeMode,
      home: DemoHome(controller: _controller),
    );
  }
}

/// The app's single screen: a [MenuSlideShell] wrapping the current page,
/// plus a Material [NavigationBar] mirroring a subset of the menu's items.
///
/// The two navigators (side menu + bottom bar) stay in sync against the same
/// [MenuSlideController]: selecting a menu row updates the bottom bar's
/// highlight, and tapping a bottom destination updates the menu's highlight
/// — neither ever shows a stale selection, and re-tapping an already-active
/// destination is never a dead click, because both read the SAME
/// `controller.selectedItemId` as their source of truth.
class DemoHome extends StatefulWidget {
  const DemoHome({super.key, required this.controller});

  final MenuSlideController controller;

  @override
  State<DemoHome> createState() => _DemoHomeState();
}

class _DemoHomeState extends State<DemoHome> {
  /// Bottom-nav destinations, in order, mirroring a subset of the menu's
  /// item ids. Not every menu item has a bottom-nav equivalent (e.g.
  /// `notifications`/`billing` are menu-only) — the bottom nav simply keeps
  /// its last highlighted destination while a menu-only page is shown, the
  /// same way most host apps combine tabs with a drawer.
  static const _bottomNavIds = ['dashboard', 'projects', 'search', 'profile'];

  /// Last `controller.selectedItemId` this widget reacted to. Set BEFORE
  /// driving the controller from [_onDestinationSelected] so
  /// [_onControllerChanged] sees the selection as already in sync and never
  /// fights a bottom-nav-driven change — the same "who changed it" guard
  /// used to coordinate the two navigators in the `rive_app` sample.
  late String? _lastMenuSelection;

  /// Locally-tracked highlighted bottom-nav index. `NavigationBar` always
  /// needs a concrete index (unlike the menu, whose selection can be
  /// `null`), so this only changes when the selection matches one of
  /// [_bottomNavIds] — otherwise it keeps its last value.
  late int _bottomIndex;

  @override
  void initState() {
    super.initState();
    _lastMenuSelection = widget.controller.selectedItemId;
    final initialIndex = _bottomNavIds.indexOf(_lastMenuSelection ?? '');
    _bottomIndex = initialIndex == -1 ? 0 : initialIndex;
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    final selectedId = widget.controller.selectedItemId;
    if (selectedId == _lastMenuSelection) return;
    _lastMenuSelection = selectedId;
    final idx = _bottomNavIds.indexOf(selectedId ?? '');
    setState(() {
      if (idx != -1) _bottomIndex = idx;
    });
  }

  void _onDestinationSelected(int index) {
    final id = _bottomNavIds[index];
    _lastMenuSelection = id;
    setState(() => _bottomIndex = index);
    widget.controller.selectItem(id);
  }

  Widget _profileHeader(BuildContext context) {
    final menuTheme = MenuSlideThemeData.resolve(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: menuTheme.selectedRowColor,
            child: Icon(Icons.person, color: menuTheme.selectedRowIconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Alex Rivera', style: menuTheme.rowTextStyle),
                const SizedBox(height: 2),
                Text('Product Engineer', style: menuTheme.sectionTitleStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _themeToggleFooter(BuildContext context) {
    final menuTheme = MenuSlideThemeData.resolve(context);
    return SwitchListTile(
      key: const Key('theme-toggle-switch'),
      contentPadding: EdgeInsets.zero,
      secondary: Icon(Icons.dark_mode_outlined, color: menuTheme.rowIconColor),
      title: Text('Dark mode', style: menuTheme.rowTextStyle),
      value: widget.controller.themeMode == ThemeMode.dark,
      // The headline feature: flipping this switch calls
      // `controller.setThemeMode`, which notifies `DemoApp`'s listener,
      // which rebuilds `MaterialApp` with the new `themeMode` — theming the
      // WHOLE app, not just this panel.
      onChanged: (value) {
        widget.controller.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = DemoMenu.pageForId(widget.controller.selectedItemId) ?? const DashboardPage();

    return Scaffold(
      body: MenuSlideShell(
        controller: widget.controller,
        sections: DemoMenu.sections,
        headerBuilder: _profileHeader,
        footerBuilder: _themeToggleFooter,
        child: page,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _bottomIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Projects',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
