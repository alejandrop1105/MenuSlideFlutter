import 'package:flutter/widgets.dart';

import '../controller/menu_slide_controller.dart';

/// Exposes the [MenuSlideController] owned by an ancestor `MenuSlideShell`
/// to any descendant widget, so ANY widget in the host's content tree —
/// deeply nested pages, buttons, arbitrary UI — can drive the menu/right
/// panel (`open()`, `close()`, `toggle()`, `openRight()`, `closeRight()`,
/// `toggleRight()`) without the host threading the controller through
/// constructor parameters.
///
/// `MenuSlideShell.build` wraps its content in this scope automatically —
/// hosts never construct it directly.
class MenuSlideScope extends InheritedNotifier<MenuSlideController> {
  const MenuSlideScope({
    super.key,
    required MenuSlideController controller,
    required super.child,
  }) : super(notifier: controller);

  /// Resolves the nearest ancestor [MenuSlideShell]'s controller.
  ///
  /// Establishes a dependency: the calling widget rebuilds whenever the
  /// controller notifies. Asserts (in debug mode) when called from a
  /// [context] with no ancestor [MenuSlideScope] — use [maybeOf] when a
  /// `MenuSlideShell` ancestor isn't guaranteed.
  static MenuSlideController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<MenuSlideScope>();
    assert(
      scope != null,
      'MenuSlideScope.of() called with a context that does not contain a '
      'MenuSlideShell.',
    );
    return scope!.notifier!;
  }

  /// Resolves the nearest ancestor [MenuSlideShell]'s controller, or `null`
  /// when [context] has no ancestor [MenuSlideScope].
  ///
  /// Reads without establishing a rebuild dependency — the calling widget
  /// does NOT rebuild on controller notifications. Prefer [of] when the
  /// caller should react to future changes.
  static MenuSlideController? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<MenuSlideScope>()?.notifier;
}
