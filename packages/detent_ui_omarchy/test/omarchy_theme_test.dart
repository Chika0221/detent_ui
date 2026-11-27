import 'dart:io';

import 'package:detent_ui/detent_ui.dart';
import 'package:detent_ui_omarchy/detent_ui_omarchy.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _latte = '''
mode = "light"
accent = "#1e66f5"
selection = "#ccd0da"
muted = "#acb0be"
background = "#eff1f5" # trailing comment
foreground = "#4c4f69"
red = "#d20f39"
green = "#40a02b"
''';

// Monochrome theme whose red/green are greys.
const _greyscale = '''
mode = "dark"
accent = "#798186"
selection = "#343d41"
background = "#101315"
foreground = "#cacccc"
red = "#565d60"
green = "#9fa5a9"
bright_red = "#de6145"
bright_green = "#343d41"

[extra]
background = "#ffffff"
''';

// Current Omarchy schema with semantic shades (flexoki-light).
const _flexoki = '''
mode = "light"
accent = "#205EA6"
selection = "#CECDC3"
muted = "#B7B5AC"
background = "#FFFCF0"
dark_background = "#f2efe4"
darker_background = "#e5e2d8"
lighter_background = "#E6E4D9"
foreground = "#100F0F"
dark_foreground = "#878580"
light_foreground = "#403E3C"
bright_foreground = "#100F0F"
red = "#D14D41"
yellow = "#D0A215"
green = "#879A39"
blue = "#205EA6"
''';

// Pre-semantic theme with short and ANSI names only.
const _legacy = '''
bg = "#282828"
fg = "#ebdbb2"
color1 = "#cc241d"
color2 = "#98971a"
color4 = "#458588"
color8 = "#928374"
''';

void main() {
  test('parses colors.toml values and hex formats', () {
    final theme = OmarchyTheme.parse(_latte);
    expect(theme.values['background'], '#eff1f5');
    expect(theme.color('background'), const Color(0xFFEFF1F5));
    expect(parseOmarchyColor('#abc'), const Color(0xFFAABBCC));
    expect(parseOmarchyColor('#11223380'), const Color(0x80112233));
    expect(parseOmarchyColor('rgb(1,2,3)'), isNull);
    expect(
      OmarchyTheme.parse(_greyscale).color('background'),
      const Color(0xFF101315),
    );
  });

  test('maps a light theme onto Detent roles', () {
    final palette = OmarchyTheme.parse(_latte).toPalette();
    expect(palette.brightness, Brightness.light);
    expect(palette.canvas, const Color(0xFFEFF1F5));
    expect(palette.ink, const Color(0xFF4C4F69));
    expect(palette.accent, const Color(0xFF1E66F5));
    expect(palette.danger, const Color(0xFFD20F39));
    // Latte's green is too light on its canvas; it is darkened, not replaced.
    expect(
      contrastRatio(palette.success, palette.canvas),
      greaterThanOrEqualTo(3),
    );
    expect(
      HSLColor.fromColor(palette.success).hue,
      closeTo(HSLColor.fromColor(const Color(0xFF40A02B)).hue, 2),
    );
    expect(
      contrastRatio(palette.accentInk, palette.accent),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrastRatio(palette.muted, palette.canvas),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('uses the semantic keys other Omarchy apps use', () {
    final palette = OmarchyTheme.parse(_flexoki).toPalette();
    expect(palette.canvas, const Color(0xFFFFFCF0));
    expect(palette.chrome, const Color(0xFFF2EFE4)); // dark_background
    expect(palette.surface, const Color(0xFFE6E4D9)); // lighter_background
    expect(palette.border, const Color(0xFFB7B5AC)); // muted
    expect(palette.selectionSurface, const Color(0xFFCECDC3)); // selection
    expect(palette.selectionForeground, const Color(0xFF100F0F));
    // Text on accent fills is the background, as in Omarchy templates.
    expect(palette.accentInk, const Color(0xFFFFFCF0));
    expect(palette.warning, isNotNull);
    expect(palette.info, isNotNull);
    // Secondary text starts from dark_foreground and is darkened until legible.
    expect(
      contrastRatio(palette.muted, palette.canvas),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      HSLColor.fromColor(palette.muted).hue,
      closeTo(HSLColor.fromColor(const Color(0xFF878580)).hue, 15),
    );
  });

  test('resolves legacy themes like omarchy-theme-color', () {
    final theme = OmarchyTheme.parse(_legacy);
    expect(theme.color('background'), const Color(0xFF282828));
    expect(theme.color('red'), const Color(0xFFCC241D));
    expect(theme.resolved['muted'], '#928374');
    expect(theme.resolved['dark_background'], '#1e1e1e');
    expect(theme.resolved['bright_red'], '#d6504a');
    final palette = theme.toPalette();
    expect(palette.brightness, Brightness.dark);
    expect(palette.ink, const Color(0xFFEBDBB2));
    // Gruvbox red is too dark on its canvas; it is lightened, not replaced.
    expect(
      contrastRatio(palette.danger, palette.canvas),
      greaterThanOrEqualTo(3),
    );
    expect(
      HSLColor.fromColor(palette.danger).hue,
      closeTo(HSLColor.fromColor(const Color(0xFFCC241D)).hue, 2),
    );
  });

  test('resolves mode with Omarchy precedence', () {
    Brightness mode(String toml, {bool lightModeFile = false}) =>
        OmarchyTheme.parse(toml, lightModeFile: lightModeFile).brightness;
    expect(
      mode('theme_type = "light"\nbackground = "#000000"'),
      Brightness.light,
    );
    expect(
      mode('background = "#202020"', lightModeFile: true),
      Brightness.light,
    );
    // RGB sum above 382 counts as light even below 0.5 relative luminance.
    expect(mode('background = "#8a8a8a"'), Brightness.light);
    expect(mode('background = "#7f7f7f"'), Brightness.dark);
    expect(mode('mode = "dark"\nbackground = "#ffffff"'), Brightness.dark);
  });

  test('falls back when status colors are not recognisable', () {
    final palette = OmarchyTheme.parse(_greyscale).toPalette();
    expect(palette.brightness, Brightness.dark);
    expect(palette.danger, const Color(0xFFDE6145));
    expect(palette.success, DetentPalette.defaults(Brightness.dark).success);
  });

  test('keepDetentAccent keeps the Detent primary action', () {
    final palette = OmarchyTheme.parse(_latte)
        .toPalette(keepDetentAccent: true);
    expect(palette.accent, DetentPalette.defaults(Brightness.light).accent);
  });

  test('controller loads and follows theme switches', () async {
    final root = await Directory.systemTemp.createTemp('omarchy');
    addTearDown(() => root.delete(recursive: true));
    final current = Directory('${root.path}/omarchy/current/theme');
    await current.create(recursive: true);
    final colors = File('${current.path}/colors.toml');
    await colors.writeAsString(_latte);
    await File('${root.path}/omarchy/current/theme.name')
        .writeAsString('catppuccin-latte\n');

    final location = OmarchyThemeLocation.detect({
      'XDG_STATE_HOME': root.path,
    })!;
    final controller = OmarchyThemeController(
      location: location,
      debounce: const Duration(milliseconds: 10),
      pollInterval: const Duration(milliseconds: 50),
    );
    addTearDown(controller.dispose);
    await controller.start();
    expect(controller.theme!.name, 'catppuccin-latte');
    expect(controller.palette!.brightness, Brightness.light);

    await colors.writeAsString(_greyscale);
    for (var i = 0; i < 100 && controller.palette!.dark != true; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    expect(controller.palette!.brightness, Brightness.dark);
  });

  test('detect returns null without an Omarchy theme', () async {
    final root = await Directory.systemTemp.createTemp('no-omarchy');
    addTearDown(() => root.delete(recursive: true));
    expect(
      OmarchyThemeLocation.detect({
        'HOME': root.path,
        'XDG_STATE_HOME': root.path,
        'XDG_CONFIG_HOME': root.path,
      }),
      isNull,
    );
  });

  testWidgets('DetentApp applies a custom palette', (tester) async {
    final palette = OmarchyTheme.parse(_latte).toPalette();
    late DetentThemeData data;
    await tester.pumpWidget(
      DetentApp(
        themeMode: DetentThemeMode.dark,
        palette: palette,
        home: Builder(
          builder: (context) {
            data = DetentTheme.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(data.dark, isFalse);
    expect(data.canvas, palette.canvas);
    expect(data.accent, palette.accent);
  });
}

extension on DetentPalette {
  bool get dark => brightness == Brightness.dark;
}
