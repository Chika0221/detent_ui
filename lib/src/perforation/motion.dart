part of 'perforation.dart';

/// Owns visibility, lifecycle and reduced-motion policy for all moving grids.
class _PerforationMotion extends StatefulWidget {
  const _PerforationMotion({
    required this.enabled,
    required this.animate,
    required this.repeat,
    required this.trigger,
    required this.duration,
    required this.builder,
  });
  final bool enabled, animate, repeat;
  final Object trigger;
  final Duration duration;
  final Widget Function(BuildContext, double phase) builder;

  @override
  State<_PerforationMotion> createState() => _PerforationMotionState();
}

class _PerforationMotionState extends State<_PerforationMotion>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: widget.animate ? 0 : 1,
  );
  final scrolls = <ScrollPosition>{};
  bool visible = false, queued = false;
  bool get foreground =>
      WidgetsBinding.instance.lifecycleState == null ||
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = <ScrollPosition>{};
    context.visitAncestorElements((element) {
      if (element is StatefulElement && element.state is ScrollableState) {
        next.add((element.state as ScrollableState).position);
      }
      return true;
    });
    for (final position in scrolls.difference(next)) {
      position.removeListener(checkVisibility);
    }
    for (final position in next.difference(scrolls)) {
      position.addListener(checkVisibility);
    }
    scrolls
      ..clear()
      ..addAll(next);
    sync();
    checkVisibility();
  }

  @override
  void didUpdateWidget(_PerforationMotion old) {
    super.didUpdateWidget(old);
    controller.duration = widget.duration;
    if (old.trigger != widget.trigger || old.animate != widget.animate) {
      controller.stop();
      controller.value = widget.animate ? 0 : 1;
    }
    sync();
    checkVisibility();
  }

  void sync() {
    final reduced = NuiTheme.of(context).reduceMotion(context);
    if (!widget.enabled || !widget.animate || reduced) {
      controller.stop();
      controller.value = 1;
      return;
    }
    if (!visible || !foreground || !TickerMode.valuesOf(context).enabled) {
      controller.stop();
      return;
    }
    if (!controller.isAnimating) {
      if (widget.repeat) {
        controller.repeat();
      } else if (controller.value < 1) {
        controller.forward();
      }
    }
  }

  void checkVisibility() {
    if (queued) return;
    queued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      queued = false;
      if (!mounted) return;
      final render = context.findRenderObject();
      var next = false;
      if (render is RenderBox && render.attached && render.hasSize) {
        final bounds = render.localToGlobal(Offset.zero) & render.size;
        var viewport = Offset.zero & MediaQuery.sizeOf(context);
        context.visitAncestorElements((element) {
          final ancestor = element.renderObject;
          if (ancestor is RenderAbstractViewport &&
              ancestor is RenderBox &&
              ancestor.attached &&
              (ancestor as RenderBox).hasSize) {
            viewport = viewport.intersect(
              (ancestor as RenderBox).localToGlobal(Offset.zero) &
                  (ancestor as RenderBox).size,
            );
          }
          if (element.widget is Offstage &&
              (element.widget as Offstage).offstage) {
            viewport = Rect.zero;
          }
          return true;
        });
        next = !viewport.isEmpty && bounds.overlaps(viewport);
      }
      visible = next;
      sync();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => sync();
  @override
  void didChangeMetrics() => checkVisibility();

  @override
  void dispose() {
    for (final position in scrolls) {
      position.removeListener(checkVisibility);
    }
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    checkVisibility();
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final curve = NuiTokens.perforation_motion_easing;
          final phase = widget.repeat
              ? controller.value
              : Cubic(
                  curve[0],
                  curve[1],
                  curve[2],
                  curve[3],
                ).transform(controller.value);
          return widget.builder(context, phase);
        },
      ),
    );
  }
}
