import 'dart:math' as math;

// Keep compatibility with Flutter's Material re-export during SDK extraction.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui_lucide/forui_lucide.dart';

import '../foundation/theme.dart';

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
  bool get enabled => widget.onPressed != null && !widget.loading;
  @override
  Widget build(BuildContext context) {
    final t = NuiTheme.of(context);
    final bg = switch (widget.variant) {
      NuiButtonVariant.primary => hovered ? t.accentHover : t.accent,
      NuiButtonVariant.danger => t.danger,
      NuiButtonVariant.quiet => hovered ? t.surface : t.canvas,
      NuiButtonVariant.secondary => hovered ? t.surface : t.raised,
    };
    final fg = widget.variant == NuiButtonVariant.primary
        ? t.accentInk
        : widget.variant == NuiButtonVariant.danger
        ? (t.dark ? Colors.black : Colors.white)
        : t.ink;
    void activate() {
      if (enabled) widget.onPressed!();
    }

    return Semantics(
      button: true,
      excludeSemantics: true,
      onTap: enabled ? activate : null,
      value: widget.loading ? '処理中' : null,
      enabled: enabled,
      label: widget.semanticLabel ?? widget.label,
      child: FocusableActionDetector(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        enabled: enabled,
        mouseCursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowFocusHighlight: (v) => setState(() => focused = v),
        onShowHoverHighlight: (v) => setState(() => hovered = v),
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              activate();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: enabled ? activate : null,
          onTapDown: enabled ? (_) => setState(() => pressed = true) : null,
          onTapCancel: () => setState(() => pressed = false),
          onTapUp: (_) => setState(() => pressed = false),
          child: Opacity(
            opacity: enabled || widget.loading ? 1 : .45,
            child: NuiFocusRing(
              focused: focused,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: AnimatedContainer(
                  duration: t.duration(context, pressed ? 60 : 120),
                  transform: Matrix4.translationValues(0, pressed ? 2 : 0, 0),
                  constraints: BoxConstraints(
                    minHeight: t.controlHeight,
                    minWidth: 28,
                  ),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: t.controlBorder),
                    boxShadow:
                        t.highContrast ||
                            pressed ||
                            widget.variant == NuiButtonVariant.quiet
                        ? const []
                        : [
                            BoxShadow(
                              color: t.controlBorder,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: IconTheme(
                    data: IconThemeData(color: fg, size: 16),
                    child: DefaultTextStyle(
                      style: Theme.of(context).textTheme.labelLarge!
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
                                    Icon(
                                      FLucideIcons.loader,
                                      semanticLabel: '処理中',
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
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Semantics(
      toggled: selected,
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

class NuiKeycap extends StatelessWidget {
  const NuiKeycap({super.key, required this.label, this.pressed = false});
  final String label;
  final bool pressed;
  @override
  Widget build(BuildContext context) {
    final t = NuiTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: pressed ? t.accent : t.raised,
        border: Border.all(color: t.controlBorder),
        borderRadius: BorderRadius.circular(4),
        boxShadow: pressed || t.highContrast
            ? []
            : [BoxShadow(color: t.controlBorder, offset: const Offset(0, 2))],
      ),
      child: Text(
        label,
        style: TextStyle(color: pressed ? t.accentInk : t.ink, fontSize: 12),
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

class NuiSegmentedControl<T> extends StatelessWidget {
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
  Widget build(BuildContext context) => SegmentedButton<T>(
    segments: [
      for (final o in options)
        ButtonSegment<T>(
          value: o.value,
          label: Text(o.label),
          icon: o.icon == null ? null : Icon(o.icon),
          enabled: o.enabled,
        ),
    ],
    selected: {value},
    showSelectedIcon: false,
    onSelectionChanged: onChanged == null ? null : (v) => onChanged!(v.single),
    style: ButtonStyle(
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      backgroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? NuiTheme.of(context).accent
            : NuiTheme.of(context).surface,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? NuiTheme.of(context).accentInk
            : NuiTheme.of(context).ink,
      ),
    ),
  );
}

class NuiCheckbox extends StatelessWidget {
  const NuiCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.label,
    this.tristate = false,
    this.focusNode,
  });
  final bool? value;
  final ValueChanged<bool?>? onChanged;
  final String? label;
  final bool tristate;
  final FocusNode? focusNode;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Checkbox(
        value: value,
        tristate: tristate,
        onChanged: onChanged,
        semanticLabel: label,
        focusNode: focusNode,
      ),
      if (label != null) Flexible(child: Text(label!)),
    ],
  );
}

class NuiRadioGroup<T> extends StatelessWidget {
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
  Widget build(BuildContext context) => RadioGroup<T>(
    groupValue: value,
    onChanged: (v) {
      if (v != null) onChanged?.call(v);
    },
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final o in options)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Radio<T>(value: o.value, enabled: onChanged != null && o.enabled),
              Flexible(child: Text(o.label)),
            ],
          ),
      ],
    ),
  );
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
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Semantics(
        label: label,
        child: Switch(value: value, onChanged: onChanged, focusNode: focusNode),
      ),
      if (label != null) Flexible(child: Text(label!)),
    ],
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

class NuiSlider extends StatelessWidget {
  const NuiSlider({
    super.key,
    required this.value,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.onChanged,
    this.label,
  });
  final double value, min, max;
  final int? divisions;
  final ValueChanged<double>? onChanged;
  final String? label;
  @override
  Widget build(BuildContext context) => Focus(
    skipTraversal: true,
    canRequestFocus: false,
    onKeyEvent: (_, e) {
      if (onChanged == null || e is KeyUpEvent) return KeyEventResult.ignored;
      final next = _adjustValue(
        e.logicalKey,
        value,
        min,
        max,
        (max - min) / (divisions ?? 100),
      );
      if (next == null) return KeyEventResult.ignored;
      onChanged!(next);
      return KeyEventResult.handled;
    },
    child: Semantics(
      label: label,
      child: Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
        label: value.toStringAsFixed(2),
        semanticFormatterCallback: (v) =>
            '${label ?? ''} ${v.toStringAsFixed(2)}',
      ),
    ),
  );
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
  });
  final RangeValues values;
  final double min, max;
  final int? divisions;
  final ValueChanged<RangeValues>? onChanged;
  final String? label;
  @override
  State<NuiRangeSlider> createState() => _NuiRangeSliderState();
}

