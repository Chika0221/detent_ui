import 'dart:async';

import '../foundation/primitives.dart';

import 'package:forui_lucide/forui_lucide.dart';

import '../controls/controls.dart';
import '../rive/artwork.dart';
import '../rive/skin.dart';

enum NuiTone { neutral, success, danger, warning }

Color nuiToneColor(NuiThemeData t, NuiTone tone) => switch (tone) {
  NuiTone.neutral => t.muted,
  NuiTone.success => t.success,
  NuiTone.danger => t.danger,
  NuiTone.warning => t.accent,
};

class NuiBadge extends StatelessWidget {
  const NuiBadge({
    super.key,
    required this.label,
    this.tone = NuiTone.neutral,
    this.icon,
  });
  final String label;
  final NuiTone tone;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final t = NuiTheme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 32),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: t.raised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, size: 16, color: nuiToneColor(t, tone))
          else
            SizedBox.square(
              dimension: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: nuiToneColor(t, tone),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class NuiTooltip extends StatelessWidget {
  const NuiTooltip({
    super.key,
    required this.message,
    required this.child,
    this.shortcut,
  });
  final String message;
  final String? shortcut;
  final Widget child;
  @override
  Widget build(BuildContext context) => NuiHint(
    message: '$message${shortcut == null ? '' : '  $shortcut'}',
    child: child,
  );
}

enum NuiProgressVariant { linear, circular }

class NuiProgress extends StatelessWidget {
  const NuiProgress({
    super.key,
    this.value,
    this.variant = NuiProgressVariant.linear,
    this.label = '処理中',
    this.color,
  });
  final double? value;
  final Color? color;
  final NuiProgressVariant variant;
  final String label;
  @override
  Widget build(BuildContext context) {
    final t = NuiTheme.of(context), v = value?.clamp(0.0, 1.0);
    if (t.reduceMotion(context) && v == null) {
      return Semantics(
        liveRegion: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(FLucideIcons.loader, size: 16),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      );
    }
    final fallback = variant == NuiProgressVariant.linear
        ? _NuiFallbackProgress(value: v, color: color ?? t.ink, circular: false)
        : _NuiFallbackProgress(value: v, color: color ?? t.ink, circular: true);
    final artwork = NuiRiveArtwork(
      artboard: variant == NuiProgressVariant.linear
          ? 'Progress'
          : 'CircularProgress',
      stretch: variant == NuiProgressVariant.linear,
      state: NuiSkinState(
        progress: v ?? .24,
        indeterminate: v == null,
        inkColor: color ?? t.ink,
      ),
      fallback: fallback,
    );
    return Semantics(
      label: label,
      value: v == null ? '進捗不明' : '${(v * 100).round()}%',
      child: variant == NuiProgressVariant.linear
          ? SizedBox(
              height: 7,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: artwork,
              ),
            )
          : SizedBox.square(dimension: 28, child: artwork),
    );
  }
}

