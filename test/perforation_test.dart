import 'dart:ui' as ui;

import 'package:detent_ui/detent_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child, {DetentThemeMode mode = DetentThemeMode.light}) =>
    DetentApp(
      riveEnabled: false,
      themeMode: mode,
      motion: DetentMotion.reduced,
      home: DetentBox(body: Center(child: child)),
    );

/// Colour of the pixel at [at] (local to the boundary).
Future<Color> pixel(WidgetTester t, GlobalKey key, Offset at) async {
  await t.pump();
  return (await t.runAsync(() async {
    final render =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await render.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final i = (at.dy.floor() * image.width + at.dx.floor()) * 4;
    final d = bytes!.buffer.asUint8List();
    image.dispose();
    return Color.fromARGB(d[i + 3], d[i], d[i + 1], d[i + 2]);
  }))!;
}

void main() {
  test('square and hex grids have exact extents and half-pitch offset', () {
    const square = DetentPerforationGeometry(rows: 3, columns: 4);
    expect(square.size, const Size(40, 28));
    expect(square.center(1, 2), const Offset(26, 14));
    const hex = DetentPerforationGeometry(
      rows: 3,
      columns: 4,
      arrangement: DetentPerforationArrangement.hexagonal,
    );
    expect(hex.size.width, 46);
    expect(hex.center(1, 0).dx - hex.center(0, 0).dx, 6);
    expect(hex.rowPitch, closeTo(10.392304845, .000001));
    expect(hex.center(2, 0).dx, hex.center(0, 0).dx);
  });

  test('geometry rejects non-finite sizes and invalid counts', () {
    expect(
      () => DetentPerforationGeometry(rows: 0, columns: 1),
      throwsAssertionError,
    );
    expect(
      () =>
          DetentPerforationGeometry(rows: 1, columns: 1, diameter: double.nan),
      throwsAssertionError,
    );
    expect(
      () =>
          DetentPerforationGeometry(rows: 1, columns: 1, gap: double.infinity),
      throwsAssertionError,
    );
  });

  testWidgets('grip size follows the tokens and fills with ink when active', (
    t,
  ) async {
    expect(DetentGrip.thickness, 8);
    final colors = <bool, Color>{};
    for (final active in [false, true]) {
      final key = GlobalKey();
      await t.pumpWidget(
        host(
          RepaintBoundary(
            key: key,
            child: DetentGrip(active: active),
          ),
        ),
      );
      expect(t.getSize(find.byType(DetentGrip)), const Size(8, 26));
      colors[active] = await pixel(t, key, const Offset(1, 1));
    }
    // Light theme: the ink fill is darker than the resting hole colour.
    expect(
      colors[true]!.computeLuminance(),
      lessThan(colors[false]!.computeLuminance()),
    );
    await t.pumpWidget(host(const DetentGrip(axis: Axis.horizontal)));
    expect(t.getSize(find.byType(DetentGrip)), const Size(26, 8));
  });

  testWidgets('chassis mark has a fixed size and no semantics', (t) async {
    final semantics = t.ensureSemantics();
    await t.pumpWidget(host(const DetentChassisMark()));
    expect(t.getSize(find.byType(DetentChassisMark)), const Size(52, 14));
    expect(
      find.descendant(
        of: find.byType(DetentChassisMark),
        matching: find.byType(ExcludeSemantics),
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('status bar shows exactly one mark at its right end', (t) async {
    await t.pumpWidget(
      host(
        const SizedBox(
          width: 600,
          child: DetentStatusBar(
            children: [Text('Ready'), Spacer(), Text('0.9')],
          ),
        ),
      ),
    );
    expect(find.byType(DetentChassisMark), findsOneWidget);
    final bar = t.getRect(find.byType(DetentStatusBar));
    final mark = t.getRect(find.byType(DetentChassisMark));
    expect(bar.right - mark.right, 8);
    expect(
      t.getRect(find.text('0.9')).right,
      lessThanOrEqualTo(mark.left - 16),
    );

    await t.pumpWidget(
      host(
        const SizedBox(
          width: 600,
          child: DetentStatusBar(showMark: false, children: [Text('Ready')]),
        ),
      ),
    );
    expect(find.byType(DetentChassisMark), findsNothing);
  });

  testWidgets('split view handle is a grip that lights on hover and drags', (
    t,
  ) async {
    double? extent;
    await t.pumpWidget(
      host(
        SizedBox(
          width: 800,
          height: 300,
          child: DetentSplitView(
            leading: const SizedBox.expand(),
            trailing: const SizedBox.expand(),
            onExtentChanged: (v) => extent = v,
          ),
        ),
      ),
    );
    final grip = find.byType(DetentGrip);
    expect(grip, findsOneWidget);
    expect(t.widget<DetentGrip>(grip).active, isFalse);

    final mouse = await t.createGesture(kind: ui.PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(t.getCenter(grip));
    await t.pump();
    expect(t.widget<DetentGrip>(grip).active, isTrue);

    await t.drag(grip, const Offset(40, 0));
    await t.pump();
    expect(extent, greaterThan(240));
  });

  testWidgets('list row reorders by grip drag and Alt+arrow keys', (t) async {
    final items = ['A', 'B', 'C'];
    await t.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) => SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (i, item) in items.indexed)
                  DetentListRow(
                    key: ValueKey(item),
                    label: item,
                    onPressed: () {},
                    onMoveUp: i == 0
                        ? null
                        : () => setState(() {
                            items.insert(i - 1, items.removeAt(i));
                          }),
                    onMoveDown: i == items.length - 1
                        ? null
                        : () => setState(() {
                            items.insert(i + 1, items.removeAt(i));
                          }),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.byType(DetentGrip), findsNWidgets(3));

    final gripA = find.descendant(
      of: find.byKey(const ValueKey('A')),
      matching: find.byType(DetentGrip),
    );
    // Past the touch slop plus one 40px row.
    await t.drag(gripA, const Offset(0, 72));
    await t.pump();
    expect(items, ['B', 'A', 'C']);

    Focus.of(t.element(find.text('C'))).requestFocus();
    await t.pump();
    await t.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await t.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await t.pump();
    expect(items, ['B', 'C', 'A']);
  });

  testWidgets('grip, mark and rows render in dark mode at large text', (
    t,
  ) async {
    for (final mode in DetentThemeMode.values) {
      await t.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: host(
            SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DetentListRow(label: '長い日本語の項目名', onMoveDown: () {}),
                  const DetentStatusBar(children: [Text('準備完了')]),
                ],
              ),
            ),
            mode: mode,
          ),
        ),
      );
      expect(t.takeException(), isNull, reason: mode.name);
    }
  });
}
