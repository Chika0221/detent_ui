import 'package:flutter/widgets.dart';
import 'package:rive/rive.dart' as rive;

import '../foundation/theme.dart';
import 'skin.dart';

/// Renders bundled script-free artboards, with input and semantics in Flutter.
/// Failure, high contrast and reduced motion preserve [fallback].
class NuiRiveArtwork extends StatefulWidget {
  const NuiRiveArtwork({
    super.key,
    required this.artboard,
    required this.fallback,
    this.state = const NuiSkinState(),
    this.asset = 'packages/detent_ui/assets/rive/detent.riv',
    this.onError,
  });
  final String artboard, asset;
  final Widget fallback;
  final NuiSkinState state;
  final ValueChanged<Object>? onError;
  @override
  State<NuiRiveArtwork> createState() => _NuiRiveArtworkState();
}

/// Files are parsed once while in use; controllers and view models are per widget.
class _RiveAsset {
  _RiveAsset(this.path)
    : future = rive.File.asset(path, riveFactory: rive.Factory.flutter);
  static final assets = <String, _RiveAsset>{};
  static _RiveAsset acquire(String path) {
    final entry = assets.putIfAbsent(path, () => _RiveAsset(path));
    entry.users++;
    return entry;
  }

  final String path;
  final Future<rive.File?> future;
  int users = 0;
  void release() {
    if (--users != 0) return;
    assets.remove(path);
    future.then((file) => file?.dispose(), onError: (Object _) {});
  }
}

class _NuiRiveArtworkState extends State<NuiRiveArtwork> {
  _RiveAsset? lease;
  rive.RiveWidgetController? controller;
  rive.ViewModelInstance? instance;
  final booleans = <String, rive.ViewModelInstanceBoolean>{};
  final numbers = <String, rive.ViewModelInstanceNumber>{};
  final colors = <String, rive.ViewModelInstanceColor>{};
  int generation = 0;
  bool started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final t = NuiTheme.of(context);
    if (!started && !t.highContrast && !t.reduceMotion(context)) {
      started = true;
      load();
    }
  }

  Future<void> load() async {
    final token = ++generation;
    final entry = _RiveAsset.acquire(widget.asset);
    lease = entry;
    try {
      final file = await entry.future;
      if (!mounted || token != generation) return;
      if (file == null) throw StateError('Rive could not load ${widget.asset}');
      final c = rive.RiveWidgetController(
        file,
        artboardSelector: rive.ArtboardSelector.byName(widget.artboard),
      );
      controller = c;
      final v = c.dataBind(rive.DataBind.auto());
      instance = v;
      for (final key in [
        'pressed',
        'selected',
        'hovered',
        'focused',
        'enabled',
      ]) {
        final property = v.boolean(key);
        if (property != null) booleans[key] = property;
      }
      for (final key in [
        'value',
        'secondaryValue',
        'progress',
        'motionScale',
      ]) {
        final property = v.number(key);
        if (property != null) numbers[key] = property;
      }
      for (final key in [
        'surfaceColor',
        'inkColor',
        'accentColor',
        'borderColor',
        'displayColor',
      ]) {
        final property = v.color(key);
        if (property != null) colors[key] = property;
      }
      setState(() {});
    } catch (e) {
      if (mounted && token == generation) {
        clear();
        widget.onError?.call(e);
      }
    }
  }

  void clear() {
    generation++;
    controller?.dispose();
    controller = null;
    for (final p in booleans.values) {
      p.dispose();
    }
    booleans.clear();
    for (final p in numbers.values) {
      p.dispose();
    }
    numbers.clear();
    for (final p in colors.values) {
      p.dispose();
    }
    colors.clear();
    instance?.dispose();
    instance = null;
    lease?.release();
    lease = null;
  }

  @override
  void didUpdateWidget(NuiRiveArtwork old) {
    super.didUpdateWidget(old);
    if (old.asset != widget.asset || old.artboard != widget.artboard) {
      clear();
      started = false;
      final t = NuiTheme.of(context);
      if (!t.highContrast && !t.reduceMotion(context)) {
        started = true;
        load();
      }
    }
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = NuiTheme.of(context), s = widget.state;
    final active =
        !t.highContrast &&
        !t.reduceMotion(context) &&
        TickerMode.valuesOf(context).enabled;
    if (controller != null && controller!.active != active) {
      controller!.active = active;
    }
    if (controller == null || !active) return widget.fallback;
    for (final e in {
      'pressed': s.pressed,
      'selected': s.selected,
      'hovered': s.hovered,
      'focused': s.focused,
      'enabled': s.enabled,
    }.entries) {
      booleans[e.key]?.value = e.value;
    }
    for (final e in {
      'value': s.value,
      'secondaryValue': s.secondaryValue,
      'progress': s.progress,
      'motionScale': s.motionScale,
    }.entries) {
      numbers[e.key]?.value = e.value;
    }
    for (final e in {
      'surfaceColor': t.raised,
      'inkColor': t.ink,
      'accentColor': t.accent,
      'borderColor': t.controlBorder,
      'displayColor': t.display,
    }.entries) {
      colors[e.key]?.value = e.value;
    }
    return ExcludeSemantics(
      child: IgnorePointer(
        child: rive.RiveWidget(controller: controller!, fit: rive.Fit.contain),
      ),
    );
  }
}
