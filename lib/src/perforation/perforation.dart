/// Precision apertures shared by material, interaction and information surfaces.
library;

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../foundation/theme.dart';
import '../foundation/tokens.g.dart';

part 'motion.dart';

enum NuiHoleSize {
  xs(NuiTokens.perforation_hole_size_xs),
  sm(NuiTokens.perforation_hole_size_sm),
  md(NuiTokens.perforation_hole_size_md),
  lg(NuiTokens.perforation_hole_size_lg);

  const NuiHoleSize(this.diameter);
  final double diameter;
}

enum NuiHoleState { inactive, active, highlighted, disabled }

enum NuiPerforationDepth { flat, inset, deep }

enum NuiPerforationArrangement { square, hexagonal }

enum NuiPerforationCoverage { full, edge, corner, custom }

enum NuiPerforationDensity {
  sparse(NuiTokens.perforation_hole_gap_relaxed),
  normal(NuiTokens.perforation_hole_gap_default),
  dense(NuiTokens.perforation_hole_gap_compact);

  const NuiPerforationDensity(this.gap);
  final double gap;
}

typedef NuiHoleStateResolver = NuiHoleState Function(int row, int column);
typedef NuiPerforationMask = bool Function(int row, int column, Offset center);

/// Grid coordinates in logical pixels. Resizing never scales the apertures.
@immutable
class NuiPerforationGeometry {
  const NuiPerforationGeometry({
    required this.rows,
    required this.columns,
    this.diameter = 4,
    this.gap = 8,
    this.arrangement = NuiPerforationArrangement.square,
  }) : assert(rows > 0 && columns > 0),
       assert(diameter > 0 && diameter < double.infinity),
       assert(gap >= 0 && gap < double.infinity);

  final int rows, columns;
  final double diameter, gap;
  final NuiPerforationArrangement arrangement;
  double get pitch => diameter + gap;
  double get rowPitch => arrangement == NuiPerforationArrangement.hexagonal
      ? pitch * math.sqrt(3) / 2
      : pitch;
  Size get size => Size(
    diameter +
        (columns - 1) * pitch +
        (arrangement == NuiPerforationArrangement.hexagonal && rows > 1
            ? pitch / 2
            : 0),
    diameter + (rows - 1) * rowPitch,
  );

  Offset center(int row, int column) {
    assert(row >= 0 && row < rows && column >= 0 && column < columns);
    return Offset(
      diameter / 2 +
          column * pitch +
          (arrangement == NuiPerforationArrangement.hexagonal && row.isOdd
              ? pitch / 2
              : 0),
      diameter / 2 + row * rowPitch,
    );
  }
}

class NuiHole extends StatelessWidget {
  const NuiHole({
    super.key,
    this.size = NuiHoleSize.md,
    this.depth = NuiPerforationDepth.inset,
    this.state = NuiHoleState.inactive,
    this.color,
  });
  final NuiHoleSize size;
  final NuiPerforationDepth depth;
  final NuiHoleState state;
  final Color? color;

  @override
  Widget build(BuildContext context) => NuiHoleGrid(
    rows: 1,
    columns: 1,
    holeSize: size,
    depth: depth,
    stateForCell: (_, _) => state,
    color: color,
  );
}

/// One paint layer, including when displaying hundreds of holes.
class NuiHoleGrid extends StatelessWidget {
  const NuiHoleGrid({
    super.key,
    this.rows = 6,
    this.columns = 12,
    this.holeSize = NuiHoleSize.md,
    this.density = NuiPerforationDensity.normal,
    this.gap,
    this.arrangement = NuiPerforationArrangement.square,
    this.depth = NuiPerforationDepth.inset,
    this.stateForCell,
    this.mask,
    this.color,
  }) : assert(rows > 0 && columns > 0),
       assert(gap == null || (gap >= 0 && gap < double.infinity));

