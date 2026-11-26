import 'package:flutter/widgets.dart';
import 'package:detent_ui/detent_ui.dart';
import 'package:detent_ui_omarchy/detent_ui_omarchy.dart';

import 'performance_probe.dart';
import 'component_catalog.dart';

void main() => runApp(const DetentGallery());

class DetentGallery extends StatefulWidget {
  const DetentGallery({super.key});
  @override
  State<DetentGallery> createState() => _DetentGalleryState();
}

class _DetentGalleryState extends State<DetentGallery> {
  DetentThemeMode mode = DetentThemeMode.light;
  bool high = false, reduced = false, riveEnabled = true;
  DetentDensity density = DetentDensity.standard;
  GalleryPerformanceProbe? _performanceProbe;

  /// Created only while the Omarchy toggle is on, so the gallery (and its
  /// tests) never touch the file system or leave polling timers by default.
  OmarchyThemeController? _omarchy;
  bool keepDetentAccent = false;

  /// The synced palette; it overrides Dark and High contrast while set.
  DetentPalette? get _omarchyPalette => _omarchy?.palette;

  @override
  void initState() {
    super.initState();
    if (const bool.fromEnvironment('DETENT_PERF')) {
      _performanceProbe = GalleryPerformanceProbe(() => riveEnabled);
    }
  }

  @override
  void dispose() {
    _omarchy?.dispose();
    _performanceProbe?.dispose();
    super.dispose();
  }

  void _setOmarchy(bool enabled) {
    _omarchy?.dispose();
    _omarchy = null;
    if (enabled) {
      _omarchy = OmarchyThemeController(keepDetentAccent: keepDetentAccent)
        ..addListener(_onOmarchyChanged)
        ..start().then((_) => _onOmarchyChanged());
    }
    setState(() {});
  }

  void _onOmarchyChanged() {
    if (mounted) setState(() {});
  }

  String get _omarchyStatus {
    final controller = _omarchy;
    if (controller == null) return 'Omarchy off';
    final theme = controller.theme;
    if (theme != null) return 'Omarchy: ${theme.name ?? 'custom'}';
    return controller.resolvedLocation == null
        ? 'Omarchy not found'
        : 'Omarchy loading…';
  }

  @override
  Widget build(BuildContext context) => DetentApp(
    title: 'Detent / UI Workshop',
    themeMode: mode,
    density: density,
    motion: reduced ? DetentMotion.reduced : DetentMotion.full,
    highContrast: high,
    riveEnabled: riveEnabled,
    palette: _omarchyPalette,
    home: Builder(
      builder: (context) => DetentAppShell(
        toolbar: DetentToolbar(
          children: [
            const Text(
              'Detent UI',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 24),
            DetentToggleButton(
              label: 'Dark',
              value: mode == DetentThemeMode.dark,
              onChanged: _omarchyPalette != null
                  ? null
                  : (v) => setState(
                      () => mode = v
                          ? DetentThemeMode.dark
                          : DetentThemeMode.light,
                    ),
            ),
            DetentToggleButton(
              label: 'High contrast',
              value: high,
              onChanged: _omarchyPalette != null
                  ? null
                  : (v) => setState(() => high = v),
            ),
            DetentToggleButton(
              label: 'Omarchy',
              value: _omarchy != null,
              onChanged: _setOmarchy,
            ),
            DetentToggleButton(
              label: 'Keep Detent accent',
              value: keepDetentAccent,
              onChanged: _omarchy == null
                  ? null
                  : (v) => setState(() {
                      keepDetentAccent = v;
                      _omarchy!.keepDetentAccent = v;
                    }),
            ),
            DetentToggleButton(
              label: 'Reduced motion',
              value: reduced,
              onChanged: (v) => setState(() => reduced = v),
            ),
            DetentToggleButton(
              label: 'Rive',
              value: riveEnabled,
              onChanged: (v) => setState(() => riveEnabled = v),
            ),
            DetentDropdownMenu(
              label: density.name,
              items: [
                for (final d in DetentDensity.values)
                  DetentMenuItem(
                    label: d.name,
                    onPressed: () => setState(() => density = d),
                  ),
              ],
            ),
          ],
        ),
        body: const GalleryBody(),
        statusBar: DetentStatusBar(
          children: [
            const Text('Detent Design System'),
            const Spacer(),
            Text(_omarchyStatus),
            const SizedBox(width: 16),
            const Text('0.8'),
          ],
        ),
      ),
    ),
  );
}
