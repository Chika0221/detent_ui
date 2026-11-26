import 'dart:math' as math;

import '../foundation/primitives.dart';
import '../inputs/inputs.dart';

import 'package:flutter/services.dart';

import '../feedback/feedback.dart';
import 'control_skin.dart';

enum DetentButtonVariant { primary, secondary, quiet, danger }

class DetentButton extends StatefulWidget {
  const DetentButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = DetentButtonVariant.secondary,
    this.loading = false,
    this.selected = false,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final DetentButtonVariant variant;

  /// A latched, neutral selection; independent of the primary action variant.
  final bool selected;
  final bool loading;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? semanticLabel;
  @override
  State<DetentButton> createState() => _DetentButtonState();
}

class _DetentButtonState extends State<DetentButton> {
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
  void didUpdateWidget(DetentButton old) {
    super.didUpdateWidget(old);
    if (!enabled) {
      pressed = false;
      keyboardPress = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = DetentTheme.of(context);
    final bg = widget.selected
        ? t.selectionSurface
        : switch (widget.variant) {
            DetentButtonVariant.primary => hovered ? t.accentHover : t.accent,
            DetentButtonVariant.danger => t.danger,
            DetentButtonVariant.quiet =>
              hovered ? t.surface : DetentColors.transparent,
            DetentButtonVariant.secondary => hovered ? t.surface : t.raised,
          };
    final fg = widget.selected
        ? t.selectionForeground
        : widget.variant == DetentButtonVariant.primary
        ? t.accentInk
        : widget.variant == DetentButtonVariant.danger
        ? t.onDanger
        : t.ink;
    final curve = const Cubic(.2, 0, .2, 1);
    Widget face(Widget child) => AnimatedContainer(
      duration: t.duration(context, pressed ? 60 : 120),
      curve: curve,
      transform: Matrix4.translationValues(
        0,
        pressed || widget.selected ? 2 : 0,
        0,
      ),
      child: child,
    );
    final fallback = Stack(
      children: [
        if (widget.variant != DetentButtonVariant.quiet && !t.highContrast)
          Positioned.fill(
            top: 2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: t.controlBorder,
                borderRadius: BorderRadius.circular(DetentRadius.control),
              ),
            ),
          ),
        Positioned.fill(
          bottom: 2,
          child: face(
            DecoratedBox(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(DetentRadius.control),
                border: Border.all(
                  color: widget.variant == DetentButtonVariant.quiet
                      ? DetentColors.transparent
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
            padding: EdgeInsets.symmetric(
              horizontal: widget.label.isEmpty
                  ? DetentSpace.gap
                  : DetentSpace.controlInline,
              vertical: DetentSpace.controlBlock,
            ),
            child: IconTheme(
              data: IconThemeData(color: fg, size: 16),
              child: DefaultTextStyle(
                style: DetentTheme.of(context).textTheme.control.copyWith(
                  color: fg,
                  fontWeight: widget.selected ? FontWeight.w600 : null,
                ),
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
                                child: DetentProgress(
                                  variant: DetentProgressVariant.circular,
                                  color: fg,
                                  label: '処理中',
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
              child: DetentFocusRing(
                focused: focused,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(child: fallback),
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

class DetentIconButton extends StatelessWidget {
  const DetentIconButton({
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
  Widget build(BuildContext context) => DetentHint(
    message: tooltip,
    child: Semantics(
      toggled: selected,
      child: SizedBox(
        width: DetentTheme.of(context).controlHeight + 10,
        child: DetentButton(
          label: '',
          semanticLabel: tooltip,
          icon: icon,
          onPressed: onPressed,
          focusNode: focusNode,
          selected: selected,
        ),
      ),
    ),
  );
}

class DetentToggleButton extends StatelessWidget {
  const DetentToggleButton({
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
    child: DetentButton(
      label: label,
      icon: icon,
      selected: value,
      onPressed: onChanged == null ? null : () => onChanged!(!value),
    ),
  );
}

/// Keyboard width in units of the key pitch. A standard 1u face is 40px;
/// the 8px inter-key gap makes 1.5u = 64px, 2u = 88px and 6.25u = 292px.
class DetentKeycap extends StatelessWidget {
  const DetentKeycap({
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
    final t = DetentTheme.of(context),
        width = (DetentTheme.of(context).controlHeight + 8) * units - 8;
    final bg = pressed ? t.ink : t.raised;
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
              child: Stack(
                children: [
                  Positioned.fill(
                    top: 2,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: t.controlBorder,
                        borderRadius: BorderRadius.circular(
                          DetentRadius.control,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    bottom: 2,
                    child: AnimatedContainer(
                      duration: t.duration(context, pressed ? 60 : 120),
                      curve: const Cubic(.2, 0, .2, 1),
                      transform: Matrix4.translationValues(
                        0,
                        pressed ? 2 : 0,
                        0,
                      ),
                      child: AnimatedContainer(
                        duration: t.duration(context, 120),
                        curve: const Cubic(.2, 0, .2, 1),
                        decoration: BoxDecoration(
                          color: bg,
                          border: Border.all(color: t.controlBorder),
                          borderRadius: BorderRadius.circular(
                            DetentRadius.control,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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
                        style: t.textTheme.caption.copyWith(
                          color: pressed
                              ? (t.dark ? t.display : t.inverse)
                              : t.ink,
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
class DetentOption<T> {
  const DetentOption(this.value, this.label, {this.icon, this.enabled = true});
  final T value;
  final String label;
  final IconData? icon;
  final bool enabled;
}

class DetentSegmentedControl<T> extends StatefulWidget {
  const DetentSegmentedControl({
    super.key,
    required this.options,
    required this.value,
    this.onChanged,
  });
  final List<DetentOption<T>> options;
  final T value;
  final ValueChanged<T>? onChanged;
  @override
  State<DetentSegmentedControl<T>> createState() =>
      _DetentSegmentedControlState<T>();
}

class _DetentSegmentedControlState<T> extends State<DetentSegmentedControl<T>> {
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
    final w = widget, t = DetentTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.controlBorder),
        borderRadius: BorderRadius.circular(DetentRadius.menu),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: DetentControlSkin(
          mechanism: 'SegmentedControl',
          resize: true,
          state: DetentControlState(
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
                    child: DetentInk(
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
                                      ? t.selectionForeground
                                      : t.ink,
                                ),
                                const SizedBox(width: 8),
                              ],
                              Flexible(
                                child: Text(
                                  o.label,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: o.value == w.value
                                        ? FontWeight.w600
                                        : null,
                                    color: !o.enabled
                                        ? t.muted
                                        : o.value == w.value
                                        ? t.selectionForeground
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

class DetentCheckbox extends StatelessWidget {
  const DetentCheckbox({
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
          DetentInk(
            focusNode: focusNode,
            onTap: onChanged == null ? null : toggle,
            child: DetentControlSkin(
              mechanism: 'Checkbox',
              visualSize: const Size(24, 24),
              state: DetentControlState(
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

class DetentRadioGroup<T> extends StatefulWidget {
  const DetentRadioGroup({
    super.key,
    required this.options,
    required this.value,
    this.onChanged,
  });
  final List<DetentOption<T>> options;
  final T? value;
  final ValueChanged<T>? onChanged;
  @override
  State<DetentRadioGroup<T>> createState() => _DetentRadioGroupState<T>();
}

class _DetentRadioGroupState<T> extends State<DetentRadioGroup<T>> {
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
              child: DetentInk(
                focusNode: nodes.putIfAbsent(o.value, FocusNode.new),
                onTap: w.onChanged == null || !o.enabled
                    ? null
                    : () => w.onChanged!(o.value),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DetentControlSkin(
                      mechanism: 'RadioGroup',
                      visualSize: const Size(24, 24),
                      state: DetentControlState(
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

/// An immediate on/off setting drawn as a physical slide switch.
///
/// [axis] defaults to [Axis.vertical]: a recessed slot with a ridged knob
/// that slides up for on, engraved ON / OFF beside it. [Axis.horizontal]
/// lays the same switch on its side: right is on, OFF and ON at the ends. Arrow keys along the axis set the
/// value directly; Enter and Space toggle.
class DetentSwitch extends StatelessWidget {
  const DetentSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.label,
    this.focusNode,
    this.axis = Axis.vertical,
  });
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;
  final FocusNode? focusNode;
  final Axis axis;
  @override
  Widget build(BuildContext context) {
    final vertical = axis == Axis.vertical;
    return Semantics(
      toggled: value,
      label: label,
      enabled: onChanged != null,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: (_, e) {
          if (onChanged == null || e is KeyUpEvent) {
            return KeyEventResult.ignored;
          }
          final key = e.logicalKey;
          final on = vertical
              ? LogicalKeyboardKey.arrowUp
              : LogicalKeyboardKey.arrowRight;
          final off = vertical
              ? LogicalKeyboardKey.arrowDown
              : LogicalKeyboardKey.arrowLeft;
          if (key != on && key != off) return KeyEventResult.ignored;
          final next = key == on;
          if (next != value) onChanged!(next);
          return KeyEventResult.handled;
        },
        child: DetentInk(
          focusNode: focusNode,
          onTap: onChanged == null ? null : () => onChanged!(!value),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DetentControlSkin(
                mechanism: vertical ? 'SwitchVertical' : 'Switch',
                visualSize: vertical ? const Size(56, 48) : const Size(112, 28),
                state: DetentControlState(
                  selected: value,
                  enabled: onChanged != null,
                ),
                inputBuilder: (_, _) => vertical
                    ? const SizedBox(width: 60, height: 52)
                    : const SizedBox(width: 116, height: 40),
              ),
              if (label != null) ...[
                const SizedBox(width: 8),
                Flexible(child: ExcludeSemantics(child: Text(label!))),
              ],
            ],
          ),
        ),
      ),
    );
  }
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
class DetentRangeValues {
  const DetentRangeValues(this.start, this.end) : assert(start <= end);
  final double start, end;
  @override
  bool operator ==(Object other) =>
      other is DetentRangeValues && other.start == start && other.end == end;
  @override
  int get hashCode => Object.hash(start, end);
}

typedef RangeValues = DetentRangeValues;

class DetentSlider extends StatefulWidget {
  const DetentSlider({
    super.key,
    required this.value,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.onChanged,
    this.label,
    this.axis = Axis.horizontal,
    this.length = 160,
  }) : assert(min <= max),
       assert(value >= min && value <= max),
       assert(divisions == null || divisions > 0);
  final double value, min, max;
  final int? divisions;
  final ValueChanged<double>? onChanged;
  final String? label;

  /// [Axis.vertical] draws a mixer-style fader with min at the bottom.
  final Axis axis;

  /// Height of a vertical slider. A horizontal slider fills its width.
  final double length;
  @override
  State<DetentSlider> createState() => _DetentSliderState();
}

class _DetentSliderState extends State<DetentSlider> {
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
            borderRadius: BorderRadius.circular(DetentRadius.control),
            border: Border.all(
              width: 2,
              color: focus.hasFocus
                  ? DetentTheme.of(context).focus
                  : DetentColors.transparent,
            ),
          ),
          child: LayoutBuilder(
            builder: (ctx, c) {
              final vertical = w.axis == Axis.vertical;
              void point(Offset p) {
                focus.requestFocus();
                final fraction = vertical
                    ? 1 - (p.dy - 24) / math.max(1, w.length - 48)
                    : (p.dx - 24) / math.max(1, c.maxWidth - 48);
                change(w.min + fraction.clamp(0.0, 1.0) * (w.max - w.min));
              }

              final enabled = w.onChanged != null;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: enabled ? (e) => point(e.localPosition) : null,
                onHorizontalDragStart: enabled && !vertical
                    ? (e) => point(e.localPosition)
                    : null,
                onHorizontalDragUpdate: enabled && !vertical
                    ? (e) => point(e.localPosition)
                    : null,
                onVerticalDragStart: enabled && vertical
                    ? (e) => point(e.localPosition)
                    : null,
                onVerticalDragUpdate: enabled && vertical
                    ? (e) => point(e.localPosition)
                    : null,
                child: DetentControlSkin(
                  mechanism: vertical ? 'SliderVertical' : 'Slider',
                  resize: true,
                  state: DetentControlState(
                    value: w.max == w.min
                        ? 0
                        : (w.value - w.min) / (w.max - w.min),
                    enabled: w.onChanged != null,
                  ),
                  inputBuilder: (_, _) => vertical
                      ? SizedBox(width: 64, height: w.length)
                      : const SizedBox(height: 64, width: double.infinity),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class DetentRangeSlider extends StatefulWidget {
  const DetentRangeSlider({
    super.key,
    required this.values,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.onChanged,
    this.label,
    this.axis = Axis.horizontal,
    this.length = 160,
  }) : assert(min <= max),
       assert(divisions == null || divisions > 0);
  final DetentRangeValues values;
  final double min, max;
  final int? divisions;
  final ValueChanged<DetentRangeValues>? onChanged;
  final String? label;

  /// [Axis.vertical] draws a mixer-style fader with min at the bottom; the
  /// upper and lower readouts sit beside it at the top and bottom.
  final Axis axis;

  /// Height of a vertical slider. A horizontal slider fills its width.
  final double length;
  @override
  State<DetentRangeSlider> createState() => _DetentRangeSliderState();
}

class _DetentRangeSliderState extends State<DetentRangeSlider> {
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
          ? DetentRangeValues(next.clamp(w.min, w.values.end), w.values.end)
          : DetentRangeValues(
              w.values.start,
              next.clamp(w.values.start, w.max),
            ),
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
        child: DetentFocusRing(
          focused: node.hasFocus,
          child: Text(
            '${first ? '下限' : '上限'} ${value.toStringAsFixed(1)}',
            style: DetentTheme.of(context).textTheme.caption,
          ),
        ),
      );
    }

    final vertical = w.axis == Axis.vertical;
    final enabled = w.onChanged != null;
    final track = LayoutBuilder(
      builder: (ctx, c) {
        double value(Offset p) {
          final fraction = vertical
              ? 1 - (p.dy - 24) / math.max(1, w.length - 48)
              : (p.dx - 24) / math.max(1, c.maxWidth - 48);
          return w.min + fraction.clamp(0.0, 1.0) * (w.max - w.min);
        }

        void begin(Offset p) {
          final v = value(p);
          start = (v - w.values.start).abs() <= (v - w.values.end).abs();
          (start ? lower : upper).requestFocus();
          change(v, start);
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: enabled ? (e) => begin(e.localPosition) : null,
          onHorizontalDragStart: enabled && !vertical
              ? (e) => begin(e.localPosition)
              : null,
          onHorizontalDragUpdate: enabled && !vertical
              ? (e) => change(value(e.localPosition), start)
              : null,
          onVerticalDragStart: enabled && vertical
              ? (e) => begin(e.localPosition)
              : null,
          onVerticalDragUpdate: enabled && vertical
              ? (e) => change(value(e.localPosition), start)
              : null,
          child: DetentControlSkin(
            mechanism: vertical ? 'RangeSliderVertical' : 'RangeSlider',
            resize: true,
            state: DetentControlState(
              value: w.max == w.min
                  ? 0
                  : (w.values.start - w.min) / (w.max - w.min),
              secondaryValue: w.max == w.min
                  ? 0
                  : (w.values.end - w.min) / (w.max - w.min),
              enabled: enabled,
            ),
            inputBuilder: (_, _) => vertical
                ? SizedBox(width: 64, height: w.length)
                : const SizedBox(height: 64, width: double.infinity),
          ),
        );
      },
    );

    return Semantics(
      label: w.label,
      child: vertical
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                track,
                const SizedBox(width: 8),
                SizedBox(
                  height: w.length,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [target(false), target(true)],
                  ),
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                track,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [target(true), target(false)],
                ),
              ],
            ),
    );
  }
}

class DetentRotaryKnob extends StatefulWidget {
  const DetentRotaryKnob({
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
  State<DetentRotaryKnob> createState() => _DetentRotaryKnobState();
}

class _DetentRotaryKnobState extends State<DetentRotaryKnob> {
  bool focused = false, dragging = false;
  double? drag;
  void set(double v) => widget.onChanged?.call(v.clamp(widget.min, widget.max));
  @override
  Widget build(BuildContext context) {
    final w = widget;
    final t = DetentTheme.of(context);
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
                  final result = await showDetentDialog<double>(
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
          child: DetentFocusRing(
            focused: focused,
            radius: w.size / 2,
            child: SizedBox.square(
              dimension: w.size,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedScale(
                      scale: dragging ? .98 : 1,
                      duration: t.duration(context, dragging ? 60 : 120),
                      curve: const Cubic(.2, 0, .2, 1),
                      child: CustomPaint(painter: _KnobPainter(t, fraction)),
                    ),
                  ),
                  Center(
                    child: Text(
                      w.valueLabel ?? w.value.toStringAsFixed(0),
                      style: DetentTheme.of(context).textTheme.readout,
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
  final DetentThemeData t;
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
  Widget build(BuildContext context) => DetentDialogFrame(
    title: Text(widget.label),
    content: DetentTextField(
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
      DetentPlainButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('キャンセル'),
      ),
      DetentPlainButton(onPressed: submit, child: const Text('適用')),
    ],
  );
}
