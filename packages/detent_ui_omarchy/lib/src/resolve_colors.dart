/// Resolves the semantic Omarchy palette from the raw keys of a `colors.toml`.
///
/// Mirrors Omarchy's `omarchy-theme-color`, which every Omarchy consumer
/// (templates, shell, terminals) shares: legacy short names (`bg`, `fg`, ...)
/// and ANSI `color0..15` are aliased, missing shades are derived the same way,
/// and `mode` follows the same precedence. Keys that are already defined are
/// never replaced.
Map<String, String> resolveOmarchyColors(
  Map<String, String> raw, {
  bool lightModeFile = false,
}) {
  final c = Map<String, String>.of(raw);
  bool has(String key) => (c[key] ?? '').isNotEmpty;
  void alias(String key, String fallback) {
    if (!has(key) && has(fallback)) c[key] = c[fallback]!;
  }

  void fill(String key, String? value) {
    if (!has(key) && value != null && value.isNotEmpty) c[key] = value;
  }

  String? first(List<String> keys) {
    for (final key in keys) {
      if (has(key)) return c[key];
    }
    return null;
  }

  String? mix(String key, String other, double amount) {
    final value = c[key];
    return value == null ? null : mixOmarchyHex(value, other, amount);
  }

  const shortNames = {
    'background': 'bg',
    'dark_background': 'dark_bg',
    'darker_background': 'darker_bg',
    'lighter_background': 'lighter_bg',
    'foreground': 'fg',
    'dark_foreground': 'dark_fg',
    'light_foreground': 'light_fg',
    'bright_foreground': 'bright_fg',
  };
  shortNames.forEach(alias);

  // Themes generated before the semantic palette may only define ANSI names.
  alias('background', 'color0');
  alias('foreground', 'color7');
  if (has('background')) c['color0'] = c['background']!;
  if (has('foreground')) c['color7'] = c['foreground']!;

  const ansiNames = {
    'red': 'color1',
    'green': 'color2',
    'yellow': 'color3',
    'blue': 'color4',
    'magenta': 'color5',
    'cyan': 'color6',
    'bright_red': 'color9',
    'bright_green': 'color10',
    'bright_yellow': 'color11',
    'bright_blue': 'color12',
    'bright_magenta': 'color13',
    'bright_cyan': 'color14',
  };
  ansiNames.forEach(alias);
  alias('magenta', 'purple');
  alias('bright_magenta', 'bright_purple');

  fill('light_foreground', first(['color7', 'foreground']));
  fill('bright_foreground', first(['color15', 'foreground']));
  if (has('bright_foreground')) c['cursor'] = c['bright_foreground']!;
  fill('lighter_background', first(['color0', 'background']));
  fill('dark_foreground', first(['color8', 'foreground']));
  fill('muted', first(['color8', 'dark_foreground']));
  fill(
    'selection',
    first(['selection_background', 'color8', 'color0', 'background']),
  );
  fill('selection_background', c['selection']);
  fill('selection_foreground', c['bright_foreground']);
  fill('orange', c['yellow']);
  fill('brown', mix('orange', '#000000', 0.5));

  fill('dark_background', mix('background', '#000000', 0.25));
  fill('darker_background', mix('background', '#000000', 0.5));
  for (final hue in const [
    'red',
    'yellow',
    'green',
    'cyan',
    'blue',
    'magenta',
  ]) {
    fill('bright_$hue', mix(hue, '#ffffff', 0.2));
  }
  alias('purple', 'magenta');
  alias('bright_purple', 'bright_magenta');

  // Keep the legacy ANSI and short names available to callers of [color].
  const ansiOut = [
    'background',
    'red',
    'green',
    'yellow',
    'blue',
    'magenta',
    'cyan',
    'foreground',
    'muted',
    'bright_red',
    'bright_green',
    'bright_yellow',
    'bright_blue',
    'bright_magenta',
    'bright_cyan',
    'bright_foreground',
  ];
  for (var i = 0; i < ansiOut.length; i++) {
    alias('color$i', ansiOut[i]);
  }
  shortNames.forEach((key, short) {
    if (has(key)) c[short] = c[key]!;
  });

  c['mode'] = _resolveMode(c, lightModeFile);
  c['theme_type'] = c['mode']!;
  return c;
}

/// `mode`, legacy `theme_type`, a `light.mode` file beside `colors.toml`,
/// then background brightness (RGB sum above 382), then dark.
String _resolveMode(Map<String, String> c, bool lightModeFile) {
  final explicit = (c['mode'] ?? '').isNotEmpty ? c['mode'] : c['theme_type'];
  if (explicit != null && explicit.isNotEmpty) return explicit;
  if (lightModeFile) return 'light';
  final bg = c['background'];
  if (bg != null && RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(bg)) {
    var sum = 0;
    for (var i = 1; i < 7; i += 2) {
      sum += int.parse(bg.substring(i, i + 2), radix: 16);
    }
    return sum > 382 ? 'light' : 'dark';
  }
  return 'dark';
}

/// Mixes two `#rrggbb` colors per channel like Omarchy's `mix_color`;
/// [amount] is the share of [end]. Returns null for other formats.
String? mixOmarchyHex(String start, String end, double amount) {
  final a = _rgb(start), b = _rgb(end);
  if (a == null || b == null) return null;
  final t = amount.clamp(0.0, 1.0);
  final buffer = StringBuffer('#');
  for (var i = 0; i < 3; i++) {
    final channel = (a[i] * (1 - t) + b[i] * t + 0.5).floor();
    buffer.write(channel.toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}

List<int>? _rgb(String value) {
  final hex = value.startsWith('#') ? value.substring(1) : value;
  if (hex.length < 6) return null;
  final rgb = int.tryParse(hex.substring(0, 6), radix: 16);
  if (rgb == null) return null;
  return [(rgb >> 16) & 0xFF, (rgb >> 8) & 0xFF, rgb & 0xFF];
}
