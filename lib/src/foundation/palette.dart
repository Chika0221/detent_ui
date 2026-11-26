import 'package:flutter/widgets.dart';

import 'theme.dart';

/// A complete set of Detent color roles.
///
/// Pass one to [DetentApp.palette] or [DetentThemeData.palette] to replace the
/// built-in colors, e.g. with a palette synced from the desktop theme. When a
/// palette is set it wins over `highContrast`, and [brightness] decides
/// light/dark artwork.
@immutable
class DetentPalette {
  const DetentPalette({
    required this.brightness,
    required this.canvas,
    required this.chrome,
    required this.surface,
    required this.raised,
    required this.display,
    required this.ink,
    required this.muted,
    required this.inverse,
    required this.border,
    required this.controlBorder,
    required this.accent,
    required this.accentHover,
    required this.accentInk,
    required this.focus,
    required this.danger,
    required this.success,
    required this.selectionSurface,
    required this.selectionForeground,
  });

  /// Builds a palette from semantic role names such as `bg.canvas`.
  factory DetentPalette.fromRoles(
    Brightness brightness,
    Map<String, Color> roles,
  ) => DetentPalette(
    brightness: brightness,
    canvas: roles['bg.canvas']!,
    chrome: roles['bg.chrome']!,
    surface: roles['bg.surface']!,
    raised: roles['bg.raised']!,
    display: roles['bg.display']!,
    ink: roles['text.primary']!,
    muted: roles['text.secondary']!,
    inverse: roles['text.inverse']!,
    border: roles['border.subtle']!,
    controlBorder: roles['border.control']!,
    accent: roles['action.primary']!,
    accentHover: roles['action.primaryHover']!,
    accentInk: roles['action.onPrimary']!,
    focus: roles['focus.ring']!,
    danger: roles['status.danger']!,
    success: roles['status.success']!,
    selectionSurface: roles['selection.surface']!,
    selectionForeground: roles['selection.foreground']!,
  );

  /// The built-in Detent palette.
  static DetentPalette defaults(
    Brightness brightness, {
    bool highContrast = false,
  }) {
    final dark = brightness == Brightness.dark;
    final key = highContrast
        ? (dark ? 'highDark' : 'highLight')
        : (dark ? 'dark' : 'light');
    return _defaults[key] ??= DetentPalette.fromRoles(
      brightness,
      detentPalettes[key]!,
    );
  }

  static final _defaults = <String, DetentPalette>{};

  final Brightness brightness;
  final Color canvas,
      chrome,
      surface,
      raised,
      display,
      ink,
      muted,
      inverse,
      border,
      controlBorder,
      accent,
      accentHover,
      accentInk,
      focus,
      danger,
      success,
      selectionSurface,
      selectionForeground;

  /// Looks up a color by semantic role name; null for unknown roles.
  Color? role(String role) => switch (role) {
    'bg.canvas' => canvas,
    'bg.chrome' => chrome,
    'bg.surface' => surface,
    'bg.raised' => raised,
    'bg.display' => display,
    'text.primary' => ink,
    'text.secondary' => muted,
    'text.inverse' => inverse,
    'border.subtle' => border,
    'border.control' => controlBorder,
    'action.primary' => accent,
    'action.primaryHover' => accentHover,
    'action.onPrimary' => accentInk,
    'focus.ring' => focus,
    'status.danger' => danger,
    'status.success' => success,
    'selection.surface' => selectionSurface,
    'selection.foreground' => selectionForeground,
    _ => null,
  };

  List<Object> get _props => [
    brightness,
    canvas,
    chrome,
    surface,
    raised,
    display,
    ink,
    muted,
    inverse,
    border,
    controlBorder,
    accent,
    accentHover,
    accentInk,
    focus,
    danger,
    success,
    selectionSurface,
    selectionForeground,
  ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DetentPalette) return false;
    final a = _props, b = other._props;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(_props);
}
