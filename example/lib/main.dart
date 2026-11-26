import 'package:flutter/widgets.dart';
import 'package:detent_ui/detent_ui.dart';

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
  @override
  void initState() {
    super.initState();
    if (const bool.fromEnvironment('DETENT_PERF')) {
      _performanceProbe = GalleryPerformanceProbe(() => riveEnabled);
    }
  }

  @override
  void dispose() {
    _performanceProbe?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DetentApp(
    title: 'Detent / UI Workshop',
    themeMode: mode,
    density: density,
    motion: reduced ? DetentMotion.reduced : DetentMotion.full,
    highContrast: high,
    riveEnabled: riveEnabled,
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
              onChanged: (v) => setState(
                () => mode = v ? DetentThemeMode.dark : DetentThemeMode.light,
              ),
            ),
            DetentToggleButton(
              label: 'High contrast',
              value: high,
              onChanged: (v) => setState(() => high = v),
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
        statusBar: const DetentStatusBar(
          children: [Text('Detent Design System'), Spacer(), Text('0.8')],
        ),
      ),
    ),
  );
}
