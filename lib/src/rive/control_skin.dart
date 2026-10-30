import '../foundation/primitives.dart';

import 'package:flutter/gestures.dart' show kPrimaryButton;

import 'artwork.dart';
import 'skin.dart';

/// Widgets-only control paint. Focus and gestures belong to the caller.
class NuiControlSkin extends StatefulWidget {
  const NuiControlSkin({
    super.key,
    required this.artboard,
    required this.state,
    required this.inputBuilder,
    this.visualSize,
    this.resize = false,
  });
  final String artboard;
  final NuiSkinState state;
  final Widget Function(BuildContext, bool) inputBuilder;
  final Size? visualSize;
  final bool resize;
  @override
  State<NuiControlSkin> createState() => _NuiControlSkinState();
}

class _NuiControlSkinState extends State<NuiControlSkin> {
  bool hovered = false, pressed = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => hovered = true),
    onExit: (_) => setState(() => hovered = false),
    child: Listener(
      onPointerDown: (e) {
        if (widget.state.enabled && (e.buttons & kPrimaryButton) != 0) {
          setState(() => pressed = true);
        }
      },
      onPointerUp: (_) => setState(() => pressed = false),
      onPointerCancel: (_) => setState(() => pressed = false),
      child: NuiRiveArtwork(
        artboard: widget.artboard,
        resize: widget.resize,
        state: widget.state.interaction(hovered: hovered, pressed: pressed),
        builder: (ctx, graphic) => Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Center(
                child: SizedBox(
                  width: widget.visualSize?.width ?? double.infinity,
                  height: widget.visualSize?.height ?? double.infinity,
                  child: Opacity(
                    opacity: widget.state.enabled ? 1 : .45,
                    child:
                        graphic ??
                        (widget.artboard == 'SegmentedControl'
                            ? TweenAnimationBuilder<double>(
                                tween: Tween(end: widget.state.value),
                                duration: NuiTheme.of(context)
                                    .duration(context, 220),
                                curve: const Cubic(.2, 0, .2, 1),
                                builder: (ctx, value, _) => CustomPaint(
                                  painter: _StaticControlPainter(
                                    widget.artboard,
                                    widget.state,
                                    NuiTheme.of(context),
                                    selectionValue: value,
                                  ),
                                ),
                              )
                            : CustomPaint(
                                painter: _StaticControlPainter(
                                  widget.artboard,
                                  widget.state,
                                  NuiTheme.of(context),
                                ),
                              )),
                  ),
                ),
              ),
            ),
            widget.inputBuilder(ctx, graphic != null),
          ],
        ),
      ),
    ),
  );
}

class _StaticControlPainter extends CustomPainter {
  _StaticControlPainter(
    this.artboard,
    this.state,
    this.theme, {
    this.selectionValue,
  });
  final double? selectionValue;
  final String artboard;
  final NuiSkinState state;
  final NuiThemeData theme;
  @override
  void paint(Canvas canvas, Size size) {
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
    if (artboard == 'Switch') {
      box(
        Rect.fromCenter(center: center, width: 48, height: 26),
        state.selected ? theme.display : theme.border,
        13,
      );
      circle(
        center + Offset(state.selected ? 11 : -11, 0),
        10,
        state.selected ? theme.accent : theme.raised,
      );
    } else if (artboard == 'Checkbox') {
      final rect = Rect.fromCenter(center: center, width: 20, height: 20);
      box(rect, state.selected ? theme.ink : theme.raised, 3);
      box(rect, theme.controlBorder, 3, outline: true);
      if (state.selected) {
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
          ..color = theme.inverse;
        canvas.drawPath(path, p);
      }
    } else if (artboard == 'RadioGroup') {
      circle(center, 10, theme.raised);
      circle(center, 10, theme.controlBorder, outline: true);
      if (state.selected) circle(center, 5, theme.ink);
    } else if (artboard == 'SegmentedControl') {
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
      box(face, theme.accent, 6);
      box(face, theme.controlBorder, 6, outline: true);
    } else if (artboard == 'Slider' || artboard == 'RangeSlider') {
      final left = 24.0, right = size.width - 24;
      p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = theme.border;
      canvas.drawLine(Offset(left, center.dy), Offset(right, center.dy), p);
      final first = left + state.value.clamp(0.0, 1.0) * (right - left);
      final end = artboard == 'RangeSlider'
          ? left + state.secondaryValue.clamp(0.0, 1.0) * (right - left)
          : first;
      p.color = theme.ink;
      canvas.drawLine(
        Offset(artboard == 'RangeSlider' ? first : left, center.dy),
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
      for (final x in [first, if (artboard == 'RangeSlider') end]) {
        final rect = Rect.fromCenter(
          center: Offset(x, center.dy),
          width: 18,
          height: 24,
        );
        box(rect.shift(const Offset(1, 2)), theme.controlBorder, 4);
        box(rect, theme.raised, 4);
        box(rect, theme.controlBorder, 4, outline: true);
      }
    }
  }

  @override
  bool shouldRepaint(_StaticControlPainter old) =>
      old.state != state ||
      old.theme != theme ||
      old.artboard != artboard ||
      old.selectionValue != selectionValue;
}