/// Independent 5×7 numeric glyphs, with ordinary text exposed to accessibility.
class NuiDotMatrix extends StatelessWidget {
  const NuiDotMatrix({
    super.key,
    required this.text,
    this.dotSize = 3,
    this.color,
    this.semanticLabel,
  });
  final String text;
  final double dotSize;
  final Color? color;
  final String? semanticLabel;
  @override
  Widget build(BuildContext context) {
    final fg = color ?? NuiTheme.of(context).inverse;
    const symbols = {
      '%': 'Percent',
      '.': 'Dot',
      ':': 'Colon',
      '-': 'Minus',
      ' ': 'Space',
    };
    return Semantics(
      label: semanticLabel ?? text,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < text.length; i++)
              SizedBox(
                key: ValueKey('digit-$i'),
                width: 6 * dotSize * 1.6,
                height: 7 * dotSize * 1.6,
                child: NuiRiveArtwork(
                  artboard:
                      'Digit${symbols[text[i]] ?? (int.tryParse(text[i]) != null ? text[i] : 'Minus')}',
                  settleOnLoad: false,
                  state: NuiSkinState(inkColor: fg),
                  // inverseColor is bound for numerical glyphs; the adapter applies fg.
                  fallback: CustomPaint(
                    painter: _DotPainter(text[i], dotSize, fg),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

const _glyphs = <String, List<String>>{
  '0': ['01110', '10001', '10011', '10101', '11001', '10001', '01110'],
  '1': ['00100', '01100', '00100', '00100', '00100', '00100', '01110'],
  '2': ['01110', '10001', '00001', '00010', '00100', '01000', '11111'],
  '3': ['11110', '00001', '00001', '01110', '00001', '00001', '11110'],
  '4': ['00010', '00110', '01010', '10010', '11111', '00010', '00010'],
  '5': ['11111', '10000', '10000', '11110', '00001', '00001', '11110'],
  '6': ['01110', '10000', '10000', '11110', '10001', '10001', '01110'],
  '7': ['11111', '00001', '00010', '00100', '01000', '01000', '01000'],
  '8': ['01110', '10001', '10001', '01110', '10001', '10001', '01110'],
  '9': ['01110', '10001', '10001', '01111', '00001', '00001', '01110'],
  '%': ['11001', '11010', '00010', '00100', '01000', '01011', '10011'],
  '.': ['00000', '00000', '00000', '00000', '00000', '00110', '00110'],
  ':': ['00000', '00100', '00100', '00000', '00100', '00100', '00000'],
  '-': ['00000', '00000', '00000', '11111', '00000', '00000', '00000'],
  ' ': ['00000', '00000', '00000', '00000', '00000', '00000', '00000'],
};

class _DotPainter extends CustomPainter {
  _DotPainter(this.text, this.dot, this.color);
  final String text;
  final double dot;
  final Color color;
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = color;
    for (var i = 0; i < text.length; i++) {
      final g = _glyphs[text[i]] ?? _glyphs['-']!;
      for (var y = 0; y < 7; y++) {
        for (var x = 0; x < 5; x++) {
          if (g[y][x] == '1') {
            c.drawCircle(
              Offset((i * 6 + x + .5) * dot * 1.6, (y + .5) * dot * 1.6),
              dot / 2,
              p,
            );
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(_DotPainter old) =>
      old.text != text || old.dot != dot || old.color != color;
}

class NuiMeter extends StatelessWidget {
  const NuiMeter({
    super.key,
    required this.value,
    this.min = 0,
    this.max = 100,
    this.segments = 32,
    this.label = 'レベル',
  });
  final double value, min, max;
  final int segments;
  final String label;
  @override
  Widget build(BuildContext context) {
    final t = NuiTheme.of(context),
        fraction = ((value - min) / (max - min)).clamp(0.0, 1.0);
    final fallbackBars = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < segments; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: ColoredBox(
                color: i / segments < fraction ? t.accent : t.controlBorder,
              ),
            ),
          ),
      ],
    );
    return Semantics(
      label: label,
      value: '$value',
      child: Container(
        padding: const EdgeInsets.all(8),
        color: t.display,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 40,
              child: segments == 32
                  ? NuiRiveArtwork(
                      artboard: 'Meter',
                      stretch: true,
                      state: NuiSkinState(progress: fraction),
                      fallback: fallbackBars,
                    )
                  : fallbackBars,
            ),
            const SizedBox(height: 8),
            DefaultTextStyle(
              style: NuiTheme.of(context).textTheme.bodySmall
                  .copyWith(color: t.inverse, fontSize: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$min'),
                  Text('${(min + max) / 2}'),
                  Text('$max'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NuiInlineAlert extends StatelessWidget {
  const NuiInlineAlert({
    super.key,
    required this.title,
    this.message,
    this.tone = NuiTone.danger,
    this.action,
  });
  final String title;
  final String? message;
  final NuiTone tone;
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    final t = NuiTheme.of(context),
        color = nuiToneColor(NuiTheme.of(context), tone);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: t.highContrast
              ? t.raised
              : Color.alphaBlend(color.withValues(alpha: .05), t.raised),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox.square(
              dimension: 16,
              child: NuiRiveArtwork(
                artboard: 'TaskGlyph',
                settleOnLoad: false,
                state: NuiSkinState(
                  taskState: tone == NuiTone.success
                      ? 2
                      : tone == NuiTone.danger || tone == NuiTone.warning
                      ? 3
                      : 0,
                  accentColor: color,
                ),
                fallback: Icon(
                  tone == NuiTone.danger
                      ? FLucideIcons.circleAlert
                      : FLucideIcons.info,
                  size: 16,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: color)),
                  if (message != null) ...[
                    const SizedBox(height: 8),
                    Text(message!, style: t.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
            if (action != null) ...[const SizedBox(width: 8), action!],
          ],
        ),
      ),
    );
  }
}

class NuiToast extends StatefulWidget {
  const NuiToast({
    super.key,
    required this.message,
    this.onDismiss,
    this.duration = const Duration(seconds: 5),
    this.actionLabel,
    this.onAction,
    this.tone = NuiTone.success,
  });
  final String message;
  final VoidCallback? onDismiss, onAction;
  final String? actionLabel;
  final Duration duration;
  final NuiTone tone;
  static NuiToastHandle show(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true),
        data = NuiTheme.of(context);
    _activeToasts.remove(overlay)?.close();
    late final NuiToastHandle handle;
    final entry = OverlayEntry(
      builder: (ctx) => Positioned(
        bottom: 24,
        left: 24,
        right: 24,
        child: Align(
          alignment: Alignment.bottomRight,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: NuiTheme(
              data: data,
              child: NuiToast(
                message: message,
                actionLabel: actionLabel,
                onAction: onAction,
                onDismiss: () => handle.close(),
              ),
            ),
          ),
        ),
      ),
    );
    handle = NuiToastHandle(entry);
    _activeToasts[overlay] = handle;
    overlay.insert(entry);
    return handle;
  }

  @override
  State<NuiToast> createState() => _NuiToastState();
}

class _NuiToastState extends State<NuiToast> {
  Timer? timer;
  late Duration remaining;
  final watch = Stopwatch();
  bool hover = false, focus = false;
  void schedule() {
    timer?.cancel();
    if (hover || focus || widget.onDismiss == null) return;
    watch
      ..reset()
      ..start();
    timer = Timer(remaining, () {
      watch.stop();
      widget.onDismiss?.call();
    });
  }

  void pause() {
    if (watch.isRunning) {
      watch.stop();
      remaining -= watch.elapsed;
      if (remaining.isNegative) remaining = Duration.zero;
    }
    timer?.cancel();
  }

  @override
  void initState() {
    super.initState();
    remaining = widget.duration;
    schedule();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) {
      pause();
      hover = true;
    },
    onExit: (_) {
      hover = false;
      schedule();
    },
    child: Focus(
      onFocusChange: (v) {
        if (v) pause();
        focus = v;
        if (!v) schedule();
      },
      child: Semantics(
        liveRegion: true,
        child: Container(
          constraints: const BoxConstraints(minHeight: 42),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: NuiTheme.of(context).raised,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: NuiTheme.of(context).controlBorder),
          ),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: nuiToneColor(NuiTheme.of(context), widget.tone),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(widget.message)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.actionLabel != null)
                    NuiPlainButton(
                      onPressed: widget.onAction,
                      child: Text(
                        widget.actionLabel!,
                        style: NuiTheme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  if (widget.onDismiss != null)
                    NuiIconAction(
                      tooltip: '通知を閉じる',
                      onPressed: widget.onDismiss,
                      icon: const Icon(FLucideIcons.x, size: 16),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class NuiDialog extends StatelessWidget {
  const NuiDialog({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
  });
  final String title;
  final Widget child;
  final List<Widget> actions;
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool dismissOnOutside = false,
    bool dismissOnEscape = true,
  }) => showNuiDialog<T>(
    context: context,
    barrierDismissible: dismissOnOutside,
    dismissOnEscape: dismissOnEscape,
    builder: builder,
  );
  @override
  Widget build(BuildContext context) =>
      NuiDialogFrame(title: Text(title), content: child, actions: actions);
}

class NuiPopover extends StatelessWidget {
  const NuiPopover({super.key, required this.label, required this.child});
  final String label;
  final Widget child;
  @override
  Widget build(BuildContext context) => NuiPopupAnchor(
    menuChildren: [
      Padding(
        padding: const EdgeInsets.all(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: child,
        ),
      ),
    ],
    builder: (ctx, c, _) => NuiButton(
      label: label,
      onPressed: () => c.isOpen ? c.close() : c.open(),
    ),
  );
}

class NuiEmptyState extends StatelessWidget {
  const NuiEmptyState({
    super.key,
    required this.title,
    this.description,
    this.action,
    this.icon = FLucideIcons.inbox,
  });
  final String title;
  final String? description;
  final Widget? action;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon == FLucideIcons.inbox)
          SizedBox.square(
            dimension: 32,
            child: NuiRiveArtwork(
              artboard: 'EmptyState',
              settleOnLoad: false,
              state: NuiSkinState(inkColor: NuiTheme.of(context).muted),
              fallback: Icon(icon, size: 32, color: NuiTheme.of(context).muted),
            ),
          )
        else
          Icon(icon, size: 32, color: NuiTheme.of(context).muted),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        if (description != null) ...[
          const SizedBox(height: 8),
          Text(description!, textAlign: TextAlign.center),
        ],
        if (action != null) ...[const SizedBox(height: 16), action!],
      ],
    ),
  );
}

class NuiSkeleton extends StatelessWidget {
  const NuiSkeleton({
    super.key,
    this.width = 160,
    this.height = 12,
    this.label = '読み込み中',
  });
  final double width, height;
  final String label;
  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: SizedBox(
      width: width,
      height: height,
      child: NuiRiveArtwork(
        artboard: 'Skeleton',
        stretch: true,
        state: const NuiSkinState(indeterminate: true),
        fallback: DecoratedBox(
          decoration: BoxDecoration(
            color: NuiTheme.of(context).border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    ),
  );
}

enum NuiTaskState { idle, running, canceling, canceled, success, error }

class NuiTaskStatus extends StatelessWidget {
  const NuiTaskStatus({
    super.key,
    required this.state,
    required this.label,
    this.progress,
    this.detail,
    this.onCancel,
    this.onRetry,
  });
  final NuiTaskState state;
  final String label;
  final double? progress;
  final String? detail;
  final VoidCallback? onCancel, onRetry;
  @override
  Widget build(BuildContext context) {
    final t = NuiTheme.of(context);
    final status = switch (state) {
      NuiTaskState.idle => '待機中',
      NuiTaskState.running => '処理中',
      NuiTaskState.canceling => '取り消し中',
      NuiTaskState.canceled => '取り消しました',
      NuiTaskState.success => '完了',
      NuiTaskState.error => '失敗',
    };
    return Semantics(
      liveRegion: true,
      label: '$label $status',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.display,
          borderRadius: BorderRadius.circular(6),
        ),
        child: DefaultTextStyle(
          style: NuiTheme.of(context).textTheme.bodyMedium
              .copyWith(color: t.inverse, fontSize: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  SizedBox.square(
                    dimension: 20,
                    child: NuiRiveArtwork(
                      artboard: 'TaskGlyph',
                      state: NuiSkinState(
                        taskState: switch (state) {
                          NuiTaskState.idle => 0,
                          NuiTaskState.running => 1,
                          NuiTaskState.success => 2,
                          NuiTaskState.error => 3,
                          NuiTaskState.canceled => 4,
                          NuiTaskState.canceling => 5,
                        },
                        accentColor: state == NuiTaskState.error
                            ? t.danger
                            : state == NuiTaskState.success
                            ? t.success
                            : t.accent,
                      ),
                      fallback: Icon(
                        state == NuiTaskState.success
                            ? FLucideIcons.circleCheck
                            : state == NuiTaskState.error
                            ? FLucideIcons.circleAlert
                            : FLucideIcons.activity,
                        color: state == NuiTaskState.error
                            ? t.danger
                            : t.accent,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text('$label · $status')),
                  if (progress != null)
                    Text('${(progress!.clamp(0.0, 1.0) * 100).round()}%'),
                ],
              ),
              if (detail != null) ...[const SizedBox(height: 8), Text(detail!)],
              if (state == NuiTaskState.running) ...[
                const SizedBox(height: 16),
                NuiProgress(value: progress, label: label, color: t.inverse),
              ],
              if (state == NuiTaskState.running && onCancel != null)
                NuiPlainButton(
                  onPressed: onCancel,
                  child: Text('取り消す', style: TextStyle(color: t.inverse)),
                ),
              if (state == NuiTaskState.error && onRetry != null)
                NuiPlainButton(
                  onPressed: onRetry,
                  child: Text('再試行', style: TextStyle(color: t.inverse)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

final _activeToasts = <OverlayState, NuiToastHandle>{};

class NuiToastHandle {
  NuiToastHandle(this._entry);
  OverlayEntry? _entry;
  void close() {
    final e = _entry;
    _entry = null;
    if (e != null) {
      e.remove();
      e.dispose();
    }
  }
}

class _NuiFallbackProgress extends StatefulWidget {
  const _NuiFallbackProgress({
    required this.value,
    required this.color,
    required this.circular,
  });
  final double? value;
  final Color color;
  final bool circular;
  @override
  State<_NuiFallbackProgress> createState() => _NuiFallbackProgressState();
}

class _NuiFallbackProgressState extends State<_NuiFallbackProgress>
    with SingleTickerProviderStateMixin {
  late final animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  @override
  void initState() {
    super.initState();
    if (widget.value == null) animation.repeat();
  }

  @override
  void didUpdateWidget(_NuiFallbackProgress old) {
    super.didUpdateWidget(old);
    if (widget.value == null && !animation.isAnimating) {
      animation.repeat();
    } else if (widget.value != null) {
      animation.stop();
    }
  }

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    builder: (ctx, _) => CustomPaint(
      painter: _ProgressPainter(
        widget.value,
        animation.value,
        widget.color,
        NuiTheme.of(context).border,
        widget.circular,
      ),
    ),
  );
}

class _ProgressPainter extends CustomPainter {
  _ProgressPainter(
    this.value,
    this.phase,
    this.color,
    this.track,
    this.circular,
  );
  final double? value;
  final double phase;
  final Color color, track;
  final bool circular;
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = track
      ..strokeWidth = 2
      ..style = circular ? PaintingStyle.stroke : PaintingStyle.fill;
    if (circular) {
      final rect = (Offset.zero & s).deflate(2);
      c.drawOval(rect, p);
      p.color = color;
      c.drawArc(
        rect,
        -1.5708 + (value == null ? phase * 6.2832 : 0),
        (value ?? .24) * 6.2832,
        false,
        p,
      );
    } else {
      c.drawRect(Offset.zero & s, p);
      p.color = color;
      final left = value == null ? phase * s.width : 0.0,
          width = value == null ? s.width * .24 : s.width * value!;
      c.drawRect(
        Rect.fromLTWH(left, 0, width.clamp(0.0, s.width - left), s.height),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressPainter old) =>
      old.value != value ||
      old.phase != phase ||
      old.color != color ||
      old.track != track;
}
