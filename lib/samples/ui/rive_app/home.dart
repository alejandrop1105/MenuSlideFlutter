import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:menu_slide_flutter/menu_slide_flutter.dart';
import 'package:flutter_samples/samples/ui/rive_app/navigation/custom_tab_bar.dart';
import 'package:flutter_samples/samples/ui/rive_app/navigation/home_tab_view.dart';
import 'package:flutter_samples/samples/ui/rive_app/on_boarding/onboarding_view.dart';
import 'package:flutter_samples/samples/ui/rive_app/theme.dart';
import 'package:flutter_samples/samples/ui/rive_app/menu_data.dart';

// Common Tab Scene for the tabs other than 1st one, showing only tab name in center
Widget commonTabScene(String tabName) {
  return Container(
      color: RiveAppTheme.background,
      alignment: Alignment.center,
      child: Text(tabName,
          style: const TextStyle(
              fontSize: 28, fontFamily: "Poppins", color: Colors.black)));
}

class RiveAppHome extends StatefulWidget {
  const RiveAppHome({Key? key}) : super(key: key);

  static const String route = '/course-rive';

  @override
  State<RiveAppHome> createState() => _RiveAppHomeState();
}

class _RiveAppHomeState extends State<RiveAppHome>
    with TickerProviderStateMixin {
  /// Owns the menu's selection, open/close intent and theme-mode command.
  /// Host-owned per design decision #618: the component is a shell that
  /// wraps host content, driven by a controller the host constructs.
  late final MenuSlideController _menuController;

  /// Mirrors `_menuController.isOpen` on the host side. `MenuSlideShell`
  /// owns the actual reveal animation internally and does not expose it
  /// (`MenuSlideController.isOpen` is documented as an INTENT only) — so
  /// any host-owned chrome that also needs to react to the reveal (the
  /// bottom tab bar and the profile avatar button, both host territory per
  /// decision #627) mirrors the intent with its own animation, using the
  /// same spring/duration as the original sample so the motion matches.
  // TODO(menu_slide_flutter): expose MenuSlideController.revealProgress so
  // hosts don't duplicate the spring.
  late AnimationController? _menuRevealMirrorController;
  late Animation<double> _menuRevealMirrorAnim;

  late AnimationController? _onBoardingAnimController;
  late Animation<double> _onBoardingAnim;

  bool _showOnBoarding = false;
  Widget _tabBody = Container(color: RiveAppTheme.background);
  final List<Widget> _screens = [
    const HomeTabView(),
    commonTabScene("Search"),
    commonTabScene("Timer"),
    commonTabScene("Bell"),
    commonTabScene("User"),
  ];

  final springDesc = const SpringDescription(
    mass: 0.1,
    stiffness: 40,
    damping: 5,
  );

  /// Last `_menuController.isOpen` value reacted to, so
  /// [_onMenuControllerChanged] can tell an open/close TRANSITION apart
  /// from any other notification (selection change) and only (re)drive the
  /// mirror animation on an actual transition.
  bool _lastMenuIsOpen = false;

  /// Last `_menuController.selectedItemId` reacted to. This is the single
  /// source of truth both navigators (the side menu and the bottom tab bar,
  /// `CustomTabBar.onTabChange` below) compare against, so a repeated
  /// selection notification never re-triggers a page swap and the two
  /// navigators never fight each other for `_tabBody` (PR8 review FIX 2).
  String? _lastMenuSelection;

  void _onMenuControllerChanged() {
    // Selection changed: the host maps the selected item id to a page and
    // swaps the body — the menu component itself never decides what to
    // load (design decision #638: click -> load model is host-owned).
    //
    // Closing the menu on a row tap is now `MenuSlideShell`'s own behavior
    // (`closeOnSelect`, default true, left at its default below) — the host
    // no longer closes it here. `CustomTabBar.onTabChange` still sets
    // `_lastMenuSelection` BEFORE calling the controller so this listener
    // does not re-navigate/override `_tabBody` when the bottom bar is the
    // one driving the change.
    final selectedId = _menuController.selectedItemId;
    if (selectedId != _lastMenuSelection) {
      if (selectedId != null) {
        _lastMenuSelection = selectedId;
        setState(() {
          _tabBody = _pageForMenuItemId(selectedId);
        });
      } else {
        // Cleared — e.g. the bottom tab bar synced to a tab with no
        // matching menu item (see `_menuIdForTabIndex`). Do not touch
        // `_tabBody`: the bottom bar already set it.
        _lastMenuSelection = null;
      }
    }

    // Open/close intent changed: mirror it for the host-owned chrome
    // (bottom tab bar + profile avatar) and flip the status bar style, both
    // previously driven directly off the old Rive menu-button boolean.
    final isOpen = _menuController.isOpen;
    if (isOpen != _lastMenuIsOpen) {
      _lastMenuIsOpen = isOpen;
      if (isOpen) {
        final springAnim = SpringSimulation(springDesc, 0, 1, 0);
        _menuRevealMirrorController?.animateWith(springAnim);
      } else {
        _menuRevealMirrorController?.reverse();
      }
      SystemChrome.setSystemUIOverlayStyle(
          isOpen ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light);
    }
  }

  /// Host-side click -> load-model mapping (design decision #638). Ids with
  /// no dedicated page — kept only for parity with the original sample's
  /// decorative extra rows — fall back to a labeled placeholder screen,
  /// matching the bottom tab bar's own `commonTabScene` pattern.
  Widget _pageForMenuItemId(String id) {
    switch (id) {
      case 'home':
        return _screens[0];
      case 'search':
        return _screens[1];
      case 'favorites':
        return commonTabScene('Favorites');
      case 'help':
        return commonTabScene('Help');
      case 'history':
        return commonTabScene('History');
      case 'notifications':
        return commonTabScene('Notifications');
      default:
        return _tabBody;
    }
  }

  /// Maps a bottom tab bar index to its matching menu item id, or `null`
  /// when the tab has no matching row (Timer/Bell/User — decorative extra
  /// tabs with no side-menu equivalent, see `RiveAppMenuData.items`).
  String? _menuIdForTabIndex(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 'home';
      case 1:
        return 'search';
      default:
        return null;
    }
  }

  void _presentOnBoarding(bool show) {
    if (show) {
      setState(() {
        _showOnBoarding = true;
      });
      final springAnim = SpringSimulation(springDesc, 0, 1, 0);
      _onBoardingAnimController?.animateWith(springAnim);
    } else {
      _onBoardingAnimController?.reverse().whenComplete(() => {
            setState(() {
              _showOnBoarding = false;
            })
          });
    }
  }

  Widget _buildMenuHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.2),
            foregroundColor: Colors.white,
            child: const Icon(Icons.person_outline),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Ashu",
                style: TextStyle(
                    color: Colors.white, fontSize: 17, fontFamily: "Inter"),
              ),
              const SizedBox(height: 2),
              Text(
                "Software Engineer",
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 15,
                    fontFamily: "Inter"),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: Icon(Icons.dark_mode_outlined, color: Colors.white),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              "Dark Mode",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontFamily: "Inter",
                  fontWeight: FontWeight.w600),
            ),
          ),
          CupertinoSwitch(
            value: _menuController.themeMode == ThemeMode.dark,
            onChanged: (value) {
              _menuController
                  .setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
            },
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _menuController = MenuSlideController(items: RiveAppMenuData.items);
    _menuController.addListener(_onMenuControllerChanged);

    _menuRevealMirrorController = AnimationController(
      duration: const Duration(milliseconds: 200),
      upperBound: 1,
      vsync: this,
    );
    _menuRevealMirrorAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
            parent: _menuRevealMirrorController!, curve: Curves.linear));

    _onBoardingAnimController = AnimationController(
      duration: const Duration(milliseconds: 350),
      upperBound: 1,
      vsync: this,
    );
    _onBoardingAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _onBoardingAnimController!,
      curve: Curves.linear,
    ));

    _tabBody = _screens.first;
  }

  @override
  void dispose() {
    _menuController.removeListener(_onMenuControllerChanged);
    _menuController.dispose();
    _menuRevealMirrorController?.dispose();
    _onBoardingAnimController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned(child: Container(color: RiveAppTheme.background2)),
          MenuSlideShell(
            controller: _menuController,
            sections: RiveAppMenuData.sections,
            headerBuilder: _buildMenuHeader,
            footerBuilder: _buildMenuFooter,
            child: _tabBody,
          ),
          // Profile avatar button, opens the onboarding modal. Sits above
          // the shell (unaffected by the diagonal reveal transform, like
          // the original sample) and mirrors the open intent to shift out
          // of the way while the menu is open.
          AnimatedBuilder(
            animation: _menuRevealMirrorAnim,
            builder: (context, child) {
              return Positioned(
                top: MediaQuery.of(context).padding.top + 20,
                right: (_menuRevealMirrorAnim.value * -100) + 16,
                child: child!,
              );
            },
            child: GestureDetector(
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: RiveAppTheme.shadow.withOpacity(0.2),
                        blurRadius: 5,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: const Icon(Icons.person_outline),
                ),
              ),
              onTap: () {
                _presentOnBoarding(true);
              },
            ),
          ),
          if (_showOnBoarding)
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _onBoardingAnim,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                        0,
                        -(MediaQuery.of(context).size.height +
                                MediaQuery.of(context).padding.bottom) *
                            (1 - _onBoardingAnim.value)),
                    child: child!,
                  );
                },
                child: SafeArea(
                  top: false,
                  maintainBottomViewPadding: true,
                  child: Container(
                    clipBehavior: Clip.hardEdge,
                    margin: EdgeInsets.only(
                        bottom: MediaQuery.of(context).padding.bottom + 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 40,
                            offset: const Offset(0, 40))
                      ],
                    ),
                    child: OnBoardingView(
                      closeModal: () {
                        _presentOnBoarding(false);
                      },
                    ),
                  ),
                ),
              ),
            ),
          // White underlay behind the bottom tab bar
          IgnorePointer(
            ignoring: true,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedBuilder(
                  animation: !_showOnBoarding
                      ? _menuRevealMirrorAnim
                      : _onBoardingAnim,
                  builder: (context, child) {
                    return Container(
                      height: 150,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            RiveAppTheme.background.withOpacity(0),
                            RiveAppTheme.background.withOpacity(1 -
                                (!_showOnBoarding
                                    ? _menuRevealMirrorAnim.value
                                    : _onBoardingAnim.value))
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    );
                  }),
            ),
          ),
        ],
      ),
      bottomNavigationBar: RepaintBoundary(
        child: AnimatedBuilder(
          animation:
              !_showOnBoarding ? _menuRevealMirrorAnim : _onBoardingAnim,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                  0,
                  !_showOnBoarding
                      ? _menuRevealMirrorAnim.value *
                          MenuSlideThemeData.fallback().navShift
                      : _onBoardingAnim.value * 200),
              child: child,
            );
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomTabBar(
                onTabChange: (tabIndex) {
                  setState(() {
                    _tabBody = _screens[tabIndex];
                  });
                  // Bottom-bar-driven nav (PR8 review FIX 2): keep the menu
                  // in sync so a later menu tap is never a stale no-op
                  // (dead click) and the menu never highlights a stale
                  // item.
                  final menuId = _menuIdForTabIndex(tabIndex);
                  // Set BEFORE calling the controller so
                  // `_onMenuControllerChanged` sees the selection as
                  // already in sync and does not re-navigate/override the
                  // `_tabBody` just set above when the controller notifies.
                  _lastMenuSelection = menuId;
                  if (menuId != null) {
                    _menuController.selectItem(menuId);
                  } else {
                    _menuController.clearSelection();
                  }
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
