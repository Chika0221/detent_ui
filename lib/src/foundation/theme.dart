import 'package:flutter/widgets.dart';

import 'tokens.g.dart';

abstract final class DetentColors {
  static const transparent = Color(0x00000000),
      black = Color(0xFF000000),
      white = Color(0xFFFFFFFF);
}

enum DetentDensity { compact, standard, comfortable }

enum DetentMotion { system, full, reduced }

enum DetentThemeMode { light, dark, system }

@immutable
class DetentTypography {
  const DetentTypography(this.ink);
  final Color ink;
  TextStyle get bodyMedium => TextStyle(
    fontFamily: 'packages/detent_ui/Manrope',
    fontFamilyFallback: const ['packages/detent_ui/IBM Plex Sans JP'],
    fontSize: 14,
    height: 1.5,
    color: ink,
  );
  TextStyle get title => bodyMedium.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  TextStyle get sectionTitle =>
      bodyMedium.copyWith(fontSize: 16, fontWeight: FontWeight.w600);
  TextStyle get readout => bodyMedium.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w500,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
  TextStyle get bodySmall => bodyMedium.copyWith(fontSize: 12);
  TextStyle get labelLarge =>
      bodyMedium.copyWith(fontWeight: FontWeight.w500, height: 1.35);
}

@immutable
class DetentThemeData {
  const DetentThemeData({
    this.brightness = Brightness.light,
    this.highContrast = false,
    this.density = DetentDensity.standard,
    this.motion = DetentMotion.system,
    this.riveEnabled = true,
  });
  final Brightness brightness;
  final bool highContrast, riveEnabled;
  final DetentDensity density;
  final DetentMotion motion;
  bool get dark => brightness == Brightness.dark;
  double get controlHeight => switch (density) {
    DetentDensity.compact => 32,
    DetentDensity.standard => 40,
    DetentDensity.comfortable => 44,
  };
  DetentTypography get textTheme => DetentTypography(ink);
  Color _color(String role) =>
      detentPalettes[highContrast
          ? (dark ? 'highDark' : 'highLight')
          : (dark ? 'dark' : 'light')]![role]!;
  Color get canvas => _color('bg.canvas');
  Color get chrome => _color('bg.chrome');
  Color get selectionSurface => _color('selection.surface');
  Color get selectionForeground => _color('selection.foreground');
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
  bool reduceMotion(BuildContext context) =>
      motion == DetentMotion.reduced ||
      (motion == DetentMotion.system &&
          MediaQuery.disableAnimationsOf(context));
  Duration duration(BuildContext context, [int milliseconds = 120]) =>
      Duration(milliseconds: reduceMotion(context) ? 0 : milliseconds);
  DetentThemeData copyWith({
    Brightness? brightness,
    bool? highContrast,
    DetentDensity? density,
    DetentMotion? motion,
    bool? riveEnabled,
  }) => DetentThemeData(
    brightness: brightness ?? this.brightness,
    highContrast: highContrast ?? this.highContrast,
    density: density ?? this.density,
    motion: motion ?? this.motion,
    riveEnabled: riveEnabled ?? this.riveEnabled,
  );
}

class DetentTheme extends InheritedTheme {
  DetentTheme({super.key, required this.data, required Widget child})
    : super(
        child: DefaultTextStyle(
          style: data.textTheme.bodyMedium,
          child: IconTheme(
            data: IconThemeData(color: data.ink, size: 16),
            child: child,
          ),
        ),
      );
  final DetentThemeData data;
  static DetentThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DetentTheme>()?.data ??
      DetentThemeData(
        brightness:
            MediaQuery.maybeOf(context)?.platformBrightness ?? Brightness.light,
        highContrast: MediaQuery.maybeOf(context)?.highContrast ?? false,
      );
  @override
  bool updateShouldNotify(DetentTheme oldWidget) => oldWidget.data != data;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      DetentTheme(data: data, child: child);
}

