/// Precision apertures shared by material, interaction and information surfaces.
library;

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../foundation/theme.dart';
import '../foundation/tokens.g.dart';

part 'motion.dart';

enum DetentHoleSize {
  xs(DetentTokens.perforation_hole_size_xs),
  sm(DetentTokens.perforation_hole_size_sm),
  md(DetentTokens.perforation_hole_size_md),
  lg(DetentTokens.perforation_hole_size_lg);

  const DetentHoleSize(this.diameter);
  final double diameter;
}

enum DetentHoleState { inactive, active, highlighted, disabled }

enum DetentPerforationDepth { flat, inset, deep }

enum DetentPerforationArrangement { square, hexagonal }

enum DetentPerforationCoverage { full, edge, corner, custom }

enum DetentPerforationDensity {
  sparse(DetentTokens.perforation_hole_gap_relaxed),
  normal(DetentTokens.perforation_hole_gap_default),
  dense(DetentTokens.perforation_hole_gap_compact);

  const DetentPerforationDensity(this.gap);
  final double gap;
}

typedef DetentHoleStateResolver = DetentHoleState Function(int row, int column);
typedef DetentPerforationMask = bool Function(
  int row,
  int column,
  Offset center,
);

/// Grid coordinates in logical pixels. Resizing never scales the apertures.
@immutable
class DetentPerforationGeometry {
  const DetentPerforationGeometry({
    required this.rows,
    required this.columns,
    this.diameter = 4,
    this.gap = 8,
    this.arrangement = DetentPerforationArrangement.square,
  }) : assert(rows > 0 && columns > 0),
       assert(diameter > 0 && diameter < double.infinity),
       assert(gap >= 0 && gap < double.infinity);

  final int rows, columns;
  final double diameter, gap;
  final DetentPerforationArrangement arrangement;
  double get pitch => diameter + gap;
  double get rowPitch => arrangement == DetentPerforationArrangement.hexagonal
      ? pitch * math.sqrt(3) / 2
      : pitch;
  Size get size => Size(
    diameter +
        (columns - 1) * pitch +
        (arrangement == DetentPerforationArrangement.hexagonal && rows > 1
            ? pitch / 2
            : 0),
    diameter + (rows - 1) * rowPitch,
  );

  Offset center(int row, int column) {
    assert(row >= 0 && row < rows && column >= 0 && column < columns);
    return Offset(
      diameter / 2 +
          column * pitch +
          (arrangement == DetentPerforationArrangement.hexagonal && row.isOdd
              ? pitch / 2
              : 0),
      diameter / 2 + row * rowPitch,
    );
  }
}

class DetentHole extends StatelessWidget {
  const DetentHole({
    super.key,
    this.size = DetentHoleSize.md,
    this.depth = DetentPerforationDepth.inset,
    this.state = DetentHoleState.inactive,
    this.color,
  });
  final DetentHoleSize size;
  final DetentPerforationDepth depth;
  final DetentHoleState state;
  final Color? color;

  @override
  Widget build(BuildContext context) => DetentHoleGrid(
    rows: 1,
    columns: 1,
    holeSize: size,
    depth: depth,
    stateForCell: (_, _) => state,
    color: color,
  );
}

/// One paint layer, including when displaying hundreds of holes.
class DetentHoleGrid extends StatelessWidget {
  const DetentHoleGrid({
    super.key,
    this.rows = 6,
    this.columns = 12,
    this.holeSize = DetentHoleSize.md,
    this.density = DetentPerforationDensity.normal,
    this.gap,
    this.arrangement = DetentPerforationArrangement.square,
    this.depth = DetentPerforationDepth.inset,
    this.stateForCell,
    this.mask,
    this.color,
  }) : assert(rows > 0 && columns > 0),
       assert(gap == null || (gap >= 0 && gap < double.infinity));

