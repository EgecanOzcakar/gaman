import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/motion.dart';

/// Urge surfing, drawn: the urge as a wave that rises fast, peaks and falls
/// away over the ten minutes. The faint line is the whole wave; the filled
/// part is what you've ridden so far; the dot is now. The surface ripples
/// gently, and the ripple calms as the wave falls (still under reduced
/// motion).
class UrgeWave extends StatefulWidget {
  const UrgeWave({super.key, required this.progress, this.height = 200});

  /// 0..1 through the urge.
  final double progress;
  final double height;

  /// Wave height at [p] (0..1): a quick rise to a peak at 25 %, then a long
  /// fall to calm. Exposed for tests.
  static double envelope(double p) {
    p = p.clamp(0.0, 1.0);
    const peak = 0.25;
    if (p < peak) return math.sin(p / peak * math.pi / 2);
    return math.pow(1 - (p - peak) / (1 - peak), 1.6).toDouble();
  }

  @override
  State<UrgeWave> createState() => _UrgeWaveState();
}

class _UrgeWaveState extends State<UrgeWave> with SingleTickerProviderStateMixin {
  late final AnimationController _ripple =
      AnimationController(vsync: this, duration: const Duration(seconds: 4));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _ripple.stop();
    } else if (!_ripple.isAnimating) {
      _ripple.repeat();
    }
  }

  @override
  void dispose() {
    _ripple.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _ripple,
        builder: (context, _) => CustomPaint(
          painter: _WavePainter(
            progress: widget.progress.clamp(0.0, 1.0),
            phase: _ripple.value * 2 * math.pi,
            color: scheme.primary,
            ghost: scheme.outlineVariant,
          ),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({
    required this.progress,
    required this.phase,
    required this.color,
    required this.ghost,
  });

  final double progress, phase;
  final Color color, ghost;

  @override
  void paint(Canvas canvas, Size size) {
    final base = size.height - 8;
    final top = 16.0;
    double y(double p) => base - (base - top) * UrgeWave.envelope(p);
    const steps = 160;

    // The whole wave, faint.
    final whole = Path()..moveTo(0, y(0));
    for (var i = 1; i <= steps; i++) {
      final p = i / steps;
      whole.lineTo(p * size.width, y(p));
    }
    canvas.drawPath(
        whole,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = ghost);

    // Ridden so far, filled, with a surface ripple that calms with the wave.
    final ripple = 3 + 5 * UrgeWave.envelope(progress);
    final ridden = Path()..moveTo(0, base);
    final n = (steps * progress).round();
    for (var i = 0; i <= n; i++) {
      final p = i / steps;
      final x = p * size.width;
      final wobble = math.sin(x / 18 + phase) * ripple * (i / (n == 0 ? 1 : n));
      ridden.lineTo(x, y(p) + wobble);
    }
    ridden
      ..lineTo(progress * size.width, base)
      ..close();
    canvas.drawPath(
        ridden,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0.55), color.withValues(alpha: 0.12)],
          ).createShader(Offset.zero & size));

    // Baseline and "now".
    canvas.drawLine(Offset(0, base), Offset(size.width, base),
        Paint()..color = ghost..strokeWidth = 1);
    canvas.drawCircle(
        Offset(progress * size.width, y(progress)), 6, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.progress != progress || old.phase != phase || old.color != color;
}
