import 'package:flutter/widgets.dart';

import 'tokens.g.dart';

abstract final class NuiColors {
  static const transparent = Color(0x00000000),
      black = Color(0xFF000000),
      white = Color(0xFFFFFFFF);
}

enum NuiDensity { compact, standard, comfortable }

enum NuiMotion { system, full, reduced }

enum NuiThemeMode { light, dark, system }

@immutable
class NuiTypography {
  const NuiTypography(this.ink);
  final Color ink;
  TextStyle get bodyMedium => TextStyle(
    fontFamily: 'packages/detent_ui/Manrope',
    fontFamilyFallback: const ['packages/detent_ui/IBM Plex Sans JP'],
    fontSize: 14,
    height: 1.5,
    color: ink,
  );
  TextStyle get bodySmall => bodyMedium.copyWith(fontSize: 12);
  TextStyle get labelLarge =>
      bodyMedium.copyWith(fontWeight: FontWeight.w500, height: 1.35);
}

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
  final bool highContrast, riveEnabled;
  final NuiDensity density;
  final NuiMotion motion;
  bool get dark => brightness == Brightness.dark;
  double get controlHeight => switch (density) {
    NuiDensity.compact => 32,
    NuiDensity.standard => 40,
    NuiDensity.comfortable => 44,
  };
  NuiTypography get textTheme => NuiTypography(ink);
  Color _color(String role) =>
      nuiPalettes[highContrast
          ? (dark ? 'highDark' : 'highLight')
          : (dark ? 'dark' : 'light')]![role]!;
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
}

class NuiTheme extends InheritedTheme {
  NuiTheme({super.key, required this.data, required Widget child})
    : super(
        child: DefaultTextStyle(
          style: data.textTheme.bodyMedium,
          child: IconTheme(
            data: IconThemeData(color: data.ink, size: 16),
            child: child,
          ),
        ),
      );
  final NuiThemeData data;
  static NuiThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NuiTheme>()?.data ??
      NuiThemeData(
        brightness:
            MediaQuery.maybeOf(context)?.platformBrightness ?? Brightness.light,
        highContrast: MediaQuery.maybeOf(context)?.highContrast ?? false,
      );
  @override
  bool updateShouldNotify(NuiTheme oldWidget) => oldWidget.data != data;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      NuiTheme(data: data, child: child);
}

/// Optional convenience host; every component also works in a plain WidgetsApp.
class NuiApp extends StatelessWidget {
  const NuiApp({
    super.key,
    required this.home,
    this.themeMode = NuiThemeMode.system,
    this.density = NuiDensity.standard,
    this.motion = NuiMotion.system,
    this.riveEnabled = true,
    this.highContrast,
    this.title = 'Detent',
  });
  final Widget home;
  final NuiThemeMode themeMode;
  final NuiDensity density;
  final NuiMotion motion;
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
        NuiThemeMode.light => Brightness.light,
        NuiThemeMode.dark => Brightness.dark,
        NuiThemeMode.system => MediaQuery.platformBrightnessOf(context),
      };
      return NuiTheme(
        data: NuiThemeData(
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

class NuiDivider extends StatelessWidget {
  const NuiDivider({super.key, this.vertical = false});
  final bool vertical;
  @override
  Widget build(BuildContext context) => vertical
      ? Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: SizedBox(
            width: 1,
            child: ColoredBox(color: NuiTheme.of(context).border),
          ),
        )
      : Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            height: 1,
            child: ColoredBox(color: NuiTheme.of(context).border),
          ),
        );
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
        color: focused ? NuiTheme.of(context).focus : NuiColors.transparent,
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