  final int rows, columns;
  final DetentHoleSize holeSize;
  final DetentPerforationDensity density;
  final double? gap;
  final DetentPerforationArrangement arrangement;
  final DetentPerforationDepth depth;
  final DetentHoleStateResolver? stateForCell;
  final DetentPerforationMask? mask;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final geometry = DetentPerforationGeometry(
      rows: rows,
      columns: columns,
      diameter: holeSize.diameter,
      gap: gap ?? density.gap,
      arrangement: arrangement,
    );
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          size: geometry.size,
          painter: _HolePainter(
            geometry: geometry,
            theme: DetentTheme.of(context),
            depth: depth,
            stateForCell: stateForCell,
            mask: mask,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// Adapts row/column counts to its available area; never stretches a circle.
class DetentPerforationPattern extends StatelessWidget {
  const DetentPerforationPattern({
    super.key,
    this.holeSize = DetentHoleSize.md,
    this.density = DetentPerforationDensity.normal,
    this.depth = DetentPerforationDepth.inset,
    this.arrangement = DetentPerforationArrangement.square,
    this.coverage = DetentPerforationCoverage.full,
    this.mask,
    this.contentBounds,
  }) : assert(coverage != DetentPerforationCoverage.custom || mask != null);
  final DetentHoleSize holeSize;
  final DetentPerforationDensity density;
  final DetentPerforationDepth depth;
  final DetentPerforationArrangement arrangement;
  final DetentPerforationCoverage coverage;
  final DetentPerforationMask? mask;

  /// Bounds in local coordinates; expanded by 16px before excluding holes.
  final Rect? contentBounds;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = constraints.constrain(
        Size(
          constraints.hasBoundedWidth ? constraints.maxWidth : 160,
          constraints.hasBoundedHeight ? constraints.maxHeight : 96,
        ),
      );
      final d = holeSize.diameter, p = d + density.gap;
      final rowPitch = arrangement == DetentPerforationArrangement.hexagonal
          ? p * math.sqrt(3) / 2
          : p;
      final rows = math.max(1, ((size.height - d) / rowPitch).floor() + 1);
      final extra =
          arrangement == DetentPerforationArrangement.hexagonal && rows > 1
          ? p / 2
          : 0;
      final columns = math.max(1, ((size.width - d - extra) / p).floor() + 1);
      final geometry = DetentPerforationGeometry(
        rows: rows,
        columns: columns,
        diameter: d,
        gap: density.gap,
        arrangement: arrangement,
      );
      return SizedBox.fromSize(
        size: size,
        child: ClipRect(
          child: Center(
            child: DetentHoleGrid(
              rows: rows,
              columns: columns,
              holeSize: holeSize,
              density: density,
              depth: depth,
              arrangement: arrangement,
              mask: (r, c, center) {
                final local =
                    center +
                    Offset(
                      (size.width - geometry.size.width) / 2,
                      (size.height - geometry.size.height) / 2,
                    );
                if (contentBounds?.inflate(16 + d / 2).contains(local) ??
                    false) {
                  return false;
                }
                final covered = switch (coverage) {
                  DetentPerforationCoverage.full => true,
                  DetentPerforationCoverage.edge =>
                    r < 2 || c < 2 || r >= rows - 2 || c >= columns - 2,
                  DetentPerforationCoverage.corner => r < 5 && c < 5,
                  DetentPerforationCoverage.custom => true,
                };
                return covered && (mask?.call(r, c, local) ?? true);
              },
            ),
          ),
        ),
      );
    },
  );
}

enum DetentPerforationSurfaceVariant {
  standard,
  subtle,
  contrast,
  elevated,
  inset,
}

class DetentPerforationSurface extends StatelessWidget {
  const DetentPerforationSurface({
    super.key,
    required this.child,
    this.variant = DetentPerforationSurfaceVariant.standard,
    this.density = DetentPerforationDensity.normal,
    this.depth = DetentPerforationDepth.inset,
    this.arrangement = DetentPerforationArrangement.square,
    this.coverage = DetentPerforationCoverage.edge,
    this.holeSize = DetentHoleSize.md,
    this.mask,
    this.padding = const EdgeInsets.all(32),
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
  }) : assert(coverage != DetentPerforationCoverage.custom || mask != null);

