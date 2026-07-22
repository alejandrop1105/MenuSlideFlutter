# MenuSlideFlutter

> Dart package name: `menu_slide_flutter` (snake_case, as required by pub).

A reusable, themeable Flutter side-menu shell with a diagonal reveal
animation. Zero third-party runtime dependencies.

## Icon tree-shaking caveat

`MenuIconData` wraps a Material `IconData`. When an `IconData`'s `codePoint`
is only known at runtime — for example, one reconstructed via
`MenuIcon.fromJson` from backend-driven JSON — it is invisible to Flutter's
icon tree-shaker. The tree-shaker only recognizes `IconData` **constant
literals** written directly in source code; it cannot see codePoints that
arrive dynamically.

If your app serves such icons, either:

- Pass `--no-tree-shake-icons` to `flutter build` for that release build, or
- Prefer `MenuAssetIcon` for backend-driven icons instead, since image assets
  are unaffected by icon tree-shaking.

Skipping this step will make backend-driven icons silently render as missing
glyphs in release builds.
