import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rive/rive.dart' as rive;
import 'package:detent_ui/detent_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Flutter switch moves and reverses without Rive', (t) async {
    var value = false;
    await t.pumpWidget(
      NuiApp(
        home: NuiBox(
          body: Center(
            child: StatefulBuilder(
              builder: (ctx, set) => NuiSwitch(
                value: value,
                onChanged: (v) => set(() => value = v),
              ),
            ),
          ),
        ),
      ),
    );
    double position() =>
        ((t
                        .widget<CustomPaint>(
                          find.descendant(
                            of: find.byType(NuiSwitch),
                            matching: find.byType(CustomPaint),
                          ),
                        )
                        .painter
                    as dynamic)
                .selectionValue
            as double);
    expect(position(), 0);
    await t.tap(find.byType(NuiSwitch));
    await t.pump();
    await t.pump(const Duration(milliseconds: 40));
    final mid = position();
    expect(mid, greaterThan(0));
    expect(mid, lessThan(1));
    await t.tap(find.byType(NuiSwitch));
    await t.pump();
    await t.pump(const Duration(milliseconds: 40));
    expect(position(), lessThan(mid));
    await t.pumpAndSettle();
    expect(position(), 0);
    expect(find.byType(NuiRiveArtwork), findsNothing);
  });
  testWidgets(
    'controls retain keyboard activation while only feedback uses Rive',
    (t) async {
      final ready = Completer<void>();
      var calls = 0;
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await t.pumpWidget(
        NuiApp(
          motion: NuiMotion.full,
          home: NuiBox(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NuiButton(
                    label: '保存',
                    focusNode: focus,
                    onPressed: () => calls++,
                  ),
                  NuiSwitch(value: true, onChanged: (_) {}),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: NuiRiveArtwork(
                      artboard: 'Spinner',
                      state: const NuiSkinState(
                        indeterminate: true,
                        progress: .24,
                      ),
                      onReady: () => ready.complete(),
                      fallback: const Text('待機'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await t.runAsync(() => ready.future.timeout(const Duration(seconds: 15)));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(rive.RiveWidget), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(NuiSwitch),
          matching: find.byType(NuiRiveArtwork),
        ),
        findsNothing,
      );
      expect(t.widget<NuiSwitch>(find.byType(NuiSwitch)).value, true);
      expect(
        find.byWidgetPredicate(
          (w) => [
            'Material',
            'MaterialApp',
            'Scaffold',
            'TextField',
            'Theme',
          ].contains(w.runtimeType.toString()),
        ),
        findsNothing,
      );
      await t.tap(find.text('保存'));
      await t.pump();
      expect(calls, 1);
      await t.sendKeyDownEvent(LogicalKeyboardKey.space);
      await t.pump(const Duration(milliseconds: 80));
      expect(calls, 1);
      await t.sendKeyUpEvent(LogicalKeyboardKey.space);
      await t.pump();
      expect(calls, 2);
      await t.sendKeyDownEvent(LogicalKeyboardKey.space);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.sendKeyUpEvent(LogicalKeyboardKey.space);
      await t.pump();
      expect(calls, 2);
      await t.pumpWidget(const SizedBox());
      await t.pump();
    },
  );
  testWidgets(
    'Flutter segment slide follows and reverses from its current position',
    (t) async {
      var value = 0;
      await t.pumpWidget(
        NuiApp(
          home: NuiBox(
            body: Center(
              child: SizedBox(
                width: 500,
                child: StatefulBuilder(
                  builder: (ctx, set) => NuiSegmentedControl(
                    options: const [NuiOption(0, '一覧'), NuiOption(1, '比較')],
                    value: value,
                    onChanged: (v) => set(() => value = v),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      double position() =>
          ((t
                          .widget<CustomPaint>(
                            find.descendant(
                              of: find.byType(NuiSegmentedControl<int>),
                              matching: find.byType(CustomPaint),
                            ),
                          )
                          .painter
                      as dynamic)
                  .selectionValue
              as double);
      await t.tap(find.text('比較'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 50));
      final mid = position();
      expect(mid, greaterThan(0));
      expect(mid, lessThan(1));
      await t.tap(find.text('一覧'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 40));
      expect(position(), lessThan(mid));
      await t.pumpAndSettle();
      expect(position(), 0);
      expect(find.byType(NuiRiveArtwork), findsNothing);
    },
  );
  testWidgets('motion policy and visibility pause the actual Rive controller', (
    t,
  ) async {
    final ready = Completer<void>();
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    final art = SizedBox(
      height: 60,
      width: 120,
      child: NuiRiveArtwork(
        artboard: 'Spinner',
        state: const NuiSkinState(indeterminate: true, progress: .24),
        onReady: () => ready.complete(),
        fallback: const Text('静的な表示'),
      ),
    );
    await t.pumpWidget(
      NuiApp(
        motion: NuiMotion.full,
        home: NuiBox(
          body: SingleChildScrollView(
            controller: scroll,
            child: Column(children: [art, const SizedBox(height: 1500)]),
          ),
        ),
      ),
    );
    await t.runAsync(() => ready.future.timeout(const Duration(seconds: 15)));
    await t.pump();
    final c = t
        .widget<rive.RiveWidget>(find.byType(rive.RiveWidget))
        .controller;
    expect(c.active, true);
    scroll.jumpTo(1000);
    await t.pump();
    await t.pump();
    expect(c.active, false);
    scroll.jumpTo(0);
    await t.pump();
    await t.pump();
    expect(c.active, true);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(c.active, false);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();
    await t.pump();
    expect(c.active, true);
    await t.pumpWidget(
      NuiApp(
        motion: NuiMotion.reduced,
        home: NuiBox(
          body: SingleChildScrollView(
            controller: scroll,
            child: Column(children: [art, const SizedBox(height: 1500)]),
          ),
        ),
      ),
    );
    await t.pump();
    expect(find.byType(rive.RiveWidget), findsNothing);
    expect(find.text('静的な表示'), findsOneWidget);
    expect(c.active, false);
    await t.pumpWidget(const SizedBox());
    await t.pump();
  });
  testWidgets(
    'native switch focus and state survive switching to reduced motion',
    (t) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      bool value = false;
      Widget host(bool reduced) => NuiApp(
        motion: reduced ? NuiMotion.reduced : NuiMotion.full,
        home: NuiBox(
          body: StatefulBuilder(
            builder: (ctx, set) => NuiSwitch(
              focusNode: focus,
              value: value,
              onChanged: (v) => set(() => value = v),
            ),
          ),
        ),
      );
      await t.pumpWidget(host(false));
      focus.requestFocus();
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.space);
      await t.pump();
      expect(value, true);
      await t.pumpWidget(host(true));
      await t.pump();
      expect(focus.hasFocus, true);
      await t.sendKeyEvent(LogicalKeyboardKey.space);
      await t.pump();
      expect(value, false);
    },
  );
  testWidgets(
    'feedback Rive preference never changes interactive control geometry',
    (t) async {
      Widget host(bool animated) => NuiApp(
        riveEnabled: animated,
        home: NuiBox(
          body: Center(
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NuiSlider(value: .68, onChanged: (_) {}),
                  NuiSegmentedControl(
                    options: const [NuiOption(0, '一覧'), NuiOption(1, '比較')],
                    value: 0,
                    onChanged: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await t.pumpWidget(host(true));
      expect(find.byType(NuiRiveArtwork), findsNothing);
      final slider = find.byType(NuiSlider);
      final skin = find
          .descendant(of: slider, matching: find.byType(CustomPaint))
          .first;
      expect(t.getSize(skin), const Size(500, 64));
      final occupied = t.getRect(slider);
      await t.pumpWidget(host(false));
      await t.pump();
      expect(t.getRect(slider), occupied);
      final paint = find
          .descendant(of: slider, matching: find.byType(CustomPaint))
          .first;
      expect(t.getSize(paint), const Size(500, 64));
    },
  );
  test(
    'processing Rive loops preserve values and settle when inactive',
    () async {
      final file = await rive.File.decode(
        await File('assets/rive/detent.riv').readAsBytes(),
        riveFactory: rive.Factory.flutter,
      );
      for (final name in ['TaskStatus', 'Meter', 'Progress']) {
        final c = rive.RiveWidgetController(
          file!,
          artboardSelector: rive.ArtboardSelector.byName(name),
        );
        Future<List<int>> pixels() async {
          final recorder = ui.PictureRecorder();
          c.artboard.draw(rive.Renderer.make(ui.Canvas(recorder)));
          final picture = recorder.endRecording();
          final image = await picture.toImage(240, 40);
          final bytes = await image.toByteData();
          final result = bytes!.buffer.asUint8List().toList();
          image.dispose();
          picture.dispose();
          return result;
        }

        final vm = c.dataBind(rive.DataBind.auto());
        vm.number('progress')!.value = .68;
        vm.boolean('indeterminate')!.value = true;
        vm.number('taskState')!.value = 1;
        c.advance(0);
        c.advance(.05);
        final first = await pixels();
        c.advance(.4);
        expect(await pixels(), isNot(equals(first)), reason: name);
        expect(vm.number('progress')!.value, closeTo(.68, .001));
        vm.boolean('indeterminate')!.value = false;
        vm.number('taskState')!.value = 0;
        c.advance(0);
        c.advance(1);
        final stopped = await pixels();
        c.advance(.4);
        expect(await pixels(), equals(stopped), reason: '$name stopped');
        c.dispose();
        vm.dispose();
      }
      file!.dispose();
    },
  );
  testWidgets('Rive animation does not repaint a static neighbour', (t) async {
    var paints = 0;
    final ready = Completer<void>();
    await t.pumpWidget(
      NuiApp(
        home: NuiBox(
          body: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: NuiRiveArtwork(
                    artboard: 'Spinner',
                    state: const NuiSkinState(indeterminate: true),
                    onReady: () => ready.complete(),
                  ),
                ),
                _PaintProbe(
                  onPaint: () => paints++,
                  child: const Text('Static neighbour'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await t.runAsync(() => ready.future.timeout(const Duration(seconds: 15)));
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    paints = 0;
    for (var i = 0; i < 12; i++) {
      await t.pump(const Duration(milliseconds: 16));
    }
    debugPrint(
      'DETENT_PERF staticNeighbourPaints=$paints for 12 animated frames',
    );
    expect(paints, 0);
  });
}

class _PaintProbe extends SingleChildRenderObjectWidget {
  const _PaintProbe({required this.onPaint, required super.child});
  final VoidCallback onPaint;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _PaintCounter(onPaint);
  @override
  void updateRenderObject(BuildContext context, _PaintCounter renderObject) {
    renderObject.onPaint = onPaint;
  }
}

class _PaintCounter extends RenderProxyBox {
  _PaintCounter(this.onPaint);
  VoidCallback onPaint;
  @override
  void paint(PaintingContext context, Offset offset) {
    onPaint();
    super.paint(context, offset);
  }
}