class _NuiRangeSliderState extends State<NuiRangeSlider> {
  final lower = FocusNode(), upper = FocusNode();
  @override
  void dispose() {
    lower.dispose();
    upper.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    Widget target(bool start) {
      final node = start ? lower : upper;
      final value = start ? w.values.start : w.values.end;
      return Focus(
        focusNode: node,
        canRequestFocus: w.onChanged != null,
        includeSemantics: false,
        onFocusChange: (_) => setState(() {}),
        onKeyEvent: (_, e) {
          if (w.onChanged == null || e is KeyUpEvent) {
            return KeyEventResult.ignored;
          }
          final next = _adjustValue(
            e.logicalKey,
            value,
            start ? w.min : w.values.start,
            start ? w.values.end : w.max,
            (w.max - w.min) / (w.divisions ?? 100),
          );
          if (next == null) return KeyEventResult.ignored;
          w.onChanged!(
            start
                ? RangeValues(next, w.values.end)
                : RangeValues(w.values.start, next),
          );
          return KeyEventResult.handled;
        },
        child: GestureDetector(
          onTap: w.onChanged == null ? null : node.requestFocus,
          child: NuiFocusRing(
            focused: node.hasFocus,
            child: Text(
              '${start ? '下限' : '上限'} ${value.toStringAsFixed(1)}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      );
    }

    return Semantics(
      label: w.label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeFocus(
            child: RangeSlider(
              values: w.values,
              min: w.min,
              max: w.max,
              divisions: w.divisions,
              onChanged: w.onChanged,
              labels: RangeLabels('${w.values.start}', '${w.values.end}'),
            ),
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
  bool focused = false;
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
              : (_) => drag = w.value,
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
                  final result = await showDialog<double>(
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
              child: CustomPaint(
                painter: _KnobPainter(t, fraction),
                child: Center(
                  child: Text(
                    w.valueLabel ?? w.value.toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
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
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.label),
    content: TextField(
      controller: c,
      autofocus: true,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      decoration: InputDecoration(errorText: error),
      onSubmitted: (_) => submit(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('キャンセル'),
      ),
      TextButton(onPressed: submit, child: const Text('適用')),
    ],
  );
}
