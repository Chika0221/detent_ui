import 'package:flutter/widgets.dart';
import 'package:detent_ui/detent_ui.dart';

void main() => runApp(const DetentGallery());

class DetentGallery extends StatefulWidget {
  const DetentGallery({super.key});
  @override
  State<DetentGallery> createState() => _DetentGalleryState();
}

class _DetentGalleryState extends State<DetentGallery> {
  NuiThemeMode mode = NuiThemeMode.light;
  bool high = false, reduced = false, riveEnabled = true;
  NuiDensity density = NuiDensity.standard;
  @override
  Widget build(BuildContext context) => NuiApp(
    title: 'Detent / Component workshop',
    themeMode: mode,
    density: density,
    motion: reduced ? NuiMotion.reduced : NuiMotion.full,
    highContrast: high,
    riveEnabled: riveEnabled,
    home: Builder(
      builder: (context) => NuiAppShell(
        toolbar: NuiToolbar(
          children: [
            const Text(
              'DETENT',
              style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 2),
            ),
            const SizedBox(width: 24),
            NuiToggleButton(
              label: 'Dark',
              value: mode == NuiThemeMode.dark,
              onChanged: (v) => setState(
                () => mode = v ? NuiThemeMode.dark : NuiThemeMode.light,
              ),
            ),
            NuiToggleButton(
              label: 'High contrast',
              value: high,
              onChanged: (v) => setState(() => high = v),
            ),
            NuiToggleButton(
              label: 'Reduced motion',
              value: reduced,
              onChanged: (v) => setState(() => reduced = v),
            ),
            NuiToggleButton(
              label: 'Rive',
              value: riveEnabled,
              onChanged: (v) => setState(() => riveEnabled = v),
            ),
            NuiDropdownMenu(
              label: density.name,
              items: [
                for (final d in NuiDensity.values)
                  NuiMenuItem(
                    label: d.name,
                    onPressed: () => setState(() => density = d),
                  ),
              ],
            ),
          ],
        ),
        body: const GalleryBody(),
        statusBar: const NuiStatusBar(
          children: [
            Text('48 components'),
            Spacer(),
            Text('Detent Design System / 0.7'),
          ],
        ),
      ),
    ),
  );
}

class GalleryBody extends StatefulWidget {
  const GalleryBody({super.key});
  @override
  State<GalleryBody> createState() => _GalleryBodyState();
}

