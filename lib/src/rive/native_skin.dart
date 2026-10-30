// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show kPrimaryButton;

import 'artwork.dart';
import 'skin.dart';
import '../foundation/theme.dart';

/// Leaves the native input in the same element slot before and after loading.
/// Only its paint changes; focus, gestures, text and semantics stay in Flutter.
class NuiNativeSkin extends StatefulWidget {
  const NuiNativeSkin({
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
  State<NuiNativeSkin> createState() => _NuiNativeSkinState();
}

class _NuiNativeSkinState extends State<NuiNativeSkin> {
  bool hovered = false, pressed = false, focused = false;
  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    skipTraversal: true,
    onFocusChange: (v) => setState(() => focused = v),
    child: MouseRegion(
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
          state: widget.state.interaction(
            hovered: hovered,
            pressed: pressed,
            focused: focused,
          ),
          builder: (context, graphic) => Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Center(
                  child: SizedBox(
                    width: widget.visualSize?.width,
                    height: widget.visualSize?.height,
                    child: Opacity(
                      opacity: widget.state.enabled ? 1 : .45,
                      child:
                          graphic ??
                          (NuiTheme.of(context).reduceMotion(context)
                              ? CustomPaint(
                                  painter: _StaticControlPainter(
                                    widget.artboard,
                                    widget.state,
                                    NuiTheme.of(context),
                                  ),
                                )
                              : const SizedBox.shrink()),
                    ),
                  ),
                ),
              ),
              Opacity(
                opacity:
                    widget.artboard == 'SegmentedControl' ||
                        (graphic == null &&
                            !NuiTheme.of(context).reduceMotion(context))
                    ? 1
                    : 0,
                alwaysIncludeSemantics: true,
                child: widget.inputBuilder(
                  context,
                  graphic != null || NuiTheme.of(context).reduceMotion(context),
                ),
              ),
              if (focused)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: SizedBox(
                        width: widget.visualSize == null
                            ? double.infinity
                            : widget.visualSize!.width + 8,
                        height: widget.visualSize == null
                            ? double.infinity
                            : widget.visualSize!.height + 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: NuiTheme.of(context).focus,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(
                              widget.artboard == 'Switch' ? 18 : 6,
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
      ),
    ),
  );
}

/// Instant final-state paint for an explicit reduced-motion override. The native
/// input stays mounted above it, with its own toggle geometry transparent.
class _StaticControlPainter extends CustomPainter {
  _StaticControlPainter(this.artboard, this.state, this.theme);
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
        Rect.fromCenter(center: center, width: 44, height: 22),
        theme.display,
        11,
      );
      circle(
        center + Offset(state.selected ? 11 : -11, 0),
        8,
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
      final x = state.value.clamp(0.0, 1.0) * (size.width - width);
      box(Rect.fromLTWH(x + 4, 4, width - 8, size.height - 8), theme.accent, 4);
    } else if (artboard == 'Slider' || artboard == 'RangeSlider') {
      final left = 24.0, right = size.width - 24;
      p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
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
      for (final x in [first, if (artboard == 'RangeSlider') end]) {
        final rect = Rect.fromCenter(
          center: Offset(x, center.dy),
          width: 12,
          height: 20,
        );
        box(rect, theme.raised, 3);
        box(rect, theme.controlBorder, 3, outline: true);
      }
    }
  }

  @override
  bool shouldRepaint(_StaticControlPainter old) =>
      old.state != state || old.theme != theme || old.artboard != artboard;
}
