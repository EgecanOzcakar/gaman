import 'dart:math' as math;

import 'package:flutter/material.dart';

/// An ensō (brush circle) drawn in code: a stroke that swells and thins and
/// leaves a gap at the end, the way a brush runs dry. [progress] (0..1)
/// draws it on. A stand-in mark until real brush artwork exists.
class Enso extends StatelessWidget {
  const Enso({super.key, this.size = 96, this.progress = 1, this.color});

  final double size;
  final double progress;
  final Color? color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: CustomPaint(
          size: Size.square(size),
          painter: _EnsoPainter(
            progress: progress.clamp(0.0, 1.0),
            color: color ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
      );
}

class _EnsoPainter extends CustomPainter {
  _EnsoPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  // Starts lower-left, runs clockwise, stops short of closing.
  static const _start = math.pi * 0.62;
  static const _sweep = math.pi * 1.82;
  static const _steps = 120;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final c = size.center(Offset.zero);
    final maxW = size.width * 0.11;
    final r = size.width / 2 - maxW / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final n = (_steps * progress).ceil();
    for (var i = 0; i <= n; i++) {
      final t = i / _steps;
      if (t > progress) break;
      // Heavy at the start, swelling again mid-stroke, dry and thin at the end.
      final w = maxW *
          (0.35 + 0.65 * math.pow(1 - t, 0.6)) *
          (0.85 + 0.15 * math.sin(t * math.pi * 3));
      final a = _start + _sweep * t;
      // A slight wobble so it reads as hand-made, not a geometric ring.
      final rr = r * (1 + 0.025 * math.sin(t * math.pi * 5));
      canvas.drawCircle(
          c + Offset(math.cos(a), math.sin(a)) * rr, w / 2, paint);
    }
  }

  @override
  bool shouldRepaint(_EnsoPainter old) =>
      old.progress != progress || old.color != color;
}
