// Keep compatibility with Flutter's Material re-export during SDK extraction.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import 'tokens.g.dart';

enum NuiDensity { compact, standard, comfortable }

enum NuiMotion { system, full, reduced }

@immutable
class NuiThemeData {
  const NuiThemeData({
    this.brightness = Brightness.light,
    this.highContrast = false,
    this.density = NuiDensity.standard,
    this.motion = NuiMotion.system,
    this.riveEnabled = true,
  });
  final Brightness brightness;
  final bool highContrast;
  final NuiDensity density;
  final NuiMotion motion;
  final bool riveEnabled;
  bool get dark => brightness == Brightness.dark;
  double get controlHeight => switch (density) {
    NuiDensity.compact => NuiTokens.density_compact_controlHeight,
    NuiDensity.standard => NuiTokens.density_standard_controlHeight,
    NuiDensity.comfortable => NuiTokens.density_comfortable_controlHeight,
  };
  Color get canvas => _color('bg.canvas');
  Color get surface => _color('bg.surface');
  Color get raised => _color('bg.raised');
  Color get display => _color('bg.display');
  Color get ink => _color('text.primary');
  Color get muted => _color('text.secondary');
  Color get inverse => _color('text.inverse');
  Color get border => _color('border.subtle');
  Color get controlBorder => _color('border.control');
  Color get accent => _color('action.primary');
  Color get accentHover => _color('action.primaryHover');
  Color get accentInk => _color('action.onPrimary');
  Color get focus => _color('focus.ring');
  Color get danger => _color('status.danger');
  Color get success => _color('status.success');
  Color _color(String role) =>
      nuiPalettes['${highContrast ? 'high' : ''}${highContrast ? (dark ? 'Dark' : 'Light') : (dark ? 'dark' : 'light')}']![role]!;
  bool reduceMotion(BuildContext context) =>
      motion == NuiMotion.reduced ||
      (motion == NuiMotion.system && MediaQuery.disableAnimationsOf(context));
  Duration duration(BuildContext context, [int milliseconds = 120]) =>
      Duration(milliseconds: reduceMotion(context) ? 0 : milliseconds);
  NuiThemeData copyWith({
    Brightness? brightness,
    bool? highContrast,
    NuiDensity? density,
    NuiMotion? motion,
    bool? riveEnabled,
  }) => NuiThemeData(
    brightness: brightness ?? this.brightness,
    highContrast: highContrast ?? this.highContrast,
    density: density ?? this.density,
    motion: motion ?? this.motion,
    riveEnabled: riveEnabled ?? this.riveEnabled,
  );
  ThemeData get materialTheme {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: accent,
          brightness: brightness,
        ).copyWith(
          primary: ink,
          onPrimary: raised,
          secondary: accent,
          onSecondary: accentInk,
          surface: raised,
          onSurface: ink,
          error: danger,
          outline: controlBorder,
        );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      fontFamily: 'packages/detent_ui/Manrope',
      fontFamilyFallback: const ['packages/detent_ui/IBM Plex Sans JP'],
    );
    return base.copyWith(
      textTheme: base.textTheme
          .apply(fontSizeFactor: 1)
          .copyWith(
            bodyMedium: base.textTheme.bodyMedium!.copyWith(
              fontSize: 14,
              height: 1.5,
            ),
            labelLarge: base.textTheme.labelLarge!.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
      iconTheme: IconThemeData(size: 16, color: ink),
      dividerColor: border,
      focusColor: focus,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: raised,
        isDense: true,
        contentPadding: const EdgeInsets.all(8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: controlBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: controlBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: focus, width: 2),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? ink : raised,
        ),
        checkColor: WidgetStatePropertyAll(raised),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? accent : raised,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? display : border,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: ink,
        inactiveTrackColor: border,
        thumbColor: raised,
        overlayColor: focus.withValues(alpha: .15),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: ink,
        linearTrackColor: border,
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(raised),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: controlBorder),
            ),
          ),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: display,
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: base.textTheme.bodySmall!.copyWith(
          color: inverse,
          fontSize: 12,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: raised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: controlBorder),
        ),
      ),
    );
  }
}

class NuiTheme extends InheritedWidget {
  const NuiTheme({super.key, required this.data, required super.child});
  final NuiThemeData data;
  static NuiThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NuiTheme>()?.data ??
      NuiThemeData(
        brightness: Theme.of(context).brightness,
        highContrast: MediaQuery.highContrastOf(context),
      );
  @override
  bool updateShouldNotify(NuiTheme oldWidget) => data != oldWidget.data;
}

/// Applies Detent's Material adapter locally, including popup/menu typography.
class NuiApp extends StatelessWidget {
  const NuiApp({
    super.key,
    required this.home,
    this.themeMode = ThemeMode.system,
    this.density = NuiDensity.standard,
    this.motion = NuiMotion.system,
    this.riveEnabled = true,
    this.highContrast,
    this.title = 'Detent',
  });
  final Widget home;
  final ThemeMode themeMode;
  final NuiDensity density;
  final NuiMotion motion;
  final bool riveEnabled;
  final bool? highContrast;
  final String title;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: title,
    debugShowCheckedModeBanner: false,
    themeMode: themeMode,
    themeAnimationDuration: motion == NuiMotion.reduced
        ? Duration.zero
        : const Duration(milliseconds: 200),
    theme: NuiThemeData(density: density).materialTheme,
    darkTheme: NuiThemeData(
      brightness: Brightness.dark,
      density: density,
    ).materialTheme,
    builder: (context, child) {
      final data = NuiThemeData(
        brightness: Theme.of(context).brightness,
        highContrast: highContrast ?? MediaQuery.highContrastOf(context),
        density: density,
        motion: motion,
        riveEnabled: riveEnabled,
      );
      return NuiTheme(
        data: data,
        child: Theme(data: data.materialTheme, child: child!),
      );
    },
    home: home,
  );
}