class _GalleryBodyState extends State<GalleryBody> {
  bool toggle = true;
  bool? check = true;
  double value = 68;
  RangeValues range = const RangeValues(25, 80);
  int choice = 0;
  Set<String> expanded = {'root'}, selected = {'button'};
  Set<Object> rows = {};
  NuiShortcut? shortcut;
  String tab = 'design', search = '';
  NuiTaskState taskState = NuiTaskState.idle;
  bool ascending = true;
  final name = TextEditingController(text: 'Atelier / 新しい作業');
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  List<NuiMenuItem> get menu => [
    NuiMenuItem(
      label: '新規ファイル',
      icon: FLucideIcons.plus,
      shortcut: 'Ctrl + N',
      onPressed: notify,
    ),
    NuiMenuItem(
      label: '保存',
      icon: FLucideIcons.save,
      shortcut: 'Ctrl + S',
      onPressed: notify,
    ),
    NuiMenuItem(
      label: '表示',
      children: [
        NuiMenuItem(
          label: 'グリッド',
          checked: toggle,
          onPressed: () => setState(() => toggle = !toggle),
        ),
      ],
    ),
    NuiMenuItem(label: '削除', danger: true, onPressed: dialog),
  ];
  void notify() => NuiToast.show(
    context,
    message: '変更を保存しました',
    actionLabel: '元に戻す',
    onAction: () {},
  );
  void dialog() => NuiDialog.show<void>(
    context,
    builder: (ctx) => NuiDialog(
      title: '変更を保存しますか？',
      actions: [
        NuiButton(
          label: 'キャンセル',
          autofocus: true,
          onPressed: () => Navigator.pop(ctx),
        ),
        NuiButton(
          label: '保存',
          variant: NuiButtonVariant.primary,
          onPressed: () {
            Navigator.pop(ctx);
            notify();
          },
        ),
      ],
      child: const Text('作業内容に未保存の変更があります。'),
    ),
  );
  Widget card(int id, String label, Widget child, {double? height}) => SizedBox(
    width: 360,
    child: NuiPanel(
      header: Row(
        children: [
          Text(
            'C${id.toString().padLeft(2, '0')}',
            style: TextStyle(color: NuiTheme.of(context).muted, fontSize: 12),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      child: Align(
        alignment: Alignment.topLeft,
        child: height == null ? child : SizedBox(height: height, child: child),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final opts = [
      const NuiOption(0, '一覧', icon: FLucideIcons.list),
      const NuiOption(1, 'グリッド', icon: FLucideIcons.layoutGrid),
      const NuiOption(2, '比較', icon: FLucideIcons.columns2),
    ];
    return NuiScrollArea(
      alwaysVisible: true,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '触れる、道具になる。',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text('Desktop instruments / デザインファイルから実装した48のコンポーネント'),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: [
                card(
                  1,
                  'Button',
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      NuiButton(
                        label: '保存',
                        icon: FLucideIcons.save,
                        variant: NuiButtonVariant.primary,
                        onPressed: notify,
                      ),
                      NuiButton(
                        label: '削除',
                        variant: NuiButtonVariant.danger,
                        onPressed: dialog,
                      ),
                      const NuiButton(label: '処理中', loading: true),
                      const NuiButton(label: '無効'),
                    ],
                  ),
                ),
                card(
                  2,
                  'IconButton',
                  Row(
                    children: [
                      NuiIconButton(
                        icon: FLucideIcons.plus,
                        tooltip: '新規作成',
                        onPressed: notify,
                      ),
                      NuiIconButton(
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
                  NuiToggleButton(
                    label: '太字',
                    icon: FLucideIcons.bold,
                    value: toggle,
                    onChanged: (v) => setState(() => toggle = v),
                  ),
                ),
                card(
                  4,
                  'Keycap',
                  const Row(
                    children: [
                      NuiKeycap(label: 'Ctrl'),
                      SizedBox(width: 8),
                      NuiKeycap(label: 'Shift', units: 1.5),
                      SizedBox(width: 8),
                      NuiKeycap(label: 'K', pressed: true),
                      SizedBox(width: 8),
                      NuiKeycap(label: 'Enter', units: 2),
                    ],
                  ),
                ),
                card(
                  5,
                  'SegmentedControl',
                  NuiSegmentedControl(
                    options: opts,
                    value: choice,
                    onChanged: (v) => setState(() => choice = v),
                  ),
                ),
                card(
                  6,
                  'Checkbox',
                  NuiCheckbox(
                    value: check,
                    tristate: true,
                    label: 'すべて選択',
                    onChanged: (v) => setState(() => check = v),
                  ),
                ),
                card(
                  7,
                  'RadioGroup',
                  NuiRadioGroup(
                    options: opts,
                    value: choice,
                    onChanged: (v) => setState(() => choice = v),
                  ),
                ),
                card(
                  8,
                  'Switch',
                  NuiSwitch(
                    value: toggle,
                    label: '自動保存',
                    onChanged: (v) => setState(() => toggle = v),
                  ),
                ),
                card(
                  9,
                  'Slider',
                  Column(
                    children: [
                      NuiSlider(
                        value: value,
                        min: 0,
                        max: 100,
                        label: '出力品質',
                        onChanged: (v) => setState(() => value = v),
                      ),
                      Text('${value.round()}%'),
                    ],
                  ),
                ),
                card(
                  10,
                  'RangeSlider',
                  NuiRangeSlider(
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
                    child: NuiRotaryKnob(
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
                  NuiNumberStepper(
                    value: value,
                    min: 0,
                    max: 100,
                    fractionDigits: 1,
                    unit: '%',
                    onChanged: (v) => setState(() => value = v),
                  ),
                ),
                card(
                  13,
                  'TextField',
                  NuiTextField(controller: name, semanticLabel: 'プロジェクト名'),
                ),
                card(
                  14,
                  'TextArea',
                  const NuiTextArea(hintText: '日本語の文章を入力できます', maxLength: 500),
                ),
                card(
                  15,
                  'SearchField',
                  NuiSearchField(
                    shortcut: 'Ctrl + K',
                    onChanged: (v) => setState(() => search = v),
                  ),
                ),
                card(
                  16,
                  'Select',
                  NuiSelect(
                    options: opts,
                    value: choice,
                    onChanged: (v) => setState(() => choice = v!),
                  ),
                ),
                card(
                  17,
                  'ComboBox',
                  NuiComboBox(
                    options: opts,
                    onSelected: (v) => setState(() => choice = v),
                  ),
                ),
                card(
                  18,
                  'ShortcutRecorder',
                  NuiShortcutRecorder(
                    value: shortcut,
                    onChanged: (v) => setState(() => shortcut = v),
                  ),
                ),
                card(
                  19,
                  'FormField',
                  const NuiFormField(
                    label: '名前',
                    required: true,
                    error: '名前を入力してください',
                    child: NuiTextField(errorText: '必須項目です'),
                  ),
                ),
                card(
                  20,
                  'Tabs',
                  NuiTabs(
                    tabs: [
                      NuiTab(
                        'design',
                        'デザイン.pen',
                        dirty: true,
                        onClose: notify,
                      ),
                      const NuiTab('spec', '仕様.md'),
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
                    child: NuiNavigationRail(
                      options: opts,
                      value: choice,
                      onChanged: (v) => setState(() => choice = v),
                    ),
                  ),
                ),
                card(
                  22,
                  'SidebarItem',
                  NuiSidebarItem(
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
                  NuiBreadcrumb(
                    items: [
                      NuiBreadcrumbItem('ワークスペース', onPressed: notify),
                      NuiBreadcrumbItem('UI', onPressed: notify),
                      const NuiBreadcrumbItem('Controls'),
                    ],
                  ),
                ),
                card(
                  24,
                  'MenuBar',
                  SizedBox(
                    width: double.infinity,
                    child: NuiMenuBar(
                      menus: [
                        NuiMenuItem(label: 'ファイル', children: menu),
                        NuiMenuItem(label: '編集', children: menu),
                      ],
                    ),
                  ),
                ),
                card(
                  25,
                  'DropdownMenu',
                  NuiDropdownMenu(label: '操作', items: menu),
                ),
                card(
                  26,
                  'ContextMenu',
                  NuiContextMenu(
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
                  NuiButton(
                    label: 'コマンドを開く',
                    onPressed: () => NuiCommandPalette.show(
                      context,
                      commands: [
                        NuiCommand(
                          id: 'save',
                          label: '変更を保存',
                          shortcut: 'Ctrl + S',
                          onPressed: notify,
                        ),
                        NuiCommand(
                          id: 'settings',
                          label: '設定を開く',
                          group: 'アプリケーション',
                          onPressed: dialog,
                        ),
                      ],
                    ),
                  ),
                ),
                card(
                  28,
                  'AppShell',
                  const NuiAppShell(
                    navigation: Center(child: Text('Navigation')),
                    body: Center(child: Text('Workspace')),
                    statusBar: NuiStatusBar(children: [Text('準備完了')]),
                  ),
                  height: 220,
                ),
                card(
                  29,
                  'Panel',
                  const NuiPanel(
                    header: Text('表示設定'),
                    footer: Text('即時に反映されます'),
                    child: Text('構造を見せる、控えめな筐体。'),
                  ),
                ),
                card(
                  30,
                  'Toolbar',
                  NuiToolbar(
                    children: [
                      NuiButton(
                        label: '新規',
                        icon: FLucideIcons.plus,
                        onPressed: notify,
                      ),
                      NuiDropdownMenu(label: '表示', items: menu),
                    ],
                  ),
                ),
                card(
                  31,
                  'SplitView',
                  const NuiSplitView(
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
                  const NuiStatusBar(
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
                  NuiListRow(
                    label: '新しいデザインの指針',
                    description: '再利用可能な48部品',
                    selected: true,
                    leading: const Icon(FLucideIcons.file),
                    onPressed: notify,
                  ),
                ),
                card(
                  34,
                  'TreeView',
                  NuiTreeView<String>(
                    nodes: const [
                      NuiTreeNode(
                        id: 'root',
                        label: 'detent_ui',
                        children: [
                          NuiTreeNode(id: 'button', label: 'Button'),
                          NuiTreeNode(id: 'input', label: 'TextField'),
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
                  NuiDataTable<String>(
                    columns: [
                      NuiTableColumn(
                        label: '名前',
                        ascending: ascending,
                        onSort: () => setState(() => ascending = !ascending),
                      ),
                      const NuiTableColumn(label: '状態'),
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
                  36,
                  'Badge',
                  const Wrap(
                    spacing: 8,
                    children: [
                      NuiBadge(label: '保存済み', tone: NuiTone.success),
                      NuiBadge(label: '要確認', tone: NuiTone.danger),
                    ],
                  ),
                ),
                card(
                  37,
                  'Tooltip',
                  NuiTooltip(
                    message: '保存',
                    shortcut: 'Ctrl + S',
                    child: NuiButton(label: 'ホバーして確認', onPressed: notify),
                  ),
                ),
                card(
                  38,
                  'Progress',
                  Column(
                    children: [
                      NuiProgress(value: value / 100),
                      const SizedBox(height: 16),
                      const NuiProgress(variant: NuiProgressVariant.circular),
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
                      color: NuiTheme.of(context).display,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: NuiDotMatrix(text: '${value.round()}%'),
                  ),
                ),
                card(40, 'Meter', NuiMeter(value: value)),
                card(
                  41,
                  'Toast',
                  NuiToast(
                    message: '変更を保存しました',
                    actionLabel: '元に戻す',
                    onAction: notify,
                  ),
                ),
                card(
                  42,
                  'InlineAlert',
                  NuiInlineAlert(
                    title: '保存できませんでした',
                    message: '保存先を確認して再試行してください。',
                    action: NuiPlainButton(
                      onPressed: notify,
                      child: const Text('再試行'),
                    ),
                  ),
                ),
                card(
                  43,
                  'Dialog',
                  NuiButton(label: '確認ダイアログ', onPressed: dialog),
                ),
                card(
                  44,
                  'Popover',
                  NuiPopover(
                    label: '表示設定',
                    child: NuiSwitch(
                      value: toggle,
                      label: 'ドット表示',
                      onChanged: (v) => setState(() => toggle = v),
                    ),
                  ),
                ),
                card(
                  45,
                  'EmptyState',
                  NuiEmptyState(
                    title: 'まだ項目がありません',
                    description: '最初の項目を作成します。',
                    action: NuiButton(
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
                      NuiSkeleton(width: 240),
                      SizedBox(height: 8),
                      NuiSkeleton(width: 160),
                      SizedBox(height: 8),
                      NuiSkeleton(width: 190),
                    ],
                  ),
                ),
                card(
                  47,
                  'TaskStatus',
                  NuiTaskStatus(
                    state: NuiTaskState.running,
                    label: '書き出し',
                    progress: value / 100,
                    detail: '17 / 25 files',
                    onCancel: notify,
                  ),
                ),
                card(
                  48,
                  'ScrollArea',
                  NuiScrollArea(
                    alwaysVisible: true,
                    child: Column(
                      children: List.generate(
                        20,
                        (i) => NuiListRow(label: '項目 ${i + 1}'),
                      ),
                    ),
                  ),
                  height: 180,
                ),
              ],
            ),
            const SizedBox(height: 32),
            NuiPanel(
              header: const Text('Rive / 操作と状態の連動'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ボタンを長押し・TabでフォーカスしてSpace・スイッチの切り替え・ノブのドラッグを試せます。RiveをオフにするとFlutter描画と比較できます。',
                  ),
                  const SizedBox(height: 16),
                  NuiTaskStatus(
                    state: taskState,
                    label: '状態プレビュー',
                    progress: taskState == NuiTaskState.running
                        ? value / 100
                        : null,
                    detail: 'スライダーで実際の表示値を指定',
                    onCancel: () =>
                        setState(() => taskState = NuiTaskState.canceled),
                    onRetry: () =>
                        setState(() => taskState = NuiTaskState.running),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final state in [
                        NuiTaskState.idle,
                        NuiTaskState.running,
                        NuiTaskState.success,
                        NuiTaskState.error,
                      ])
                        NuiButton(
                          label: switch (state) {
                            NuiTaskState.idle => '待機',
                            NuiTaskState.running => '処理中',
                            NuiTaskState.success => '成功',
                            _ => '失敗',
                          },
                          variant: taskState == state
                              ? NuiButtonVariant.primary
                              : NuiButtonVariant.secondary,
                          onPressed: () => setState(() => taskState = state),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Rive / Runtime artboards',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final artboard in [
                  'Button',
                  'Switch',
                  'RotaryKnob',
                  'Progress',
                  'Meter',
                ])
                  SizedBox(
                    width: 240,
                    child: NuiPanel(
                      header: Text(artboard),
                      child: SizedBox(
                        height: 50,
                        child: NuiRiveArtwork(
                          artboard: artboard,
                          state: NuiSkinState(
                            selected: toggle,
                            value: value / 100,
                            progress: value / 100,
                          ),
                          fallback: Text('$artboard / static'),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
