import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

import 'theme.dart';

export 'package:flutter/widgets.dart';

export 'theme.dart';

class NuiSurface extends StatelessWidget {
  const NuiSurface({
    super.key,
    this.color,
    this.shape,
    this.borderRadius,
    this.elevation = 0,
    required this.child,
  });
  final Color? color;
  final ShapeBorder? shape;
  final BorderRadius? borderRadius;
  final double elevation;
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: ShapeDecoration(
      color: color ?? NuiTheme.of(context).raised,
      shape:
          shape ??
          RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(8),
          ),
      shadows: elevation == 0
          ? null
          : [
              BoxShadow(
                color: NuiColors.black.withValues(alpha: .15),
                blurRadius: elevation * 3,
                offset: Offset(0, elevation),
              ),
            ],
    ),
    child: child,
  );
}

class NuiBox extends StatelessWidget {
  const NuiBox({super.key, required this.body, this.backgroundColor});
  final Widget body;
  final Color? backgroundColor;
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: backgroundColor ?? NuiTheme.of(context).canvas,
    child: body,
  );
}

class NuiInk extends StatefulWidget {
  const NuiInk({
    super.key,
    required this.child,
    this.onTap,
    this.focusNode,
    this.autofocus = false,
    this.color,
    this.hoverColor,
    this.selected = false,
  });
  final Widget child;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final bool autofocus, selected;
  final Color? color, hoverColor;
  @override
  State<NuiInk> createState() => _NuiInkState();
}

class _NuiInkState extends State<NuiInk> {
  bool hover = false, focus = false;
  @override
  Widget build(BuildContext context) => Semantics(
    button: widget.onTap != null,
    enabled: widget.onTap != null,
    selected: widget.selected,
    child: FocusableActionDetector(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      enabled: widget.onTap != null,
      onShowFocusHighlight: (v) => setState(() => focus = v),
      onShowHoverHighlight: (v) => setState(() => hover = v),
      mouseCursor: widget.onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap?.call();
            return null;
          },
        ),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: hover
                ? widget.hoverColor ?? NuiTheme.of(context).surface
                : widget.color,
            border: Border.all(
              color: focus ? NuiTheme.of(context).focus : NuiColors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: widget.child,
        ),
      ),
    ),
  );
}

class NuiPlainButton extends StatelessWidget {
  const NuiPlainButton({
    super.key,
    required this.child,
    this.onPressed,
    this.autofocus = false,
    this.focusNode,
  });
  final Widget child;
  final VoidCallback? onPressed;
  final bool autofocus;
  final FocusNode? focusNode;
  @override
  Widget build(BuildContext context) => NuiInk(
    onTap: onPressed,
    autofocus: autofocus,
    focusNode: focusNode,
    child: Padding(padding: const EdgeInsets.all(8), child: child),
  );
}

class NuiIconAction extends StatelessWidget {
  const NuiIconAction({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.padding = const EdgeInsets.all(6),
    this.constraints = const BoxConstraints(minWidth: 28, minHeight: 28),
  });
  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final EdgeInsetsGeometry padding;
  final BoxConstraints constraints;
  @override
  Widget build(BuildContext context) {
    final button = Semantics(
      label: tooltip,
      child: NuiInk(
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: constraints,
          child: Padding(padding: padding, child: icon),
        ),
      ),
    );
    return tooltip == null ? button : NuiHint(message: tooltip!, child: button);
  }
}

class NuiTile extends StatelessWidget {
  const NuiTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.dense = false,
    this.selected = false,
    this.enabled = true,
    this.contentPadding = const EdgeInsets.all(8),
    this.minTileHeight,
    this.tileColor,
    this.selectedTileColor,
    this.selectedColor,
    this.shape,
  });
  final Widget title;
  final Widget? subtitle, leading, trailing;
  final VoidCallback? onTap;
  final bool dense, selected, enabled;
  final EdgeInsetsGeometry contentPadding;
  final double? minTileHeight;
  final Color? tileColor, selectedTileColor, selectedColor;
  final ShapeBorder? shape;
  @override
  Widget build(BuildContext context) => NuiInk(
    onTap: enabled ? onTap : null,
    selected: selected,
    color: selected ? selectedTileColor : tileColor,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: minTileHeight ?? NuiTheme.of(context).controlHeight,
      ),
      child: Padding(
        padding: contentPadding,
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 8)],
            Expanded(
              child: DefaultTextStyle.merge(
                style: TextStyle(color: selected ? selectedColor : null),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [title, ?subtitle],
                ),
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    ),
  );
}

