import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:detent_ui/detent_ui.dart';

// Run from the package root as well as the standalone example.
// ignore: avoid_relative_lib_imports
import '../lib/main.dart';

void main() {
  setUpAll(() async {
    final icons = FontLoader('packages/forui_lucide/ForuiLucideIcons')
      ..addFont(rootBundle.load('packages/forui_lucide/assets/lucide.ttf'));
    await icons.load();
    for (final family in ['Manrope', 'IBM Plex Sans JP']) {
      final loader = FontLoader('packages/detent_ui/$family');
      loader.addFont(
        rootBundle.load(
          'packages/detent_ui/assets/fonts/${family == 'Manrope' ? 'Manrope.ttf' : 'IBMPlexSansJP-Regular.ttf'}',
        ),
      );
      await loader.load();
    }
  });
  testWidgets('all 48 component cards render across themes and large text', (
    t,
  ) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(1440, 1000);
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    for (final dark in [false, true]) {
      for (final high in [false, true]) {
        final theme = NuiThemeData(
          brightness: dark ? Brightness.dark : Brightness.light,
          highContrast: high,
          motion: NuiMotion.reduced,
        );
        await t.pumpWidget(
          NuiApp(
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(1440, 1000),
                textScaler: TextScaler.linear(2),
              ),
              child: NuiTheme(
                data: theme,
                child: const NuiBox(body: GalleryBody()),
              ),
            ),
          ),
        );
        await t.pump(const Duration(milliseconds: 200));
        expect(find.byType(NuiButton), findsWidgets);
        for (var i = 1; i <= 48; i++) {
          expect(find.text('C${i.toString().padLeft(2, '0')}'), findsOneWidget);
        }
        expect(
          t.takeException(),
          isNull,
          reason: 'dark=$dark high=$high scale=2',
        );
      }
    }
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 2));
  });
  testWidgets('gallery renders at 1024, 1440, and 1920 and exports previews', (
    t,
  ) async {
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    for (final width in [1024.0, 1440.0, 1920.0]) {
      t.view.physicalSize = Size(width, 1000);
      final boundary = GlobalKey();
      await t.pumpWidget(
        RepaintBoundary(key: boundary, child: const DetentGallery()),
      );
      await t.pump(const Duration(seconds: 1));
      expect(t.takeException(), isNull, reason: 'width=$width');
      if (width == 1440) {
        Future<void> capture(String name) async {
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)),
          );
          await t.pump();
          await t.pump(const Duration(milliseconds: 400));
          await t.runAsync(() async {
            final render =
                boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final img = await render.toImage();
            final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
            File('/tmp/detent-gallery-$name.png')
                .writeAsBytesSync(bytes!.buffer.asUint8List());
            img.dispose();
          });
        }

        await capture('light');
        await t.tap(find.text('Rive'));
        await t.pump();
        await capture('static');
        await t.tap(find.text('Rive'));
        await t.pump();
        await t.ensureVisible(find.text('C16'));
        await t.pump();
        await t.tap(
          find.descendant(
            of: find.byType(NuiSelect<int>),
            matching: find.byType(EditableText),
          ),
        );
        await t.pump();
        await capture('select');
        await t.sendKeyEvent(LogicalKeyboardKey.escape);
        await t.pump();
        await t.tap(
          find.descendant(
            of: find.byType(NuiComboBox<int>),
            matching: find.byType(EditableText),
          ),
        );
        await t.pump();
        await capture('combobox');
        await t.sendKeyEvent(LogicalKeyboardKey.escape);
        await t.pump();
        await t.ensureVisible(find.text('C20'));
        await t.pump();
        await capture('navigation');
        await t.drag(find.byType(NuiScrollArea).first, const Offset(0, 5000));
        await t.pump(const Duration(seconds: 1));
        await t.tap(find.text('Dark'));
        await t.pump();
        await t.pump(const Duration(seconds: 1));
        await t.pump(const Duration(seconds: 1));
        await t.pump(const Duration(seconds: 1));
        await capture('dark');
        await t.ensureVisible(find.text('C28'));
        await t.pump(const Duration(milliseconds: 300));
        await capture('workspace');
        await t.ensureVisible(find.text('C39'));
        await t.pump(const Duration(milliseconds: 300));
        await capture('feedback');
      }
    }
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 2));
  });
}