  final Widget child;
  final DetentPerforationSurfaceVariant variant;
  final DetentPerforationDensity density;
  final DetentPerforationDepth depth;
  final DetentPerforationArrangement arrangement;
  final DetentPerforationCoverage coverage;
  final DetentHoleSize holeSize;
  final DetentPerforationMask? mask;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final t = DetentTheme.of(context);
    final contrast = variant == DetentPerforationSurfaceVariant.contrast;
    final color = switch (variant) {
      DetentPerforationSurfaceVariant.subtle ||
      DetentPerforationSurfaceVariant.elevated => t.raised,
      DetentPerforationSurfaceVariant.contrast => t.display,
      _ => t.surface,
    };
    Widget result = DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
        border: Border.all(color: t.controlBorder),
        boxShadow: variant == DetentPerforationSurfaceVariant.elevated
            ? [
                BoxShadow(
                  color: DetentColors.black.withValues(alpha: .1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IgnorePointer(
                  child: DetentPerforationPattern(
                    holeSize: holeSize,
                    density: density,
                    depth: variant == DetentPerforationSurfaceVariant.inset
                        ? DetentPerforationDepth.deep
                        : depth,
                    arrangement: arrangement,
                    coverage: coverage,
                    mask: mask,
                  ),
                ),
              ),
            ),
            Padding(
              padding: padding,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Padding(padding: const EdgeInsets.all(16), child: child),
              ),
            ),
          ],
        ),
      ),
    );
    if (contrast) {
      result = DetentTheme(
        data: t.copyWith(brightness: Brightness.dark),
        child: DefaultTextStyle.merge(
          style: t.textTheme.bodyMedium.copyWith(
            color: t.copyWith(brightness: Brightness.dark).ink,
          ),
          child: result,
        ),
      );
    }
    return result;
  }
}

enum DetentResonanceState { idle, hover, active, pulse, listening, disabled }

enum DetentResonanceInteraction { radial, pointer, audio, notification }

enum DetentPerforationSpeed { fast, normal, slow }

int _milliseconds(DetentPerforationSpeed speed) => switch (speed) {
  DetentPerforationSpeed.fast => DetentTokens.perforation_motion_fast.toInt(),
  DetentPerforationSpeed.normal =>
    DetentTokens.perforation_motion_normal.toInt(),
  DetentPerforationSpeed.slow => DetentTokens.perforation_motion_slow.toInt(),
};

/// Visual feedback only. Audio capture and application actions stay with the host.
class DetentResonanceGrid extends StatefulWidget {
  const DetentResonanceGrid({
    super.key,
    this.rows = 11,
    this.columns = 11,
    this.holeSize = DetentHoleSize.lg,
    this.density = DetentPerforationDensity.normal,
    this.arrangement = DetentPerforationArrangement.square,
    this.state = DetentResonanceState.idle,
    this.interaction = DetentResonanceInteraction.radial,
    this.intensity = 1,
    this.level = 0,
    this.speed = DetentPerforationSpeed.normal,
    this.pulseId = 0,
    this.label = 'Audio response',
  }) : assert(rows > 0 && columns > 0),
       assert(intensity >= 0 && intensity <= 1),
       assert(level >= 0 && level <= 1);

  final int rows, columns;
  final DetentHoleSize holeSize;
  final DetentPerforationDensity density;
  final DetentPerforationArrangement arrangement;
  final DetentResonanceState state;
  final DetentResonanceInteraction interaction;
  final double intensity, level;
  final DetentPerforationSpeed speed;

  /// Increment for each notification, including repeated notifications.
  final int pulseId;
  final String label;
  @override
  State<DetentResonanceGrid> createState() => _DetentResonanceGridState();
}

class _DetentResonanceGridState extends State<DetentResonanceGrid> {
  Offset? pointer;
  int contact = 0;

