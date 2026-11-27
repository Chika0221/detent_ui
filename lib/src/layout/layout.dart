import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import '../foundation/primitives.dart';
import '../perforation/perforation.dart';

import 'package:flutter/services.dart';

import 'package:forui_lucide/forui_lucide.dart';

class DetentAppShell extends StatelessWidget {
  const DetentAppShell({
    super.key,
    required this.body,
    this.menu,
    this.navigation,
    this.inspector,
    this.statusBar,
    this.toolbar,
  });
  final Widget body;
  final Widget? menu, navigation, inspector, statusBar, toolbar;
  @override
  Widget build(BuildContext context) => DetentBox(
    backgroundColor: DetentTheme.of(context).canvas,
    body: SafeArea(
      child: Column(
        children: [
          ?menu,
          ?toolbar,
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) => Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (navigation != null)
                    SizedBox(
                      width: c.maxWidth < 800 ? 200 : 240,
                      child: navigation,
                    ),
                  Expanded(child: body),
                  if (inspector != null && c.maxWidth >= 1100)
                    SizedBox(width: 288, child: inspector),
                  if (inspector != null && c.maxWidth < 1100)
                    SizedBox(
                      width: 40,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: DetentIconAction(
                          tooltip: '補助パネルを開く',
                          icon: const Icon(
                            FLucideIcons.slidersHorizontal,
                            size: 16,
                          ),
                          onPressed: () => showDetentDialog<void>(
                            context: context,
                            builder: (_) =>
                                SizedBox(height: 440, child: inspector),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          ?statusBar,
        ],
      ),
    ),
  );
}

class DetentPanel extends StatelessWidget {
  const DetentPanel({
    super.key,
    required this.child,
    this.header,
    this.footer,
    this.inset = false,
    this.padding = const EdgeInsets.all(16),
  });
  final Widget child;
  final Widget? header, footer;
  final bool inset;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) {
    final t = DetentTheme.of(context);
    return DetentSurface(
      color: inset ? t.canvas : t.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DetentRadius.panel),
        side: BorderSide(color: t.border),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (header != null) ...[header!, const DetentDivider()],
            child,
            if (footer != null) ...[const DetentDivider(), footer!],
          ],
        ),
      ),
    );
  }
}

class DetentToolbar extends StatelessWidget {
  const DetentToolbar({
    super.key,
    required this.children,
    this.overflow = const [],
  });
  final List<Widget> children, overflow;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: DetentTheme.of(context).raised,
      border: Border(bottom: BorderSide(color: DetentTheme.of(context).border)),
    ),
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...children,
        if (overflow.isNotEmpty)
          DetentPopupAnchor(
            menuChildren: overflow,
            builder: (context, c, _) => DetentIconAction(
              tooltip: 'その他の操作',
              icon: const Icon(FLucideIcons.ellipsis, size: 16),
              onPressed: () => c.isOpen ? c.close() : c.open(),
            ),
          ),
      ],
    ),
  );
}

class DetentSplitView extends StatefulWidget {
  const DetentSplitView({
    super.key,
    required this.leading,
    required this.trailing,
    this.initialExtent = 240,
    this.minLeading = 160,
    this.minTrailing = 240,
    this.onExtentChanged,
    this.collapsed = false,
    this.onCollapsedChanged,
  });
  final Widget leading, trailing;
  final double initialExtent, minLeading, minTrailing;
  final ValueChanged<double>? onExtentChanged;
  final bool collapsed;
  final ValueChanged<bool>? onCollapsedChanged;
  @override
  State<DetentSplitView> createState() => _DetentSplitViewState();
}

class _DetentSplitViewState extends State<DetentSplitView> {
  late double extent = widget.initialExtent;
  bool focused = false, hovered = false, dragging = false;

