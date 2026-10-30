import 'package:flutter/widgets.dart';

import '../foundation/theme.dart';

/// Host-neutral values for Rive adapters. Flutter owns events and accessibility.
@immutable
class NuiSkinState {
  const NuiSkinState({
    this.hovered = false,
    this.pressed = false,
    this.focused = false,
    this.enabled = true,
    this.selected = false,
    this.value = 0,
    this.secondaryValue = 1,
    this.progress = 0,
    this.indeterminate = false,
    this.motionScale = 1,
  });
  final bool hovered, pressed, focused, enabled, selected, indeterminate;
  final double value, secondaryValue, progress, motionScale;
}

typedef NuiSkinBuilder = Widget? Function(
  BuildContext context,
  String component,
  NuiSkinState state,
);

/// Install a renderer; return null on unavailable assets to retain the fallback.
class NuiSkin extends InheritedWidget {
  const NuiSkin({super.key, required this.builder, required super.child});
  final NuiSkinBuilder builder;
  static Widget render(
    BuildContext context, {
    required String component,
    required NuiSkinState state,
    required Widget fallback,
  }) {
    if (NuiTheme.of(context).reduceMotion(context)) return fallback;
    return context.dependOnInheritedWidgetOfExactType<NuiSkin>()?.builder(
          context,
          component,
          state,
        ) ??
        fallback;
  }

  @override
  bool updateShouldNotify(NuiSkin oldWidget) => builder != oldWidget.builder;
}
