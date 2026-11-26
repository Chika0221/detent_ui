import 'package:detent_ui/detent_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'material_workspace.dart';
import 'perforation_showcase.dart';
import 'workshop_navigation.dart';

class GalleryBody extends StatefulWidget {
  const GalleryBody({super.key});
  @override
  State<GalleryBody> createState() => _GalleryBodyState();
}

enum _Section {
  controls('操作部品', FLucideIcons.slidersHorizontal),
  inputs('入力', FLucideIcons.keyboard),
  navigation('ナビゲーション', FLucideIcons.compass),
  workspace('作業領域', FLucideIcons.panelsTopLeft),
  feedback('状態と通知', FLucideIcons.bell),
  material('素材ワークスペース', FLucideIcons.shapes),
  perforation('Perforation', FLucideIcons.grid2x2),
  motion('モーション', FLucideIcons.play);

  const _Section(this.title, this.icon);
  final String title;
  final IconData icon;
}

class _GalleryBodyState extends State<GalleryBody> {
  final _scroll = ScrollController();
  final _anchors = {
    for (final section in _Section.values) section: GlobalKey(),
  };
  _Section _active = _Section.controls;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_updateActiveSection);
  }

  void _updateActiveSection() {
    if (!_scroll.hasClients || !_scroll.position.hasContentDimensions) return;
    if (_scroll.offset >= _scroll.position.maxScrollExtent - 1 &&
        _scroll.position.maxScrollExtent > 0) {
      if (_active != _Section.motion) setState(() => _active = _Section.motion);
      return;
    }
    var current = _Section.controls;
    for (final section in _Section.values) {
      final render = _anchors[section]!.currentContext?.findRenderObject();
      if (render == null || !render.attached) continue;
      final viewport = RenderAbstractViewport.maybeOf(render);
      if (viewport == null) continue;
      final offset = viewport.getOffsetToReveal(render, 0).offset;
      if (offset <= _scroll.offset + 56) current = section;
    }
    if (current != _active) setState(() => _active = current);
  }

  void _openSection(_Section section) {
    final target = _anchors[section]!.currentContext;
    if (target != null) Scrollable.ensureVisible(target);
  }

  bool toggle = true;
  bool? check = true;
  double value = 68;
  RangeValues range = const RangeValues(25, 80);
  int choice = 0;
  Set<String> expanded = {'root'}, selected = {'button'};
  Set<Object> rows = {};
  DetentShortcut? shortcut;
  String tab = 'design', search = '';
  DetentTaskState taskState = DetentTaskState.idle;
  bool ascending = true;
  final name = TextEditingController(text: 'Atelier / 新しい作業');
  @override
  void dispose() {
    _scroll.dispose();
    name.dispose();
    super.dispose();
  }

  List<DetentMenuItem> get menu => [
    DetentMenuItem(
      label: '新規ファイル',
      icon: FLucideIcons.plus,
      shortcut: 'Ctrl + N',
      onPressed: notify,
    ),
    DetentMenuItem(
      label: '保存',
      icon: FLucideIcons.save,
      shortcut: 'Ctrl + S',
      onPressed: notify,
    ),
    DetentMenuItem(
      label: '表示',
      children: [
        DetentMenuItem(
          label: 'グリッド',
          checked: toggle,
          onPressed: () => setState(() => toggle = !toggle),
        ),
      ],
    ),
    DetentMenuItem(label: '削除', danger: true, onPressed: dialog),
  ];
  void notify() => DetentToast.show(
    context,
    message: '変更を保存しました',
    actionLabel: '元に戻す',
    onAction: () {},
  );
  void dialog() => DetentDialog.show<void>(
    context,
    builder: (ctx) => DetentDialog(
      title: '変更を保存しますか？',
      actions: [
        DetentButton(
          label: 'キャンセル',
          autofocus: true,
          onPressed: () => Navigator.pop(ctx),
        ),
        DetentButton(
          label: '保存',
          variant: DetentButtonVariant.primary,
          onPressed: () {
            Navigator.pop(ctx);
            notify();
          },
        ),
      ],
      child: const Text('作業内容に未保存の変更があります。'),
    ),
  );
  // A spec sheet: each component is a cell under one rule, named in an
  // engraved label with its catalogue number at the right edge. Only the
  // controls themselves keep physical depth (DESIGN_SYSTEM.md §5.7).
  Widget card(int id, String label, Widget child, {double? height}) {
    final t = DetentTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.controlBorder)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(child: Text(label, style: t.textTheme.label)),
                Text(
                  'C${id.toString().padLeft(2, '0')}',
                  style: t.textTheme.label.copyWith(color: t.muted),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.topLeft,
              child: height == null
                  ? child
                  : SizedBox(height: height, child: child),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final opts = [
      const DetentOption(0, '一覧', icon: FLucideIcons.list),
      const DetentOption(1, 'グリッド', icon: FLucideIcons.layoutGrid),
      const DetentOption(2, '比較', icon: FLucideIcons.columns2),
    ];
    final theme = DetentTheme.of(context);
    Widget group(List<Widget> children, {String? title}) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null) ...[
          Row(
            children: [
              // A small square marker, like a printed index tab.
              SizedBox.square(
                dimension: 6,
                child: ColoredBox(color: theme.ink),
              ),
              const SizedBox(width: 8),
              Text(title, style: theme.textTheme.componentTitle),
            ],
          ),
          const SizedBox(height: 16),
        ],
        // Even columns from the available width instead of fixed 360px cards.
        LayoutBuilder(
          builder: (context, box) {
            const gap = 24.0, minWidth = 300.0;
            final columns = ((box.maxWidth + gap) / (minWidth + gap))
                .floor()
                .clamp(1, 4);
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
    Widget section(
      _Section section,
      List<Widget> children, {
      bool showTitle = true,
    }) => Padding(
      key: _anchors[section],
      padding: const EdgeInsets.only(top: 24, bottom: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 32,
        children: [
          if (showTitle)
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: theme.ink, width: 2)),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    SizedBox(
                      width: 56,
                      child: Text(
                        (section.index + 1).toString().padLeft(2, '0'),
                        style: theme.textTheme.readout.copyWith(
                          color: theme.muted,
                        ),
                      ),
                    ),
                    Text(section.title, style: theme.textTheme.section),
                  ],
                ),
              ),
            ),
          ...children,
        ],
      ),
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title block: a quiet spec line over one large heading.
        Text(
          'DETENT UI  /  COMPONENT WORKSHOP  /  ${_Section.values.length} SECTIONS',
          style: theme.textTheme.label.copyWith(color: theme.muted),
        ),
        const SizedBox(height: 12),
        Text(
          'UIワークショップ',
          style: theme.textTheme.page.copyWith(
            fontSize: DetentTokens.primitive_typeSize_display,
            height: 1.1,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Detent UIの部品と画面作例',
          style: theme.textTheme.body.copyWith(color: theme.muted),
        ),
        const SizedBox(height: 40),
        section(_Section.controls, [
          group([
            card(
              1,
              'Button',
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  DetentButton(
                    label: '保存',
                    icon: FLucideIcons.save,
                    variant: DetentButtonVariant.primary,
                    onPressed: notify,
                  ),
                  DetentButton(
                    label: '削除',
                    variant: DetentButtonVariant.danger,
                    onPressed: dialog,
                  ),
                  const DetentButton(label: '処理中', loading: true),
                  const DetentButton(label: '無効'),
                ],
              ),
            ),
            card(
              2,
              'IconButton',
              Row(
                children: [
                  DetentIconButton(
                    icon: FLucideIcons.plus,
                    tooltip: '新規作成',
                    onPressed: notify,
                  ),
                  DetentIconButton(
                    icon: FLucideIcons.ellipsis,
                    tooltip: 'その他',
                    onPressed: notify,
                  ),
                ],
              ),
            ),
            card(
              3,
              'ToggleButton',
              DetentToggleButton(
                label: '太字',
                icon: FLucideIcons.bold,
                value: toggle,
                onChanged: (v) => setState(() => toggle = v),
              ),
            ),
            card(
              4,
              'Keycap',
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  DetentKeycap(label: 'Ctrl'),
                  DetentKeycap(label: 'Shift', units: 1.5),
                  DetentKeycap(label: 'K', pressed: true),
                  DetentKeycap(label: 'Enter', units: 2),
                ],
              ),
            ),
          ], title: 'ボタンとキー'),
          group([
            card(
              5,
              'SegmentedControl',
              DetentSegmentedControl(
                options: opts,
                value: choice,
                onChanged: (v) => setState(() => choice = v),
              ),
            ),
            card(
              6,
              'Checkbox',
              DetentCheckbox(
                value: check,
                tristate: true,
                label: 'すべて選択',
                onChanged: (v) => setState(() => check = v),
              ),
            ),
            card(
              7,
              'RadioGroup',
              DetentRadioGroup(
                options: opts,
                value: choice,
                onChanged: (v) => setState(() => choice = v),
              ),
            ),
            card(
              8,
              'Switch',
              Wrap(
                spacing: 24,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  DetentSwitch(
                    value: toggle,
                    label: '自動保存',
                    onChanged: (v) => setState(() => toggle = v),
                  ),
                  DetentSwitch(
                    value: !toggle,
                    axis: Axis.horizontal,
                    label: '横向き',
                    onChanged: (v) => setState(() => toggle = !v),
                  ),
                ],
              ),
            ),
          ], title: '切り替えと選択'),
          group([
            card(
              9,
              'Slider',
              Column(
                children: [
                  DetentSlider(
                    value: value,
                    min: 0,
                    max: 100,
                    label: '出力品質',
                    onChanged: (v) => setState(() => value = v),
                  ),
                  Text('${value.round()}%'),
                  const SizedBox(height: 16),
                  // The same value on a mixer-style vertical fader.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      DetentSlider(
                        value: value,
                        min: 0,
                        max: 100,
                        axis: Axis.vertical,
                        length: 144,
                        label: '出力品質（縦）',
                        onChanged: (v) => setState(() => value = v),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            card(
              10,
              'RangeSlider',
              DetentRangeSlider(
                values: range,
                min: 0,
                max: 100,
                onChanged: (v) => setState(() => range = v),
              ),
            ),
            card(
              11,
              'RotaryKnob',
              Center(
                child: DetentRotaryKnob(
                  value: value,
                  min: 0,
                  max: 100,
                  label: 'ズーム',
                  valueLabel: '${value.round()}%',
                  onChanged: (v) => setState(() => value = v),
                ),
              ),
            ),
            card(
              12,
              'NumberStepper',
              DetentNumberStepper(
                value: value,
                min: 0,
                max: 100,
                fractionDigits: 1,
                unit: '%',
                onChanged: (v) => setState(() => value = v),
              ),
            ),
          ], title: '値の調整'),
        ]),
        section(_Section.inputs, [
          group([
            card(
              13,
              'TextField',
              DetentTextField(controller: name, semanticLabel: 'プロジェクト名'),
            ),
            card(
              14,
              'TextArea',
              const DetentTextArea(hintText: '日本語の文章を入力できます', maxLength: 500),
            ),
            card(
              15,
              'SearchField',
              DetentSearchField(
                shortcut: 'Ctrl + K',
                onChanged: (v) => setState(() => search = v),
              ),
            ),
          ], title: 'テキスト入力'),
          group([
            card(
              16,
              'Select',
              DetentSelect(
                options: opts,
                value: choice,
                onChanged: (v) => setState(() => choice = v!),
              ),
            ),
            card(
              17,
              'ComboBox',
              DetentComboBox(
                options: opts,
                onSelected: (v) => setState(() => choice = v),
              ),
            ),
            card(
              18,
              'ShortcutRecorder',
              DetentShortcutRecorder(
                value: shortcut,
                onChanged: (v) => setState(() => shortcut = v),
              ),
            ),
            card(
              19,
              'FormField',
              const DetentFormField(
                label: '名前',
                required: true,
                error: '名前を入力してください',
                child: DetentTextField(errorText: '必須項目です'),
              ),
            ),
          ], title: '選択・ショートカット・フォーム'),
        ]),
        section(_Section.navigation, [
          group([
            card(
              20,
              'Tabs',
              DetentTabs(
                tabs: [
                  DetentTab(
                    'design',
                    'デザイン.json',
                    dirty: true,
                    onClose: notify,
                  ),
                  const DetentTab('spec', '仕様.md'),
                ],
                value: tab,
                onChanged: (v) => setState(() => tab = v),
              ),
            ),
            card(
              21,
              'NavigationRail',
              Align(
                alignment: Alignment.centerLeft,
                child: DetentNavigationRail(
                  options: opts,
                  value: choice,
                  onChanged: (v) => setState(() => choice = v),
                ),
              ),
            ),
            card(
              22,
              'SidebarItem',
              DetentSidebarItem(
                label: 'コンポーネント',
                icon: FLucideIcons.layoutGrid,
                selected: true,
                count: 48,
                onPressed: notify,
              ),
            ),
            card(
              23,
              'Breadcrumb',
              DetentBreadcrumb(
                items: [
                  DetentBreadcrumbItem('ワークスペース', onPressed: notify),
                  DetentBreadcrumbItem('UI', onPressed: notify),
                  const DetentBreadcrumbItem('Controls'),
                ],
              ),
            ),
            card(
              24,
              'MenuBar',
              SizedBox(
                width: double.infinity,
                child: DetentMenuBar(
                  menus: [
                    DetentMenuItem(label: 'ファイル', children: menu),
                    DetentMenuItem(label: '編集', children: menu),
                  ],
                ),
              ),
            ),
            card(
              25,
              'DropdownMenu',
              DetentDropdownMenu(label: '操作', items: menu),
            ),
            card(
              26,
              'ContextMenu',
              DetentContextMenu(
                items: menu,
                child: const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('右クリック / Shift + F10'),
                ),
              ),
            ),
            card(
              27,
              'CommandPalette',
              DetentButton(
                label: 'コマンドを開く',
                onPressed: () => DetentCommandPalette.show(
                  context,
                  commands: [
                    DetentCommand(
                      id: 'save',
                      label: '変更を保存',
                      shortcut: 'Ctrl + S',
                      onPressed: notify,
                    ),
                    DetentCommand(
                      id: 'settings',
                      label: '設定を開く',
                      group: 'アプリケーション',
                      onPressed: dialog,
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ]),
        section(_Section.workspace, [
          group([
            card(
              28,
              'AppShell',
              // Framed so the miniature reads as an example, not the page.
              DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  border: Border.all(color: theme.controlBorder),
                  borderRadius: BorderRadius.circular(DetentRadius.control),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(DetentRadius.control),
                  child: const DetentAppShell(
                    navigation: Center(child: Text('Navigation')),
                    body: Center(child: Text('Workspace')),
                    statusBar: DetentStatusBar(children: [Text('準備完了')]),
                  ),
                ),
              ),
              height: 220,
            ),
            card(
              29,
              'Panel',
              const DetentPanel(
                header: Text('表示設定'),
                footer: Text('即時に反映されます'),
                child: Text('構造を見せる、控えめな筐体。'),
              ),
            ),
            card(
              30,
              'Toolbar',
              DetentToolbar(
                children: [
                  DetentButton(
                    label: '新規',
                    icon: FLucideIcons.plus,
                    onPressed: notify,
                  ),
                  DetentDropdownMenu(label: '表示', items: menu),
                ],
              ),
            ),
            card(
              31,
              'SplitView',
              const DetentSplitView(
                minLeading: 80,
                minTrailing: 80,
                initialExtent: 120,
                leading: Center(child: Text('一覧')),
                trailing: Center(child: Text('詳細')),
              ),
              height: 140,
            ),
            card(
              32,
              'StatusBar',
              const DetentStatusBar(
                children: [
                  Icon(FLucideIcons.circleCheck, size: 16),
                  SizedBox(width: 8),
                  Text('すべて保存済み'),
                  Spacer(),
                  Text('125%'),
                ],
              ),
            ),
            card(
              33,
              'ListRow',
              DetentListRow(
                label: '新しいデザインの指針',
                description: '部品ライブラリ',
                selected: true,
                leading: const Icon(FLucideIcons.file),
                onPressed: notify,
              ),
            ),
            card(
              34,
              'TreeView',
              DetentTreeView<String>(
                nodes: const [
                  DetentTreeNode(
                    id: 'root',
                    label: 'detent_ui',
                    children: [
                      DetentTreeNode(id: 'button', label: 'Button'),
                      DetentTreeNode(id: 'input', label: 'TextField'),
                    ],
                  ),
                ],
                expanded: expanded,
                selected: selected,
                onExpandedChanged: (v) => setState(() => expanded = v),
                onSelectionChanged: (v) => setState(() => selected = v),
              ),
              height: 160,
            ),
            card(
              35,
              'DataTable',
              DetentDataTable<String>(
                columns: [
                  DetentTableColumn(
                    label: '名前',
                    ascending: ascending,
                    onSort: () => setState(() => ascending = !ascending),
                  ),
                  const DetentTableColumn(label: '状態'),
                ],
                rows: ascending
                    ? ['Button', 'TextField', 'Switch']
                    : ['Switch', 'TextField', 'Button'],
                rowId: (r) => r,
                cells: (r) => [Text(r), const Text('実装済み')],
                selected: rows,
                onSelectionChanged: (v) => setState(() => rows = v),
              ),
              height: 240,
            ),
            card(
              48,
              'ScrollArea',
              DetentScrollArea(
                alwaysVisible: true,
                child: Column(
                  children: List.generate(
                    20,
                    (i) => DetentListRow(label: '項目 ${i + 1}'),
                  ),
                ),
              ),
              height: 180,
            ),
          ]),
        ]),
        section(_Section.feedback, [
          group([
            card(
              36,
              'Badge',
              const Wrap(
                spacing: 8,
                children: [
                  DetentBadge(label: '保存済み', tone: DetentTone.success),
                  DetentBadge(label: '要確認', tone: DetentTone.danger),
                ],
              ),
            ),
            card(
              37,
              'Tooltip',
              DetentTooltip(
                message: '保存',
                shortcut: 'Ctrl + S',
                child: DetentButton(label: 'ホバーして確認', onPressed: notify),
              ),
            ),
            card(
              38,
              'Progress',
              Column(
                children: [
                  DetentProgress(value: value / 100),
                  const SizedBox(height: 16),
                  const DetentProgress(variant: DetentProgressVariant.circular),
                ],
              ),
            ),
            card(
              39,
              'DotMatrix',
              Container(
                width: double.infinity,
                height: 96,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DetentTheme.of(context).display,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: DetentDotMatrix(text: '${value.round()}%'),
              ),
            ),
            card(40, 'Meter', DetentMeter(value: value)),
            card(
              41,
              'Toast',
              DetentToast(
                message: '変更を保存しました',
                actionLabel: '元に戻す',
                onAction: notify,
              ),
            ),
            card(
              42,
              'InlineAlert',
              DetentInlineAlert(
                title: '保存できませんでした',
                message: '保存先を確認して再試行してください。',
                action: DetentPlainButton(
                  onPressed: notify,
                  child: const Text('再試行'),
                ),
              ),
            ),
            card(
              43,
              'Dialog',
              DetentButton(label: '確認ダイアログ', onPressed: dialog),
            ),
            card(
              44,
              'Popover',
              DetentPopover(
                label: '表示設定',
                child: DetentSwitch(
                  value: toggle,
                  label: 'ドット表示',
                  onChanged: (v) => setState(() => toggle = v),
                ),
              ),
            ),
            card(
              45,
              'EmptyState',
              DetentEmptyState(
                title: 'まだ項目がありません',
                description: '最初の項目を作成します。',
                action: DetentButton(
                  label: '新規作成',
                  icon: FLucideIcons.plus,
                  onPressed: notify,
                ),
              ),
            ),
            card(
              46,
              'Skeleton',
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DetentSkeleton(width: 240),
                  SizedBox(height: 8),
                  DetentSkeleton(width: 160),
                  SizedBox(height: 8),
                  DetentSkeleton(width: 190),
                ],
              ),
            ),
            card(
              47,
              'TaskStatus',
              DetentTaskStatus(
                state: DetentTaskState.running,
                label: '書き出し',
                progress: value / 100,
                detail: '17 / 25 files',
                onCancel: notify,
              ),
            ),
          ]),
        ]),
        section(_Section.material, [
          const MaterialWorkspace(),
        ], showTitle: false),
        section(_Section.perforation, [
          const PerforationShowcase(),
        ], showTitle: false),
        section(_Section.motion, [
          DetentPanel(
            header: const Text('操作と処理表示'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ボタン・スイッチ・ノブなどの操作はFlutterのアニメーションです。Riveは進捗・メーター・読み込み・タスク状態に使用し、上部のRive切替で表示を比較できます。',
                ),
                const SizedBox(height: 16),
                DetentTaskStatus(
                  state: taskState,
                  label: '状態プレビュー',
                  progress: taskState == DetentTaskState.running
                      ? value / 100
                      : null,
                  detail: 'スライダーで実際の表示値を指定',
                  onCancel: () =>
                      setState(() => taskState = DetentTaskState.canceled),
                  onRetry: () =>
                      setState(() => taskState = DetentTaskState.running),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final state in [
                      DetentTaskState.idle,
                      DetentTaskState.running,
                      DetentTaskState.success,
                      DetentTaskState.error,
                    ])
                      DetentButton(
                        label: switch (state) {
                          DetentTaskState.idle => '待機',
                          DetentTaskState.running => '処理中',
                          DetentTaskState.success => '成功',
                          _ => '失敗',
                        },
                        selected: taskState == state,
                        onPressed: () => setState(() => taskState = state),
                      ),
                  ],
                ),
              ],
            ),
          ),
          group([
            for (final artboard in [
              'Progress',
              'CircularProgress',
              'Spinner',
              'Meter',
              'TaskStatus',
              'TaskGlyph',
              'Skeleton',
            ])
              SizedBox(
                width: 240,
                child: DetentPanel(
                  header: Text(artboard),
                  child: SizedBox(
                    height: 50,
                    child: DetentRiveArtwork(
                      artboard: artboard,
                      state: DetentSkinState(
                        progress: value / 100,
                        indeterminate: true,
                        taskState: 1,
                      ),
                      fallback: Text('$artboard / static'),
                    ),
                  ),
                ),
              ),
          ], title: 'Riveアートボード'),
        ]),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 760;
        final inset = narrow
            ? 16.0
            : constraints.maxWidth < 1280
            ? 24.0
            : 40.0;
        final viewport = DetentScrollArea(
          controller: _scroll,
          alwaysVisible: true,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Padding(
                padding: EdgeInsets.fromLTRB(inset, inset, inset, inset + 32),
                child: content,
              ),
            ),
          ),
        );
        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ColoredBox(
                color: theme.chrome,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: DetentDropdownMenu(
                    label: _active.title,
                    items: [
                      for (final section in _Section.values)
                        DetentMenuItem(
                          label: section.title,
                          icon: section.icon,
                          checked: section == _active,
                          onPressed: () => _openSection(section),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(child: viewport),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: constraints.maxWidth < 1280 ? 208 : 224,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.chrome,
                  border: Border(right: BorderSide(color: theme.border)),
                ),
                child: SingleChildScrollView(
                  primary: false,
                  padding: const EdgeInsets.fromLTRB(12, 24, 12, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final section in _Section.values) ...[
                        if (section == _Section.material) const DetentDivider(),
                        WorkshopNavigationItem(
                          label: section.title,
                          icon: section.icon,
                          selected: section == _active,
                          onPressed: () => _openSection(section),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Expanded(child: viewport),
          ],
        );
      },
    );
  }
}