/// Optional convenience host; every component also works in a plain WidgetsApp.
class DetentApp extends StatelessWidget {
  const DetentApp({
    super.key,
    required this.home,
    this.themeMode = DetentThemeMode.system,
    this.density = DetentDensity.standard,
    this.motion = DetentMotion.system,
    this.riveEnabled = true,
    this.highContrast,
    this.title = 'Detent',
  });
  final Widget home;
  final DetentThemeMode themeMode;
  final DetentDensity density;
  final DetentMotion motion;
  final bool riveEnabled;
  final bool? highContrast;
  final String title;
  @override
  Widget build(BuildContext context) => WidgetsApp(
    color: const Color(0xFFE9CF48),
    title: title,
    debugShowCheckedModeBanner: false,
    pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (ctx, _, _) => builder(ctx),
      transitionDuration: Duration.zero,
    ),
    builder: (context, child) {
      final brightness = switch (themeMode) {
        DetentThemeMode.light => Brightness.light,
        DetentThemeMode.dark => Brightness.dark,
        DetentThemeMode.system => MediaQuery.platformBrightnessOf(context),
      };
      return DetentTheme(
        data: DetentThemeData(
          brightness: brightness,
          highContrast: highContrast ?? MediaQuery.highContrastOf(context),
          density: density,
          motion: motion,
          riveEnabled: riveEnabled,
        ),
        child: child!,
      );
    },
    home: home,
  );
}

class DetentDivider extends StatelessWidget {
  const DetentDivider({super.key, this.vertical = false});
  final bool vertical;
  @override
  Widget build(BuildContext context) => vertical
      ? Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: SizedBox(
            width: 1,
            child: ColoredBox(color: DetentTheme.of(context).border),
          ),
        )
      : Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            height: 1,
            child: ColoredBox(color: DetentTheme.of(context).border),
          ),
        );
}

class DetentFocusRing extends StatelessWidget {
  const DetentFocusRing({
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
        color: focused
            ? DetentTheme.of(context).focus
            : DetentColors.transparent,
        width: 2,
      ),
    ),
    child: Padding(padding: const EdgeInsets.all(4), child: child),
  );
}

