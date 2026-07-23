/// A reusable, themeable Flutter side-menu shell with a diagonal reveal
/// animation.
///
/// This is the single public entrypoint for the `menu_slide_flutter` package.
/// Internals under `src/` are not exported and must not be imported
/// directly by consumers.
library;

export 'src/controller/menu_slide_controller.dart' show MenuSlideController;
export 'src/models/menu_badge.dart' show MenuBadge;
export 'src/models/menu_icon.dart' show MenuIcon, MenuIconData, MenuAssetIcon, MenuCustomIcon;
export 'src/models/menu_item.dart' show MenuItem;
export 'src/models/menu_section.dart' show MenuSection, groupItemsBySection;
export 'src/theme/menu_slide_theme_data.dart' show MenuSlideThemeData;
export 'src/widgets/menu_slide_shell.dart' show MenuSlideShell;