  @override
  Widget build(BuildContext context) {
    final w = widget, t = DetentTheme.of(context);
    final geometry = DetentPerforationGeometry(
      rows: w.rows,
      columns: w.columns,
      diameter: w.holeSize.diameter,
      gap: w.density.gap,
      arrangement: w.arrangement,
    );
    final enabled = w.state != DetentResonanceState.disabled;
    final pulse = w.state == DetentResonanceState.pulse || contact > 0;
    final motion = _PerforationMotion(
      enabled: enabled,
      repeat: false,
      trigger: (w.pulseId, contact, w.state),
      animate: pulse,
      duration: Duration(
        milliseconds:
            _milliseconds(w.speed) +
            (DetentTokens.perforation_motion_radius *
                    DetentTokens.perforation_motion_stagger)
                .round(),
      ),
      builder: (context, phase) {
        final origin =
            pointer ??
            Offset(geometry.size.width / 2, geometry.size.height / 2);
        return ExcludeSemantics(
          child: CustomPaint(
            size: geometry.size,
            painter: _HolePainter(
              geometry: geometry,
              theme: t,
              depth: DetentPerforationDepth.inset,
              strength:
                  w.intensity *
                  (pulse
                      ? 1 - DetentTokens.perforation_motion_intensity * phase
                      : 1),
              stateForCell: (r, c) {
                if (!enabled) return DetentHoleState.disabled;
                final distance =
                    (geometry.center(r, c) - origin).distance / geometry.pitch;
                final on = switch (w.interaction) {
                  DetentResonanceInteraction.audio =>
                    w.state != DetentResonanceState.idle &&
                        r >= w.rows - (w.level * w.rows).ceil(),
                  DetentResonanceInteraction.pointer =>
                    pointer != null && distance < 2,
                  DetentResonanceInteraction.radial ||
                  DetentResonanceInteraction.notification =>
                    pulse
                        ? (t.reduceMotion(context)
                              ? w.state == DetentResonanceState.active &&
                                    distance < 1.5
                              : phase < 1 && (distance - phase * 3).abs() < .65)
                        : (w.state == DetentResonanceState.active ||
                                  w.state == DetentResonanceState.hover ||
                                  w.state == DetentResonanceState.listening) &&
                              distance < 1.5,
                };
                return on ? DetentHoleState.active : DetentHoleState.inactive;
              },
            ),
          ),
        );
      },
    );
    return Semantics(
      label: w.label,
      value: w.state.name,
      enabled: enabled,
      child: RepaintBoundary(
        child: MouseRegion(
          onHover: enabled
              ? (event) => setState(() => pointer = event.localPosition)
              : null,
          onExit: (_) => setState(() => pointer = null),
          child: Listener(
            onPointerDown: enabled
                ? (event) => setState(() {
                    pointer = event.localPosition;
                    contact++;
                  })
                : null,
            child: motion,
          ),
        ),
      ),
    );
  }
}

enum DetentSpeakerMatrixType { progress, status, level, signal, loading }

enum DetentConnectionStatus { connected, disconnected, processing }

/// Information paired with visible and machine-readable labels.
class DetentSpeakerMatrix extends StatelessWidget {
  const DetentSpeakerMatrix.progress({
    super.key,
    required double value,
    required this.label,
    this.rows = 2,
    this.columns = 10,
    this.holeSize = DetentHoleSize.lg,
    this.density = DetentPerforationDensity.normal,
    this.orientation = Axis.horizontal,
    this.enabled = true,
  }) : type = DetentSpeakerMatrixType.progress,
       value = value,
       levels = const [],
       status = DetentConnectionStatus.connected,
       strength = 0,
       maxStrength = 5,
       assert(value >= 0 && value <= 1),
       assert(rows > 0 && columns > 0);

  const DetentSpeakerMatrix.status({
    super.key,
    required this.status,
    required this.label,
    this.rows = 2,
    this.columns = 6,
    this.holeSize = DetentHoleSize.lg,
    this.density = DetentPerforationDensity.normal,
    this.orientation = Axis.horizontal,
    this.enabled = true,
  }) : type = DetentSpeakerMatrixType.status,
       value = 0,
       levels = const [],
       strength = 0,
       maxStrength = 5,
       assert(rows > 0 && columns > 0);