  /// Handle width: the P1 grip plus 2px on each side for the focus edge.
  static final double _handle = DetentGrip.thickness + 4;
  void resize(double v, double max) {
    setState(() => extent = v.clamp(widget.minLeading, max));
    widget.onExtentChanged?.call(extent);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      if (!c.hasBoundedWidth) {
        return Row(
          children: [
            SizedBox(width: extent, child: widget.leading),
            widget.trailing,
          ],
        );
      }
      final max = (c.maxWidth - widget.minTrailing - _handle).clamp(
        0.0,
        double.infinity,
      );
      if (max < widget.minLeading) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: widget.minLeading + widget.minTrailing + _handle,
            height: c.hasBoundedHeight ? c.maxHeight : null,
            child: Row(
              children: [
                SizedBox(width: widget.minLeading, child: widget.leading),
                SizedBox(width: _handle),
                SizedBox(width: widget.minTrailing, child: widget.trailing),
              ],
            ),
          ),
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.collapsed)
            SizedBox(
              width: extent.clamp(widget.minLeading, max),
              child: widget.leading,
            ),
          Semantics(
            label: 'パネルの幅',
            value: '${extent.round()}',
            increasedValue:
                '${(extent + 16).clamp(widget.minLeading, max).round()}',
            decreasedValue:
                '${(extent - 16).clamp(widget.minLeading, max).round()}',
            onIncrease: () => resize(extent + 16, max),
            onDecrease: () => resize(extent - 16, max),
            child: Focus(
              onFocusChange: (v) => setState(() => focused = v),
              onKeyEvent: (_, e) {
                if (e is KeyUpEvent) return KeyEventResult.ignored;
                if (e.logicalKey == LogicalKeyboardKey.arrowLeft) {
                  resize(extent - 16, max);
                  return KeyEventResult.handled;
                }
                if (e.logicalKey == LogicalKeyboardKey.arrowRight) {
                  resize(extent + 16, max);
                  return KeyEventResult.handled;
                }
                if (e.logicalKey == LogicalKeyboardKey.home) {
                  resize(widget.minLeading, max);
                  return KeyEventResult.handled;
                }
                if (e.logicalKey == LogicalKeyboardKey.end) {
                  resize(max, max);
                  return KeyEventResult.handled;
                }
                if (e.logicalKey == LogicalKeyboardKey.enter &&
                    widget.onCollapsedChanged != null) {
                  widget.onCollapsedChanged!(!widget.collapsed);
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                onEnter: (_) => setState(() => hovered = true),
                onExit: (_) => setState(() => hovered = false),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: widget.collapsed
                      ? null
                      : (_) => setState(() => dragging = true),
                  onHorizontalDragEnd: (_) => setState(() => dragging = false),
                  onHorizontalDragCancel: () =>
                      setState(() => dragging = false),
                  onHorizontalDragUpdate: widget.collapsed
                      ? null
                      : (e) => resize(extent + e.delta.dx, max),
                  onDoubleTap: widget.onCollapsedChanged == null
                      ? null
                      : () => widget.onCollapsedChanged!(!widget.collapsed),
                  // P1 Grip (DESIGN_SYSTEM.md §5.8): the holes fill while
                  // the boundary is hovered, dragged or focused; focus also
                  // draws 2px edges in the focus colour.
                  child: Container(
                    width: _handle,
                    decoration: BoxDecoration(
                      color: DetentTheme.of(context).chrome,
                      border: Border.symmetric(
                        vertical: BorderSide(
                          color: focused
                              ? DetentTheme.of(context).focus
                              : DetentTheme.of(context).border,
                          width: focused ? 2 : 1,
                        ),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: DetentGrip(
                      active: hovered || dragging || focused,
                      enabled: !widget.collapsed,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(child: widget.trailing),
        ],
      );
    },
  );
}

class DetentStatusBar extends StatelessWidget {
  const DetentStatusBar({
    super.key,
    required this.children,
    this.showMark = true,
  });
  final List<Widget> children;

  /// Shows the P3 chassis mark at the right end (DESIGN_SYSTEM.md §5.8).
  /// Keep it on for the window's status bar; turn it off only for a second
  /// status bar in the same window, so each window has exactly one mark.
  final bool showMark;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(8),
    color: DetentTheme.of(context).surface,
    child: DefaultTextStyle.merge(
      style: DetentTheme.of(context).textTheme.caption,
      child: showMark
          ? _MarkedBar(
              content: Row(children: children),
              mark: const DetentChassisMark(),
            )
          : Row(children: children),
    ),
  );
}

/// Lays out the status bar content and keeps the chassis mark at the right
/// end. The content always wins: when its natural width (Spacers count as
/// zero) leaves no room for the mark — a narrow bar or large text — the mark
/// is not shown, so text is never pushed out.
class _MarkedBar extends MultiChildRenderObjectWidget {
  _MarkedBar({required Widget content, required Widget mark})
    : super(children: [content, mark]);

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderMarkedBar();
}

class _MarkedBarParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderMarkedBar extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _MarkedBarParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _MarkedBarParentData> {
  static const _gap = 16.0;
  bool _showMark = true;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _MarkedBarParentData) {
      child.parentData = _MarkedBarParentData();
    }
  }

  RenderBox get _content => firstChild!;
  RenderBox get _mark => lastChild!;

  @override
  double computeMinIntrinsicWidth(double height) =>
      _content.getMinIntrinsicWidth(height);
  @override
  double computeMaxIntrinsicWidth(double height) =>
      _content.getMaxIntrinsicWidth(height) +
      _gap +
      _mark.getMaxIntrinsicWidth(height);
  @override
  double computeMinIntrinsicHeight(double width) => math.max(
    _content.getMinIntrinsicHeight(width),
    _mark.getMinIntrinsicHeight(width),
  );
  @override
  double computeMaxIntrinsicHeight(double width) => math.max(
    _content.getMaxIntrinsicHeight(width),
    _mark.getMaxIntrinsicHeight(width),
  );

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final layout = _plan(constraints, dry: true);
    return layout.size;
  }

  ({Size size, double contentWidth, Size mark}) _plan(
    BoxConstraints constraints, {
    required bool dry,
  }) {
    final width = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : _content.getMaxIntrinsicWidth(double.infinity);
    final mark = dry
        ? _mark.getDryLayout(const BoxConstraints())
        : (_mark..layout(const BoxConstraints(), parentUsesSize: true)).size;
    final natural = _content.getMaxIntrinsicWidth(double.infinity);
    final show = width - natural >= mark.width + _gap;
    final contentWidth = show ? width - mark.width - _gap : width;
    final childConstraints = BoxConstraints.tightFor(width: contentWidth)
        .enforce(constraints.loosen());
    final content = dry
        ? _content.getDryLayout(childConstraints)
        : (_content..layout(childConstraints, parentUsesSize: true)).size;
    if (!dry) _showMark = show;
    final height = math.max(content.height, show ? mark.height : 0.0);
    return (
      size: constraints.constrain(Size(width, height)),
      contentWidth: contentWidth,
      mark: mark,
    );
  }

  @override
  void performLayout() {
    final layout = _plan(constraints, dry: false);
    size = layout.size;
    (_content.parentData! as _MarkedBarParentData).offset = Offset(
      0,
      (size.height - _content.size.height) / 2,
    );
    (_mark.parentData! as _MarkedBarParentData).offset = Offset(
      size.width - layout.mark.width,
      (size.height - layout.mark.height) / 2,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.paintChild(
      _content,
      (_content.parentData! as _MarkedBarParentData).offset + offset,
    );
    if (_showMark) {
      context.paintChild(
        _mark,
        (_mark.parentData! as _MarkedBarParentData).offset + offset,
      );
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final data = _content.parentData! as _MarkedBarParentData;
    return result.addWithPaintOffset(
      offset: data.offset,
      position: position,
      hitTest: (result, transformed) =>
          _content.hitTest(result, position: transformed),
    );
  }
}

class DetentScrollArea extends StatefulWidget {
  const DetentScrollArea({
    super.key,
    required this.child,
    this.controller,
    this.alwaysVisible = false,
    this.axis = Axis.vertical,
  });
  final Widget child;
  final ScrollController? controller;
  final bool alwaysVisible;
  final Axis axis;
  @override
  State<DetentScrollArea> createState() => _DetentScrollAreaState();
}

class _DetentScrollAreaState extends State<DetentScrollArea> {
  final own = ScrollController();
  @override
  void dispose() {
    own.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller ?? own;
    return RawScrollbar(
      controller: c,
      thumbVisibility: widget.alwaysVisible,
      interactive: true,
      child: SingleChildScrollView(
        controller: c,
        scrollDirection: widget.axis,
        child: widget.child,
      ),
    );
  }
}
