import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:detent_ui/detent_ui.dart';

/// A session-only reference workflow, not a file editor or export service.
class MaterialWorkspace extends StatefulWidget {
  const MaterialWorkspace({super.key});
  @override
  State<MaterialWorkspace> createState() => _MaterialWorkspaceState();
}

class _MaterialWorkspaceState extends State<MaterialWorkspace> {
  static const names = ['同心円', '波形', '格子'];
  int material = 0, view = 0;
  String query = '';
  final search = TextEditingController();
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  final values = <double>[64, 50, 50];
  final saved = <double>[50, 50, 50];
  bool get dirty => values[material] != saved[material];

  @override
  Widget build(BuildContext context) {
    final t = NuiTheme.of(context);
    final type = t.textTheme;
    Widget section(String title, Widget child) => NuiPanel(
      header: Text(title, style: type.sectionTitle),
      child: child,
    );
    final library = section(
      '素材ライブラリ',
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NuiSearchField(
            controller: search,
            hintText: '素材を検索',
            onChanged: (v) => setState(() => query = v),
          ),
          const SizedBox(height: 16),
          if (!names.any((name) => name.contains(query)))
            const Text('一致する素材がありません'),
          for (var i = 0; i < names.length; i++)
            if (names[i].contains(query)) ...[
              NuiListRow(
                label: names[i],
                description: values[i] != saved[i] ? '未確定の調整あり' : '調整済み',
                leading: Icon(
                  [
                    FLucideIcons.circle,
                    FLucideIcons.activity,
                    FLucideIcons.grid2x2,
                  ][i],
                ),
                trailing: i == material ? const Icon(FLucideIcons.check) : null,
                selected: i == material,
                onPressed: () => setState(() => material = i),
              ),
              const SizedBox(height: 8),
            ],
          const SizedBox(height: 16),
          const Text('素材を切り替えても調整値を保持します。'),
        ],
      ),
    );
    final preview = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 24,
          runSpacing: 12,
          children: [
            Text('プレビュー', style: type.sectionTitle),
            const NuiHoleGrid(
              rows: 2,
              columns: 16,
              holeSize: NuiHoleSize.sm,
              gap: 9,
            ),
          ],
        ),
        const SizedBox(height: 12),
        NuiSegmentedControl<int>(
          options: const [NuiOption(0, '調整後'), NuiOption(1, '確定値')],
          value: view,
          onChanged: (v) => setState(() => view = v),
        ),
        const SizedBox(height: 16),
        Semantics(
          image: true,
          label:
              '${names[material]}、${view == 0 ? '調整後' : '確定値'}、密度 ${(view == 0 ? values[material] : saved[material]).round()}パーセント',
          child: Container(
            height: 360,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: t.raised,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: t.controlBorder),
              boxShadow: t.highContrast
                  ? null
                  : [BoxShadow(color: t.border, offset: const Offset(0, 2))],
            ),
            child: CustomPaint(
              painter: _MaterialPainter(
                material,
                view == 0 ? values[material] : saved[material],
                t.ink,
                t.border,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            Text(names[material]),
            Text(view == 0 ? '調整後を表示' : '確定値を表示', style: type.bodySmall),
          ],
        ),
      ],
    );
    final inspector = section(
      '素材の調整',
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('密度'),
          const SizedBox(height: 12),
          Center(
            child: NuiRotaryKnob(
              label: '素材の密度',
              value: values[material],
              valueLabel: '${values[material].round()}%',
              onChanged: (v) => setState(() => values[material] = v),
            ),
          ),
          const SizedBox(height: 8),
          NuiSlider(
            label: '素材の密度',
            value: values[material],
            max: 100,
            divisions: 100,
            onChanged: (v) => setState(() => values[material] = v),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: t.display,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: t.controlBorder),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: NuiDotMatrix(
                text: '${values[material].round()}%',
                dotSize: 4,
                semanticLabel: '密度 ${values[material].round()}パーセント',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(dirty ? '未確定の調整があります' : '調整は確定済みです'),
          const SizedBox(height: 16),
          NuiButton(
            label: '確定値に戻す',
            onPressed: dirty
                ? () => setState(() => values[material] = saved[material])
                : null,
          ),
          const SizedBox(height: 16),
          Text('この見本の確定値は画面を開いている間だけ保持されます。', style: type.bodySmall),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.controlBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              Text('素材編集ワークスペース', style: type.title),
              NuiButton(
                label: '調整を確定',
                variant: NuiButtonVariant.primary,
                onPressed: dirty
                    ? () => setState(() => saved[material] = values[material])
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('素材を選び、密度を調整し、確定値と比較できます。'),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, c) {
              final scaled = MediaQuery.textScalerOf(context).scale(14) > 20;
              if (c.maxWidth < 1000 || scaled) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    library,
                    const SizedBox(height: 16),
                    preview,
                    const SizedBox(height: 16),
                    inspector,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 224, child: library),
                  const SizedBox(width: 16),
                  Expanded(child: preview),
                  const SizedBox(width: 16),
                  SizedBox(width: 264, child: inspector),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const NuiDivider(),
          Text(
            '${names[material]} / ${view == 0 ? '調整後を表示' : '確定値を表示'} / ${dirty ? '未確定' : '確定済み'}',
            style: type.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _MaterialPainter extends CustomPainter {
  const _MaterialPainter(this.material, this.value, this.ink, this.border);
  final int material;
  final double value;
  final Color ink, border;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = border
      ..strokeWidth = 1;
    // Edge graduations belong to the frame; the artwork stays pattern-free.
    for (double x = 12; x < size.width - 12; x += 12) {
      canvas.drawLine(Offset(x, 0), Offset(x, x % 60 == 0 ? 10 : 5), p);
      canvas.drawLine(Offset(x, size.height), Offset(x, size.height - 5), p);
    }
    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(16, 18, math.max(0, size.width - 32), size.height - 36),
    );
    p
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final count = 3 + (value / 6).round();
    final center = size.center(Offset.zero);
    if (material == 0) {
      for (var i = 1; i <= count; i++) {
        canvas.drawCircle(
          center,
          i * math.min(size.width, size.height) * .4 / count,
          p,
        );
      }
    } else if (material == 1) {
      final path = Path();
      for (var x = 0.0; x <= size.width; x += 2) {
        final y =
            center.dy +
            math.sin(x / size.width * math.pi * count) * size.height * .28;
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, p);
    } else {
      final pitch = 120 / count;
      for (double x = center.dx % pitch; x < size.width; x += pitch) {
        canvas.drawLine(Offset(x, 20), Offset(x, size.height - 20), p);
      }
      for (double y = center.dy % pitch; y < size.height - 20; y += pitch) {
        canvas.drawLine(Offset(20, y), Offset(size.width - 20, y), p);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MaterialPainter old) =>
      material != old.material ||
      value != old.value ||
      ink != old.ink ||
      border != old.border;
}
