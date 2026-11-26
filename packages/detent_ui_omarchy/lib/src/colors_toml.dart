/// Parses the flat `key = "value"` subset of TOML that Omarchy uses for
/// `colors.toml`. Tables, arrays and multi-line strings are ignored.
Map<String, String> parseColorsToml(String source) {
  final values = <String, String>{};
  String? table;
  for (final rawLine in source.split('\n')) {
    final line = _stripComment(rawLine).trim();
    if (line.isEmpty) continue;
    if (line.startsWith('[')) {
      table = line;
      continue;
    }
    // Only top-level keys describe the palette.
    if (table != null) continue;
    final eq = line.indexOf('=');
    if (eq <= 0) continue;
    final key = line.substring(0, eq).trim();
    var value = line.substring(eq + 1).trim();
    if (value.length >= 2 &&
        (value.startsWith('"') && value.endsWith('"') ||
            value.startsWith("'") && value.endsWith("'"))) {
      value = value.substring(1, value.length - 1);
    }
    values[key] = value;
  }
  return values;
}

String _stripComment(String line) {
  String? quote;
  for (var i = 0; i < line.length; i++) {
    final char = line[i];
    if (quote != null) {
      if (char == quote) quote = null;
    } else if (char == '"' || char == "'") {
      quote = char;
    } else if (char == '#') {
      return line.substring(0, i);
    }
  }
  return line;
}
