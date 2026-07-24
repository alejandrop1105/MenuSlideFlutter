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

/// Bundled backdrop images offered on the Configuration page, copied into
/// this example app under `assets/backdrops/` (declared in `pubspec.yaml`).
/// The package itself bundles no assets — these are entirely host-owned.
const List<String> demoBackdropImageAssets = [
  'assets/backdrops/spline.png',
  'assets/backdrops/course_rive.png',
  'assets/backdrops/grid_magnification.png',
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
              caption: 'Colors the menu panel behind its rows. Pick the transparent swatch to '
                  'let the backdrop show through the panel.',
              keyPrefix: 'config-menu-swatch',
              selected: settings.menuColor,
              onSelected: (color) => settings.menuColor = color,
              includeTransparentOption: true,
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
            const SizedBox(height: 24),
            _BackdropImageSection(
              selectedAsset: settings.backdropImageAsset,
              onSelected: (asset) => settings.backdropImageAsset = asset,
            ),
            const SizedBox(height: 24),
            _LabeledSlider(
              sliderKey: const Key('config-backdrop-blur-slider'),
              title: 'Backdrop blur',
              caption: 'Gaussian blur applied to the shell backdrop.',
              value: settings.backdropBlur,
              min: 0,
              max: 20,
              valueLabel: settings.backdropBlur.toStringAsFixed(1),
              onChanged: (value) => settings.backdropBlur = value,
            ),
            const SizedBox(height: 24),
            _LabeledSlider(
              sliderKey: const Key('config-backdrop-opacity-slider'),
              title: 'Backdrop opacity',
              caption: 'Transparency of the shell backdrop layer.',
              value: settings.backdropOpacity,
              min: 0,
              max: 1,
              valueLabel: '${(settings.backdropOpacity * 100).round()}%',
              onChanged: (value) => settings.backdropOpacity = value,
            ),
            const SizedBox(height: 24),
            _LabeledSlider(
              sliderKey: const Key('config-reveal-factor-slider'),
              title: 'Menu / page separation',
              caption:
                  "0% = flush with the menu's edge; increasing adds a gap (responsive % of "
                  'the remaining width).',
              value: settings.revealFactor,
              min: 0.0,
              max: 0.85,
              valueLabel: '${(settings.revealFactor * 100).round()}%',
              onChanged: (value) => settings.revealFactor = value,
            ),
            const SizedBox(height: 24),
            _LabeledSlider(
              sliderKey: const Key('config-tilt-degrees-slider'),
              title: '3D tilt angle',
              caption: 'Opening angle of the page, independent of the separation.',
              value: settings.tiltDegrees,
              min: 0,
              max: 60,
              valueLabel: '${settings.tiltDegrees.round()}°',
              onChanged: (value) => settings.tiltDegrees = value,
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
    this.includeTransparentOption = false,
  });

  final String title;
  final String caption;
  final String keyPrefix;

  /// The currently selected color, or `null` when no explicit override is
  /// set yet (no swatch shows as selected in that case).
  final Color? selected;
  final ValueChanged<Color> onSelected;

  /// When `true`, appends a recognizable transparent swatch after the
  /// preset palette — selecting it sets the target color to
  /// [Colors.transparent], letting whatever renders behind it show through.
  final bool includeTransparentOption;

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
            if (includeTransparentOption)
              _TransparentSwatch(
                key: Key('$keyPrefix-transparent'),
                isSelected: selected == Colors.transparent,
                onTap: () => onSelected(Colors.transparent),
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

/// A recognizable "transparent" swatch option: an invisible fill would be
/// impossible to see or tap with confidence, so this renders a bordered
/// circle with a reset-color icon instead — matching [_ColorSwatch]'s size
/// and selected-state highlight (a thicker primary-colored border).
class _TransparentSwatch extends StatelessWidget {
  const _TransparentSwatch({
    super.key,
    required this.isSelected,
    required this.onTap,
  });

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
          color: Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Icon(
          Icons.format_color_reset,
          color: theme.colorScheme.onSurfaceVariant,
          size: 18,
        ),
      ),
    );
  }
}

/// Offers "None" plus a thumbnail per [demoBackdropImageAssets] entry.
/// Tapping a thumbnail selects that asset; tapping "None" (highlighted when
/// [selectedAsset] is `null`) clears the backdrop image override.
class _BackdropImageSection extends StatelessWidget {
  const _BackdropImageSection({required this.selectedAsset, required this.onSelected});

  final String? selectedAsset;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Backdrop image', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'An optional image painted on the shell backdrop, behind the panel and page.',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _ImageThumbnail(
              key: const Key('config-backdrop-image-none'),
              isSelected: selectedAsset == null,
              onTap: () => onSelected(null),
              child: const Icon(Icons.block),
            ),
            for (var i = 0; i < demoBackdropImageAssets.length; i++)
              _ImageThumbnail(
                key: Key('config-backdrop-image-$i'),
                isSelected: selectedAsset == demoBackdropImageAssets[i],
                onTap: () => onSelected(demoBackdropImageAssets[i]),
                child: Image.asset(demoBackdropImageAssets[i], fit: BoxFit.cover),
              ),
          ],
        ),
      ],
    );
  }
}

class _ImageThumbnail extends StatelessWidget {
  const _ImageThumbnail({
    super.key,
    required this.child,
    required this.isSelected,
    required this.onTap,
  });

  final Widget child;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 56,
        height: 56,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}

/// A titled [Slider] with a caption and a live value label — shared layout
/// for every numeric knob on the Configuration page (backdrop blur/opacity,
/// reveal separation).
class _LabeledSlider extends StatelessWidget {
  const _LabeledSlider({
    required this.sliderKey,
    required this.title,
    required this.caption,
    required this.value,
    required this.min,
    required this.max,
    required this.valueLabel,
    required this.onChanged,
  });

  final Key sliderKey;
  final String title;
  final String caption;
  final double value;
  final double min;
  final double max;
  final String valueLabel;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            Text(valueLabel, style: theme.textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          caption,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        Slider(
          key: sliderKey,
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