class NuiDivider extends StatelessWidget {
  const NuiDivider({super.key, this.vertical = false});
  final bool vertical;
  @override
  Widget build(BuildContext context) => vertical
      ? VerticalDivider(width: 16, color: NuiTheme.of(context).border)
      : Divider(height: 16, color: NuiTheme.of(context).border);
}

class NuiFocusRing extends StatelessWidget {
  const NuiFocusRing({
    super.key,
    required this.child,
    required this.focused,
    this.radius = 6,
  });
  final Widget child;
  final bool focused;
  final double radius;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius + 4),
      border: Border.all(
        color: focused ? NuiTheme.of(context).focus : Colors.transparent,
        width: 2,
      ),
    ),
    child: Padding(padding: const EdgeInsets.all(4), child: child),
  );
}

const nuiPalettes = <String, Map<String, Color>>{
  'light': {
    'bg.canvas': NuiTokens.semantic_light_color_bg_canvas,
    'bg.surface': NuiTokens.semantic_light_color_bg_surface,
    'bg.raised': NuiTokens.semantic_light_color_bg_raised,
    'bg.display': NuiTokens.semantic_light_color_bg_display,
    'text.primary': NuiTokens.semantic_light_color_text_primary,
    'text.secondary': NuiTokens.semantic_light_color_text_secondary,
    'text.inverse': NuiTokens.semantic_light_color_text_inverse,
    'border.subtle': NuiTokens.semantic_light_color_border_subtle,
    'border.control': NuiTokens.semantic_light_color_border_control,
    'action.primary': NuiTokens.semantic_light_color_action_primary,
    'action.primaryHover': NuiTokens.semantic_light_color_action_primaryHover,
    'action.onPrimary': NuiTokens.semantic_light_color_action_onPrimary,
    'focus.ring': NuiTokens.semantic_light_color_focus_ring,
    'status.danger': NuiTokens.semantic_light_color_status_danger,
    'status.success': NuiTokens.semantic_light_color_status_success,
  },
  'dark': {
    'bg.canvas': NuiTokens.semantic_dark_color_bg_canvas,
    'bg.surface': NuiTokens.semantic_dark_color_bg_surface,
    'bg.raised': NuiTokens.semantic_dark_color_bg_raised,
    'bg.display': NuiTokens.semantic_dark_color_bg_display,
    'text.primary': NuiTokens.semantic_dark_color_text_primary,
    'text.secondary': NuiTokens.semantic_dark_color_text_secondary,
    'text.inverse': NuiTokens.semantic_dark_color_text_inverse,
    'border.subtle': NuiTokens.semantic_dark_color_border_subtle,
    'border.control': NuiTokens.semantic_dark_color_border_control,
    'action.primary': NuiTokens.semantic_dark_color_action_primary,
    'action.primaryHover': NuiTokens.semantic_dark_color_action_primaryHover,
    'action.onPrimary': NuiTokens.semantic_dark_color_action_onPrimary,
    'focus.ring': NuiTokens.semantic_dark_color_focus_ring,
    'status.danger': NuiTokens.semantic_dark_color_status_danger,
    'status.success': NuiTokens.semantic_dark_color_status_success,
  },
  'highLight': {
    'bg.canvas': NuiTokens.semantic_highLight_color_bg_canvas,
    'bg.surface': NuiTokens.semantic_highLight_color_bg_surface,
    'bg.raised': NuiTokens.semantic_highLight_color_bg_raised,
    'bg.display': NuiTokens.semantic_highLight_color_bg_display,
    'text.primary': NuiTokens.semantic_highLight_color_text_primary,
    'text.secondary': NuiTokens.semantic_highLight_color_text_secondary,
    'text.inverse': NuiTokens.semantic_highLight_color_text_inverse,
    'border.subtle': NuiTokens.semantic_highLight_color_border_subtle,
    'border.control': NuiTokens.semantic_highLight_color_border_control,
    'action.primary': NuiTokens.semantic_highLight_color_action_primary,
    'action.primaryHover':
        NuiTokens.semantic_highLight_color_action_primaryHover,
    'action.onPrimary': NuiTokens.semantic_highLight_color_action_onPrimary,
    'focus.ring': NuiTokens.semantic_highLight_color_focus_ring,
    'status.danger': NuiTokens.semantic_highLight_color_status_danger,
    'status.success': NuiTokens.semantic_highLight_color_status_success,
  },
  'highDark': {
    'bg.canvas': NuiTokens.semantic_highDark_color_bg_canvas,
    'bg.surface': NuiTokens.semantic_highDark_color_bg_surface,
    'bg.raised': NuiTokens.semantic_highDark_color_bg_raised,
    'bg.display': NuiTokens.semantic_highDark_color_bg_display,
    'text.primary': NuiTokens.semantic_highDark_color_text_primary,
    'text.secondary': NuiTokens.semantic_highDark_color_text_secondary,
    'text.inverse': NuiTokens.semantic_highDark_color_text_inverse,
    'border.subtle': NuiTokens.semantic_highDark_color_border_subtle,
    'border.control': NuiTokens.semantic_highDark_color_border_control,
    'action.primary': NuiTokens.semantic_highDark_color_action_primary,
    'action.primaryHover':
        NuiTokens.semantic_highDark_color_action_primaryHover,
    'action.onPrimary': NuiTokens.semantic_highDark_color_action_onPrimary,
    'focus.ring': NuiTokens.semantic_highDark_color_focus_ring,
    'status.danger': NuiTokens.semantic_highDark_color_status_danger,
    'status.success': NuiTokens.semantic_highDark_color_status_success,
  },
};
