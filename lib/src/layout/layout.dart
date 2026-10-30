// Keep compatibility with Flutter's Material re-export during SDK extraction.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../foundation/theme.dart';

import 'package:forui_lucide/forui_lucide.dart';

class NuiAppShell extends StatelessWidget {
  const NuiAppShell({
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
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: NuiTheme.of(context).canvas,
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
                        child: IconButton(
                          tooltip: '補助パネルを開く',
                          icon: const Icon(
                            FLucideIcons.slidersHorizontal,
                            size: 16,
                          ),
                          onPressed: () => showModalBottomSheet<void>(
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

class NuiPanel extends StatelessWidget {
  const NuiPanel({
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
    final t = NuiTheme.of(context);
    return Material(
      color: inset ? t.canvas : t.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: t.border),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (header != null) ...[header!, const NuiDivider()],
            child,
            if (footer != null) ...[const NuiDivider(), footer!],
          ],
        ),
      ),
    );
  }
}

class NuiToolbar extends StatelessWidget {
  const NuiToolbar({
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
      color: NuiTheme.of(context).raised,
      border: Border(bottom: BorderSide(color: NuiTheme.of(context).border)),
    ),
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...children,
        if (overflow.isNotEmpty)
          MenuAnchor(
            menuChildren: overflow,
            builder: (context, c, _) => IconButton(
              tooltip: 'その他の操作',
              icon: const Icon(FLucideIcons.ellipsis, size: 16),
              onPressed: () => c.isOpen ? c.close() : c.open(),
            ),
          ),
      ],
    ),
  );
}

class NuiSplitView extends StatefulWidget {
  const NuiSplitView({
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
  State<NuiSplitView> createState() => _NuiSplitViewState();
}

class _NuiSplitViewState extends State<NuiSplitView> {
  late double extent = widget.initialExtent;
  bool focused = false;
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
      final max = (c.maxWidth - widget.minTrailing - 8).clamp(
        0.0,
        double.infinity,
      );
      if (max < widget.minLeading) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: widget.minLeading + widget.minTrailing + 8,
            height: c.hasBoundedHeight ? c.maxHeight : null,
            child: Row(
              children: [
                SizedBox(width: widget.minLeading, child: widget.leading),
                const SizedBox(width: 8),
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
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: widget.collapsed
                      ? null
                      : (e) => resize(extent + e.delta.dx, max),
                  onDoubleTap: widget.onCollapsedChanged == null
                      ? null
                      : () => widget.onCollapsedChanged!(!widget.collapsed),
                  child: Container(
                    width: 8,
                    color: focused
                        ? NuiTheme.of(context).focus
                        : NuiTheme.of(context).border,
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

class NuiStatusBar extends StatelessWidget {
  const NuiStatusBar({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(8),
    color: NuiTheme.of(context).surface,
    child: DefaultTextStyle.merge(
      style: const TextStyle(fontSize: 12),
      child: Row(children: children),
    ),
  );
}

class NuiScrollArea extends StatefulWidget {
  const NuiScrollArea({
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
  State<NuiScrollArea> createState() => _NuiScrollAreaState();
}

class _NuiScrollAreaState extends State<NuiScrollArea> {
  final own = ScrollController();
  @override
  void dispose() {
    own.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller ?? own;
    return Scrollbar(
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
