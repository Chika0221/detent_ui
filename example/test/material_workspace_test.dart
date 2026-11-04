import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:detent_ui/detent_ui.dart';

// Supports running from both the package root and the standalone example.
// ignore: avoid_relative_lib_imports
import '../lib/material_workspace.dart';

void main() {
  setUpAll(() async {
    final icons = FontLoader('packages/forui_lucide/ForuiLucideIcons')
      ..addFont(rootBundle.load('packages/forui_lucide/assets/lucide.ttf'));
    await icons.load();
    for (final entry in {'Manrope': 'Manrope.ttf', 'IBM Plex Sans JP': 'IBMPlexSansJP-Regular.ttf'}.entries) {
      final loader = FontLoader('packages/detent_ui/${entry.key}')
        ..addFont(rootBundle.load('packages/detent_ui/assets/fonts/${entry.value}'));
      await loader.load();
    }
  });
  testWidgets(
    'adjustment survives material changes and commits for comparison',
    (t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(1440, 1000);
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final boundary = GlobalKey();
      await t.pumpWidget(
        NuiApp(
          home: SingleChildScrollView(
            child: RepaintBoundary(
              key: boundary,
              child: const MaterialWorkspace(),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(t.widget<NuiDotMatrix>(find.byType(NuiDotMatrix)).text, '64%');
      await t.tap(find.widgetWithText(NuiListRow, '波形'));
      await t.pumpAndSettle();
      expect(t.widget<NuiDotMatrix>(find.byType(NuiDotMatrix)).text, '50%');
      await t.tap(find.widgetWithText(NuiListRow, '同心円'));
      await t.pumpAndSettle();
      expect(t.widget<NuiDotMatrix>(find.byType(NuiDotMatrix)).text, '64%');
      await t.tap(find.text('確定値'));
      await t.pumpAndSettle();
      expect(find.bySemanticsLabel('同心円、確定値、密度 50パーセント'), findsOneWidget);
      await t.tap(find.text('調整を確定'));
      await t.pumpAndSettle();
      expect(find.bySemanticsLabel('同心円、確定値、密度 64パーセント'), findsOneWidget);
      expect(
        t.widget<NuiButton>(find.widgetWithText(NuiButton, '調整を確定')).onPressed,
        isNull,
      );
      expect(t.takeException(), isNull);
      await t.runAsync(() async {
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await render.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('/tmp/detent-material-workspace.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
    },
  );

  testWidgets('narrow layout and large text retain controls without overflow', (
    t,
  ) async {
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    for (final width in [390.0, 1024.0]) {
      t.view.physicalSize = Size(width, 1000);
      await t.pumpWidget(
        NuiApp(
          home: MediaQuery(
            data: MediaQueryData(
              textScaler: TextScaler.linear(2),
              size: Size(width, 1000),
            ),
            child: const SingleChildScrollView(child: MaterialWorkspace()),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull, reason: 'width=$width');
    }
  });
}
