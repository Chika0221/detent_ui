import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:detent_ui/detent_ui.dart';

Widget host(Widget child) => WidgetsApp(
  color: const Color(0xFFE9CF48),
  pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
    settings: settings,
    pageBuilder: (ctx, _, _) => builder(ctx),
  ),
  home: NuiTheme(
    data: const NuiThemeData(riveEnabled: false),
    child: NuiBox(
      body: Center(child: SizedBox(width: 500, child: child)),
    ),
  ),
);
void main() {
  test('library imports no UI kit from the framework', () {
    for (final f
        in Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
      expect(
        f.readAsStringSync(),
        isNot(contains('package:flutter/material')),
        reason: f.path,
      );
      expect(
        f.readAsStringSync(),
        isNot(contains('package:material_ui')),
        reason: f.path,
      );
      expect(
        f.readAsStringSync(),
        isNot(contains('package:flutter/cupertino')),
        reason: f.path,
      );
    }
  });
  testWidgets(
    'keycap units include the inter-key spacing and keep height stable',
    (t) async {
      await t.pumpWidget(
        host(
          const Row(
            children: [
              NuiKeycap(label: 'K'),
              SizedBox(width: 8),
              NuiKeycap(label: 'Shift', units: 1.5),
              SizedBox(width: 8),
              NuiKeycap(label: 'Enter', units: 2),
            ],
          ),
        ),
      );
      final caps = find.byType(NuiKeycap);
      expect(t.getSize(caps.at(0)), const Size(40, 42));
      expect(t.getSize(caps.at(1)), const Size(64, 42));
      expect(t.getSize(caps.at(2)), const Size(88, 42));
      final before = t.getRect(caps.at(2));
      await t.pumpWidget(
        host(
          const Row(
            children: [
              NuiKeycap(label: 'K'),
              SizedBox(width: 8),
              NuiKeycap(label: 'Shift', units: 1.5, pressed: true),
              SizedBox(width: 8),
              NuiKeycap(label: 'Enter', units: 2),
            ],
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(t.getRect(caps.at(2)), before);
    },
  );
  testWidgets(
    'plain WidgetsApp supports selection, editing, menus and modal focus',
    (t) async {
      var selected = 0;
      String? changed;
      await t.pumpWidget(
        host(
          StatefulBuilder(
            builder: (ctx, set) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NuiSelect(
                  options: const [NuiOption(0, 'Alpha'), NuiOption(1, 'Beta')],
                  value: selected,
                  onChanged: (v) => set(() => selected = v!),
                ),
                NuiComboBox(
                  options: const [NuiOption(0, 'Alpha'), NuiOption(1, 'Beta')],
                  onChanged: (v) => changed = v,
                ),
                NuiButton(
                  label: '確認',
                  onPressed: () => NuiDialog.show<void>(
                    ctx,
                    builder: (dialog) => NuiDialog(
                      title: '保存しますか',
                      actions: [
                        NuiButton(
                          label: '戻る',
                          autofocus: true,
                          onPressed: () => Navigator.pop(dialog),
                        ),
                      ],
                      child: const Text('入力を保ちます'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await t.tap(find.byType(EditableText).first);
      await t.pumpAndSettle();
      await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pumpAndSettle();
      expect(selected, 1);
      await t.enterText(find.byType(EditableText).last, '日本語');
      await t.pump();
      expect(changed, '日本語');
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      await t.tap(find.text('確認'));
      await t.pumpAndSettle();
      expect(find.text('保存しますか'), findsOneWidget);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(find.text('保存しますか'), findsNothing);
      expect(
        find.byWidgetPredicate(
          (w) => [
            'Material',
            'MaterialApp',
            'Scaffold',
            'InkWell',
            'TextField',
            'MenuAnchor',
          ].contains(w.runtimeType.toString()),
        ),
        findsNothing,
      );
    },
  );
  testWidgets(
    'plain WidgetsApp supports pointer text selection and edit toolbar',
    (t) async {
      final controller = TextEditingController(text: 'alpha beta');
      addTearDown(controller.dispose);
      await t.pumpWidget(host(NuiTextField(controller: controller)));
      final field = find.byType(EditableText);
      await t.tapAt(t.getTopLeft(field) + const Offset(16, 10));
      await t.pump(const Duration(milliseconds: 40));
      await t.tapAt(t.getTopLeft(field) + const Offset(16, 10));
      await t.pumpAndSettle();
      expect(controller.selection.isCollapsed, false);
      final state = t.state<EditableTextState>(field);
      expect(state.showToolbar(), true);
      await t.pumpAndSettle();
      expect(find.text('コピー'), findsOneWidget);
      expect(t.takeException(), isNull);
      state.hideToolbar();
      await t.enterText(field, '日本語入力');
      await t.pump();
      expect(controller.text, '日本語入力');
    },
  );
  testWidgets(
    'menu actions and nested menus close their overlay in WidgetsApp',
    (t) async {
      var calls = 0;
      await t.pumpWidget(
        host(
          NuiDropdownMenu(
            label: 'Menu',
            items: [
              NuiMenuItem(
                label: 'Submenu',
                children: [
                  NuiMenuItem(label: 'Run action', onPressed: () => calls++),
                ],
              ),
            ],
          ),
        ),
      );
      await t.tap(find.text('Menu'));
      await t.pumpAndSettle();
      await t.tap(find.text('Submenu'));
      await t.pumpAndSettle();
      await t.tap(find.text('Run action'));
      await t.pumpAndSettle();
      expect(calls, 1);
      expect(find.text('Submenu'), findsNothing);
      expect(find.text('Run action'), findsNothing);
    },
  );
  testWidgets('fixed slider ranges retain finite geometry in WidgetsApp', (
    t,
  ) async {
    await t.pumpWidget(
      host(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NuiSlider(value: 3, min: 3, max: 3),
            NuiRangeSlider(values: NuiRangeValues(3, 3), min: 3, max: 3),
          ],
        ),
      ),
    );
    await t.pump();
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'fallback mechanisms fill the same occupied bounds as the input',
    (t) async {
      await t.pumpWidget(
        host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NuiSlider(value: .68, onChanged: (_) {}),
              NuiRangeSlider(
                values: const NuiRangeValues(.25, .8),
                onChanged: (_) {},
              ),
              NuiSegmentedControl(
                options: const [NuiOption(0, '一覧'), NuiOption(1, '比較')],
                value: 0,
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      );
      for (final component in [
        find.byType(NuiSlider),
        find.byType(NuiRangeSlider),
        find.byType(NuiSegmentedControl<int>),
      ]) {
        final painter = find
            .descendant(of: component, matching: find.byType(CustomPaint))
            .first;
        expect(t.getSize(painter).width, greaterThan(400));
        expect(t.getSize(painter).height, greaterThanOrEqualTo(50));
      }
    },
  );
}
