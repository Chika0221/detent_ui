import 'package:detent_ui/detent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'colors_toml.dart';

/// A snapshot of the active Omarchy theme (`colors.toml`).
@immutable
class OmarchyTheme {
  const OmarchyTheme({this.name, required this.values});

  /// Parses the contents of an Omarchy `colors.toml`.
  factory OmarchyTheme.parse(String colorsToml, {String? name}) =>
      OmarchyTheme(name: name, values: parseColorsToml(colorsToml));

  /// Theme directory name, e.g. `catppuccin-latte`, when known.
  final String? name;

  /// Raw top-level keys from `colors.toml`.
  final Map<String, String> values;

  /// Parses `#rgb`, `#rrggbb` or `#rrggbbaa` values. Returns null otherwise.
  Color? color(String key) => parseOmarchyColor(values[key]);

  Brightness get brightness {
    switch (values['mode']?.toLowerCase()) {
      case 'light':
        return Brightness.light;
      case 'dark':
        return Brightness.dark;
    }
    final bg = color('background');
    if (bg == null) return Brightness.dark;
    return bg.computeLuminance() > 0.5 ? Brightness.light : Brightness.dark;
  }

  /// Maps the Omarchy palette onto Detent roles.
  ///
  /// Omarchy themes vary widely, so every role is checked for legibility and
  /// falls back to a derived or Detent default color when the theme value would
  /// be unreadable (for example a grey `red` used as `status.danger`).
  ///
  /// Set [keepDetentAccent] to keep Detent's yellow primary action while
  /// following the rest of the desktop theme.
  DetentPalette toPalette({bool keepDetentAccent = false}) {
    final mode = brightness;
    final dark = mode == Brightness.dark;
    final defaults = DetentPalette.defaults(mode);

    final canvas = color('background') ?? defaults.canvas;
    final ink =
        _legible(color('foreground'), canvas, 7) ??
        _bestContrast(canvas, [
          defaults.ink,
          DetentColors.black,
          DetentColors.white,
        ]);

    final chrome = _mix(canvas, ink, 0.04);
    final surface = _mix(canvas, ink, 0.08);
    final raised = dark
        ? _mix(canvas, ink, 0.16)
        : _mix(canvas, DetentColors.white, 0.6);
    final display = dark
        ? _mix(canvas, DetentColors.black, 0.4)
        : _mix(ink, DetentColors.black, 0.4);
    final inverse = _bestContrast(display, [ink, canvas, defaults.inverse]);

    final muted =
        _firstLegible(canvas, 4.5, [
          for (final t in const [0.4, 0.3, 0.2, 0.1]) _mix(ink, canvas, t),
        ]) ??
        ink;
    final border = _mix(canvas, ink, 0.2);
    final controlBorder =
        _firstLegible(canvas, 3, [
          for (final t in const [0.5, 0.6, 0.7, 0.8]) _mix(canvas, ink, t),
        ]) ??
        ink;

    final Color accent, accentHover, accentInk;
    final themeAccent = color('accent');
    if (keepDetentAccent || themeAccent == null) {
      accent = defaults.accent;
      accentHover = defaults.accentHover;
      accentInk = defaults.accentInk;
    } else {
      accent = themeAccent;
      accentHover = _hover(themeAccent);
      accentInk = _bestContrast(accent, [
        ink,
        canvas,
        DetentColors.black,
        DetentColors.white,
      ], minimum: 4.5);
    }

    final focus = contrastRatio(accent, canvas) >= 3 ? accent : controlBorder;

    final danger =
        _status(
          canvas,
          [color('red'), color('bright_red'), color('orange')],
          hueCenter: 0,
          hueRange: 30,
        ) ??
        defaults.danger;
    final success =
        _status(
          canvas,
          [color('green'), color('bright_green'), color('cyan')],
          hueCenter: 130,
          hueRange: 50,
        ) ??
        defaults.success;

    final themeSelection = color('selection_background') ?? color('selection');
    final selectionSurface =
        themeSelection != null && contrastRatio(themeSelection, canvas) >= 1.1
        ? themeSelection
        : _mix(canvas, ink, 0.14);
    final selectionForeground =
        _legible(color('selection_foreground'), selectionSurface, 4.5) ??
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
    );
  }

  @override
  bool operator ==(Object other) =>
      other is OmarchyTheme &&
      other.name == name &&
      mapEquals(other.values, values);

  @override
  int get hashCode => Object.hash(
    name,
    Object.hashAllUnordered(
      values.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );
}

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