  const DetentSpeakerMatrix.level({
    super.key,
    required this.levels,
    required this.label,
    this.rows = 5,
    this.holeSize = DetentHoleSize.lg,
    this.density = DetentPerforationDensity.normal,
    this.orientation = Axis.horizontal,
    this.enabled = true,
  }) : type = DetentSpeakerMatrixType.level,
       columns = 0,
       value = 0,
       status = DetentConnectionStatus.connected,
       strength = 0,
       maxStrength = 5,
       assert(rows > 0);

  const DetentSpeakerMatrix.signal({
    super.key,
    required this.strength,
    required this.label,
    this.maxStrength = 5,
    this.holeSize = DetentHoleSize.lg,
    this.density = DetentPerforationDensity.normal,
    this.orientation = Axis.horizontal,
    this.enabled = true,
  }) : type = DetentSpeakerMatrixType.signal,
       rows = maxStrength,
       columns = maxStrength,
       value = 0,
       levels = const [],
       status = DetentConnectionStatus.connected,
       assert(maxStrength > 0),
       assert(strength >= 0 && strength <= maxStrength);

  const DetentSpeakerMatrix.loading({
    super.key,
    required this.label,
    this.rows = 1,
    this.columns = 8,
    this.holeSize = DetentHoleSize.lg,
    this.density = DetentPerforationDensity.normal,
    this.orientation = Axis.horizontal,
    this.enabled = true,
  }) : type = DetentSpeakerMatrixType.loading,
       value = 0,
       levels = const [],
       status = DetentConnectionStatus.processing,
       strength = 0,
       maxStrength = 5,
       assert(rows > 0 && columns > 0);

