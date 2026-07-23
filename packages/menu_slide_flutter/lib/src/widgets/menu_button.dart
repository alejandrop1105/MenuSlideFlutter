import 'package:flutter/material.dart';

/// The shell's built-in floating toggle button: a small circular button
/// showing an [AnimatedIcon] that morphs between a hamburger and a close
/// (X) glyph as [progress] advances from `0` (closed) to `1` (open).
///
/// Private to the package (not exported via the barrel) — see
/// [`MenuSlideShell.showMenuButton`] for the host opt-out. Replaces the
/// original sample's Rive-driven `menuButtonRiv` per design decision #618
/// (Rive dropped, zero third-party dependencies).
class MenuSlideButton extends StatelessWidget {
  const MenuSlideButton({
    super.key,
    required this.progress,
    required this.onTap,
  });

  /// Drives the [AnimatedIcon]'s morph — the SAME animation that drives the
  /// shell's diagonal reveal, so the icon and the page transform always stay
  /// in sync.
  final Animation<double> progress;

  /// Invoked on tap. The shell wires this to `controller.toggle()`.
  final VoidCallback onTap;

  static const double _size = 44;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          key: const Key('menu-slide-button'),
          width: _size,
          height: _size,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_size / 2),
            boxShadow: const [
              BoxShadow(color: Color(0x33000000), blurRadius: 5, offset: Offset(0, 5)),
            ],
          ),
          child: AnimatedIcon(icon: AnimatedIcons.menu_close, progress: progress),
        ),
      ),
    );
  }
}
