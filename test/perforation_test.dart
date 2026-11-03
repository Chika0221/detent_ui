import 'dart:ui' as ui;

import 'package:detent_ui/detent_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(
  Widget child, {
  NuiThemeData theme = const NuiThemeData(
    riveEnabled: false,
    motion: NuiMotion.reduced,
  ),
  bool disableAnimations = false,
}) => NuiApp(
  riveEnabled: false,
  home: MediaQuery(
    data: MediaQueryData(
      size: const Size(800, 600),
      disableAnimations: disableAnimations,
    ),
    child: NuiTheme(
      data: theme,
      child: Center(child: child),
    ),
  ),
);

Future<List<int>> pixels(WidgetTester t, GlobalKey key) async {
  await t.pump();
  return (await t.runAsync(() async {
    final render =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await render.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final result = bytes!.buffer.asUint8List().toList();
    image.dispose();
    return result;
  }))!;
}

Future<int> activeCount(
  WidgetTester t,
  double value, {
  Axis axis = Axis.horizontal,
}) async {
  final key = GlobalKey();
  await t.pumpWidget(
    host(
      RepaintBoundary(
        key: key,
        child: SizedBox(
          width: 300,
          height: 180,
          child: NuiSpeakerMatrix.progress(
            value: value,
            label: 'Export',
            orientation: axis,
          ),
        ),
      ),
    ),
  );
  await t.pump();
  final paint = find.descendant(
    of: find.byType(NuiSpeakerMatrix),
    matching: find.byType(CustomPaint),
  );
  final origin = t.getTopLeft(paint) - t.getTopLeft(find.byKey(key));
  final data = await pixels(t, key);
  var active = 0;
  for (var r = 0; r < 2; r++) {
    for (var c = 0; c < 10; c++) {
      final x = (origin.dx + 3 + c * 14).floor();
      final y = (origin.dy + 3 + r * 14).floor();
      final offset = (y * 300 + x) * 4;
      if (data[offset] == 233 &&
          data[offset + 1] == 207 &&
          data[offset + 2] == 72) {
        active++;
      }
    }
  }
  return active;
}

