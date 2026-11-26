import 'package:detent_ui/detent_ui.dart';
import 'package:flutter/widgets.dart';

import 'controller.dart';

/// Rebuilds [builder] with the live Omarchy palette.
///
/// ```dart
/// OmarchyThemeSync(
///   builder: (context, palette) => DetentApp(palette: palette, home: Home()),
/// )
/// ```
///
/// `palette` is null until the theme loads, and stays null on desktops without
/// Omarchy, so [DetentApp] keeps its built-in palette there.
class OmarchyThemeSync extends StatefulWidget {
  const OmarchyThemeSync({
    super.key,
    required this.builder,
    this.controller,
    this.keepDetentAccent = false,
  });

  final Widget Function(BuildContext context, DetentPalette? palette) builder;

  /// Optional externally owned controller. When null, one is created, started
  /// and disposed with this widget.
  final OmarchyThemeController? controller;

  /// Applies to the internally created controller only.
  final bool keepDetentAccent;

  @override
  State<OmarchyThemeSync> createState() => _OmarchyThemeSyncState();
}

class _OmarchyThemeSyncState extends State<OmarchyThemeSync> {
  OmarchyThemeController? _owned;

  OmarchyThemeController get _controller => widget.controller ?? _owned!;

  @override
  void initState() {
    super.initState();
    _attach();
  }

  @override
  void didUpdateWidget(OmarchyThemeSync oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _owned?.dispose();
      _owned = null;
      _attach();
    } else {
      _owned?.keepDetentAccent = widget.keepDetentAccent;
    }
  }

  void _attach() {
    if (widget.controller == null) {
      _owned = OmarchyThemeController(
        keepDetentAccent: widget.keepDetentAccent,
      );
    }
    _controller.start();
  }

  @override
  void dispose() {
    _owned?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _controller,
    builder: (context, _) => widget.builder(context, _controller.palette),
  );
}