class NuiPopupController {
  _NuiPopupAnchorState? _anchor;
  NuiPopupController get root => _anchor?.parent?.root ?? this;
  bool get isOpen => _anchor?.portal.isShowing ?? false;
  void open({Offset? position}) => _anchor?.open(position);
  void close() => _anchor?.close();
  static NuiPopupController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_PopupScope>()?.controller;
  void closeAll() {
    final parent = _anchor?.parent;
    close();
    parent?.closeAll();
  }
}

class _PopupScope extends InheritedWidget {
  const _PopupScope({required this.controller, required super.child});
  final NuiPopupController controller;
  @override
  bool updateShouldNotify(_PopupScope old) => old.controller != controller;
}

class NuiPopupAnchor extends StatefulWidget {
  const NuiPopupAnchor({
    super.key,
    this.controller,
    this.childFocusNode,
    required this.menuChildren,
    required this.builder,
    this.alignmentOffset = const Offset(0, 4),
    this.padding = const EdgeInsets.all(8),
    this.focusMenu = false,
    this.onClose,
    this.surfaceColor,
    this.borderColor,
    this.radius = 8,
  });
  final NuiPopupController? controller;
  final FocusNode? childFocusNode;
  final List<Widget> menuChildren;
  final Widget Function(BuildContext, NuiPopupController, Widget?) builder;
  final Offset alignmentOffset;
  final EdgeInsetsGeometry padding;
  final bool focusMenu;
  final Color? surfaceColor, borderColor;
  final double radius;
  final VoidCallback? onClose;
  @override
  State<NuiPopupAnchor> createState() => _NuiPopupAnchorState();
}

class _NuiPopupAnchorState extends State<NuiPopupAnchor> {
  final portal = OverlayPortalController();
  final link = LayerLink();
  final anchor = GlobalKey();
  final menuFocus = FocusScopeNode();
  late final own = NuiPopupController();
  NuiPopupController get control => widget.controller ?? own;
  NuiPopupController? parent;
  Offset? position;
  ScrollPosition? scroll;
  @override
  void initState() {
    super.initState();
    control._anchor = this;
  }

  @override
  void didUpdateWidget(NuiPopupAnchor old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      (old.controller ?? own)._anchor = null;
      control._anchor = this;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    parent = NuiPopupController.maybeOf(context);
    final next = Scrollable.maybeOf(context)?.position;
    if (next != scroll) {
      scroll?.removeListener(close);
      scroll = next;
      scroll?.addListener(close);
    }
  }

