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
  NuiThemeMode mode = NuiThemeMode.light;
  bool high = false, reduced = false, riveEnabled = true;
  NuiDensity density = NuiDensity.standard;
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
  Widget build(BuildContext context) => NuiApp(
    title: 'Detent / UI Workshop',
    themeMode: mode,
    density: density,
    motion: reduced ? NuiMotion.reduced : NuiMotion.full,
    highContrast: high,
    riveEnabled: riveEnabled,
    home: Builder(
      builder: (context) => NuiAppShell(
        toolbar: NuiToolbar(
          children: [
            const Text(
              'Detent UI',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 24),
            NuiToggleButton(
              label: 'Dark',
              value: mode == NuiThemeMode.dark,
              onChanged: (v) => setState(
                () => mode = v ? NuiThemeMode.dark : NuiThemeMode.light,
              ),
            ),
            NuiToggleButton(
              label: 'High contrast',
              value: high,
              onChanged: (v) => setState(() => high = v),
            ),
            NuiToggleButton(
              label: 'Reduced motion',
              value: reduced,
              onChanged: (v) => setState(() => reduced = v),
            ),
            NuiToggleButton(
              label: 'Rive',
              value: riveEnabled,
              onChanged: (v) => setState(() => riveEnabled = v),
            ),
            NuiDropdownMenu(
              label: density.name,
              items: [
                for (final d in NuiDensity.values)
                  NuiMenuItem(
                    label: d.name,
                    onPressed: () => setState(() => density = d),
                  ),
              ],
            ),
          ],
        ),
        body: const GalleryBody(),
        statusBar: const NuiStatusBar(
          children: [Text('Detent Design System'), Spacer(), Text('0.8')],
        ),
      ),
    ),
  );
}
