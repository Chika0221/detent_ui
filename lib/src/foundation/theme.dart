import 'package:flutter/widgets.dart';

import 'palette.dart';
import 'tokens.g.dart';

export 'palette.dart';

abstract final class DetentColors {
  static const transparent = Color(0x00000000),
      black = Color(0xFF000000),
      white = Color(0xFFFFFFFF);
}

enum DetentDensity { compact, standard, comfortable }

enum DetentMotion { system, full, reduced }

enum DetentThemeMode { light, dark, system }

/// Corner radii from `primitive.radius` (DESIGN_SYSTEM.md §5.3).
abstract final class DetentRadius {
  /// Small position marks, meter cells, and thin indicators.
  static const mark = DetentTokens.primitive_radius_mark;

  /// Buttons, inputs, list rows, and other controls.
  static const control = DetentTokens.primitive_radius_button;

  /// Menus, popovers, tooltips, and toasts.
  static const menu = DetentTokens.primitive_radius_menu;

  /// Panels, cards, dialogs, and displays.
  static const panel = DetentTokens.primitive_radius_panel;

  /// The outer chassis of a device-like surface.
  static const chassis = DetentTokens.primitive_radius_shell;
}

/// Spacing from `primitive.space` and `component.*.button` (§5.3).
abstract final class DetentSpace {
  static const gap = 8.0;
  static const controlInline =
      DetentTokens.component_light_button_paddingInline;
  static const controlBlock = DetentTokens.component_light_button_paddingBlock;
  static const panel = 16.0;
  static const section = 24.0;
}

/// Type roles from DESIGN_SYSTEM.md §5.2. Manrope draws Latin and figures,
/// IBM Plex Sans JP draws Japanese.
@immutable
class DetentTypography {
  const DetentTypography(this.ink);
  final Color ink;

  /// Running text. 14 / 400.
  TextStyle get body => TextStyle(
    fontFamily: 'packages/detent_ui/Manrope',
    fontFamilyFallback: const ['packages/detent_ui/IBM Plex Sans JP'],
    fontSize: DetentTokens.primitive_typeSize_body,
    height: 1.5,
    color: ink,
  );

  /// Page heading. 32 / 600.
  TextStyle get page => body.copyWith(
    fontSize: DetentTokens.primitive_typeSize_page,
    fontWeight: FontWeight.w600,
    height: DetentTokens.primitive_lineHeight_heading,
  );

  /// Section heading. 20 / 500.
  TextStyle get section => body.copyWith(
    fontSize: DetentTokens.primitive_typeSize_section,
    fontWeight: FontWeight.w500,
    height: DetentTokens.primitive_lineHeight_heading,
  );

  /// Component and panel title. 14 / 600.
  TextStyle get componentTitle => body.copyWith(fontWeight: FontWeight.w600);

  /// Labels on buttons, tabs, and other controls. 14 / 500.
  TextStyle get control => body.copyWith(
    fontWeight: FontWeight.w500,
    height: DetentTokens.primitive_lineHeight_control,
  );

  /// Supporting text, units, and metadata. 12 / 400.
  TextStyle get caption => body.copyWith(
    fontSize: DetentTokens.primitive_typeSize_caption,
    height: DetentTokens.primitive_lineHeight_caption,
  );

  /// Instrument values. 20 / 500 with tabular figures.
  TextStyle get readout => body.copyWith(
    fontSize: DetentTokens.primitive_typeSize_section,
    fontWeight: FontWeight.w500,
    height: DetentTokens.primitive_lineHeight_heading,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  @Deprecated('Use body. Will be removed after 0.10.')
  TextStyle get bodyMedium => body;
  @Deprecated('Use caption. Will be removed after 0.10.')
  TextStyle get bodySmall => caption;
  @Deprecated('Use control. Will be removed after 0.10.')
  TextStyle get labelLarge => control;
  @Deprecated('Use section. Will be removed after 0.10.')
  TextStyle get sectionTitle => section;
  @Deprecated('Use page. Will be removed after 0.10.')
  TextStyle get title => page;
}

@immutable
class DetentThemeData {
  const DetentThemeData({
    this.brightness = Brightness.light,
    this.highContrast = false,
    this.density = DetentDensity.standard,
    this.motion = DetentMotion.system,
    this.riveEnabled = true,
    this.palette,
  });
  final Brightness brightness;
  final bool highContrast, riveEnabled;
  final DetentDensity density;
  final DetentMotion motion;

  /// Replaces the built-in colors (and [brightness]) when set.
  final DetentPalette? palette;
  bool get dark => (palette?.brightness ?? brightness) == Brightness.dark;
  double get controlHeight => switch (density) {
    DetentDensity.compact => 32,
    DetentDensity.standard => 40,
    DetentDensity.comfortable => 44,
  };
  DetentTypography get textTheme => DetentTypography(ink);
  Color _color(String role) =>
      palette?.role(role) ??
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
  Color get warning => _color('status.warning');
  Color get info => _color('status.info');
  Color get onDanger => _color('status.onDanger');
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
    DetentPalette? palette,
  }) => DetentThemeData(
    brightness: brightness ?? this.brightness,
    highContrast: highContrast ?? this.highContrast,
    density: density ?? this.density,
    motion: motion ?? this.motion,
    riveEnabled: riveEnabled ?? this.riveEnabled,
    palette: palette ?? this.palette,
  );
}

class DetentTheme extends InheritedTheme {
  DetentTheme({super.key, required this.data, required Widget child})
    : super(
        child: DefaultTextStyle(
          style: data.textTheme.body,
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
    this.palette,
    this.title = 'Detent',
  });
  final Widget home;
  final DetentThemeMode themeMode;
  final DetentDensity density;
  final DetentMotion motion;
  final bool riveEnabled;
  final bool? highContrast;

  /// Custom colors, e.g. from `detent_ui_omarchy`. When set, its brightness
  /// overrides [themeMode].
  final DetentPalette? palette;
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
      final brightness =
          palette?.brightness ??
          switch (themeMode) {
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
          palette: palette,
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
    this.radius = DetentRadius.control,
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
    'status.warning': DetentTokens.semantic_light_color_status_warning,
    'status.info': DetentTokens.semantic_light_color_status_info,
    'status.onDanger': DetentTokens.semantic_light_color_status_onDanger,
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
    'status.warning': DetentTokens.semantic_dark_color_status_warning,
    'status.info': DetentTokens.semantic_dark_color_status_info,
    'status.onDanger': DetentTokens.semantic_dark_color_status_onDanger,
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
    'status.warning': DetentTokens.semantic_highLight_color_status_warning,
    'status.info': DetentTokens.semantic_highLight_color_status_info,
    'status.onDanger': DetentTokens.semantic_highLight_color_status_onDanger,
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
    'status.warning': DetentTokens.semantic_highDark_color_status_warning,
    'status.info': DetentTokens.semantic_highDark_color_status_info,
    'status.onDanger': DetentTokens.semantic_highDark_color_status_onDanger,
  },
};