  void open(Offset? at) {
    position = at;
    portal.show();
    if (widget.focusMenu) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && portal.isShowing) {
          menuFocus.requestFocus();
          menuFocus.nextFocus();
        }
      });
    }
  }

  void close() {
    if (portal.isShowing) {
      portal.hide();
      widget.onClose?.call();
    }
  }

  @override
  void dispose() {
    scroll?.removeListener(close);
    control._anchor = null;
    menuFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _PopupScope(
    controller: control,
    child: TapRegion(
      groupId: control.root,
      onTapOutside: (_) => close(),
      child: OverlayPortal(
        controller: portal,
        overlayChildBuilder: (ctx) {
          final box = anchor.currentContext!.findRenderObject()! as RenderBox;
          final origin = box.localToGlobal(Offset.zero);
          final rect = origin & box.size;
          final t = NuiTheme.of(context);
          return Positioned.fill(
            child: CompositedTransformFollower(
              link: link,
              showWhenUnlinked: false,
              offset: -origin,
              child: CustomSingleChildLayout(
                delegate: _PopupLayout(
                  rect,
                  position,
                  widget.alignmentOffset,
                  Directionality.of(context),
                ),
                child: TapRegion(
                  groupId: control.root,
                  child: FocusScope(
                    node: menuFocus,
                    canRequestFocus: widget.focusMenu,
                    child: Focus(
                      canRequestFocus: false,
                      skipTraversal: true,
                      onKeyEvent: (_, e) {
                        if (e is KeyUpEvent) return KeyEventResult.ignored;
                        if (e.logicalKey == LogicalKeyboardKey.escape) {
                          close();
                          widget.childFocusNode?.requestFocus();
                          return KeyEventResult.handled;
                        }
                        if (widget.focusMenu &&
                            (e.logicalKey == LogicalKeyboardKey.arrowDown ||
                                e.logicalKey == LogicalKeyboardKey.arrowUp)) {
                          e.logicalKey == LogicalKeyboardKey.arrowDown
                              ? menuFocus.nextFocus()
                              : menuFocus.previousFocus();
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                      child: NuiTheme(
                        data: t,
                        child: NuiSurface(
                          color: widget.surfaceColor ?? t.raised,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(widget.radius),
                            side: BorderSide(
                              color: widget.borderColor ?? t.controlBorder,
                            ),
                          ),
                          child: Padding(
                            padding: widget.padding,
                            child: IntrinsicWidth(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: widget.menuChildren,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        child: CompositedTransformTarget(
          link: link,
          child: KeyedSubtree(
            key: anchor,
            child: Builder(
              builder: (ctx) => widget.builder(ctx, control, null),
            ),
          ),
        ),
      ),
    ),
  );
}

class _PopupLayout extends SingleChildLayoutDelegate {
  _PopupLayout(this.anchor, this.position, this.offset, this.direction);
  final Rect anchor;
  final Offset? position;
  final Offset offset;
  final TextDirection direction;
  @override
  BoxConstraints getConstraintsForChild(BoxConstraints c) => BoxConstraints(
    maxWidth: math.max(0, c.maxWidth - 16),
    maxHeight: math.max(0, c.maxHeight - 16),
  );
  @override
  Offset getPositionForChild(Size size, Size child) {
    final desiredX = position == null
        ? (direction == TextDirection.rtl
              ? anchor.right - child.width
              : anchor.left)
        : anchor.left + position!.dx;
    var y = position == null
        ? anchor.bottom + offset.dy
        : anchor.top + position!.dy;
    if (y + child.height > size.height - 8) {
      y = anchor.top - child.height - offset.dy;
    }
    return Offset(
      (desiredX + offset.dx).clamp(
        8.0,
        math.max(8, size.width - child.width - 8),
      ),
      y.clamp(8.0, math.max(8, size.height - child.height - 8)),
    );
  }

  @override
  bool shouldRelayout(_PopupLayout old) =>
      old.anchor != anchor ||
      old.position != position ||
      old.offset != offset ||
      old.direction != direction;
}

class NuiHint extends StatefulWidget {
  const NuiHint({
    super.key,
    required this.message,
    required this.child,
    this.excludeFromSemantics = false,
  });
  final String message;
  final Widget child;
  final bool excludeFromSemantics;
  @override
  State<NuiHint> createState() => _NuiHintState();
}

class _NuiHintState extends State<NuiHint> {
  final controller = NuiPopupController();
  Timer? timer;
  void hide() {
    timer?.cancel();
    controller.close();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => NuiPopupAnchor(
    controller: controller,
    surfaceColor: NuiTheme.of(context).display,
    borderColor: NuiColors.transparent,
    radius: 5,
    padding: const EdgeInsets.all(8),
    menuChildren: [
      Text(
        widget.message,
        style: NuiTheme.of(context).textTheme.bodySmall
            .copyWith(color: NuiColors.white),
      ),
    ],
    builder: (ctx, c, _) => Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (v) {
        if (v) {
          c.open();
        } else {
          hide();
        }
      },
      child: MouseRegion(
        onEnter: (_) {
          timer = Timer(const Duration(milliseconds: 400), () => c.open());
        },
        onExit: (_) => hide(),
        child: widget.excludeFromSemantics
            ? widget.child
            : Semantics(tooltip: widget.message, child: widget.child),
      ),
    ),
  );
}

Future<T?> showNuiDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = false,
  bool dismissOnEscape = true,
}) {
  final data = NuiTheme.of(context);
  Widget contents(BuildContext ctx) => NuiTheme(
    data: data,
    child: Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.escape): NuiDismissIntent(),
      },
      child: Actions(
        actions: {
          NuiDismissIntent: CallbackAction<NuiDismissIntent>(
            onInvoke: (_) {
              if (dismissOnEscape) Navigator.pop(ctx);
              return null;
            },
          ),
        },
        child: PopScope(
          canPop: dismissOnEscape,
          child: FocusTraversalGroup(
            child: FocusScope(
              autofocus: true,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: builder(ctx),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  return Navigator.of(context).push<T>(
    RawDialogRoute<T>(
      barrierDismissible: barrierDismissible,
      barrierLabel: '閉じる',
      barrierColor: NuiColors.black.withValues(alpha: .4),
      transitionDuration: data.duration(context, 140),
      pageBuilder: (ctx, _, _) => contents(ctx),
    ),
  );
}

class NuiDismissIntent extends Intent {
  const NuiDismissIntent();
}

class NuiDialogFrame extends StatelessWidget {
  const NuiDialogFrame({
    super.key,
    this.title,
    this.content,
    this.actions = const [],
    this.child,
  });
  final Widget? title, content, child;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 456),
    child: NuiSurface(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: NuiTheme.of(context).controlBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child:
            child ??
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title != null) ...[
                  DefaultTextStyle.merge(
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                    child: title!,
                  ),
                  const SizedBox(height: 16),
                ],
                ?content,
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: actions,
                  ),
                ],
              ],
            ),
      ),
    ),
  );
}
