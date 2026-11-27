import 'package:detent_ui/detent_ui.dart';
import 'package:flutter/widgets.dart';

/// Perforation in the spec-sheet style: holes mean a physical opening and do
/// two jobs only (DESIGN_SYSTEM.md §5.8).
///
/// P1 Grip : where a boundary or a row can be held and moved.
/// P3 Mark : the one engraved grille on the window chassis.
class PerforationSpec extends StatefulWidget {
  const PerforationSpec({super.key});
  @override
  State<PerforationSpec> createState() => _PerforationSpecState();
}

class _PerforationSpecState extends State<PerforationSpec> {
  final tracks = ['Kick', 'Snare', 'Hat', 'Bass'];

  @override
  Widget build(BuildContext context) {
    final t = DetentTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 40,
      children: [
        _thesis(t),
        _group(
          t,
          'P1  Grip — 掴む所',
          '境界の幅や行の順序を、手で動かせる所にだけ置く。普段は地の穴の色で、'
              'ポインタが乗ったとき・ドラッグ中・フォーカス中だけ文字色で埋まる。'
              'SplitViewの境界と、並べ替えできるListRowに組み込み済み。',
          [
            _cell(t, 'C49', 'Grip / 状態', _gripStates(t)),
            _cell(
              t,
              '→ C31',
              'SplitView / 境界',
              _splitView(t),
              note: 'ドラッグか、フォーカスして←→で幅を変える。',
            ),
            _cell(
              t,
              '→ C33',
              'ListRow / 並べ替え',
              _reorder(),
              note: 'Gripを縦にドラッグするか、Alt+↑↓で1行ずつ動く。',
            ),
          ],
        ),
        _group(
          t,
          'P3  Mark — 筐体の刻印',
          '機材のスピーカーのように、ウィンドウの筐体に一つだけ刻む。'
              'StatusBarの右端に既定で入り、色も動きも意味も持たない。',
          [
            _cell(t, 'C50', 'ChassisMark', _markSpec(t)),
            _cell(
              t,
              '→ C32',
              'StatusBar / 右端',
              const SizedBox(
                width: 300,
                child: DetentStatusBar(
                  children: [Text('すべて保存済み'), Spacer(), Text('48 kHz')],
                ),
              ),
              note: '同じウィンドウに二つ目のStatusBarを置くときだけ showMark: false。',
            ),
            _cell(t, '→ C28', 'AppShell / 1ウィンドウに1つ', _window(t)),
          ],
        ),
        _group(t, '使わない場面', '穴は上の二つ以外に使わない。同じ点の並びに別の意味を持たせると、どれも読めなくなる。', [
          _dont(t, '内容の額縁', '文字の周りを穴で囲むと切手のように見える。', '罫線と余白（§5.7）'),
          _dont(
            t,
            '値や状態を点灯で示す',
            '進捗・レベル・接続状態を穴の点灯で表すと、Progressなどと二通りになる。',
            'DetentProgress / DetentMeter / DetentTaskStatus',
          ),
          _dont(t, 'ポインタに反応する飾り', '動かせない所の穴が光ると、Gripと区別できない。', 'Gripだけが反応する'),
          _dont(
            t,
            'Markを複数置く',
            'パネルやカードごとに刻むと、筐体の印ではなく模様になる。',
            'StatusBarの右端に一つ',
          ),
        ], maxColumns: 4),
      ],
    );
  }

  // ── Layout helpers (spec-sheet cells, as in the component catalogue) ──

  Widget _thesis(DetentThemeData t) {
    TableRow row(List<String> cells, {bool head = false}) => TableRow(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: head ? t.controlBorder : t.border),
        ),
      ),
      children: [
        for (final c in cells)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Text(
              c,
              style: head
                  ? t.textTheme.label.copyWith(color: t.muted)
                  : t.textTheme.caption.copyWith(color: t.ink),
            ),
          ),
      ],
    );
    final table = Table(
      columnWidths: const {
        0: FixedColumnWidth(72),
        1: FlexColumnWidth(1.4),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1.3),
      },
      children: [
        row(['役割', '置く所', '穴', '色'], head: true),
        row([
          'P1 Grip',
          'SplitViewの境界・ListRowの並べ替え',
          'xs 2px / gap 4',
          '地の色、操作中は文字色',
        ]),
        row(['P3 Mark', 'StatusBarの右端（1ウィンドウに1つ）', 'sm 3px / 六角', '色なし・動きなし']),
      ],
    );
    final statement = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PERFORATION', style: t.textTheme.label.copyWith(color: t.muted)),
        const SizedBox(height: 12),
        Text('穴は「掴む所」と「筐体の刻印」だけ', style: t.textTheme.section),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            '実物の機材で穴が開いているのは、指を掛ける所と、筐体のスピーカーや通気口。'
            'Detentでも穴はこの二つの意味に限り、見ればすぐに「動かせる」か「機材の印」かが分かるようにする。',
            style: t.textTheme.body.copyWith(color: t.muted),
          ),
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, box) => box.maxWidth < 860
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 24,
              children: [statement, table],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 40,
              children: [
                Expanded(child: statement),
                Expanded(child: table),
              ],
            ),
    );
  }

  Widget _group(
    DetentThemeData t,
    String title,
    String lead,
    List<Widget> children, {
    int maxColumns = 3,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          SizedBox.square(dimension: 6, child: ColoredBox(color: t.ink)),
          const SizedBox(width: 8),
          Text(title, style: t.textTheme.componentTitle),
        ],
      ),
      const SizedBox(height: 8),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Text(lead, style: t.textTheme.caption.copyWith(color: t.muted)),
      ),
      const SizedBox(height: 20),
      LayoutBuilder(
        builder: (context, box) {
          const gap = 24.0, minWidth = 300.0;
          final columns = ((box.maxWidth + gap) / (minWidth + gap))
              .floor()
              .clamp(1, maxColumns);
          final width = (box.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: 24,
            children: [
              for (final child in children)
                SizedBox(width: width, child: child),
            ],
          );
        },
      ),
    ],
  );

  Widget _cellHeader(DetentThemeData t, String label, Widget end) => Row(
    crossAxisAlignment: CrossAxisAlignment.baseline,
    textBaseline: TextBaseline.alphabetic,
    children: [
      Expanded(child: Text(label, style: t.textTheme.label)),
      end,
    ],
  );

  Widget _cell(
    DetentThemeData t,
    String id,
    String label,
    Widget child, {
    String? note,
  }) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border(top: BorderSide(color: t.controlBorder)),
    ),
    child: Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cellHeader(
            t,
            label,
            Text(id, style: t.textTheme.label.copyWith(color: t.muted)),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 176),
            child: Align(alignment: Alignment.topLeft, child: child),
          ),
          if (note != null) ...[
            const SizedBox(height: 12),
            Text(note, style: t.textTheme.caption.copyWith(color: t.muted)),
          ],
        ],
      ),
    ),
  );

  Widget _dont(
    DetentThemeData t,
    String label,
    String reason,
    String instead,
  ) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border(top: BorderSide(color: t.controlBorder)),
    ),
    child: Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cellHeader(
            t,
            label,
            Text('使わない', style: t.textTheme.label.copyWith(color: t.danger)),
          ),
          const SizedBox(height: 12),
          Text(reason, style: t.textTheme.caption.copyWith(color: t.ink)),
          const SizedBox(height: 4),
          Text(
            '→ $instead',
            style: t.textTheme.caption.copyWith(color: t.muted),
          ),
        ],
      ),
    ),
  );

  // ── P1 Grip ──

  Widget _gripStates(DetentThemeData t) {
    Widget specimen(String caption, Widget grip) => Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        SizedBox(width: 56, height: 32, child: Center(child: grip)),
        Text(caption, style: t.textTheme.caption.copyWith(color: t.muted)),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 24,
      children: [
        Wrap(
          spacing: 32,
          runSpacing: 16,
          children: [
            specimen('待機', const DetentGrip()),
            specimen('操作中', const DetentGrip(active: true)),
            specimen('無効', const DetentGrip(enabled: false)),
            specimen('横向き', const DetentGrip(axis: Axis.horizontal)),
          ],
        ),
        Text(
          '2列 × 5段（並べ替えは3段）、穴 xs 2px・間隔 4px、太さ 8px',
          style: t.textTheme.caption.copyWith(color: t.ink),
        ),
      ],
    );
  }

  Widget _pane(DetentThemeData t, String title, Color color) => ColoredBox(
    color: color,
    child: SingleChildScrollView(
      primary: false,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Text(title, style: t.textTheme.label.copyWith(color: t.muted)),
          for (final f in [.8, .5, .65])
            FractionallySizedBox(
              widthFactor: f,
              child: SizedBox(height: 6, child: ColoredBox(color: t.border)),
            ),
        ],
      ),
    ),
  );

  Widget _splitView(DetentThemeData t) => SizedBox(
    width: 300,
    height: 160,
    child: DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(DetentRadius.control),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DetentRadius.control),
        child: DetentSplitView(
          initialExtent: 120,
          minLeading: 80,
          minTrailing: 100,
          leading: _pane(t, 'BROWSER', t.surface),
          trailing: _pane(t, 'ARRANGE', t.raised),
        ),
      ),
    ),
  );

  Widget _reorder() => SizedBox(
    width: 280,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, name) in tracks.indexed)
          DetentListRow(
            key: ValueKey(name),
            label: name,
            onPressed: () {},
            onMoveUp: i == 0
                ? null
                : () =>
                      setState(() => tracks.insert(i - 1, tracks.removeAt(i))),
            onMoveDown: i == tracks.length - 1
                ? null
                : () =>
                      setState(() => tracks.insert(i + 1, tracks.removeAt(i))),
          ),
      ],
    ),
  );

  // ── P3 Mark ──

  Widget _markSpec(DetentThemeData t) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 16,
    children: [
      DecoratedBox(
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(DetentRadius.control),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: DetentChassisMark(),
        ),
      ),
      Text(
        '52 × 14px、穴 sm 3px・間隔 4px・六角配置',
        style: t.textTheme.caption.copyWith(color: t.ink),
      ),
    ],
  );

  Widget _window(DetentThemeData t) => SizedBox(
    width: 300,
    height: 160,
    child: DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: t.controlBorder),
        borderRadius: BorderRadius.circular(DetentRadius.panel),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DetentRadius.panel),
        child: DetentAppShell(
          navigation: ColoredBox(
            color: t.chrome,
            child: SingleChildScrollView(
              primary: false,
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  for (final s in ['Library', 'Arrange', 'Mixer'])
                    Text(s, style: t.textTheme.caption.copyWith(color: t.ink)),
                ],
              ),
            ),
          ),
          body: _pane(t, 'SESSION', t.canvas),
          statusBar: const DetentStatusBar(children: [Text('準備完了')]),
        ),
      ),
    ),
  );
}
