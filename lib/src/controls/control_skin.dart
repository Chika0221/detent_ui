import 'dart:math' as math;

import '../foundation/primitives.dart';

import 'package:flutter/gestures.dart' show kPrimaryButton;

@immutable
class DetentControlState {
  const DetentControlState({
    this.selected = false,
    this.enabled = true,
    this.value = 0,
    this.secondaryValue = 1,
    this.selectionCount = 1,
    this.selectionState = 0,
  });
  final bool selected, enabled;
  final double value, secondaryValue, selectionCount, selectionState;
}

/// Flutter-only control motion. No Rive controller or asset is created here.
class DetentControlSkin extends StatefulWidget {
  const DetentControlSkin({
    super.key,
    required this.mechanism,
    required this.state,
    required this.inputBuilder,
    this.visualSize,
    this.resize = false,
  });
  final String mechanism;
  final DetentControlState state;
  final Widget Function(BuildContext, bool) inputBuilder;
  final Size? visualSize;
  final bool resize;
  @override
  State<DetentControlSkin> createState() => _DetentControlSkinState();
}

class _DetentControlSkinState extends State<DetentControlSkin> {
  bool pressed = false;
  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (e) {
      if (widget.state.enabled && (e.buttons & kPrimaryButton) != 0) {
        setState(() => pressed = true);
      }
    },
    onPointerUp: (_) => setState(() => pressed = false),
    onPointerCancel: (_) => setState(() => pressed = false),
    child: TweenAnimationBuilder<double>(
      tween: Tween(
        end: widget.mechanism == 'SegmentedControl'
            ? widget.state.value
            : widget.state.selected
            ? 1.0
            : 0.0,
      ),
      duration: DetentTheme.of(context).duration(
        context,
        widget.mechanism == 'SegmentedControl'
            ? 220
            : widget.mechanism.startsWith('Switch')
            ? 160
            : 120,
      ),
      curve: const Cubic(.2, 0, .2, 1),
      child: widget.inputBuilder(context, false),
      builder: (ctx, position, input) => Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Center(
              child: SizedBox(
                width: widget.visualSize?.width ?? double.infinity,
                height: widget.visualSize?.height ?? double.infinity,
                child: Opacity(
                  opacity: widget.state.enabled ? 1 : .45,
                  child: RepaintBoundary(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: pressed ? 1.0 : 0.0),
                      duration: DetentTheme.of(context)
                          .duration(context, pressed ? 60 : 120),
                      curve: const Cubic(.2, 0, .2, 1),
                      builder: (ctx, press, _) => CustomPaint(
                        painter: _StaticControlPainter(
                          widget.mechanism,
                          widget.state,
                          DetentTheme.of(context),
                          selectionValue: position,
                          press: press,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          input!,
        ],
      ),
    ),
  );
}

class _StaticControlPainter extends CustomPainter {
  _StaticControlPainter(
    this.mechanism,
    this.state,
    this.theme, {
    this.selectionValue,
    this.press = 0,
    this.capShadow = const Offset(1, 2),
  });

  /// Offset of the slider cap's base, in the painter's own frame.
  final Offset capShadow;
  final double? selectionValue;
  final double press;
  final String mechanism;
  final DetentControlState state;
  final DetentThemeData theme;
  @override
  void paint(Canvas canvas, Size size) {
    // A vertical slider is the horizontal fader turned a quarter: min at the
    // bottom, ticks on the right, the cap wide and short like a mixer fader.
    if (mechanism == 'SliderVertical' || mechanism == 'RangeSliderVertical') {
      canvas.save();
      canvas.translate(0, size.height);
      canvas.rotate(-math.pi / 2);
      _StaticControlPainter(
        mechanism.replaceFirst('Vertical', ''),
        state,
        theme,
        selectionValue: selectionValue,
        press: press,
        capShadow: const Offset(-2, 1),
      ).paint(canvas, Size(size.height, size.width));
      canvas.restore();
      return;
    }
    final p = Paint()..isAntiAlias = true;
    void box(Rect rect, Color color, double radius, {bool outline = false}) {
      p
        ..color = color
        ..style = outline ? PaintingStyle.stroke : PaintingStyle.fill
        ..strokeWidth = 1;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(radius)),
        p,
      );
    }

    void circle(
      Offset center,
      double radius,
      Color color, {
      bool outline = false,
    }) {
      p
        ..color = color
        ..style = outline ? PaintingStyle.stroke : PaintingStyle.fill
        ..strokeWidth = 1;
      canvas.drawCircle(center, radius, p);
    }

    final center = size.center(Offset.zero);
    if (mechanism == 'SwitchVertical' || mechanism == 'Switch') {
      // A chunky slide switch in the Slider's language: a dark recessed bed,
      // an oversized knob drawn like the Slider's raised cap with its offset
      // base, and short ruler ticks at the two positions beside engraved
      // ON / OFF.
      // Vertical: up is on. Horizontal: right is on.
      final vertical = mechanism == 'SwitchVertical';
      final amount = (selectionValue ?? 0).clamp(0.0, 1.0);
      const long = 48.0, short = 28.0, knobLong = 24.0, inset = 3.0;
      TextPainter engraving(String text, bool active) => TextPainter(
        text: TextSpan(
          text: text,
          style: theme.textTheme.label.copyWith(
            color: active ? theme.ink : theme.muted,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final on = engraving('ON', amount >= .5),
          off = engraving('OFF', amount < .5);
      final bed = vertical
          ? Rect.fromCenter(
              center: Offset(size.width - short / 2 - 1, center.dy - 1),
              width: short,
              height: long,
            )
          : Rect.fromCenter(
              center: Offset(
                (size.width - on.width + off.width) / 2,
                center.dy - 1,
              ),
              width: long,
              height: short,
            );
      box(bed, theme.highContrast ? theme.canvas : theme.display, 6);
      box(bed, theme.controlBorder, 6, outline: true);
      final travel = long - inset * 2 - knobLong;
      final lift = 2 * press;
      final knob = vertical
          ? Rect.fromLTWH(
              bed.left + inset,
              bed.top + inset + travel * (1 - amount) + lift,
              short - inset * 2,
              knobLong - 2,
            )
          : Rect.fromLTWH(
              bed.left + inset + travel * amount,
              bed.top + inset + lift,
              knobLong,
              short - inset * 2 - 2,
            );
      box(knob.shift(Offset(1, 2 - lift)), theme.controlBorder, 4);
      box(knob, theme.raised, 4);
      box(knob, theme.controlBorder, 4, outline: true);
      // One short mark on the knob, across the direction of travel.
      p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = theme.controlBorder;
      final c = knob.center;
      canvas.drawLine(
        vertical ? c - const Offset(5, 0) : c - const Offset(0, 5),
        vertical ? c + const Offset(5, 0) : c + const Offset(0, 5),
        p,
      );
      // Ruler ticks at the two knob positions, outside the bed.
      p
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.butt;
      final onAt = vertical
          ? Offset(bed.left, bed.top + inset + knobLong / 2)
          : Offset(bed.right - inset - knobLong / 2, bed.bottom);
      final offAt = vertical
          ? Offset(bed.left, bed.bottom - inset - knobLong / 2)
          : Offset(bed.left + inset + knobLong / 2, bed.bottom);
      for (final at in [onAt, offAt]) {
        canvas.drawLine(
          vertical ? at - const Offset(8, 0) : at + const Offset(0, 3),
          vertical ? at - const Offset(3, 0) : at + const Offset(0, 8),
          p,
        );
      }
      if (vertical) {
        on.paint(
          canvas,
          Offset(onAt.dx - 12 - on.width, onAt.dy - on.height / 2),
        );
        off.paint(
          canvas,
          Offset(offAt.dx - 12 - off.width, offAt.dy - off.height / 2),
        );
      } else {
        off.paint(
          canvas,
          Offset(bed.left - 6 - off.width, bed.center.dy - off.height / 2),
        );
        on.paint(canvas, Offset(bed.right + 6, bed.center.dy - on.height / 2));
      }
      on.dispose();
      off.dispose();
    } else if (mechanism == 'Checkbox') {
      final rect = Rect.fromCenter(center: center, width: 20, height: 20);
      final amount = (selectionValue ?? 0).clamp(0.0, 1.0);
      box(rect, Color.lerp(theme.raised, theme.selectionSurface, amount)!, 4);
      box(rect, theme.controlBorder, 3, outline: true);
      if (amount > 0) {
        final path = Path();
        if (state.selectionState == 2) {
          path.moveTo(center.dx - 6, center.dy);
          path.lineTo(center.dx + 6, center.dy);
        } else {
          path.moveTo(center.dx - 6, center.dy);
          path.lineTo(center.dx - 2, center.dy + 4);
          path.lineTo(center.dx + 6, center.dy - 4);
        }
        p
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = theme.selectionForeground.withValues(alpha: amount);
        canvas.drawPath(path, p);
      }
    } else if (mechanism == 'RadioGroup') {
      circle(center, 10, theme.raised);
      circle(center, 10, theme.controlBorder, outline: true);
      circle(center, 5 * (selectionValue ?? 0).clamp(0.0, 1.0), theme.ink);
    } else if (mechanism == 'SegmentedControl') {
      box(Offset.zero & size, theme.surface, 6);
      final width = size.width / state.selectionCount.clamp(1, double.infinity);
      final x =
          (selectionValue ?? state.value).clamp(0.0, 1.0) *
          (size.width - width);
      box(
        Rect.fromLTWH(x + 4, 6, width - 8, size.height - 10),
        theme.controlBorder,
        6,
      );
      final face = Rect.fromLTWH(x + 4, 4, width - 8, size.height - 10);
      box(face, theme.selectionSurface, 6);
      box(face, theme.controlBorder, 6, outline: true);
    } else if (mechanism == 'Slider' || mechanism == 'RangeSlider') {
      final left = 24.0, right = size.width - 24;
      p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = theme.border;
      canvas.drawLine(Offset(left, center.dy), Offset(right, center.dy), p);
      final first = left + state.value.clamp(0.0, 1.0) * (right - left);
      final end = mechanism == 'RangeSlider'
          ? left + state.secondaryValue.clamp(0.0, 1.0) * (right - left)
          : first;
      p.color = theme.ink;
      canvas.drawLine(
        Offset(mechanism == 'RangeSlider' ? first : left, center.dy),
        Offset(end, center.dy),
        p,
      );
      p
        ..color = theme.controlBorder
        ..strokeWidth = 1;
      for (var i = 0; i <= 20; i++) {
        final x = left + (right - left) * i / 20;
        canvas.drawLine(
          Offset(x, center.dy + 18),
          Offset(x, center.dy + 18 + (i % 5 == 0 ? 8 : 4)),
          p,
        );
      }
      for (final x in [first, if (mechanism == 'RangeSlider') end]) {
        final rect = Rect.fromCenter(
          center: Offset(x, center.dy),
          width: 18,
          height: 24 - press * 2,
        );
        box(rect.shift(capShadow), theme.controlBorder, 4);
        box(rect, theme.raised, 4);
        box(rect, theme.controlBorder, 4, outline: true);
      }
    }
  }

  @override
  bool shouldRepaint(_StaticControlPainter old) =>
      old.state != state ||
      old.theme != theme ||
      old.mechanism != mechanism ||
      old.selectionValue != selectionValue ||
      old.press != press;
}
