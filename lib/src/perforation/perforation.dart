/// Perforation: holes that stand for a physical opening, used for two jobs
/// only (DESIGN_SYSTEM.md §5.8).
///
/// * P1 Grip — [DetentGrip]: where a boundary or a row can be held and moved.
/// * P3 Mark — [DetentChassisMark]: the one engraved grille on the window
///   chassis, at the right end of `DetentStatusBar`.
///
/// [DetentHoleGrid] and [DetentPerforationPattern] are the drawing primitives
/// behind both. Holes never carry progress, status, decoration frames or
/// pointer effects.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../foundation/theme.dart';
import '../foundation/tokens.g.dart';

enum DetentHoleSize {
  xs(DetentTokens.perforation_hole_size_xs),
  sm(DetentTokens.perforation_hole_size_sm),
  md(DetentTokens.perforation_hole_size_md),
  lg(DetentTokens.perforation_hole_size_lg);

  const DetentHoleSize(this.diameter);
  final double diameter;
}

/// `active` fills a hole with the ink colour (a grip being held or hovered).
enum DetentHoleState { inactive, active, disabled }

enum DetentPerforationDepth { flat, inset, deep }

enum DetentPerforationArrangement { square, hexagonal }

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

  @override
  bool operator ==(Object other) =>
      other is DetentPerforationGeometry &&
      other.rows == rows &&
      other.columns == columns &&
      other.diameter == diameter &&
      other.gap == gap &&
      other.arrangement == arrangement;

  @override
  int get hashCode => Object.hash(rows, columns, diameter, gap, arrangement);
}

/// Drawing primitive: one paint layer, however many holes.
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
          ),
        ),
      ),
    );
  }
}

/// Fills its area with as many whole holes as fit; never stretches a circle.
class DetentPerforationPattern extends StatelessWidget {
  const DetentPerforationPattern({
    super.key,
    this.holeSize = DetentHoleSize.md,
    this.density = DetentPerforationDensity.normal,
    this.depth = DetentPerforationDepth.inset,
    this.arrangement = DetentPerforationArrangement.square,
    this.mask,
  });
  final DetentHoleSize holeSize;
  final DetentPerforationDensity density;
  final DetentPerforationDepth depth;
  final DetentPerforationArrangement arrangement;
  final DetentPerforationMask? mask;

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
      final hex = arrangement == DetentPerforationArrangement.hexagonal;
      final rowPitch = hex ? p * math.sqrt(3) / 2 : p;
      final rows = math.max(1, ((size.height - d) / rowPitch).floor() + 1);
      final extra = hex && rows > 1 ? p / 2 : 0;
      final columns = math.max(1, ((size.width - d - extra) / p).floor() + 1);
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
              mask: mask,
            ),
          ),
        ),
      );
    },
  );
}

/// P1 Grip: two lines of small holes marking where a boundary or a row can be
/// held and moved. Holes fill with the ink colour while [active] (hovered,
/// dragged or focused). It draws only; the owner handles input and semantics.
class DetentGrip extends StatelessWidget {
  const DetentGrip({
    super.key,
    this.axis = Axis.vertical,
    this.length = 5,
    this.active = false,
    this.enabled = true,
  }) : assert(length > 0);

  /// Direction of the long side: vertical for a column splitter.
  final Axis axis;

  /// Number of holes along the long side (`perforation.grip.rows`).
  final int length;
  final bool active, enabled;

  /// Thickness across the short side (8px with the default tokens).
  static double get thickness =>
      DetentTokens.perforation_grip_hole +
      (DetentTokens.perforation_grip_columns - 1) *
          (DetentTokens.perforation_grip_hole +
              DetentTokens.perforation_grip_gap);

  @override
  Widget build(BuildContext context) {
    final across = DetentTokens.perforation_grip_columns.toInt();
    final vertical = axis == Axis.vertical;
    final state = !enabled
        ? DetentHoleState.disabled
        : active
        ? DetentHoleState.active
        : DetentHoleState.inactive;
    return DetentHoleGrid(
      rows: vertical ? length : across,
      columns: vertical ? across : length,
      holeSize: DetentHoleSize.xs,
      gap: DetentTokens.perforation_grip_gap,
      depth: DetentPerforationDepth.flat,
      stateForCell: (_, _) => state,
    );
  }
}

/// P3 Mark: the one engraved speaker grille on the window chassis. It has no
/// colour, motion or meaning beyond "this is the instrument". Place one per
/// window; `DetentStatusBar` shows it at its right end by default.
class DetentChassisMark extends StatelessWidget {
  const DetentChassisMark({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: DetentTokens.perforation_mark_width,
    height: DetentTokens.perforation_mark_height,
    child: DetentPerforationPattern(
      holeSize: DetentHoleSize.sm,
      density: DetentPerforationDensity.dense,
      depth: DetentPerforationDepth.flat,
      arrangement: DetentPerforationArrangement.hexagonal,
    ),
  );
}

class _HolePainter extends CustomPainter {
  _HolePainter({
    required this.geometry,
    required this.theme,
    required this.depth,
    this.stateForCell,
    this.mask,
  });
  final DetentPerforationGeometry geometry;
  final DetentThemeData theme;
  final DetentPerforationDepth depth;
  final DetentHoleStateResolver? stateForCell;
  final DetentPerforationMask? mask;

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
        final lit = state == DetentHoleState.active;
        var fill = lit ? theme.ink : inactive;
        if (state == DetentHoleState.disabled) {
          fill = Color.lerp(fill, theme.surface, .65)!;
        }
        final rect = Rect.fromCircle(center: center, radius: radius);
        // The lower lip of the hole catches light.
        p
          ..shader = null
          ..style = PaintingStyle.fill
          ..color = theme.highContrast || theme.dark
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
        if (theme.highContrast) {
          p
            ..style = PaintingStyle.stroke
            ..strokeWidth = .75
            ..color = theme.controlBorder;
          canvas.drawCircle(center, radius, p);
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
      mask != old.mask;
}
