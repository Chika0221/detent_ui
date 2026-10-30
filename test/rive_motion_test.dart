import 'dart:io';
import 'dart:async';

// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rive/rive.dart' as rive;
import 'package:detent_ui/detent_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('switch mechanism reaches selection and reverses from an intermediate position', () async {
    final file = await rive.File.decode(
      await File('assets/rive/detent.riv').readAsBytes(),
      riveFactory: rive.Factory.flutter,
    );
    final c = rive.RiveWidgetController(
      file!,
      artboardSelector: rive.ArtboardSelector.byName('Switch'),
    );
    final vm = c.dataBind(rive.DataBind.auto());
    final selected = vm.boolean('selected')!;
    for (var i = 0; i < 3; i++) {
      c.advance(1 / 60);
    }
    final thumb = c.artboard.component('Sliding thumb')!;
    expect(thumb.x, closeTo(13, .01));
    selected.value = true;
    c.advance(1 / 60);
    c.advance(.08);
    expect(thumb.x, greaterThan(13));
    expect(thumb.x, lessThan(35));
    selected.value = false;
    for (var i = 0; i < 20; i++) {
      c.advance(1 / 60);
    }
    expect(thumb.x, closeTo(13, .01));
    selected.value = true;
    for (var i = 0; i < 20; i++) {
      c.advance(1 / 60);
    }
    expect(thumb.x, closeTo(35, .01));
    thumb.dispose();
    selected.dispose();
    c.dispose();
    vm.dispose();
    file.dispose();
  });
  testWidgets(
    'ordinary controls use Rive after loading and retain keyboard activation',
    (t) async {
      final ready = Completer<void>();
      var calls = 0;
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await t.pumpWidget(
        NuiApp(
          motion: NuiMotion.full,
          home: Scaffold(
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
      expect(find.byType(rive.RiveWidget), findsAtLeastNWidgets(3));
      final switchGraphic = t
          .widgetList<rive.RiveWidget>(find.byType(rive.RiveWidget))
          .singleWhere((w) => w.controller.artboard.name == 'Switch');
      final thumb = switchGraphic.controller.artboard.component(
        'Sliding thumb',
      )!;
      expect(thumb.x, closeTo(35, .01));
      thumb.dispose();
      final nativeSwitch = t.widget<Switch>(find.byType(Switch));
      expect(
        nativeSwitch.thumbColor!.resolve({WidgetState.selected}),
        Colors.transparent,
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
  test('segmented selection follows its target over time', () async {
    final file = await rive.File.decode(
      await File('assets/rive/detent.riv').readAsBytes(),
      riveFactory: rive.Factory.flutter,
    );
    final c = rive.RiveWidgetController(
      file!,
      artboardSelector: rive.ArtboardSelector.byName('SegmentedControl'),
    );
    final vm = c.dataBind(rive.DataBind.auto());
    final target = vm.number('position')!;
    target.value = 48;
    for (var i = 0; i < 30; i++) {
      c.advance(1 / 60);
    }
    final selection = c.artboard.component('Travelling selection')!;
    expect(selection.x, closeTo(48, .1));
    target.value = 240;
    c.advance(0);
    c.advance(.04);
    expect(selection.x, greaterThan(48));
    expect(selection.x, lessThan(240));
    for (var i = 0; i < 30; i++) {
      c.advance(1 / 60);
    }
    expect(selection.x, closeTo(240, .1));
    selection.dispose();
    target.dispose();
    c.dispose();
    vm.dispose();
    file.dispose();
  });
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
        home: Scaffold(
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
        home: Scaffold(
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
        home: Scaffold(
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
}
