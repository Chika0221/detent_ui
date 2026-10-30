import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:rive/rive.dart' as rive;

import '../foundation/theme.dart';
import 'skin.dart';

typedef NuiRiveVisualBuilder = Widget Function(
  BuildContext context,
  Widget? graphic,
);

/// Script-free Rive graphics. Native inputs can use [builder] to change paint
/// without replacing their focus/gesture/semantics element when assets load.
class NuiRiveArtwork extends StatefulWidget {
  const NuiRiveArtwork({
    super.key,
    required this.artboard,
    this.fallback = const SizedBox.shrink(),
    this.state = const NuiSkinState(),
    this.asset = 'packages/detent_ui/assets/rive/detent.riv',
    this.onError,
    this.onReady,
    this.builder,
    this.resize = false,
    this.stretch = false,
    this.settleOnLoad = true,
  });
  final String artboard, asset;
  final Widget fallback;
  final NuiSkinState state;
  final ValueChanged<Object>? onError;
  final VoidCallback? onReady;
  final NuiRiveVisualBuilder? builder;

  /// Resize the authored canvas and bind pixel dimensions, preserving corners.
  final bool resize, stretch, settleOnLoad;
  @override
  State<NuiRiveArtwork> createState() => _NuiRiveArtworkState();
}

class _RiveAsset {
  _RiveAsset(this.path) : future = _load(path);
  static Future<rive.File?> _load(String path) async {
    if (!await rive.RiveNative.init()) {
      throw StateError('Rive could not initialize');
    }
    return rive.File.asset(path, riveFactory: rive.Factory.flutter);
  }

  static final assets = <String, _RiveAsset>{};
  static _RiveAsset acquire(String path) {
    final a = assets.putIfAbsent(path, () => _RiveAsset(path));
    a.users++;
    return a;
  }

  final String path;
  final Future<rive.File?> future;
  int users = 0;
  void release() {
    if (--users != 0) return;
    assets.remove(path);
    future.then((f) => f?.dispose(), onError: (Object _) {});
  }
}