void main() {
  test('square and hex grids have exact extents and half-pitch offset', () {
    const square = NuiPerforationGeometry(rows: 3, columns: 4);
    expect(square.size, const Size(40, 28));
    expect(square.center(1, 2), const Offset(26, 14));
    const hex = NuiPerforationGeometry(
      rows: 3,
      columns: 4,
      arrangement: NuiPerforationArrangement.hexagonal,
    );
    expect(hex.size.width, 46);
    expect(hex.center(1, 0).dx - hex.center(0, 0).dx, 6);
    expect(hex.rowPitch, closeTo(10.392304845, .000001));
    expect(hex.center(2, 0).dx, hex.center(0, 0).dx);
  });

  test('geometry rejects non-finite sizes and invalid counts', () {
    expect(
      () => NuiPerforationGeometry(rows: 0, columns: 1),
      throwsAssertionError,
    );
    expect(
      () => NuiPerforationGeometry(rows: 1, columns: 1, diameter: double.nan),
      throwsAssertionError,
    );
    expect(
      () => NuiPerforationGeometry(rows: 1, columns: 1, gap: double.infinity),
      throwsAssertionError,
    );
  });

  testWidgets('progress raster lights exactly 0, 5, 10, 15 and 20 holes', (
    t,
  ) async {
    for (final v in [0.0, .25, .5, .75, 1.0]) {
      expect(await activeCount(t, v), (v * 20).floor());
    }
    expect(await activeCount(t, .5, axis: Axis.vertical), 10);
  });

  testWidgets('one semantic node exposes values; decorative holes do not', (
    t,
  ) async {
    final semantics = t.ensureSemantics();
    await t.pumpWidget(
      host(const NuiSpeakerMatrix.progress(value: .75, label: 'Export')),
    );
    expect(find.bySemanticsLabel('Export'), findsOneWidget);
    expect(
      t.getSemantics(find.bySemanticsLabel('Export')),
      matchesSemantics(
        label: 'Export',
        value: '75%',
        hasEnabledState: true,
        isEnabled: true,
      ),
    );
    await t.pumpWidget(host(const NuiSpeakerMatrix.loading(label: 'Import')));
    expect(t.getSemantics(find.bySemanticsLabel('Import')).value, 'Processing');
    semantics.dispose();
  });

  testWidgets('all types, surface recipes and themes render at large text', (
    t,
  ) async {
    for (final brightness in Brightness.values) {
      for (final high in [false, true]) {
        final theme = NuiThemeData(
          brightness: brightness,
          highContrast: high,
          motion: NuiMotion.reduced,
        );
        final samples = <Widget>[
          for (final variant in NuiPerforationSurfaceVariant.values)
            NuiPerforationSurface(
              variant: variant,
              child: const Text('Content'),
            ),
          for (final status in NuiConnectionStatus.values)
            NuiSpeakerMatrix.status(status: status, label: 'Connection'),
          const NuiSpeakerMatrix.level(levels: [.2, .4, .8, 1], label: 'Input'),
          const NuiSpeakerMatrix.signal(strength: 4, label: 'Signal'),
          const NuiSpeakerMatrix.loading(label: 'Loading'),
          for (final state in NuiResonanceState.values)
            NuiResonanceGrid(state: state, level: .6),
        ];
        for (final sample in samples) {
          await t.pumpWidget(
            host(
              MediaQuery(
                data: const MediaQueryData(
                  size: Size(800, 600),
                  textScaler: TextScaler.linear(2),
                ),
                child: SizedBox(width: 280, child: sample),
              ),
              theme: theme,
            ),
          );
          await t.pump();
          expect(
            t.takeException(),
            isNull,
            reason: '$brightness/$high/${sample.runtimeType}',
          );
        }
      }
    }
  });

  testWidgets(
    'pattern adapts to tiny and unbounded constraints without scaling holes',
    (t) async {
      final centers = <Offset>[];
      for (final size in [const Size(1, 1), const Size(180, 100)]) {
        await t.pumpWidget(
          host(
            SizedBox.fromSize(
              size: size,
              child: NuiPerforationPattern(
                coverage: NuiPerforationCoverage.custom,
                arrangement: NuiPerforationArrangement.hexagonal,
                mask: (r, c, center) {
                  centers.add(center);
                  return true;
                },
              ),
            ),
          ),
        );
        await t.pump();
        expect(t.takeException(), isNull);
      }
      expect(centers.length, greaterThan(30));
      await t.pumpWidget(host(const NuiPerforationPattern()));
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'pointer response changes pixels; disabled grids ignore the pointer',
    (t) async {
      final key = GlobalKey();
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      for (final state in [
        NuiResonanceState.idle,
        NuiResonanceState.disabled,
      ]) {
        await t.pumpWidget(
          host(
            RepaintBoundary(
              key: key,
              child: NuiResonanceGrid(
                state: state,
                interaction: NuiResonanceInteraction.pointer,
              ),
            ),
          ),
        );
        final before = await pixels(t, key);
        await mouse.moveTo(t.getCenter(find.byType(NuiResonanceGrid)));
        await t.pump();
        final after = await pixels(t, key);
        if (state == NuiResonanceState.disabled) {
          expect(after, before);
        } else {
          expect(after, isNot(before));
        }
        await mouse.moveTo(Offset.zero);
        await t.pump();
      }
    },
  );

  testWidgets('audio levels reflect external values without capturing input', (
    t,
  ) async {
    final key = GlobalKey();
    Widget audio(double level) => host(
      RepaintBoundary(
        key: key,
        child: NuiResonanceGrid(
          state: NuiResonanceState.listening,
          interaction: NuiResonanceInteraction.audio,
          level: level,
        ),
      ),
    );
    await t.pumpWidget(audio(.1));
    final low = await pixels(t, key);
    await t.pumpWidget(audio(.9));
    final high = await pixels(t, key);
    expect(high, isNot(low));
    expect(t.binding.transientCallbackCount, 0);
  });

  testWidgets('notification is finite and can be retriggered', (t) async {
    Widget pulse(int id) => host(
      NuiResonanceGrid(state: NuiResonanceState.pulse, pulseId: id),
      theme: const NuiThemeData(motion: NuiMotion.full),
    );
    await t.pumpWidget(pulse(0));
    await t.pump(const Duration(milliseconds: 90));
    expect(t.binding.transientCallbackCount, greaterThan(0));
    await t.pump(const Duration(milliseconds: 400));
    expect(t.binding.transientCallbackCount, 0);
    await t.pumpWidget(pulse(1));
    await t.pump(const Duration(milliseconds: 20));
    expect(t.binding.transientCallbackCount, greaterThan(0));
    await t.pumpWidget(const SizedBox());
    await t.pump();
    expect(t.binding.transientCallbackCount, 0);
  });

  testWidgets('loading respects system/reduced motion and TickerMode', (
    t,
  ) async {
    for (final motion in NuiMotion.values) {
      await t.pumpWidget(
        host(
          const NuiSpeakerMatrix.loading(label: 'Processing'),
          disableAnimations: true,
          theme: NuiThemeData(motion: motion),
        ),
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 40));
      expect(
        t.binding.transientCallbackCount,
        motion == NuiMotion.full ? greaterThan(0) : 0,
      );
    }
    await t.pumpWidget(
      host(
        const TickerMode(
          enabled: false,
          child: NuiSpeakerMatrix.loading(label: 'Processing'),
        ),
        theme: const NuiThemeData(motion: NuiMotion.full),
      ),
    );
    await t.pump();
    expect(t.binding.transientCallbackCount, 0);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('offscreen and background loading stop and resume', (t) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await t.pumpWidget(
      host(
        SizedBox(
          height: 300,
          child: SingleChildScrollView(
            controller: scroll,
            child: const Column(
              children: [
                SizedBox(height: 800),
                NuiSpeakerMatrix.loading(label: 'Processing'),
                SizedBox(height: 400),
              ],
            ),
          ),
        ),
        theme: const NuiThemeData(motion: NuiMotion.full),
      ),
    );
    await t.pump();
    expect(t.binding.transientCallbackCount, 0);
    scroll.jumpTo(700);
    await t.pump();
    await t.pump();
    expect(t.binding.transientCallbackCount, greaterThan(0));
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await t.pump();
    expect(t.binding.transientCallbackCount, 0);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();
    expect(t.binding.transientCallbackCount, greaterThan(0));
    scroll.jumpTo(0);
    await t.pump();
    await t.pump();
    expect(t.binding.transientCallbackCount, 0);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets(
    'nested scroll view visibility observes outer and inner positions',
    (t) async {
      final outer = ScrollController(), inner = ScrollController();
      addTearDown(outer.dispose);
      addTearDown(inner.dispose);
      await t.pumpWidget(
        host(
          SizedBox(
            height: 300,
            child: SingleChildScrollView(
              controller: outer,
              child: Column(
                children: [
                  const SizedBox(height: 600),
                  SizedBox(
                    height: 180,
                    child: SingleChildScrollView(
                      controller: inner,
                      child: const Column(
                        children: [
                          NuiSpeakerMatrix.loading(label: 'Nested processing'),
                          SizedBox(height: 500),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 600),
                ],
              ),
            ),
          ),
          theme: const NuiThemeData(motion: NuiMotion.full),
        ),
      );
      await t.pump();
      expect(t.binding.transientCallbackCount, 0);
      outer.jumpTo(550);
      await t.pump();
      await t.pump();
      expect(t.binding.transientCallbackCount, greaterThan(0));
      inner.jumpTo(200);
      await t.pump();
      await t.pump();
      expect(t.binding.transientCallbackCount, 0);
      inner.jumpTo(0);
      await t.pump();
      await t.pump();
      expect(t.binding.transientCallbackCount, greaterThan(0));
      outer.jumpTo(0);
      await t.pump();
      await t.pump();
      expect(t.binding.transientCallbackCount, 0);
      await t.pumpWidget(const SizedBox());
    },
  );

  testWidgets('content safety mask excludes holes and its 16px clearance', (
    t,
  ) async {
    final centers = <Offset>[];
    const content = Rect.fromLTWH(32, 32, 50, 30);
    await t.pumpWidget(
      host(
        SizedBox(
          width: 160,
          height: 100,
          child: NuiPerforationPattern(
            coverage: NuiPerforationCoverage.custom,
            contentBounds: content,
            mask: (r, c, center) {
              centers.add(center);
              return true;
            },
          ),
        ),
      ),
    );
    await t.pump();
    expect(centers, isNotEmpty);
    expect(
      centers.every((point) => !content.inflate(18).contains(point)),
      true,
    );
  });
}
