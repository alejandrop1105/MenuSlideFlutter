import 'package:flutter/material.dart';

import 'demo_settings.dart';

/// Curated preset colors offered on the Configuration page for both the
/// menu panel and the shell backdrop swatches. A plain `List<Color>` — no
/// third-party color-picker dependency.
const List<Color> demoColorPalette = [
  Color(0xFF17203A), // Deep navy — the package's default panel color.
  Color(0xFF0B1220), // Near-black navy — the package's default backdrop.
  Color(0xFF3D5AFE), // Indigo — this app's Material 3 seed color.
  Color(0xFF00695C), // Teal.
  Color(0xFF6A1B9A), // Purple.
  Color(0xFFB71C1C), // Deep red.
];

/// Live controls for the demo's menu theming and layout: menu background,
/// backdrop background, and a full-screen-menu toggle. Every control reads
/// its current value from [settings] and writes back to it immediately —
/// changes apply to the running app as soon as they're made; open the menu
/// to see a background change, since the panel itself is off-canvas while
/// closed.
class ConfigurationPage extends StatelessWidget {
  const ConfigurationPage({super.key, required this.settings});

  final DemoSettings settings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('page-settings'),
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 96),
          children: [
            Text('Configuration', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Changes apply live to the running menu — open it to see them.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              key: const Key('config-fullscreen-switch'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Full-screen menu'),
              subtitle: const Text('Bottom bar inside the menu shell'),
              value: settings.fullScreenMenu,
              onChanged: (value) => settings.fullScreenMenu = value,
            ),
            const SizedBox(height: 24),
            _SwatchSection(
              title: 'Menu background',
              caption: 'Colors the menu panel behind its rows.',
              keyPrefix: 'config-menu-swatch',
              selected: settings.menuColor,
              onSelected: (color) => settings.menuColor = color,
            ),
            const SizedBox(height: 24),
            _SwatchSection(
              title: 'Backdrop background',
              caption:
                  'Colors the shell layer behind the panel and page during the diagonal reveal.',
              keyPrefix: 'config-backdrop-swatch',
              selected: settings.backdropColor,
              onSelected: (color) => settings.backdropColor = color,
            ),
          ],
        ),
      ),
    );
  }
}

class _SwatchSection extends StatelessWidget {
  const _SwatchSection({
    required this.title,
    required this.caption,
    required this.keyPrefix,
    required this.selected,
    required this.onSelected,
  });

  final String title;
  final String caption;
  final String keyPrefix;

  /// The currently selected color, or `null` when no explicit override is
  /// set yet (no swatch shows as selected in that case).
  final Color? selected;
  final ValueChanged<Color> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          caption,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var i = 0; i < demoColorPalette.length; i++)
              _ColorSwatch(
                key: Key('$keyPrefix-$i'),
                color: demoColorPalette[i],
                isSelected: demoColorPalette[i] == selected,
                onTap: () => onSelected(demoColorPalette[i]),
              ),
          ],
        ),
      ],
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    super.key,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            width: 3,
          ),
        ),
        child: isSelected
            ? Icon(Icons.check, color: _contrastingIconColor(color), size: 18)
            : null,
      ),
    );
  }

  Color _contrastingIconColor(Color background) =>
      background.computeLuminance() > 0.5 ? Colors.black : Colors.white;
}
