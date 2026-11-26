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
  DetentConnectionStatus connection = DetentConnectionStatus.connected;

  Widget specimen(String label, Widget child, {double width = 280}) => SizedBox(
    width: width,
    child: DetentPanel(header: Text(label), child: child),
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
          for (final variant in DetentPerforationSurfaceVariant.values)
            SizedBox(
              width: 240,
              child: DetentPerforationSurface(
                variant: variant,
                density: DetentPerforationDensity.sparse,
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
          for (final arrangement in DetentPerforationArrangement.values)
            specimen(
              arrangement.name,
              DetentHoleGrid(rows: 5, columns: 12, arrangement: arrangement),
            ),
          for (final depth in DetentPerforationDepth.values)
            specimen(
              depth.name,
              DetentHoleGrid(rows: 3, columns: 12, depth: depth),
            ),
          specimen(
            'Hole / states and sizes',
            Wrap(
              spacing: 16,
              children: [
                for (final size in DetentHoleSize.values)
                  for (final state in DetentHoleState.values)
                    DetentHole(size: size, state: state),
              ],
            ),
          ),
          for (final coverage in DetentPerforationCoverage.values)
            specimen(
              'Coverage / ${coverage.name}',
              SizedBox(
                height: 80,
                width: 230,
                child: DetentPerforationPattern(
                  coverage: coverage,
                  mask: coverage == DetentPerforationCoverage.custom
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
          for (final state in DetentResonanceState.values)
            specimen(
              'C50 / ${state.name}',
              DetentResonanceGrid(
                state: state,
                level: level,
                pulseId: pulse,
                interaction: state == DetentResonanceState.listening
                    ? DetentResonanceInteraction.audio
                    : DetentResonanceInteraction.radial,
              ),
            ),
          specimen(
            'Pointer response',
            const DetentResonanceGrid(
              interaction: DetentResonanceInteraction.pointer,
            ),
          ),
          specimen(
            'Notification / one shot',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DetentResonanceGrid(
                  pulseId: pulse,
                  state: DetentResonanceState.pulse,
                  interaction: DetentResonanceInteraction.notification,
                ),
                const SizedBox(height: 12),
                DetentButton(
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
              DetentSpeakerMatrix.progress(value: v, label: '書き出し'),
            ),
          for (final s in DetentConnectionStatus.values)
            specimen(
              'C51 / Status',
              DetentSpeakerMatrix.status(status: s, label: '接続状態'),
            ),
          specimen(
            'C51 / Level',
            DetentSpeakerMatrix.level(
              levels: [level / 2, level, .8, .3],
              label: '入力レベル',
            ),
          ),
          specimen(
            'C51 / Signal',
            const DetentSpeakerMatrix.signal(strength: 4, label: '信号強度'),
          ),
          specimen(
            'C51 / Loading',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DetentSpeakerMatrix.loading(label: '処理中', enabled: loading),
                const SizedBox(height: 12),
                DetentToggleButton(
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
                    DetentSwitch(
                      value: monitor,
                      onChanged: (v) => setState(() => monitor = v),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DetentSlider(
                  value: level,
                  onChanged: (v) => setState(() => level = v),
                ),
                const SizedBox(height: 12),
                DetentSlider(
                  value: progress,
                  onChanged: (v) => setState(() => progress = v),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 280,
                  child: DetentProgress(value: progress, label: 'セッション書き出し'),
                ),
                const SizedBox(height: 16),
                DetentButton(
                  label: 'セッションを保存',
                  onPressed: () => setState(() => progress = 1),
                ),
              ],
            ),
            width: 360,
          ),
          specimen(
            '音声フィードバック',
            DetentResonanceGrid(
              interaction: DetentResonanceInteraction.audio,
              level: level,
              state: monitor
                  ? DetentResonanceState.listening
                  : DetentResonanceState.disabled,
            ),
          ),
          specimen(
            '書き出し',
            DetentSpeakerMatrix.progress(value: progress, label: 'セッション書き出し'),
          ),
          specimen(
            '接続状態',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DetentSpeakerMatrix.status(status: connection, label: '入力デバイス'),
                const SizedBox(height: 12),
                DetentButton(
                  label: '接続状態を切替',
                  onPressed: () => setState(() {
                    connection =
                        DetentConnectionStatus.values[(connection.index + 1) %
                            DetentConnectionStatus.values.length];
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
