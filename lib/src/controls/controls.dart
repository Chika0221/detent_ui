import 'dart:math' as math;

import '../foundation/primitives.dart';
import '../inputs/inputs.dart';

import 'package:flutter/services.dart';
import 'package:forui_lucide/forui_lucide.dart';

import '../rive/artwork.dart';
import '../rive/skin.dart';
import '../rive/control_skin.dart';

enum NuiButtonVariant { primary, secondary, quiet, danger }

class NuiButton extends StatefulWidget {
  const NuiButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = NuiButtonVariant.secondary,
    this.loading = false,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final NuiButtonVariant variant;
  final bool loading;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? semanticLabel;
  @override
  State<NuiButton> createState() => _NuiButtonState();
}

class _NuiButtonState extends State<NuiButton> {
  bool pressed = false, hovered = false, focused = false;
  LogicalKeyboardKey? keyboardPress;
  final ownFocus = FocusNode();
  FocusNode get node => widget.focusNode ?? ownFocus;
  bool get enabled => widget.onPressed != null && !widget.loading;
  void performAction() {
    if (enabled) widget.onPressed!();
  }

  @override
  void dispose() {
    ownFocus.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(NuiButton old) {
    super.didUpdateWidget(old);
    if (!enabled) {
      pressed = false;
      keyboardPress = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = NuiTheme.of(context);
    final bg = switch (widget.variant) {
      NuiButtonVariant.primary => hovered ? t.accentHover : t.accent,
      NuiButtonVariant.danger => t.danger,
      NuiButtonVariant.quiet => hovered ? t.surface : NuiColors.transparent,
      NuiButtonVariant.secondary => hovered ? t.surface : t.raised,
    };
    final fg = widget.variant == NuiButtonVariant.primary
        ? t.accentInk
        : widget.variant == NuiButtonVariant.danger
        ? (t.dark ? NuiColors.black : NuiColors.white)
        : t.ink;
    final curve = const Cubic(.2, 0, .2, 1);
    Widget face(Widget child) => AnimatedContainer(
      duration: t.duration(context, pressed ? 60 : 120),
      curve: curve,
      transform: Matrix4.translationValues(0, pressed ? 2 : 0, 0),
      child: child,
    );
    final fallback = Stack(
      children: [
        if (widget.variant != NuiButtonVariant.quiet && !t.highContrast)
          Positioned.fill(
            top: 2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: t.controlBorder,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        Positioned.fill(
          bottom: 2,
          child: face(
            DecoratedBox(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: widget.variant == NuiButtonVariant.quiet
                      ? NuiColors.transparent
                      : t.controlBorder,
                ),
              ),
            ),
          ),
        ),
      ],
    );
    final content = Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: face(
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: t.controlHeight, minWidth: 28),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: IconTheme(
              data: IconThemeData(color: fg, size: 16),
              child: DefaultTextStyle(
                style: NuiTheme.of(context).textTheme.labelLarge
                    .copyWith(color: fg),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) Icon(widget.icon),
                    if (widget.icon != null && widget.label.isNotEmpty)
                      const SizedBox(width: 8),
                    if (widget.label.isNotEmpty || widget.loading)
                      Flexible(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Opacity(
                              opacity: widget.loading ? 0 : 1,
                              child: Text(
                                widget.label,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            if (widget.loading)
                              SizedBox.square(
                                dimension: 16,
                                child: NuiRiveArtwork(
                                  artboard: 'Spinner',
                                  state: NuiSkinState(
                                    indeterminate: true,
                                    progress: .24,
                                    inkColor: fg,
                                  ),
                                  fallback: const Icon(
                                    FLucideIcons.loader,
                                    semanticLabel: '処理中',
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return Semantics(
      button: true,
      excludeSemantics: true,
      enabled: enabled,
      onTap: enabled ? performAction : null,
      label: widget.semanticLabel ?? widget.label,
      value: widget.loading ? '処理中' : null,
      child: Focus(
        skipTraversal: true,
        canRequestFocus: false,
        onKeyEvent: (_, e) {
          if (!enabled) return KeyEventResult.ignored;
          final key = e.logicalKey;
          if (key == LogicalKeyboardKey.escape && keyboardPress != null) {
            setState(() {
              pressed = false;
              keyboardPress = null;
            });
            return KeyEventResult.handled;
          }
          if (key != LogicalKeyboardKey.space &&
              key != LogicalKeyboardKey.enter) {
            return KeyEventResult.ignored;
          }
          if (e is KeyDownEvent) {
            keyboardPress = key;
            setState(() => pressed = true);
          }
          if (e is KeyUpEvent && keyboardPress == key) {
            keyboardPress = null;
            setState(() => pressed = false);
            performAction();
          }
          return KeyEventResult.handled;
        },
        child: FocusableActionDetector(
          focusNode: node,
          autofocus: widget.autofocus,
          enabled: enabled,
          onFocusChange: (v) {
            if (!v && pressed) {
              setState(() {
                pressed = false;
                keyboardPress = null;
              });
            }
          },
          onShowFocusHighlight: (v) => setState(() => focused = v),
          onShowHoverHighlight: (v) => setState(() => hovered = v),
          mouseCursor: enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                performAction();
                return null;
              },
            ),
          },
          child: GestureDetector(
            onTap: enabled ? performAction : null,
            onTapDown: enabled
                ? (_) {
                    node.requestFocus();
                    setState(() => pressed = true);
                  }
                : null,
            onTapCancel: () => setState(() => pressed = false),
            onTapUp: (_) => setState(() => pressed = false),
            child: Opacity(
              opacity: enabled || widget.loading ? 1 : .45,
              child: NuiFocusRing(
                focused: focused,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: NuiRiveArtwork(
                        artboard: widget.variant == NuiButtonVariant.quiet
                            ? 'FlatButton'
                            : 'Button',
                        resize: true,
                        state: NuiSkinState(
                          pressed: pressed,
                          hovered: hovered,
                          focused: focused,
                          enabled: enabled,
                          surfaceColor: bg,
                        ),
                        fallback: fallback,
                      ),
                    ),
                    content,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NuiIconButton extends StatelessWidget {
  const NuiIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.selected = false,
    this.focusNode,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool selected;
  final FocusNode? focusNode;
  @override
  Widget build(BuildContext context) => NuiHint(
    message: tooltip,
    child: Semantics(
      toggled: selected,
      child: SizedBox(
        width: NuiTheme.of(context).controlHeight + 10,
        child: NuiButton(
          label: '',
          semanticLabel: tooltip,
          icon: icon,
          onPressed: onPressed,
          focusNode: focusNode,
          variant: selected
              ? NuiButtonVariant.primary
              : NuiButtonVariant.secondary,
        ),
      ),
    ),
  );
}

class NuiToggleButton extends StatelessWidget {
  const NuiToggleButton({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
    this.icon,
  });
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Semantics(
    toggled: value,
    child: NuiButton(
      label: label,
      icon: icon,
      variant: value ? NuiButtonVariant.primary : NuiButtonVariant.secondary,
      onPressed: onChanged == null ? null : () => onChanged!(!value),
    ),
  );
}

/// Keyboard width in units of the key pitch. A standard 1u face is 40px;
/// the 8px inter-key gap makes 1.5u = 64px, 2u = 88px and 6.25u = 292px.
class NuiKeycap extends StatelessWidget {
  const NuiKeycap({
    super.key,
    required this.label,
    this.pressed = false,
    this.units = 1,
  }) : assert(units >= .5 && units < double.infinity);
  final String label;
  final bool pressed;
  final double units;
  @override
  Widget build(BuildContext context) {
    final t = NuiTheme.of(context),
        width = (NuiTheme.of(context).controlHeight + 8) * units - 8;
    final bg = pressed ? t.accent : t.raised;
    return Semantics(
      label: label,
      value: pressed ? '押下中' : null,
      excludeSemantics: true,
      child: SizedBox(
        width: width,
        height: t.controlHeight + 2,
        child: Stack(
          children: [
            Positioned.fill(
              child: NuiRiveArtwork(
                artboard: 'Keycap',
                resize: true,
                state: NuiSkinState(pressed: pressed, surfaceColor: bg),
                fallback: Stack(
                  children: [
                    Positioned.fill(
                      top: 2,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: t.controlBorder,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      bottom: 2,
                      child: Transform.translate(
                        offset: Offset(0, pressed ? 2 : 0),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: bg,
                            border: Border.all(color: t.controlBorder),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: AnimatedContainer(
                duration: t.duration(context, pressed ? 60 : 120),
                curve: const Cubic(.2, 0, .2, 1),
                transform: Matrix4.translationValues(0, pressed ? 2 : 0, 0),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: pressed ? t.accentInk : t.ink,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@immutable
class NuiOption<T> {
  const NuiOption(this.value, this.label, {this.icon, this.enabled = true});
  final T value;
  final String label;
  final IconData? icon;
  final bool enabled;
}

class NuiSegmentedControl<T> extends StatefulWidget {
  const NuiSegmentedControl({
    super.key,
    required this.options,
    required this.value,
    this.onChanged,
  });
  final List<NuiOption<T>> options;
  final T value;
  final ValueChanged<T>? onChanged;
  @override
  State<NuiSegmentedControl<T>> createState() => _NuiSegmentedControlState<T>();
}

class _NuiSegmentedControlState<T> extends State<NuiSegmentedControl<T>> {
  final nodes = <T, FocusNode>{};
  @override
  void dispose() {
    for (final n in nodes.values) {
      n.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget, t = NuiTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.controlBorder),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: NuiControlSkin(
          artboard: 'SegmentedControl',
          resize: true,
          state: NuiSkinState(
            value: w.options.length < 2
                ? 0
                : w.options.indexWhere((o) => o.value == w.value) /
                      (w.options.length - 1),
            selectionCount: w.options.length.toDouble(),
            enabled: w.onChanged != null,
          ),
          inputBuilder: (context, painted) => LayoutBuilder(
            builder: (ctx, c) {
              final children = [
                for (final o in w.options)
                  Focus(
                    canRequestFocus: false,
                    skipTraversal: true,
                    onKeyEvent: (_, e) {
                      if (e is KeyUpEvent || w.onChanged == null) {
                        return KeyEventResult.ignored;
                      }
                      final k = e.logicalKey;
                      if (k != LogicalKeyboardKey.arrowLeft &&
                          k != LogicalKeyboardKey.arrowRight) {
                        return KeyEventResult.ignored;
                      }
                      final enabled = w.options
                          .where((o) => o.enabled)
                          .toList();
                      if (enabled.isEmpty) return KeyEventResult.handled;
                      final index =
                          (enabled.indexOf(o) +
                              (k == LogicalKeyboardKey.arrowRight ? 1 : -1)) %
                          enabled.length;
                      nodes[enabled[index].value]?.requestFocus();
                      w.onChanged!(enabled[index].value);
                      return KeyEventResult.handled;
                    },
                    child: NuiInk(
                      focusNode: nodes.putIfAbsent(o.value, FocusNode.new),
                      selected: o.value == w.value,
                      onTap: w.onChanged == null || !o.enabled
                          ? null
                          : () => w.onChanged!(o.value),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: t.controlHeight + 10,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (o.icon != null) ...[
                                Icon(
                                  o.icon,
                                  size: 16,
                                  color: o.value == w.value
                                      ? t.accentInk
                                      : t.ink,
                                ),
                                const SizedBox(width: 8),
                              ],
                              Flexible(
                                child: Text(
                                  o.label,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: !o.enabled
                                        ? t.muted
                                        : o.value == w.value
                                        ? t.accentInk
                                        : t.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ];
              return c.hasBoundedWidth
                  ? Row(
                      children: [
                        for (final child in children) Expanded(child: child),
                      ],
                    )
                  : IntrinsicWidth(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: children,
                      ),
                    );
            },
          ),
        ),
      ),
    );
  }
}

class NuiCheckbox extends StatelessWidget {
  const NuiCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.label,
    this.tristate = false,
    this.focusNode,
  }) : assert(tristate || value != null);
  final bool? value;
  final ValueChanged<bool?>? onChanged;
  final String? label;
  final bool tristate;
  final FocusNode? focusNode;
  @override
  Widget build(BuildContext context) {
    void toggle() => onChanged?.call(
      value == false
          ? true
          : value == true && tristate
          ? null
          : false,
    );
    return Semantics(
      checked: value == true,
      mixed: value == null,
      label: label,
      enabled: onChanged != null,
      onTap: onChanged == null ? null : toggle,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          NuiInk(
            focusNode: focusNode,
            onTap: onChanged == null ? null : toggle,
            child: NuiControlSkin(
              artboard: 'Checkbox',
              visualSize: const Size(24, 24),
              state: NuiSkinState(
                selected: value != false,
                selectionState: value == null
                    ? 2
                    : value == true
                    ? 1
                    : 0,
                enabled: onChanged != null,
              ),
              inputBuilder: (_, _) => const SizedBox(width: 40, height: 40),
            ),
          ),
          if (label != null) ...[
            const SizedBox(width: 8),
            Flexible(child: ExcludeSemantics(child: Text(label!))),
          ],
        ],
      ),
    );
  }
}

class NuiRadioGroup<T> extends StatefulWidget {
  const NuiRadioGroup({
    super.key,
    required this.options,
    required this.value,
    this.onChanged,
  });
  final List<NuiOption<T>> options;
  final T? value;
  final ValueChanged<T>? onChanged;
  @override
  State<NuiRadioGroup<T>> createState() => _NuiRadioGroupState<T>();
}

class _NuiRadioGroupState<T> extends State<NuiRadioGroup<T>> {
  final nodes = <T, FocusNode>{};
  @override
  void dispose() {
    for (final node in nodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final o in w.options)
          Focus(
            canRequestFocus: false,
            skipTraversal: true,
            onKeyEvent: (_, e) {
              if (e is KeyUpEvent || w.onChanged == null) {
                return KeyEventResult.ignored;
              }
              final k = e.logicalKey;
              if (![
                LogicalKeyboardKey.arrowUp,
                LogicalKeyboardKey.arrowDown,
                LogicalKeyboardKey.arrowLeft,
                LogicalKeyboardKey.arrowRight,
              ].contains(k)) {
                return KeyEventResult.ignored;
              }
              final enabled = w.options.where((o) => o.enabled).toList();
              if (enabled.isEmpty) return KeyEventResult.handled;
              final next =
                  enabled[(enabled.indexOf(o) +
                          (k == LogicalKeyboardKey.arrowUp ||
                                  k == LogicalKeyboardKey.arrowLeft
                              ? -1
                              : 1)) %
                      enabled.length];
              nodes[next.value]?.requestFocus();
              w.onChanged!(next.value);
              return KeyEventResult.handled;
            },
            child: Semantics(
              checked: w.value == o.value,
              inMutuallyExclusiveGroup: true,
              label: o.label,
              enabled: w.onChanged != null && o.enabled,
              child: NuiInk(
                focusNode: nodes.putIfAbsent(o.value, FocusNode.new),
                onTap: w.onChanged == null || !o.enabled
                    ? null
                    : () => w.onChanged!(o.value),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    NuiControlSkin(
                      artboard: 'RadioGroup',
                      visualSize: const Size(24, 24),
                      state: NuiSkinState(
                        selected: w.value == o.value,
                        enabled: w.onChanged != null && o.enabled,
                      ),
                      inputBuilder: (_, _) =>
                          const SizedBox(width: 40, height: 40),
                    ),
                    const SizedBox(width: 8),
                    Flexible(child: ExcludeSemantics(child: Text(o.label))),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class NuiSwitch extends StatelessWidget {
  const NuiSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.label,
    this.focusNode,
  });
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;
  final FocusNode? focusNode;
  @override
  Widget build(BuildContext context) => Semantics(
    toggled: value,
    label: label,
    enabled: onChanged != null,
    child: NuiInk(
      focusNode: focusNode,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          NuiControlSkin(
            artboard: 'Switch',
            visualSize: const Size(48, 28),
            state: NuiSkinState(
              selected: value,
              enabled: onChanged != null,
              surfaceColor: value
                  ? NuiTheme.of(context).display
                  : NuiTheme.of(context).border,
              inkColor: value
                  ? NuiTheme.of(context).accent
                  : NuiTheme.of(context).raised,
            ),
            inputBuilder: (_, _) => const SizedBox(width: 56, height: 40),
          ),
          if (label != null) ...[
            const SizedBox(width: 8),
            Flexible(child: ExcludeSemantics(child: Text(label!))),
          ],
        ],
      ),
    ),
  );
}

double? _adjustValue(
  LogicalKeyboardKey key,
  double value,
  double min,
  double max,
  double step,
) {
  if (key == LogicalKeyboardKey.home) return min;
  if (key == LogicalKeyboardKey.end) return max;
  if (key == LogicalKeyboardKey.pageUp) {
    return (value + step * 10).clamp(min, max);
  }
  if (key == LogicalKeyboardKey.pageDown) {
    return (value - step * 10).clamp(min, max);
  }
  if (key == LogicalKeyboardKey.arrowUp ||
      key == LogicalKeyboardKey.arrowRight) {
    return (value + step).clamp(min, max);
  }
  if (key == LogicalKeyboardKey.arrowDown ||
      key == LogicalKeyboardKey.arrowLeft) {
    return (value - step).clamp(min, max);
  }
  return null;
}

@immutable
class NuiRangeValues {
  const NuiRangeValues(this.start, this.end) : assert(start <= end);
  final double start, end;
  @override
  bool operator ==(Object other) =>
      other is NuiRangeValues && other.start == start && other.end == end;
  @override
  int get hashCode => Object.hash(start, end);
}

typedef RangeValues = NuiRangeValues;

class NuiSlider extends StatefulWidget {
  const NuiSlider({
    super.key,
    required this.value,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.onChanged,
    this.label,
  }) : assert(min <= max),
       assert(value >= min && value <= max),
       assert(divisions == null || divisions > 0);
  final double value, min, max;
  final int? divisions;
  final ValueChanged<double>? onChanged;
  final String? label;
  @override
  State<NuiSlider> createState() => _NuiSliderState();
}

class _NuiSliderState extends State<NuiSlider> {
  final focus = FocusNode();
  @override
  void dispose() {
    focus.dispose();
    super.dispose();
  }

  void change(double v) {
    final w = widget;
    var next = v.clamp(w.min, w.max);
    if (w.divisions != null && w.max > w.min) {
      next =
          w.min +
          ((next - w.min) / (w.max - w.min) * w.divisions!).round() /
              w.divisions! *
              (w.max - w.min);
    }
    w.onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final w = widget, step = (w.max - w.min) / (w.divisions ?? 100);
    return Semantics(
      label: w.label,
      value: '${w.value}',
      increasedValue: '${(w.value + step).clamp(w.min, w.max)}',
      decreasedValue: '${(w.value - step).clamp(w.min, w.max)}',
      onIncrease: w.onChanged == null ? null : () => change(w.value + step),
      onDecrease: w.onChanged == null ? null : () => change(w.value - step),
      child: Focus(
        focusNode: focus,
        onFocusChange: (_) => setState(() {}),
        canRequestFocus: w.onChanged != null,
        onKeyEvent: (_, e) {
          if (e is KeyUpEvent || w.onChanged == null) {
            return KeyEventResult.ignored;
          }
          final next = _adjustValue(e.logicalKey, w.value, w.min, w.max, step);
          if (next == null) return KeyEventResult.ignored;
          change(next);
          return KeyEventResult.handled;
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              width: 2,
              color: focus.hasFocus
                  ? NuiTheme.of(context).focus
                  : NuiColors.transparent,
            ),
          ),
          child: LayoutBuilder(
            builder: (ctx, c) {
              void point(Offset p) {
                focus.requestFocus();
                change(
                  w.min +
                      ((p.dx - 24) / math.max(1, c.maxWidth - 48)).clamp(
                            0.0,
                            1.0,
                          ) *
                          (w.max - w.min),
                );
              }

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: w.onChanged == null
                    ? null
                    : (e) => point(e.localPosition),
                onHorizontalDragStart: w.onChanged == null
                    ? null
                    : (e) => point(e.localPosition),
                onHorizontalDragUpdate: w.onChanged == null
                    ? null
                    : (e) => point(e.localPosition),
                child: NuiControlSkin(
                  artboard: 'Slider',
                  resize: true,
                  state: NuiSkinState(
                    value: w.max == w.min
                        ? 0
                        : (w.value - w.min) / (w.max - w.min),
                    enabled: w.onChanged != null,
                  ),
                  inputBuilder: (_, _) =>
                      const SizedBox(height: 64, width: double.infinity),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class NuiRangeSlider extends StatefulWidget {
  const NuiRangeSlider({
    super.key,
    required this.values,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.onChanged,
    this.label,
  }) : assert(min <= max),
       assert(divisions == null || divisions > 0);
  final NuiRangeValues values;
  final double min, max;
  final int? divisions;
  final ValueChanged<NuiRangeValues>? onChanged;
  final String? label;
  @override
  State<NuiRangeSlider> createState() => _NuiRangeSliderState();
}

class _NuiRangeSliderState extends State<NuiRangeSlider> {
  final lower = FocusNode(), upper = FocusNode();
  bool start = true;
  @override
  void dispose() {
    lower.dispose();
    upper.dispose();
    super.dispose();
  }

  void change(double v, bool first) {
    final w = widget;
    var next = v.clamp(
      first ? w.min : w.values.start,
      first ? w.values.end : w.max,
    );
    if (w.divisions != null && w.max > w.min) {
      next =
          w.min +
          ((next - w.min) / (w.max - w.min) * w.divisions!).round() /
              w.divisions! *
              (w.max - w.min);
    }
    w.onChanged?.call(
      first
          ? NuiRangeValues(next.clamp(w.min, w.values.end), w.values.end)
          : NuiRangeValues(w.values.start, next.clamp(w.values.start, w.max)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    Widget target(bool first) {
      final value = first ? w.values.start : w.values.end,
          node = first ? lower : upper;
      return Focus(
        focusNode: node,
        canRequestFocus: w.onChanged != null,
        onFocusChange: (_) => setState(() {}),
        onKeyEvent: (_, e) {
          if (e is KeyUpEvent || w.onChanged == null) {
            return KeyEventResult.ignored;
          }
          final next = _adjustValue(
            e.logicalKey,
            value,
            first ? w.min : w.values.start,
            first ? w.values.end : w.max,
            (w.max - w.min) / (w.divisions ?? 100),
          );
          if (next == null) return KeyEventResult.ignored;
          change(next, first);
          return KeyEventResult.handled;
        },
        child: NuiFocusRing(
          focused: node.hasFocus,
          child: Text(
            '${first ? '下限' : '上限'} ${value.toStringAsFixed(1)}',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      );
    }

    return Semantics(
      label: w.label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LayoutBuilder(
            builder: (ctx, c) {
              double value(Offset p) =>
                  w.min +
                  ((p.dx - 24) / math.max(1, c.maxWidth - 48)).clamp(0.0, 1.0) *
                      (w.max - w.min);
              void begin(Offset p) {
                final v = value(p);
                start = (v - w.values.start).abs() <= (v - w.values.end).abs();
                (start ? lower : upper).requestFocus();
                change(v, start);
              }

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: w.onChanged == null
                    ? null
                    : (e) => begin(e.localPosition),
                onHorizontalDragStart: w.onChanged == null
                    ? null
                    : (e) => begin(e.localPosition),
                onHorizontalDragUpdate: w.onChanged == null
                    ? null
                    : (e) => change(value(e.localPosition), start),
                child: NuiControlSkin(
                  artboard: 'RangeSlider',
                  resize: true,
                  state: NuiSkinState(
                    value: w.max == w.min
                        ? 0
                        : (w.values.start - w.min) / (w.max - w.min),
                    secondaryValue: w.max == w.min
                        ? 0
                        : (w.values.end - w.min) / (w.max - w.min),
                    enabled: w.onChanged != null,
                  ),
                  inputBuilder: (_, _) =>
                      const SizedBox(height: 64, width: double.infinity),
                ),
              );
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [target(true), target(false)],
          ),
        ],
      ),
    );
  }
}

class NuiRotaryKnob extends StatefulWidget {
  const NuiRotaryKnob({
    super.key,
    required this.value,
    this.min = 0,
    this.max = 100,
    this.step = 1,
    this.onChanged,
    this.label = '値',
    this.valueLabel,
    this.size = 96,
  });
  final double value, min, max, step, size;
  final ValueChanged<double>? onChanged;
  final String label;
  final String? valueLabel;
  @override
  State<NuiRotaryKnob> createState() => _NuiRotaryKnobState();
}

class _NuiRotaryKnobState extends State<NuiRotaryKnob> {
  bool focused = false, dragging = false;
  double? drag;
  void set(double v) => widget.onChanged?.call(v.clamp(widget.min, widget.max));
  @override
  Widget build(BuildContext context) {
    final w = widget;
    final t = NuiTheme.of(context);
    final fraction = (w.value.clamp(w.min, w.max) - w.min) / (w.max - w.min);
    return Semantics(
      label: w.label,
      value: w.valueLabel ?? '${w.value}',
      increasedValue: '${(w.value + w.step).clamp(w.min, w.max)}',
      decreasedValue: '${(w.value - w.step).clamp(w.min, w.max)}',
      onIncrease: w.onChanged == null ? null : () => set(w.value + w.step),
      onDecrease: w.onChanged == null ? null : () => set(w.value - w.step),
      child: Focus(
        onFocusChange: (v) => setState(() => focused = v),
        canRequestFocus: w.onChanged != null,
        onKeyEvent: (_, e) {
          if (w.onChanged == null || e is KeyUpEvent) {
            return KeyEventResult.ignored;
          }
          final k = e.logicalKey;
          if (k == LogicalKeyboardKey.arrowUp ||
              k == LogicalKeyboardKey.arrowRight) {
            set(w.value + w.step);
          } else if (k == LogicalKeyboardKey.arrowDown ||
              k == LogicalKeyboardKey.arrowLeft) {
            set(w.value - w.step);
          } else if (k == LogicalKeyboardKey.home) {
            set(w.min);
          } else if (k == LogicalKeyboardKey.end) {
            set(w.max);
          } else if (k == LogicalKeyboardKey.pageUp) {
            set(w.value + 10 * w.step);
          } else if (k == LogicalKeyboardKey.pageDown) {
            set(w.value - 10 * w.step);
          } else {
            return KeyEventResult.ignored;
          }
          return KeyEventResult.handled;
        },
        child: GestureDetector(
          onVerticalDragStart: w.onChanged == null
              ? null
              : (_) {
                  drag = w.value;
                  setState(() => dragging = true);
                },
          onVerticalDragEnd: (_) => setState(() => dragging = false),
          onVerticalDragCancel: () => setState(() => dragging = false),
          onVerticalDragUpdate: w.onChanged == null
              ? null
              : (e) {
                  drag = (drag! - e.delta.dy * (w.max - w.min) / 160).clamp(
                    w.min,
                    w.max,
                  );
                  set(drag!);
                },
          onDoubleTap: w.onChanged == null
              ? null
              : () async {
                  final result = await showNuiDialog<double>(
                    context: context,
                    builder: (ctx) => _KnobValueDialog(
                      label: w.label,
                      value: w.value,
                      min: w.min,
                      max: w.max,
                    ),
                  );
                  if (result != null && mounted) set(result);
                },
          child: NuiFocusRing(
            focused: focused,
            radius: w.size / 2,
            child: SizedBox.square(
              dimension: w.size,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: NuiRiveArtwork(
                      artboard: 'RotaryKnob',
                      state: NuiSkinState(
                        value: fraction,
                        focused: focused,
                        pressed: dragging,
                        enabled: w.onChanged != null,
                      ),
                      fallback: CustomPaint(painter: _KnobPainter(t, fraction)),
                    ),
                  ),
                  Center(
                    child: Text(
                      w.valueLabel ?? w.value.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KnobPainter extends CustomPainter {
  _KnobPainter(this.t, this.fraction);
  final NuiThemeData t;
  final double fraction;
  @override
  void paint(Canvas c, Size s) {
    final center = s.center(Offset.zero), r = s.shortestSide / 2;
    final p = Paint()
      ..color = t.controlBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i <= 30; i++) {
      final a = math.pi * .75 + i / 30 * math.pi * 1.5;
      c.drawLine(
        center + Offset(math.cos(a), math.sin(a)) * (r - 2),
        center + Offset(math.cos(a), math.sin(a)) * (r - 4),
        p,
      );
    }
    c.drawCircle(
      center + const Offset(0, 2),
      r - 10,
      Paint()..color = t.controlBorder,
    );
    c.drawCircle(center, r - 10, Paint()..color = t.raised);
    c.drawCircle(center, r - 10, p);
    c.drawCircle(center, r - 16, p..color = t.border);
    final a = math.pi * .75 + fraction * math.pi * 1.5;
    c.drawCircle(
      center + Offset(math.cos(a), math.sin(a)) * (r - 13),
      2.5,
      Paint()..color = t.ink,
    );
  }

  @override
  bool shouldRepaint(_KnobPainter old) =>
      old.t != t || old.fraction != fraction;
}

class _KnobValueDialog extends StatefulWidget {
  const _KnobValueDialog({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
  });
  final String label;
  final double value, min, max;
  @override
  State<_KnobValueDialog> createState() => _KnobValueDialogState();
}

class _KnobValueDialogState extends State<_KnobValueDialog> {
  late final c = TextEditingController(text: '${widget.value}');
  String? error;
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  void submit() {
    final n = double.tryParse(c.text);
    if (n == null || !n.isFinite || n < widget.min || n > widget.max) {
      setState(() => error = '${widget.min}〜${widget.max} の値を入力してください');
      return;
    }
    Navigator.pop(context, n);
  }

  @override
  Widget build(BuildContext context) => NuiDialogFrame(
    title: Text(widget.label),
    content: NuiTextField(
      controller: c,
      autofocus: true,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      errorText: error,
      onSubmitted: (_) => submit(),
    ),
    actions: [
      NuiPlainButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('キャンセル'),
      ),
      NuiPlainButton(onPressed: submit, child: const Text('適用')),
    ],
  );
}
