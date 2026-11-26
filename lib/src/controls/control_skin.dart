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
    if (mechanism == 'SliderVertical') {
      canvas.save();
      canvas.translate(0, size.height);
      canvas.rotate(-math.pi / 2);
      _StaticControlPainter(
        'Slider',
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
    if (mechanism == 'SwitchVertical') {
      // A slide switch: a dark recessed slot, a ridged knob with a 2px base
      // like the keys, and engraved ON / OFF labels. Up is on.
      final amount = (selectionValue ?? 0).clamp(0.0, 1.0);
      const slotWidth = 22.0, slotHeight = 46.0, knobHeight = 20.0;
      final slot = Rect.fromCenter(
        center: Offset(size.width - slotWidth / 2 - 1, center.dy),
        width: slotWidth,
        height: slotHeight,
      );
      box(slot, theme.highContrast ? theme.canvas : theme.display, 4);
      box(slot, theme.controlBorder, 4, outline: true);
      final travel = slotHeight - 6 - knobHeight;
      final top = slot.top + 3 + travel * (1 - amount);
      final depth = 2 * (1 - press);
      final knob = Rect.fromLTWH(
        slot.left + 3,
        top + 2 - depth,
        slotWidth - 6,
        knobHeight - 2,
      );
      box(knob.shift(Offset(0, depth)), theme.controlBorder, 3);
      box(knob, theme.raised, 3);
      box(knob, theme.controlBorder, 3, outline: true);
      p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = theme.controlBorder;
      for (final dy in [-3.0, 0.0, 3.0]) {
        final y = knob.center.dy + dy;
        canvas.drawLine(Offset(knob.left + 4, y), Offset(knob.right - 4, y), p);
      }
      void engrave(String text, bool active, double y) {
        final painter = TextPainter(
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
        painter.paint(
          canvas,
          Offset(slot.left - 6 - painter.width, y - painter.height / 2),
        );
        painter.dispose();
      }

      engrave('ON', amount >= .5, slot.top + 3 + knobHeight / 2);
      engrave('OFF', amount < .5, slot.bottom - 3 - knobHeight / 2);
    } else if (mechanism == 'Switch') {
      final amount = (selectionValue ?? 0).clamp(0.0, 1.0);
      final track = Rect.fromCenter(center: center, width: 48, height: 26);
      box(track, Color.lerp(theme.border, theme.display, amount)!, 13);
      if (theme.dark) box(track, theme.controlBorder, 13, outline: true);
      circle(
        center + Offset(-11 + 22 * amount, 0),
        10 * (1 - press * .05),
        theme.dark
            ? Color.lerp(
                theme.highContrast ? theme.canvas : theme.inverse,
                theme.inverse,
                amount,
              )!
            : theme.raised,
      );
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
