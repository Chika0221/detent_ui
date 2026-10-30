import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rive/rive.dart' as rive;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'all authored artboards decode and bind in the pinned Flutter runtime',
    () async {
      final file = await rive.File.decode(
        await File('assets/rive/detent.riv').readAsBytes(),
        riveFactory: rive.Factory.flutter,
      );
      expect(file, isNotNull);
      final manifest = jsonDecode(
        await File('assets/rive/manifest.json').readAsString(),
      ) as Map<String, dynamic>;
      expect(
        (manifest['skins'] as List).map((skin) => skin['artboard']),
        unorderedEquals([
          'Progress',
          'CircularProgress',
          'Spinner',
          'Meter',
          'TaskStatus',
          'TaskGlyph',
          'Skeleton',
        ]),
      );
      for (final skin in manifest['skins'] as List) {
        final controller = rive.RiveWidgetController(
          file!,
          artboardSelector: rive.ArtboardSelector.byName(
            skin['artboard'] as String,
          ),
        );
        final instance = controller.dataBind(rive.DataBind.auto());
        expect(instance.boolean('pressed'), isNotNull);
        expect(instance.number('progress'), isNotNull);
        instance.boolean('pressed')!.value = true;
        instance.number('progress')!.value = .9;
        controller.advance(1 / 60);
        controller.advance(.2);
        expect(instance.boolean('pressed')!.value, isTrue);
        expect(instance.number('progress')!.value, closeTo(.9, .001));
        controller.dispose();
        instance.dispose();
      }
      file!.dispose();
    },
  );
}
