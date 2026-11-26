import 'dart:async';
import 'dart:io';

import 'package:detent_ui/detent_ui.dart';
import 'package:flutter/foundation.dart';

import 'omarchy_theme.dart';

/// Where the active Omarchy theme lives on disk.
@immutable
class OmarchyThemeLocation {
  const OmarchyThemeLocation(this.currentDirectory);

  /// Resolves the active theme directory from the environment.
  ///
  /// Current Omarchy keeps it in `$XDG_STATE_HOME/omarchy/current` (default
  /// `~/.local/state/omarchy/current`); older releases used
  /// `~/.config/omarchy/current`. The first one that contains a theme wins.
  /// Returns null when neither exists (not an Omarchy desktop).
  static OmarchyThemeLocation? detect([Map<String, String>? environment]) {
    final env = environment ?? Platform.environment;
    final home = env['HOME'];
    final stateHome =
        env['XDG_STATE_HOME'] ?? (home == null ? null : '$home/.local/state');
    final configHome =
        env['XDG_CONFIG_HOME'] ?? (home == null ? null : '$home/.config');
    for (final base in [stateHome, configHome]) {
      if (base == null) continue;
      final location = OmarchyThemeLocation('$base/omarchy/current');
      if (File(location.colorsFile).existsSync()) return location;
    }
    return null;
  }

  /// The `current` directory that holds `theme/` and `theme.name`.
  final String currentDirectory;

  String get colorsFile => '$currentDirectory/theme/colors.toml';
  String get nameFile => '$currentDirectory/theme.name';

  /// Reads the theme, or returns null when `colors.toml` is missing.
  Future<OmarchyTheme?> read() async {
    final colors = File(colorsFile);
    if (!await colors.exists()) return null;
    final source = await colors.readAsString();
    return OmarchyTheme.parse(source, name: await _readName());
  }

  Future<String?> _readName() async {
    final file = File(nameFile);
    if (await file.exists()) {
      final name = (await file.readAsString()).trim();
      if (name.isNotEmpty) return name;
    }
    // Legacy layout: `theme` is a symlink to the theme directory.
    try {
      final target = await Link('$currentDirectory/theme').target();
      return target.split('/').lastWhere((part) => part.isNotEmpty);
    } on FileSystemException {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is OmarchyThemeLocation &&
      other.currentDirectory == currentDirectory;

  @override
  int get hashCode => currentDirectory.hashCode;
}

/// Loads the active Omarchy theme and follows `omarchy-theme-set` live.
///
/// Call [start] once, listen for changes, and pass [palette] to
/// [DetentApp.palette]. [palette] stays null when no Omarchy theme is found,
/// so apps fall back to the built-in Detent palette.
class OmarchyThemeController extends ChangeNotifier {
  OmarchyThemeController({
    this.location,
    bool keepDetentAccent = false,
    this.watch = true,
    this.pollInterval = const Duration(seconds: 2),
    this.debounce = const Duration(milliseconds: 150),
  }) : _keepDetentAccent =
           keepDetentAccent; // ignore: prefer_initializing_formals

  /// Theme location; detected from the environment when null.
  final OmarchyThemeLocation? location;

  /// Whether to follow theme changes after the first load.
  final bool watch;

  /// How often `colors.toml` is checked; file events can arrive sooner.
  final Duration pollInterval;

  /// Coalesces the burst of file events produced by one theme switch.
  final Duration debounce;

  OmarchyThemeLocation? _location;
  OmarchyTheme? _theme;
  DetentPalette? _palette;
  bool _keepDetentAccent;
  bool _started = false, _disposed = false;
  StreamSubscription<FileSystemEvent>? _events;
  Timer? _debounceTimer, _pollTimer;
  DateTime? _lastModified;

  /// The active Omarchy theme, or null when none was found.
  OmarchyTheme? get theme => _theme;

  /// Detent palette mapped from [theme], or null when none was found.
  DetentPalette? get palette => _palette;

  /// The resolved location, available after [start].
  OmarchyThemeLocation? get resolvedLocation => _location;

  /// Keep Detent's yellow primary action instead of the theme accent.
  bool get keepDetentAccent => _keepDetentAccent;
  set keepDetentAccent(bool value) {
    if (value == _keepDetentAccent) return;
    _keepDetentAccent = value;
    _palette = _theme?.toPalette(keepDetentAccent: value);
    notifyListeners();
  }

  /// Loads the theme and, when [watch] is true, starts following changes.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    _location = location ?? OmarchyThemeLocation.detect();
    await reload();
    if (watch && !_disposed && _location != null) _startWatching();
  }

  /// Re-reads `colors.toml` and notifies listeners when the theme changed.
  Future<void> reload() async {
    final location = _location ?? this.location;
    if (location == null || _disposed) return;
    OmarchyTheme? next;
    try {
      next = await location.read();
      _lastModified = await _modified(location);
    } on FileSystemException {
      // Mid-switch the theme directory can briefly disappear; keep the
      // previous palette and pick up the next event instead.
      return;
    }
    if (_disposed || next == null || next == _theme) return;
    _theme = next;
    _palette = next.toPalette(keepDetentAccent: _keepDetentAccent);
    notifyListeners();
  }

  void _startWatching() {
    // Recursive watches do not report changes inside existing subdirectories
    // on every platform (e.g. `theme/colors.toml` on Linux), so polling always
    // runs as a safety net and file events only make updates faster.
    _startPolling();
    final directory = Directory(_location!.currentDirectory);
    try {
      _events = directory
          .watch(recursive: true)
          .listen((_) => _scheduleReload(), onError: (Object _) {});
    } on FileSystemException {
      // Polling already covers this case.
    } on UnsupportedError {
      // Polling already covers this case.
    }
  }

  void _startPolling() {
    _pollTimer ??= Timer.periodic(pollInterval, (_) async {
      final location = _location;
      if (location == null) return;
      final modified = await _modified(location);
      if (modified != _lastModified) _scheduleReload();
    });
  }

  void _scheduleReload() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, reload);
  }

  static Future<DateTime?> _modified(OmarchyThemeLocation location) async {
    try {
      return (await File(location.colorsFile).stat()).modified;
    } on FileSystemException {
      return null;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _events?.cancel();
    _debounceTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }
}