const detentPalettes = <String, Map<String, Color>>{
  'light': {
    'bg.canvas': DetentTokens.semantic_light_color_bg_canvas,
    'bg.chrome': DetentTokens.semantic_light_color_bg_chrome,
    'selection.surface': DetentTokens.semantic_light_color_selection_surface,
    'selection.foreground':
        DetentTokens.semantic_light_color_selection_foreground,
    'bg.surface': DetentTokens.semantic_light_color_bg_surface,
    'bg.raised': DetentTokens.semantic_light_color_bg_raised,
    'bg.display': DetentTokens.semantic_light_color_bg_display,
    'text.primary': DetentTokens.semantic_light_color_text_primary,
    'text.secondary': DetentTokens.semantic_light_color_text_secondary,
    'text.inverse': DetentTokens.semantic_light_color_text_inverse,
    'border.subtle': DetentTokens.semantic_light_color_border_subtle,
    'border.control': DetentTokens.semantic_light_color_border_control,
    'action.primary': DetentTokens.semantic_light_color_action_primary,
    'action.primaryHover':
        DetentTokens.semantic_light_color_action_primaryHover,
    'action.onPrimary': DetentTokens.semantic_light_color_action_onPrimary,
    'focus.ring': DetentTokens.semantic_light_color_focus_ring,
    'status.danger': DetentTokens.semantic_light_color_status_danger,
    'status.success': DetentTokens.semantic_light_color_status_success,
  },
  'dark': {
    'bg.canvas': DetentTokens.semantic_dark_color_bg_canvas,
    'bg.chrome': DetentTokens.semantic_dark_color_bg_chrome,
    'selection.surface': DetentTokens.semantic_dark_color_selection_surface,
    'selection.foreground':
        DetentTokens.semantic_dark_color_selection_foreground,
    'bg.surface': DetentTokens.semantic_dark_color_bg_surface,
    'bg.raised': DetentTokens.semantic_dark_color_bg_raised,
    'bg.display': DetentTokens.semantic_dark_color_bg_display,
    'text.primary': DetentTokens.semantic_dark_color_text_primary,
    'text.secondary': DetentTokens.semantic_dark_color_text_secondary,
    'text.inverse': DetentTokens.semantic_dark_color_text_inverse,
    'border.subtle': DetentTokens.semantic_dark_color_border_subtle,
    'border.control': DetentTokens.semantic_dark_color_border_control,
    'action.primary': DetentTokens.semantic_dark_color_action_primary,
    'action.primaryHover': DetentTokens.semantic_dark_color_action_primaryHover,
    'action.onPrimary': DetentTokens.semantic_dark_color_action_onPrimary,
    'focus.ring': DetentTokens.semantic_dark_color_focus_ring,
    'status.danger': DetentTokens.semantic_dark_color_status_danger,
    'status.success': DetentTokens.semantic_dark_color_status_success,
  },
  'highLight': {
    'bg.canvas': DetentTokens.semantic_highLight_color_bg_canvas,
    'bg.chrome': DetentTokens.semantic_highLight_color_bg_chrome,
    'selection.surface':
        DetentTokens.semantic_highLight_color_selection_surface,
    'selection.foreground':
        DetentTokens.semantic_highLight_color_selection_foreground,
    'bg.surface': DetentTokens.semantic_highLight_color_bg_surface,
    'bg.raised': DetentTokens.semantic_highLight_color_bg_raised,
    'bg.display': DetentTokens.semantic_highLight_color_bg_display,
    'text.primary': DetentTokens.semantic_highLight_color_text_primary,
    'text.secondary': DetentTokens.semantic_highLight_color_text_secondary,
    'text.inverse': DetentTokens.semantic_highLight_color_text_inverse,
    'border.subtle': DetentTokens.semantic_highLight_color_border_subtle,
    'border.control': DetentTokens.semantic_highLight_color_border_control,
    'action.primary': DetentTokens.semantic_highLight_color_action_primary,
    'action.primaryHover':
        DetentTokens.semantic_highLight_color_action_primaryHover,
    'action.onPrimary': DetentTokens.semantic_highLight_color_action_onPrimary,
    'focus.ring': DetentTokens.semantic_highLight_color_focus_ring,
    'status.danger': DetentTokens.semantic_highLight_color_status_danger,
    'status.success': DetentTokens.semantic_highLight_color_status_success,
  },
  'highDark': {
    'bg.canvas': DetentTokens.semantic_highDark_color_bg_canvas,
    'bg.chrome': DetentTokens.semantic_highDark_color_bg_chrome,
    'selection.surface': DetentTokens.semantic_highDark_color_selection_surface,
    'selection.foreground':
        DetentTokens.semantic_highDark_color_selection_foreground,
    'bg.surface': DetentTokens.semantic_highDark_color_bg_surface,
    'bg.raised': DetentTokens.semantic_highDark_color_bg_raised,
    'bg.display': DetentTokens.semantic_highDark_color_bg_display,
    'text.primary': DetentTokens.semantic_highDark_color_text_primary,
    'text.secondary': DetentTokens.semantic_highDark_color_text_secondary,
    'text.inverse': DetentTokens.semantic_highDark_color_text_inverse,
    'border.subtle': DetentTokens.semantic_highDark_color_border_subtle,
    'border.control': DetentTokens.semantic_highDark_color_border_control,
    'action.primary': DetentTokens.semantic_highDark_color_action_primary,
    'action.primaryHover':
        DetentTokens.semantic_highDark_color_action_primaryHover,
    'action.onPrimary': DetentTokens.semantic_highDark_color_action_onPrimary,
    'focus.ring': DetentTokens.semantic_highDark_color_focus_ring,
    'status.danger': DetentTokens.semantic_highDark_color_status_danger,
    'status.success': DetentTokens.semantic_highDark_color_status_success,
  },
};
