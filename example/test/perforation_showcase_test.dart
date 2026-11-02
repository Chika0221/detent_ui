import 'dart:io';
import 'dart:ui' as ui;

import 'package:detent_ui/detent_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../lib/perforation_showcase.dart';

void main() {
  setUpAll(() async {
    for (final family in ['Manrope', 'IBM Plex Sans JP']) {
      await (FontLoader('packages/detent_ui/$family')..addFont(
            rootBundle.load(
              'packages/detent_ui/assets/fonts/${family == 'Manrope' ? 'Manrope.ttf' : 'IBMPlexSansJP-Regular.ttf'}',
            ),
          ))
          .load();
    }
  });

  testWidgets(
    'Perforation showcase renders at desktop widths and exports themes',
    (t) async {
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.view.resetPhysicalSize);
      for (final width in [1024.0, 1440.0, 1920.0]) {
        t.view.physicalSize = Size(width, 1000);
        for (final mode in [NuiThemeMode.light, NuiThemeMode.dark]) {
          final boundary = GlobalKey();
          final scroll = ScrollController();
          await t.pumpWidget(
            RepaintBoundary(
              key: boundary,
              child: NuiApp(
                riveEnabled: false,
                themeMode: mode,
                motion: NuiMotion.reduced,
                home: NuiBox(
                  body: SingleChildScrollView(
                    controller: scroll,
                    child: const Padding(
                      padding: EdgeInsets.all(24),
                      child: PerforationShowcase(),
                    ),
                  ),
                ),
              ),
            ),
          );
          await t.pumpAndSettle();
          expect(t.takeException(), isNull, reason: '$width/$mode');
          expect(find.byType(NuiPerforationSurface), findsNWidgets(5));
          Future<void> capture(String area) async {
            await t.pump();
            await t.runAsync(() async {
              final render =
                  boundary.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              final image = await render.toImage(pixelRatio: 1);
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              File('/tmp/detent-perforation-${mode.name}-$area.png')
                  .writeAsBytesSync(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }

          if (width == 1440) await capture('foundations');
          scroll.jumpTo(scroll.position.maxScrollExtent);
          await t.pumpAndSettle();
          expect(t.takeException(), isNull, reason: '$width/$mode/workspace');
          if (width == 1440) await capture('workspace');
          await t.pumpWidget(const SizedBox());
          scroll.dispose();
        }
      }
    },
  );
}