class _NuiRiveArtworkState extends State<NuiRiveArtwork>
    with WidgetsBindingObserver {
  _RiveAsset? lease;
  rive.RiveWidgetController? controller;
  rive.ViewModelInstance? instance;
  final booleans = <String, rive.ViewModelInstanceBoolean>{};
  final numbers = <String, rive.ViewModelInstanceNumber>{};
  final colors = <String, rive.ViewModelInstanceColor>{};
  int generation = 0;
  bool started = false, visible = false, queued = false;
  ScrollPosition? position;
  bool get foreground =>
      WidgetsBinding.instance.lifecycleState == null ||
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  bool policy(BuildContext context) {
    final t = NuiTheme.of(context);
    return t.riveEnabled &&
        !t.highContrast &&
        !t.reduceMotion(context) &&
        TickerMode.valuesOf(context).enabled;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = Scrollable.maybeOf(context)?.position;
    if (next != position) {
      position?.removeListener(scheduleVisibility);
      position = next;
      position?.addListener(scheduleVisibility);
    }
    scheduleVisibility();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      controller?.active = false;
    }
    scheduleVisibility();
  }

  void scheduleVisibility() {
    if (queued) return;
    queued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      queued = false;
      if (!mounted) return;
      final box = context.findRenderObject();
      var inView = false;
      if (box is RenderBox && box.attached && box.hasSize) {
        final rect = box.localToGlobal(Offset.zero) & box.size;
        var viewport = Offset.zero & MediaQuery.sizeOf(context);
        final scrollBox = Scrollable.maybeOf(context)?.context
            .findRenderObject();
        if (scrollBox is RenderBox && scrollBox.attached && scrollBox.hasSize) {
          viewport = viewport.intersect(
            scrollBox.localToGlobal(Offset.zero) & scrollBox.size,
          );
        }
        inView = rect.overlaps(viewport);
      }
      if (visible != inView) {
        setState(() => visible = inView);
      }
      if (inView && foreground && policy(context) && !started) {
        started = true;
        load();
      }
      final c = controller;
      if (c != null) {
        final active = inView && foreground && policy(context);
        if (c.active != active) c.active = active;
      }
    });
  }

  Future<void> load() async {
    final token = ++generation;
    try {
      final entry = _RiveAsset.acquire(widget.asset);
      lease = entry;
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
      for (final k in [
        'pressed',
        'selected',
        'hovered',
        'focused',
        'enabled',
        'indeterminate',
      ]) {
        final p = v.boolean(k);
        if (p != null) booleans[k] = p;
      }
      for (final k in [
        'value',
        'secondaryValue',
        'progress',
        'motionScale',
        'selectionState',
        'taskState',
        'width',
        'height',
        'centerX',
        'centerY',
        'position',
        'secondaryPosition',
        'extent',
        'segmentWidth',
        'trackWidth',
        'activeStart',
        'activeWidth',
      ]) {
        final p = v.number(k);
        if (p != null) numbers[k] = p;
      }
      for (final k in [
        'surfaceColor',
        'inkColor',
        'accentColor',
        'borderColor',
        'displayColor',
        'focusColor',
        'inverseColor',
        'lineColor',
      ]) {
        final p = v.color(k);
        if (p != null) colors[k] = p;
      }
      apply(Size(c.artboard.widthOriginal, c.artboard.heightOriginal));
      c.advance(0);
      if (widget.settleOnLoad) c.advance(1);
      setState(() {});
      widget.onReady?.call();
      scheduleVisibility();
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

  void apply(Size size) {
    final t = NuiTheme.of(context), s = widget.state;
    final width = size.width, height = size.height;
    final segmented =
        widget.artboard == 'SegmentedControl' || widget.artboard == 'Tabs';
    final count = math.max(1, s.selectionCount), segmentWidth = width / count;
    final trackWidth = math.max(0, width - 48);
    for (final e in {
      'pressed': s.pressed,
      'selected': s.selected,
      'hovered': s.hovered,
      'focused': s.focused,
      'enabled': s.enabled,
      'indeterminate': s.indeterminate,
    }.entries) {
      final p = booleans[e.key];
      if (p != null && p.value != e.value) p.value = e.value;
    }
    for (final e in {
      'value': s.value,
      'secondaryValue': s.secondaryValue,
      'progress': s.progress,
      'motionScale': s.motionScale,
      'selectionState': s.selectionState,
      'taskState': s.taskState,
      'width': width,
      'height': height,
      'centerX': width / 2,
      'centerY': height / 2,
      'position': segmented
          ? segmentWidth / 2 +
                s.value.clamp(0.0, 1.0) * math.max(0, width - segmentWidth)
          : 24 + s.value.clamp(0.0, 1.0) * trackWidth,
      'secondaryPosition': 24 + s.secondaryValue.clamp(0.0, 1.0) * trackWidth,
      'extent': s.progress.clamp(0.0, 1.0) * width,
      'segmentWidth': math.max(0, segmentWidth - 8),
      'trackWidth': trackWidth,
      'activeStart': widget.artboard == 'RangeSlider'
          ? 24 + s.value.clamp(0.0, 1.0) * trackWidth
          : 24.0,
      'activeWidth':
          trackWidth *
          (widget.artboard == 'RangeSlider'
              ? (s.secondaryValue - s.value).clamp(0.0, 1.0)
              : s.value.clamp(0.0, 1.0)),
    }.entries) {
      final p = numbers[e.key];
      if (p != null && p.value != e.value) p.value = e.value.toDouble();
    }
    for (final e in {
      'surfaceColor': s.surfaceColor ?? t.raised,
      'inkColor': s.inkColor ?? t.ink,
      'accentColor': s.accentColor ?? t.accent,
      'borderColor': t.controlBorder,
      'displayColor': t.display,
      'focusColor': t.focus,
      'inverseColor': t.inverse,
      'lineColor': t.border,
    }.entries) {
      final p = colors[e.key];
      if (p != null && p.value != e.value) p.value = e.value;
    }
  }

  @override
  void didUpdateWidget(NuiRiveArtwork old) {
    super.didUpdateWidget(old);
    if (old.asset != widget.asset || old.artboard != widget.artboard) {
      clear();
      started = false;
      scheduleVisibility();
    }
  }

  @override
  void dispose() {
    position?.removeListener(scheduleVisibility);
    WidgetsBinding.instance.removeObserver(this);
    clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = visible && foreground && policy(context);
    final c = controller;
    if (c != null && c.active != active) c.active = active;
    Widget? graphic;
    if (c != null && active) {
      graphic = ExcludeSemantics(
        child: IgnorePointer(
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              final original = Size(
                c.artboard.widthOriginal,
                c.artboard.heightOriginal,
              );
              final size = widget.resize
                  ? Size(
                      constraints.hasBoundedWidth
                          ? constraints.maxWidth
                          : original.width,
                      constraints.hasBoundedHeight
                          ? constraints.maxHeight
                          : original.height,
                    )
                  : original;
              if (widget.resize) {
                if (c.artboard.width != size.width) {
                  c.artboard.width = size.width;
                }
                if (c.artboard.height != size.height) {
                  c.artboard.height = size.height;
                }
              }
              apply(size);
              return rive.RiveWidget(
                controller: c,
                fit: widget.resize || widget.stretch
                    ? rive.Fit.fill
                    : rive.Fit.contain,
              );
            },
          ),
        ),
      );
    }
    return widget.builder?.call(context, graphic) ?? graphic ?? widget.fallback;
  }
}
