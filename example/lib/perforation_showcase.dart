import 'package:detent_ui/detent_ui.dart';
import 'package:flutter/widgets.dart';

/// Working host values; the subsystem never captures audio or starts work itself.
class PerforationShowcase extends StatefulWidget {
  const PerforationShowcase({super.key});
  @override
  State<PerforationShowcase> createState() => _PerforationShowcaseState();
}

class _PerforationShowcaseState extends State<PerforationShowcase> {
  double progress = .75, level = .6;
  int pulse = 0;
  bool loading = true, monitor = true;
  NuiConnectionStatus connection = NuiConnectionStatus.connected;

  Widget specimen(String label, Widget child, {double width = 280}) => SizedBox(
    width: width,
    child: NuiPanel(header: Text(label), child: child),
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Signature Systems / Perforation',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      const Text('Digital interfaces with physical character. / C49–C51'),
      const SizedBox(height: 24),
      Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final variant in NuiPerforationSurfaceVariant.values)
            SizedBox(
              width: 240,
              child: NuiPerforationSurface(
                variant: variant,
                density: NuiPerforationDensity.sparse,
                child: Text('C49 / ${variant.name}'),
              ),
            ),
        ],
      ),
      const SizedBox(height: 24),
      Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final arrangement in NuiPerforationArrangement.values)
            specimen(
              arrangement.name,
              NuiHoleGrid(rows: 5, columns: 12, arrangement: arrangement),
            ),
          for (final depth in NuiPerforationDepth.values)
            specimen(
              depth.name,
              NuiHoleGrid(rows: 3, columns: 12, depth: depth),
            ),
          specimen(
            'Hole / states and sizes',
            Wrap(
              spacing: 16,
              children: [
                for (final size in NuiHoleSize.values)
                  for (final state in NuiHoleState.values)
                    NuiHole(size: size, state: state),
              ],
            ),
          ),
          for (final coverage in NuiPerforationCoverage.values)
            specimen(
              'Coverage / ${coverage.name}',
              SizedBox(
                height: 80,
                width: 230,
                child: NuiPerforationPattern(
                  coverage: coverage,
                  mask: coverage == NuiPerforationCoverage.custom
                      ? (r, c, _) => r == c || r + c == 7
                      : null,
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 24),
      Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final state in NuiResonanceState.values)
            specimen(
              'C50 / ${state.name}',
              NuiResonanceGrid(
                state: state,
                level: level,
                pulseId: pulse,
                interaction: state == NuiResonanceState.listening
                    ? NuiResonanceInteraction.audio
                    : NuiResonanceInteraction.radial,
              ),
            ),
          specimen(
            'Pointer response',
            const NuiResonanceGrid(
              interaction: NuiResonanceInteraction.pointer,
            ),
          ),
          specimen(
            'Notification / one shot',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NuiResonanceGrid(
                  pulseId: pulse,
                  state: NuiResonanceState.pulse,
                  interaction: NuiResonanceInteraction.notification,
                ),
                const SizedBox(height: 12),
                NuiButton(
                  label: '通知を送る',
                  onPressed: () => setState(() => pulse++),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final v in [.25, .5, .75, 1.0])
            specimen(
              'C51 / Progress',
              NuiSpeakerMatrix.progress(value: v, label: '書き出し'),
            ),
          for (final s in NuiConnectionStatus.values)
            specimen(
              'C51 / Status',
              NuiSpeakerMatrix.status(status: s, label: '接続状態'),
            ),
          specimen(
            'C51 / Level',
            NuiSpeakerMatrix.level(
              levels: [level / 2, level, .8, .3],
              label: '入力レベル',
            ),
          ),
          specimen(
            'C51 / Signal',
            const NuiSpeakerMatrix.signal(strength: 4, label: '信号強度'),
          ),
          specimen(
            'C51 / Loading',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NuiSpeakerMatrix.loading(label: '処理中', enabled: loading),
                const SizedBox(height: 12),
                NuiToggleButton(
                  label: '処理中',
                  value: loading,
                  onChanged: (v) => setState(() => loading = v),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 32),
      const Text(
        'Audio workspace / composition',
        style: TextStyle(fontSize: 24),
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          specimen(
            '入力設定',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Studio Microphone / Input 02'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('入力モニター'),
                    NuiSwitch(
                      value: monitor,
                      onChanged: (v) => setState(() => monitor = v),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                NuiSlider(
                  value: level,
                  onChanged: (v) => setState(() => level = v),
                ),
                const SizedBox(height: 12),
                NuiSlider(
                  value: progress,
                  onChanged: (v) => setState(() => progress = v),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 280,
                  child: NuiProgress(value: progress, label: 'セッション書き出し'),
                ),
                const SizedBox(height: 16),
                NuiButton(
                  label: 'セッションを保存',
                  onPressed: () => setState(() => progress = 1),
                ),
              ],
            ),
            width: 360,
          ),
          specimen(
            '音声フィードバック',
            NuiResonanceGrid(
              interaction: NuiResonanceInteraction.audio,
              level: level,
              state: monitor
                  ? NuiResonanceState.listening
                  : NuiResonanceState.disabled,
            ),
          ),
          specimen(
            '書き出し',
            NuiSpeakerMatrix.progress(value: progress, label: 'セッション書き出し'),
          ),
          specimen(
            '接続状態',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NuiSpeakerMatrix.status(status: connection, label: '入力デバイス'),
                const SizedBox(height: 12),
                NuiButton(
                  label: '接続状態を切替',
                  onPressed: () => setState(() {
                    connection =
                        NuiConnectionStatus.values[(connection.index + 1) %
                            NuiConnectionStatus.values.length];
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    ],
  );
}
