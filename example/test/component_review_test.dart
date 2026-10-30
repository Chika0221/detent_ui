import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:detent_ui/detent_ui.dart';
import 'package:rive/rive.dart' as rive;

void main() {
  testWidgets(
    'review corrected controls and export a continuous slide reversal',
    (t) async {
      t.view.physicalSize = const Size(800, 420);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await (FontLoader('packages/forui_lucide/ForuiLucideIcons')..addFont(
            rootBundle.load('packages/forui_lucide/assets/lucide.ttf'),
          ))
          .load();
      for (final family in ['Manrope', 'IBM Plex Sans JP']) {
        await (FontLoader('packages/detent_ui/$family')..addFont(
              rootBundle.load(
                'packages/detent_ui/assets/fonts/${family == 'Manrope' ? 'Manrope.ttf' : 'IBMPlexSansJP-Regular.ttf'}',
              ),
            ))
            .load();
      }
      final boundary = GlobalKey(), segment = GlobalKey();
      var value = 0;
      Widget row(String label, Widget child) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            SizedBox(width: 128, child: Text(label)),
            SizedBox(width: 500, child: child),
          ],
        ),
      );
      await t.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: NuiApp(
            home: NuiBox(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: StatefulBuilder(
                    builder: (ctx, set) => Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        row(
                          'IconButton',
                          Align(
                            alignment: Alignment.centerLeft,
                            child: NuiIconButton(
                              icon: FLucideIcons.plus,
                              tooltip: '追加',
                              onPressed: () {},
                            ),
                          ),
                        ),
                        row(
                          'Tabs',
                          NuiTabs(
                            tabs: [
                              NuiTab(0, '仕様書.md', dirty: true, onClose: () {}),
                              NuiTab(1, 'デザイン.pen', onClose: () {}),
                            ],
                            value: 0,
                            onChanged: (_) {},
                          ),
                        ),
                        row(
                          'TaskStatus',
                          const NuiTaskStatus(
                            state: NuiTaskState.running,
                            label: '書き出し中',
                            detail: '17 / 25 files',
                            progress: .68,
                          ),
                        ),
                        row(
                          'SegmentedControl',
                          RepaintBoundary(
                            key: segment,
                            child: NuiSegmentedControl(
                              options: const [
                                NuiOption(0, '一覧', icon: FLucideIcons.list),
                                NuiOption(
                                  1,
                                  'グリッド',
                                  icon: FLucideIcons.layoutGrid,
                                ),
                                NuiOption(2, '比較', icon: FLucideIcons.columns2),
                              ],
                              value: value,
                              onChanged: (v) => set(() => value = v),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      for (
        var i = 0;
        i < 40 && find.byType(rive.RiveWidget).evaluate().isEmpty;
        i++
      ) {
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await t.pump();
      }
      expect(find.byType(rive.RiveWidget), findsOneWidget);
      Future<void> capture(GlobalKey key, String path) async {
        await t.runAsync(() async {
          final render =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final img = await render.toImage();
          final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
          File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
          img.dispose();
        });
      }

      await t.pump(const Duration(milliseconds: 300));
      await capture(boundary, '/tmp/detent-component-detail.png');
      for (var i = 0; i < 60; i++) {
        if ([6, 18, 30].contains(i)) {
          await t.tap(
            find.descendant(
              of: find.byType(NuiSegmentedControl<int>),
              matching: find.text(
                i == 6
                    ? '比較'
                    : i == 18
                    ? '一覧'
                    : 'グリッド',
              ),
            ),
          );
        }
        await t.pump(const Duration(milliseconds: 16));
        await capture(
          segment,
          '/tmp/detent-slide-${i.toString().padLeft(2, '0')}.png',
        );
      }
      expect(value, 1);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    },
  );
}
