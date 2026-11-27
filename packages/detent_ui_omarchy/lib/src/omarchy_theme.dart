import 'package:detent_ui/detent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'colors_toml.dart';
import 'resolve_colors.dart';

/// A snapshot of the active Omarchy theme (`colors.toml`).
@immutable
class OmarchyTheme {
  const OmarchyTheme({
    this.name,
    required this.values,
    this.lightModeFile = false,
  });

  /// Parses the contents of an Omarchy `colors.toml`.
  factory OmarchyTheme.parse(
    String colorsToml, {
    String? name,
    bool lightModeFile = false,
  }) => OmarchyTheme(
    name: name,
    values: parseColorsToml(colorsToml),
    lightModeFile: lightModeFile,
  );

  /// Theme directory name, e.g. `catppuccin-latte`, when known.
  final String? name;

  /// Raw top-level keys from `colors.toml`.
  final Map<String, String> values;

  /// Whether the theme ships a `light.mode` marker file, which Omarchy uses
  /// as a light-mode hint when `colors.toml` has no `mode`.
  final bool lightModeFile;

  /// [values] after Omarchy's alias and fallback cascade, so legacy themes
  /// (`bg`/`fg`, `color0..15`) and missing shades resolve exactly as they do
  /// for every other Omarchy app.
  Map<String, String> get resolved =>
      resolveOmarchyColors(values, lightModeFile: lightModeFile);

  /// Resolved color for [key]; parses `#rgb`, `#rrggbb` or `#rrggbbaa`.
  /// Returns null otherwise.
  Color? color(String key) => parseOmarchyColor(resolved[key]);

  Brightness get brightness => _brightness(resolved);