  final DetentSpeakerMatrixType type;
  final String label;
  final int rows, columns, strength, maxStrength;
  final double value;
  final List<double> levels;
  final DetentConnectionStatus status;
  final DetentHoleSize holeSize;
  final DetentPerforationDensity density;
  final Axis orientation;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    assert(type != DetentSpeakerMatrixType.level || levels.isNotEmpty);
    assert(levels.every((v) => v.isFinite && v >= 0 && v <= 1));
    final t = DetentTheme.of(context);
    final cols = type == DetentSpeakerMatrixType.level
        ? levels.length
        : columns;
    final total = rows * cols;
    final loading =
        type == DetentSpeakerMatrixType.loading ||
        type == DetentSpeakerMatrixType.status &&
            status == DetentConnectionStatus.processing;
    final description = switch (type) {
      DetentSpeakerMatrixType.progress => '${(value * 100).round()}%',
      DetentSpeakerMatrixType.status => status.name,
      DetentSpeakerMatrixType.level =>
        levels.map((v) => '${(v * 100).round()}%').join(' / '),
      DetentSpeakerMatrixType.signal => '$strength / $maxStrength',
      DetentSpeakerMatrixType.loading => 'Processing',
    };
    final color = type == DetentSpeakerMatrixType.status
        ? switch (status) {
            DetentConnectionStatus.connected => t.success,
            DetentConnectionStatus.disconnected => t.danger,
            DetentConnectionStatus.processing => t.accent,
          }
        : t.accent;
    return Semantics(
      label: label,
      value: description,
      enabled: enabled,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: t.textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(description, style: t.textTheme.labelLarge),
            const SizedBox(height: 12),
            _PerforationMotion(
              animate: loading,
              repeat: loading,
              enabled: enabled,
              trigger: (type, status),
              duration: Duration(milliseconds: math.max(800, total * 90)),
              builder: (context, phase) {
                Widget grid = DetentHoleGrid(
                  rows: rows,
                  columns: cols,
                  holeSize: holeSize,
                  density: density,
                  color: color,
                  stateForCell: (r, c) {
                    if (!enabled) return DetentHoleState.disabled;
                    final i = orientation == Axis.horizontal
                        ? r * cols + c
                        : c * rows + r;
                    final on = switch (type) {
                      DetentSpeakerMatrixType.progress =>
                        i < (value * total).floor(),
                      DetentSpeakerMatrixType.status => switch (status) {
                        DetentConnectionStatus.connected =>
                          c < math.max(1, cols ~/ 3),
                        DetentConnectionStatus.disconnected =>
                          c == (r.isEven ? 0 : cols - 1),
                        DetentConnectionStatus.processing =>
                          i == (phase * total).floor() % total,
                      },
                      DetentSpeakerMatrixType.level =>
                        r >= rows - (levels[c] * rows).ceil(),
                      DetentSpeakerMatrixType.signal =>
                        c < strength && r >= rows - c - 1,
                      DetentSpeakerMatrixType.loading =>
                        i == (phase * total).floor() % total,
                    };
                    return on
                        ? DetentHoleState.active
                        : DetentHoleState.inactive;
                  },
                );
                if (orientation == Axis.vertical &&
                    type != DetentSpeakerMatrixType.progress &&
                    type != DetentSpeakerMatrixType.loading &&
                    type != DetentSpeakerMatrixType.status) {
                  grid = RotatedBox(quarterTurns: 1, child: grid);
                }
                return grid;
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HolePainter extends CustomPainter {
  _HolePainter({
    required this.geometry,
    required this.theme,
    required this.depth,
    this.stateForCell,
    this.mask,
    this.color,
    this.strength = 1,
  });
  final DetentPerforationGeometry geometry;
  final DetentThemeData theme;
  final DetentPerforationDepth depth;
  final DetentHoleStateResolver? stateForCell;
  final DetentPerforationMask? mask;
  final Color? color;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = true;
    final radius = geometry.diameter / 2;
    final inactive = theme.dark
        ? DetentTokens.perforation_color_dark_default
        : DetentTokens.perforation_color_light_default;
    final offset = switch (depth) {
      DetentPerforationDepth.flat => DetentTokens.perforation_depth_flat,
      DetentPerforationDepth.inset => DetentTokens.perforation_depth_inset,
      DetentPerforationDepth.deep => DetentTokens.perforation_depth_deep,
    };
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (var r = 0; r < geometry.rows; r++) {
      final y = geometry.center(r, 0).dy;
      if (y - radius > size.height) break;
      for (var c = 0; c < geometry.columns; c++) {
        final center = geometry.center(r, c);
        if (center.dx - radius > size.width) break;
        if (!(mask?.call(r, c, center) ?? true)) continue;
        final state = stateForCell?.call(r, c) ?? DetentHoleState.inactive;
        final lit =
            state == DetentHoleState.active ||
            state == DetentHoleState.highlighted;
        var fill = lit ? color ?? theme.accent : inactive;
        if (state == DetentHoleState.disabled) {
          fill = Color.lerp(fill, theme.surface, .65)!;
        }
        if (lit && strength < 1) fill = Color.lerp(inactive, fill, strength)!;
        final rect = Rect.fromCircle(center: center, radius: radius);
        p.shader = null;
        p.style = PaintingStyle.fill;
        p.color = theme.highContrast
            ? theme.controlBorder
            : theme.dark
            ? theme.controlBorder
            : theme.raised;
        canvas.drawCircle(center.translate(0, .4), radius + .5, p);
        if (depth != DetentPerforationDepth.flat &&
            !lit &&
            !theme.highContrast) {
          p.shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.lerp(fill, DetentColors.black, offset * .2)!, fill],
          ).createShader(rect);
        }
        p.color = fill;
        canvas.drawCircle(center, radius, p);
        p.shader = null;
        if (lit || theme.highContrast) {
          p.style = PaintingStyle.stroke;
          p.strokeWidth = state == DetentHoleState.highlighted ? 1 : .75;
          p.color = theme.controlBorder;
          canvas.drawCircle(center, radius, p);
          p.style = PaintingStyle.fill;
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HolePainter old) =>
      geometry != old.geometry ||
      theme != old.theme ||
      depth != old.depth ||
      stateForCell != old.stateForCell ||
      mask != old.mask ||
      color != old.color ||
      strength != old.strength;
}
