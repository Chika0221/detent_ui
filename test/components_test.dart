import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:detent_ui/detent_ui.dart';

Future<void> host(
  WidgetTester t,
  Widget child, {
  NuiThemeData theme = const NuiThemeData(),
}) => t.pumpWidget(
  NuiApp(
    home: NuiTheme(
      data: theme,
      child: NuiBox(
        body: Center(child: SizedBox(width: 500, child: child)),
      ),
    ),
  ),
);
void main() {
  testWidgets('button occupies 50px and cancels pointer activation', (t) async {
    var calls = 0;
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await host(
      t,
      NuiButton(label: '保存', focusNode: focus, onPressed: () => calls++),
    );
    final initial = t.getSize(find.byType(NuiButton));
    expect(initial.height, 50);
    final g = await t.startGesture(t.getCenter(find.byType(NuiButton)));
    await t.pump();
    expect(t.getSize(find.byType(NuiButton)), initial);
    await g.cancel();
    await t.pump();
    expect(calls, 0);
    await t.tap(find.byType(NuiButton));
    await t.pump();
    expect(calls, 1);
    focus.requestFocus();
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(calls, 2);
    expect(t.getSize(find.byType(NuiButton)), initial);
  });
  testWidgets('disabled and loading buttons never invoke host', (t) async {
    var calls = 0;
    await host(
      t,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const NuiButton(label: '無効'),
          NuiButton(label: '保存', loading: true, onPressed: () => calls++),
        ],
      ),
    );
    await t.tap(find.text('保存'), warnIfMissed: false);
    await t.pump();
    expect(calls, 0);
    expect(t.getSize(find.byType(NuiButton).first).height, 50);
  });
  testWidgets('switch tracks external controlled values', (t) async {
    bool? result;
    await host(t, NuiSwitch(value: false, onChanged: (v) => result = v));
    await t.tap(find.byType(NuiSwitch));
    await t.pump();
    expect(result, true);
    expect(t.widget<NuiSwitch>(find.byType(NuiSwitch)).value, false);
    await host(t, NuiSwitch(value: true, onChanged: (v) => result = v));
    await t.pump();
    expect(t.widget<NuiSwitch>(find.byType(NuiSwitch)).value, true);
  });
  testWidgets('knob keyboard adjustments clamp to its range', (t) async {
    double value = 99;
    await host(
      t,
      StatefulBuilder(
        builder: (context, set) => NuiRotaryKnob(
          value: value,
          min: 0,
          max: 100,
          onChanged: (v) => set(() => value = v),
        ),
      ),
    );
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await t.pump();
    expect(value, 100);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await t.pump();
    expect(value, 100);
    await t.sendKeyEvent(LogicalKeyboardKey.home);
    await t.pump();
    expect(value, 0);
    await t.sendKeyEvent(LogicalKeyboardKey.pageUp);
    await t.pump();
    expect(value, 10);
  });
  testWidgets(
    'number entry preserves partial negatives and rejects out of range',
    (t) async {
      double? changed;
      await host(
        t,
        NuiNumberStepper(
          value: 10,
          min: -20,
          max: 20,
          onChanged: (v) => changed = v,
        ),
      );
      await t.enterText(find.byType(EditableText), '-');
      await t.pump();
      expect(find.text('-'), findsOneWidget);
      expect(changed, null);
      await t.enterText(find.byType(EditableText), '200');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pump();
      expect(changed, null);
      expect(find.text('-20.0〜20.0 の値を入力してください'), findsOneWidget);
      await t.enterText(find.byType(EditableText), '-12');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pump();
      expect(changed, -12);
    },
  );
  testWidgets(
    'range endpoints have independent keyboard focus and cannot cross',
    (t) async {
      var range = const RangeValues(25, 75);
      await host(
        t,
        StatefulBuilder(
          builder: (ctx, set) => NuiRangeSlider(
            values: range,
            min: 0,
            max: 100,
            onChanged: (v) => set(() => range = v),
          ),
        ),
      );
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.end);
      await t.pump();
      expect(range.start, 75);
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.home);
      await t.pump();
      expect(range.end, 75);
      await t.sendKeyEvent(LogicalKeyboardKey.pageUp);
      await t.pump();
      expect(range.end, 85);
    },
  );
  testWidgets('modal Escape and outside dismissal are independent', (t) async {
    await host(
      t,
      Builder(
        builder: (ctx) => NuiButton(
          label: '開く',
          onPressed: () => NuiDialog.show<void>(
            ctx,
            builder: (dialog) => NuiDialog(
              title: '確認',
              actions: [
                NuiButton(
                  label: '戻る',
                  autofocus: true,
                  onPressed: () => Navigator.pop(dialog),
                ),
              ],
              child: const Text('内容'),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('開く'));
    await t.pumpAndSettle();
    await t.tapAt(const Offset(2, 2));
    await t.pumpAndSettle();
    expect(find.text('確認'), findsOneWidget);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await t.pumpAndSettle();
    expect(find.text('確認'), findsNothing);
  });
  testWidgets('tree separates keyboard focus from selection', (t) async {
    Set<String> expanded = {}, selection = {};
    await host(
      t,
      StatefulBuilder(
        builder: (context, set) => SizedBox(
          height: 200,
          child: NuiTreeView<String>(
            nodes: const [
              NuiTreeNode(
                id: 'root',
                label: 'Root',
                children: [NuiTreeNode(id: 'child', label: 'Child')],
              ),
            ],
            expanded: expanded,
            selected: selection,
            onExpandedChanged: (v) => set(() => expanded = v),
            onSelectionChanged: (v) => set(() => selection = v),
          ),
        ),
      ),
    );
    await t.tap(find.text('Root'));
    await t.pump();
    expect(selection, {'root'});
    await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await t.pump();
    expect(expanded, {'root'});
    await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await t.pump();
    expect(selection, {'root'});
    await t.sendKeyEvent(LogicalKeyboardKey.space);
    await t.pump();
    expect(selection, {'child'});
  });
  testWidgets('command palette searches and invokes exactly one command', (
    t,
  ) async {
    var calls = 0;
    await host(
      t,
      SizedBox(
        height: 300,
        child: NuiCommandPalette(
          commands: [
            NuiCommand(id: 'save', label: 'Save', onPressed: () => calls++),
            NuiCommand(id: 'open', label: 'Open', onPressed: () => calls += 10),
          ],
        ),
      ),
    );
    await t.pump();
    await t.enterText(find.byType(EditableText), 'Open');
    await t.pump();
    expect(find.text('Save'), findsNothing);
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pump();
    expect(calls, 10);
  });
  testWidgets('toast pauses timeout while hovered', (t) async {
    var dismiss = 0;
    await host(
      t,
      NuiToast(
        message: '保存済み',
        duration: const Duration(seconds: 2),
        onDismiss: () => dismiss++,
      ),
    );
    final pointer = await t.createGesture(kind: PointerDeviceKind.mouse);
    await pointer.addPointer(location: Offset.zero);
    await t.pump();
    await pointer.moveTo(t.getCenter(find.byType(NuiToast)));
    await t.pump(const Duration(seconds: 3));
    expect(dismiss, 0);
    await pointer.moveTo(Offset.zero);
    await t.pump(const Duration(seconds: 3));
    expect(dismiss, 1);
    await pointer.removePointer();
  });
  testWidgets('reduced motion exposes indeterminate progress without loop', (
    t,
  ) async {
    await host(
      t,
      const NuiProgress(),
      theme: const NuiThemeData(motion: NuiMotion.reduced),
    );
    expect(find.byType(NuiRiveArtwork), findsNothing);
    expect(find.text('処理中'), findsOneWidget);
  });
  testWidgets('large table builds only visible rows and retains stable IDs', (
    t,
  ) async {
    final data = List.generate(10000, (i) => i);
    var built = 0;
    await host(
      t,
      SizedBox(
        height: 300,
        child: NuiDataTable<int>(
          columns: const [NuiTableColumn(label: 'ID')],
          rows: data,
          rowId: (r) => r,
          cells: (r) {
            built++;
            return [Text('$r')];
          },
        ),
      ),
    );
    expect(built, lessThan(50));
    expect(find.text('9999'), findsNothing);
  });
  testWidgets('menu closes with Escape and returns focus', (t) async {
    await host(
      t,
      NuiDropdownMenu(
        label: '操作',
        items: [NuiMenuItem(label: '保存', onPressed: () {})],
      ),
    );
    await t.tap(find.text('操作'));
    await t.pumpAndSettle();
    expect(find.text('保存'), findsOneWidget);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await t.pumpAndSettle();
    expect(find.text('保存'), findsNothing);
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pumpAndSettle();
    expect(find.text('保存'), findsOneWidget);
  });
  testWidgets('Rive asset failure preserves dimensions and fallback', (
    t,
  ) async {
    Object? error;
    await host(
      t,
      SizedBox(
        width: 144,
        height: 50,
        child: NuiRiveArtwork(
          artboard: 'Button',
          asset: 'missing.riv',
          fallback: const Text('静的な代替'),
          onError: (e) => error = e,
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('静的な代替'), findsOneWidget);
    expect(error, isNotNull);
    expect(t.getSize(find.byType(NuiRiveArtwork)).height, 50);
  });
  test('all four palettes resolve roles from canonical token values', () {
    for (final dark in [false, true]) {
      for (final high in [false, true]) {
        final theme = NuiThemeData(
          brightness: dark ? Brightness.dark : Brightness.light,
          highContrast: high,
        );
        expect(
          theme.ink.computeLuminance() > theme.canvas.computeLuminance(),
          dark,
        );
        expect(theme.controlHeight, 40);
        expect(theme.accentInk, const Color(0xFF202426));
      }
    }
  });
}