  /// Maps the Omarchy palette onto Detent roles.
  ///
  /// Roles use the same semantic keys other Omarchy apps use (`dark_background`
  /// for chrome, `lighter_background` for panels, `muted` for borders,
  /// `dark_foreground` for secondary text, `selection`, ...). Each one is
  /// checked for legibility and falls back to a color mixed from `background`
  /// and `foreground` (or a Detent default) when the theme value would be
  /// unreadable, for example a grey `red` used as `status.danger`.
  ///
  /// Set [keepDetentAccent] to keep Detent's yellow primary action while
  /// following the rest of the desktop theme.
  DetentPalette toPalette({bool keepDetentAccent = false}) {
    final r = resolved;
    Color? c(String key) => parseOmarchyColor(r[key]);

    final mode = _brightness(r);
    final dark = mode == Brightness.dark;
    final defaults = DetentPalette.defaults(mode);

    final canvas = c('background') ?? defaults.canvas;
    final ink =
        _legible(c('foreground'), canvas, 4.5) ??
        _bestContrast(canvas, [
          defaults.ink,
          DetentColors.black,
          DetentColors.white,
        ]);

    // Theme surfaces are used as long as body text stays readable on them.
    Color tone(Color? themed, Color fallback) =>
        themed != null && contrastRatio(ink, themed) >= 4.5 ? themed : fallback;

    final chrome = tone(c('dark_background'), _mix(canvas, ink, 0.04));
    final surface = tone(c('lighter_background'), _mix(canvas, ink, 0.08));
    final raised = dark
        ? _mix(surface, ink, 0.08)
        : _mix(canvas, DetentColors.white, 0.6);
    final display = dark
        ? tone(c('darker_background'), _mix(canvas, DetentColors.black, 0.4))
        : _mix(ink, DetentColors.black, 0.4);
    final inverse = _bestContrast(display, [ink, canvas, defaults.inverse]);

    // Omarchy's dim text is `dark_foreground`; nudge it toward `foreground`
    // until it reads, then fall back to the shell's placeholder mix.
    final dim = c('dark_foreground');
    final muted =
        _firstLegible(canvas, 4.5, [
          if (dim != null)
            for (final t in const [0.0, 0.2, 0.4, 0.6]) _mix(dim, ink, t),
          for (final t in const [0.34, 0.3, 0.2, 0.1]) _mix(ink, canvas, t),
        ]) ??
        ink;

    final themeBorder = c('muted');
    final border =
        themeBorder != null && contrastRatio(themeBorder, canvas) >= 1.2
        ? themeBorder
        : _mix(canvas, ink, 0.2);
    // The Omarchy shell draws idle control borders as `foreground` at 40%.
    final controlBorder =
        _firstLegible(canvas, 3, [
          for (final t in const [0.4, 0.5, 0.6, 0.7, 0.8]) _mix(canvas, ink, t),
        ]) ??
        ink;

    final Color accent, accentHover, accentInk;
    final themeAccent = c('accent');
    if (keepDetentAccent || themeAccent == null) {
      accent = defaults.accent;
      accentHover = defaults.accentHover;
      accentInk = defaults.accentInk;
    } else {
      accent = themeAccent;
      accentHover = _hover(themeAccent);
      // Omarchy puts `background` on accent fills.
      accentInk = _onFill(accent, canvas, ink);
    }

    final focus = contrastRatio(accent, canvas) >= 3 ? accent : controlBorder;

    final danger =
        _status(
          canvas,
          [c('red'), c('bright_red'), c('orange')],
          hueCenter: 0,
          hueRange: 30,
        ) ??
        defaults.danger;
    final success =
        _status(
          canvas,
          [c('green'), c('bright_green'), c('cyan')],
          hueCenter: 130,
          hueRange: 50,
        ) ??
        defaults.success;
    final warning = _status(
      canvas,
      [c('yellow'), c('bright_yellow'), c('orange')],
      hueCenter: 45,
      hueRange: 25,
    );
    final info = _status(
      canvas,
      [c('blue'), c('bright_blue'), c('cyan')],
      hueCenter: 215,
      hueRange: 40,
    );

    final themeSelection = c('selection');
    final selectionSurface =
        themeSelection != null && contrastRatio(themeSelection, canvas) >= 1.1
        ? themeSelection
        // The Omarchy shell's selected fill is `foreground` at 18%.
        : _mix(canvas, ink, 0.18);
    final selectionForeground =
        _legible(c('selection_foreground'), selectionSurface, 4.5) ??
        _bestContrast(selectionSurface, [
          ink,
          canvas,
          DetentColors.black,
          DetentColors.white,
        ], minimum: 4.5);

    return DetentPalette(
      brightness: mode,
      canvas: canvas,
      chrome: chrome,
      surface: surface,
      raised: raised,
      display: display,
      ink: ink,
      muted: muted,
      inverse: inverse,
      border: border,
      controlBorder: controlBorder,
      accent: accent,
      accentHover: accentHover,
      accentInk: accentInk,
      focus: focus,
      danger: danger,
      success: success,
      selectionSurface: selectionSurface,
      selectionForeground: selectionForeground,
      warning: warning,
      info: info,
      onDanger: _onFill(danger, canvas, ink),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is OmarchyTheme &&
      other.name == name &&
      other.lightModeFile == lightModeFile &&
      mapEquals(other.values, values);

  @override
  int get hashCode => Object.hash(
    name,
    lightModeFile,
    Object.hashAllUnordered(
      values.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );
}

Brightness _brightness(Map<String, String> resolved) =>
    resolved['mode']?.toLowerCase() == 'light'
    ? Brightness.light
    : Brightness.dark;

/// Text color for a filled [fill]: `background` first, as Omarchy does.
Color _onFill(Color fill, Color canvas, Color ink) => _bestContrast(fill, [
  canvas,
  ink,
  DetentColors.black,
  DetentColors.white,
], minimum: 4.5);

/// Parses an Omarchy hex color (`#rgb`, `#rrggbb`, `#rrggbbaa`).
Color? parseOmarchyColor(String? value) {
  if (value == null) return null;
  var hex = value.trim();
  if (hex.startsWith('#')) hex = hex.substring(1);
  if (hex.length == 3) hex = hex.split('').map((c) => '$c$c').join();
  if (hex.length == 6) hex = '${hex}ff';
  if (hex.length != 8) return null;
  final rgba = int.tryParse(hex, radix: 16);
  if (rgba == null) return null;
  return Color(((rgba & 0xFF) << 24) | (rgba >> 8));
}

/// WCAG contrast ratio between two opaque colors.
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

Color? _legible(Color? color, Color background, double minimum) =>
    color != null && contrastRatio(color, background) >= minimum ? color : null;

Color? _firstLegible(Color background, double minimum, List<Color> options) {
  for (final option in options) {
    if (contrastRatio(option, background) >= minimum) return option;
  }
  return null;
}

/// Prefers the first option meeting [minimum]; otherwise the highest contrast.
Color _bestContrast(
  Color background,
  List<Color> options, {
  double minimum = double.infinity,
}) {
  final legible = _firstLegible(background, minimum, options);
  if (legible != null) return legible;
  return options.reduce(
    (a, b) =>
        contrastRatio(a, background) >= contrastRatio(b, background) ? a : b,
  );
}

Color _hover(Color accent) {
  final hsl = HSLColor.fromColor(accent);
  final lightness = hsl.lightness > 0.75
      ? hsl.lightness - 0.06
      : (hsl.lightness + 0.06).clamp(0.0, 1.0);
  return hsl.withLightness(lightness).toColor();
}

/// First candidate that reads as the intended hue and is visible on [canvas].
Color? _status(
  Color canvas,
  List<Color?> candidates, {
  required double hueCenter,
  required double hueRange,
}) {
  for (final candidate in candidates) {
    if (candidate == null) continue;
    final hsl = HSLColor.fromColor(candidate);
    final distance = ((hsl.hue - hueCenter + 540) % 360 - 180).abs();
    if (hsl.saturation >= 0.3 && distance <= hueRange) {
      return _ensureContrast(candidate, canvas, 3);
    }
  }
  return null;
}

/// Shifts [color]'s lightness away from [background] until it reaches
/// [minimum] contrast, keeping its hue.
Color _ensureContrast(Color color, Color background, double minimum) {
  if (contrastRatio(color, background) >= minimum) return color;
  final darken = background.computeLuminance() > 0.5;
  var hsl = HSLColor.fromColor(color);
  for (var i = 0; i < 20; i++) {
    final lightness = (hsl.lightness + (darken ? -0.03 : 0.03)).clamp(0.0, 1.0);
    hsl = hsl.withLightness(lightness);
    final adjusted = hsl.toColor();
    if (contrastRatio(adjusted, background) >= minimum) return adjusted;
  }
  return hsl.toColor();
}