  final int rows, columns;
  final NuiHoleSize holeSize;
  final NuiPerforationDensity density;
  final double? gap;
  final NuiPerforationArrangement arrangement;
  final NuiPerforationDepth depth;
  final NuiHoleStateResolver? stateForCell;
  final NuiPerforationMask? mask;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final geometry = NuiPerforationGeometry(
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
            theme: NuiTheme.of(context),
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
class NuiPerforationPattern extends StatelessWidget {
  const NuiPerforationPattern({
    super.key,
    this.holeSize = NuiHoleSize.md,
    this.density = NuiPerforationDensity.normal,
    this.depth = NuiPerforationDepth.inset,
    this.arrangement = NuiPerforationArrangement.square,
    this.coverage = NuiPerforationCoverage.full,
    this.mask,
    this.contentBounds,
  }) : assert(coverage != NuiPerforationCoverage.custom || mask != null);
  final NuiHoleSize holeSize;
  final NuiPerforationDensity density;
  final NuiPerforationDepth depth;
  final NuiPerforationArrangement arrangement;
  final NuiPerforationCoverage coverage;
  final NuiPerforationMask? mask;

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
      final rowPitch = arrangement == NuiPerforationArrangement.hexagonal
          ? p * math.sqrt(3) / 2
          : p;
      final rows = math.max(1, ((size.height - d) / rowPitch).floor() + 1);
      final extra =
          arrangement == NuiPerforationArrangement.hexagonal && rows > 1
          ? p / 2
          : 0;
      final columns = math.max(1, ((size.width - d - extra) / p).floor() + 1);
      final geometry = NuiPerforationGeometry(
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
            child: NuiHoleGrid(
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
                  NuiPerforationCoverage.full => true,
                  NuiPerforationCoverage.edge =>
                    r < 2 || c < 2 || r >= rows - 2 || c >= columns - 2,
                  NuiPerforationCoverage.corner => r < 5 && c < 5,
                  NuiPerforationCoverage.custom => true,
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

enum NuiPerforationSurfaceVariant {
  standard,
  subtle,
  contrast,
  elevated,
  inset,
}

class NuiPerforationSurface extends StatelessWidget {
  const NuiPerforationSurface({
    super.key,
    required this.child,
    this.variant = NuiPerforationSurfaceVariant.standard,
    this.density = NuiPerforationDensity.normal,
    this.depth = NuiPerforationDepth.inset,
    this.arrangement = NuiPerforationArrangement.square,
    this.coverage = NuiPerforationCoverage.edge,
    this.holeSize = NuiHoleSize.md,
    this.mask,
    this.padding = const EdgeInsets.all(32),
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
  }) : assert(coverage != NuiPerforationCoverage.custom || mask != null);

  final Widget child;
  final NuiPerforationSurfaceVariant variant;
  final NuiPerforationDensity density;
  final NuiPerforationDepth depth;
  final NuiPerforationArrangement arrangement;
  final NuiPerforationCoverage coverage;
  final NuiHoleSize holeSize;
  final NuiPerforationMask? mask;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final t = NuiTheme.of(context);
    final contrast = variant == NuiPerforationSurfaceVariant.contrast;
    final color = switch (variant) {
      NuiPerforationSurfaceVariant.subtle ||
      NuiPerforationSurfaceVariant.elevated => t.raised,
      NuiPerforationSurfaceVariant.contrast => t.display,
      _ => t.surface,
    };
    Widget result = DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
        border: Border.all(color: t.controlBorder),
        boxShadow: variant == NuiPerforationSurfaceVariant.elevated
            ? [
                BoxShadow(
                  color: NuiColors.black.withValues(alpha: .1),
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
                  child: NuiPerforationPattern(
                    holeSize: holeSize,
                    density: density,
                    depth: variant == NuiPerforationSurfaceVariant.inset
                        ? NuiPerforationDepth.deep
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
      result = NuiTheme(
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

enum NuiResonanceState { idle, hover, active, pulse, listening, disabled }

enum NuiResonanceInteraction { radial, pointer, audio, notification }

enum NuiPerforationSpeed { fast, normal, slow }

int _milliseconds(NuiPerforationSpeed speed) => switch (speed) {
  NuiPerforationSpeed.fast => NuiTokens.perforation_motion_fast.toInt(),
  NuiPerforationSpeed.normal => NuiTokens.perforation_motion_normal.toInt(),
  NuiPerforationSpeed.slow => NuiTokens.perforation_motion_slow.toInt(),
};

/// Visual feedback only. Audio capture and application actions stay with the host.
class NuiResonanceGrid extends StatefulWidget {
  const NuiResonanceGrid({
    super.key,
    this.rows = 11,
    this.columns = 11,
    this.holeSize = NuiHoleSize.lg,
    this.density = NuiPerforationDensity.normal,
    this.arrangement = NuiPerforationArrangement.square,
    this.state = NuiResonanceState.idle,
    this.interaction = NuiResonanceInteraction.radial,
    this.intensity = 1,
    this.level = 0,
    this.speed = NuiPerforationSpeed.normal,
    this.pulseId = 0,
    this.label = 'Audio response',
  }) : assert(rows > 0 && columns > 0),
       assert(intensity >= 0 && intensity <= 1),
       assert(level >= 0 && level <= 1);

  final int rows, columns;
  final NuiHoleSize holeSize;
  final NuiPerforationDensity density;
  final NuiPerforationArrangement arrangement;
  final NuiResonanceState state;
  final NuiResonanceInteraction interaction;
  final double intensity, level;
  final NuiPerforationSpeed speed;

  /// Increment for each notification, including repeated notifications.
  final int pulseId;
  final String label;
  @override
  State<NuiResonanceGrid> createState() => _NuiResonanceGridState();
}

class _NuiResonanceGridState extends State<NuiResonanceGrid> {
  Offset? pointer;
  int contact = 0;

  @override
  Widget build(BuildContext context) {
    final w = widget, t = NuiTheme.of(context);
    final geometry = NuiPerforationGeometry(
      rows: w.rows,
      columns: w.columns,
      diameter: w.holeSize.diameter,
      gap: w.density.gap,
      arrangement: w.arrangement,
    );
    final enabled = w.state != NuiResonanceState.disabled;
    final pulse = w.state == NuiResonanceState.pulse || contact > 0;
    final motion = _PerforationMotion(
      enabled: enabled,
      repeat: false,
      trigger: (w.pulseId, contact, w.state),
      animate: pulse,
      duration: Duration(
        milliseconds:
            _milliseconds(w.speed) +
            (NuiTokens.perforation_motion_radius *
                    NuiTokens.perforation_motion_stagger)
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
              depth: NuiPerforationDepth.inset,
              strength:
                  w.intensity *
                  (pulse
                      ? 1 - NuiTokens.perforation_motion_intensity * phase
                      : 1),
              stateForCell: (r, c) {
                if (!enabled) return NuiHoleState.disabled;
                final distance =
                    (geometry.center(r, c) - origin).distance / geometry.pitch;
                final on = switch (w.interaction) {
                  NuiResonanceInteraction.audio =>
                    w.state != NuiResonanceState.idle &&
                        r >= w.rows - (w.level * w.rows).ceil(),
                  NuiResonanceInteraction.pointer =>
                    pointer != null && distance < 2,
                  NuiResonanceInteraction.radial ||
                  NuiResonanceInteraction.notification =>
                    pulse
                        ? (t.reduceMotion(context)
                              ? w.state == NuiResonanceState.active &&
                                    distance < 1.5
                              : phase < 1 && (distance - phase * 3).abs() < .65)
                        : (w.state == NuiResonanceState.active ||
                                  w.state == NuiResonanceState.hover ||
                                  w.state == NuiResonanceState.listening) &&
                              distance < 1.5,
                };
                return on ? NuiHoleState.active : NuiHoleState.inactive;
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

enum NuiSpeakerMatrixType { progress, status, level, signal, loading }

enum NuiConnectionStatus { connected, disconnected, processing }

/// Information paired with visible and machine-readable labels.
class NuiSpeakerMatrix extends StatelessWidget {
  const NuiSpeakerMatrix.progress({
    super.key,
    required double value,
    required this.label,
    this.rows = 2,
    this.columns = 10,
    this.holeSize = NuiHoleSize.lg,
    this.density = NuiPerforationDensity.normal,
    this.orientation = Axis.horizontal,
    this.enabled = true,
  }) : type = NuiSpeakerMatrixType.progress,
       value = value,
       levels = const [],
       status = NuiConnectionStatus.connected,
       strength = 0,
       maxStrength = 5,
       assert(value >= 0 && value <= 1),
       assert(rows > 0 && columns > 0);

  const NuiSpeakerMatrix.status({
    super.key,
    required this.status,
    required this.label,
    this.rows = 2,
    this.columns = 6,
    this.holeSize = NuiHoleSize.lg,
    this.density = NuiPerforationDensity.normal,
    this.orientation = Axis.horizontal,
    this.enabled = true,
  }) : type = NuiSpeakerMatrixType.status,
       value = 0,
       levels = const [],
       strength = 0,
       maxStrength = 5,
       assert(rows > 0 && columns > 0);

  const NuiSpeakerMatrix.level({
    super.key,
    required this.levels,
    required this.label,
    this.rows = 5,
    this.holeSize = NuiHoleSize.lg,
    this.density = NuiPerforationDensity.normal,
    this.orientation = Axis.horizontal,
    this.enabled = true,
  }) : type = NuiSpeakerMatrixType.level,
       columns = 0,
       value = 0,
       status = NuiConnectionStatus.connected,
       strength = 0,
       maxStrength = 5,
       assert(rows > 0);

  const NuiSpeakerMatrix.signal({
    super.key,
    required this.strength,
    required this.label,
    this.maxStrength = 5,
    this.holeSize = NuiHoleSize.lg,
    this.density = NuiPerforationDensity.normal,
    this.orientation = Axis.horizontal,
    this.enabled = true,
  }) : type = NuiSpeakerMatrixType.signal,
       rows = maxStrength,
       columns = maxStrength,
       value = 0,
       levels = const [],
       status = NuiConnectionStatus.connected,
       assert(maxStrength > 0),
       assert(strength >= 0 && strength <= maxStrength);

  const NuiSpeakerMatrix.loading({
    super.key,
    required this.label,
    this.rows = 1,
    this.columns = 8,
    this.holeSize = NuiHoleSize.lg,
    this.density = NuiPerforationDensity.normal,
    this.orientation = Axis.horizontal,
    this.enabled = true,
  }) : type = NuiSpeakerMatrixType.loading,
       value = 0,
       levels = const [],
       status = NuiConnectionStatus.processing,
       strength = 0,
       maxStrength = 5,
       assert(rows > 0 && columns > 0);

  final NuiSpeakerMatrixType type;
  final String label;
  final int rows, columns, strength, maxStrength;
  final double value;
  final List<double> levels;
  final NuiConnectionStatus status;
  final NuiHoleSize holeSize;
  final NuiPerforationDensity density;
  final Axis orientation;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    assert(type != NuiSpeakerMatrixType.level || levels.isNotEmpty);
    assert(levels.every((v) => v.isFinite && v >= 0 && v <= 1));
    final t = NuiTheme.of(context);
    final cols = type == NuiSpeakerMatrixType.level ? levels.length : columns;
    final total = rows * cols;
    final loading =
        type == NuiSpeakerMatrixType.loading ||
        type == NuiSpeakerMatrixType.status &&
            status == NuiConnectionStatus.processing;
    final description = switch (type) {
      NuiSpeakerMatrixType.progress => '${(value * 100).round()}%',
      NuiSpeakerMatrixType.status => status.name,
      NuiSpeakerMatrixType.level =>
        levels.map((v) => '${(v * 100).round()}%').join(' / '),
      NuiSpeakerMatrixType.signal => '$strength / $maxStrength',
      NuiSpeakerMatrixType.loading => 'Processing',
    };
    final color = type == NuiSpeakerMatrixType.status
        ? switch (status) {
            NuiConnectionStatus.connected => t.success,
            NuiConnectionStatus.disconnected => t.danger,
            NuiConnectionStatus.processing => t.accent,
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
                Widget grid = NuiHoleGrid(
                  rows: rows,
                  columns: cols,
                  holeSize: holeSize,
                  density: density,
                  color: color,
                  stateForCell: (r, c) {
                    if (!enabled) return NuiHoleState.disabled;
                    final i = orientation == Axis.horizontal
                        ? r * cols + c
                        : c * rows + r;
                    final on = switch (type) {
                      NuiSpeakerMatrixType.progress =>
                        i < (value * total).floor(),
                      NuiSpeakerMatrixType.status => switch (status) {
                        NuiConnectionStatus.connected =>
                          c < math.max(1, cols ~/ 3),
                        NuiConnectionStatus.disconnected =>
                          c == (r.isEven ? 0 : cols - 1),
                        NuiConnectionStatus.processing =>
                          i == (phase * total).floor() % total,
                      },
                      NuiSpeakerMatrixType.level =>
                        r >= rows - (levels[c] * rows).ceil(),
                      NuiSpeakerMatrixType.signal =>
                        c < strength && r >= rows - c - 1,
                      NuiSpeakerMatrixType.loading =>
                        i == (phase * total).floor() % total,
                    };
                    return on ? NuiHoleState.active : NuiHoleState.inactive;
                  },
                );
                if (orientation == Axis.vertical &&
                    type != NuiSpeakerMatrixType.progress &&
                    type != NuiSpeakerMatrixType.loading &&
                    type != NuiSpeakerMatrixType.status) {
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
  final NuiPerforationGeometry geometry;
  final NuiThemeData theme;
  final NuiPerforationDepth depth;
  final NuiHoleStateResolver? stateForCell;
  final NuiPerforationMask? mask;
  final Color? color;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = true;
    final radius = geometry.diameter / 2;
    final inactive = theme.dark
        ? NuiTokens.perforation_color_dark_default
        : NuiTokens.perforation_color_light_default;
    final offset = switch (depth) {
      NuiPerforationDepth.flat => NuiTokens.perforation_depth_flat,
      NuiPerforationDepth.inset => NuiTokens.perforation_depth_inset,
      NuiPerforationDepth.deep => NuiTokens.perforation_depth_deep,
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
        final state = stateForCell?.call(r, c) ?? NuiHoleState.inactive;
        final lit =
            state == NuiHoleState.active || state == NuiHoleState.highlighted;
        var fill = lit ? color ?? theme.accent : inactive;
        if (state == NuiHoleState.disabled) {
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
        if (depth != NuiPerforationDepth.flat && !lit && !theme.highContrast) {
          p.shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.lerp(fill, NuiColors.black, offset * .2)!, fill],
          ).createShader(rect);
        }
        p.color = fill;
        canvas.drawCircle(center, radius, p);
        p.shader = null;
        if (lit || theme.highContrast) {
          p.style = PaintingStyle.stroke;
          p.strokeWidth = state == NuiHoleState.highlighted ? 1 : .75;
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
