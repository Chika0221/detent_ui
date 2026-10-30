import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Opt-in local measurements: --dart-define=DETENT_PERF=true.
/// Frame reports are observations, not a cross-device benchmark.
class GalleryPerformanceProbe {
  GalleryPerformanceProbe(this.riveEnabled) {
    SchedulerBinding.instance.addTimingsCallback(_record);
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _report());
  }
  final bool Function() riveEnabled;
  late final Timer _timer;
  final List<FrameTiming> _frames = [];
  bool? _mode;
  void _record(List<FrameTiming> frames) {
    final mode = riveEnabled();
    if (_mode != mode) {
      _frames.clear();
      _mode = mode;
    }
    _frames.addAll(frames);
  }

  void _report() {
    if (_frames.isEmpty) {
      debugPrint(
        'DETENT_FRAME ${jsonEncode({'rive': riveEnabled(), 'frames': 0})}',
      );
      return;
    }
    double percentile(List<double> values, double p) {
      values.sort();
      return values[((values.length - 1) * p).round()];
    }

    final build = _frames
        .map((f) => f.buildDuration.inMicroseconds / 1000)
        .toList();
    final raster = _frames
        .map((f) => f.rasterDuration.inMicroseconds / 1000)
        .toList();
    debugPrint(
      'DETENT_FRAME ${jsonEncode({'rive': _mode, 'frames': _frames.length, 'buildMedianMs': percentile(build, .5), 'buildP95Ms': percentile(build, .95), 'rasterMedianMs': percentile(raster, .5), 'rasterP95Ms': percentile(raster, .95)})}',
    );
    _frames.clear();
  }

  void dispose() {
    _timer.cancel();
    SchedulerBinding.instance.removeTimingsCallback(_record);
  }
}
