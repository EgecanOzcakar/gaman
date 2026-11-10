import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../providers/activity_log.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';

/// The practice chain as a strip of stone tiles. A missed day between two
/// practised days is mended with a gold seam (kintsugi) instead of breaking
/// the chain; two missed days leave a gap. When a day becomes mended while
/// on screen, its seam glows once (skipped under reduced motion).
class KintsugiChain extends StatefulWidget {
  const KintsugiChain({super.key, required this.marks, this.height = 28});

  final List<DayMark> marks;
  final double height;

  @override
  State<KintsugiChain> createState() => _KintsugiChainState();
}

class _KintsugiChainState extends State<KintsugiChain>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400));

  static int _mended(List<DayMark> m) => m.where((d) => d == DayMark.mended).length;

  @override
  void didUpdateWidget(KintsugiChain old) {
    super.didUpdateWidget(old);
    if (_mended(widget.marks) > _mended(old.marks) &&
        old.marks.length == widget.marks.length &&
        !Motion.reduced(context)) {
      _glow.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final marks = widget.marks;
    final done = marks.where((m) => m == DayMark.done).length;
    return Semantics(
      label: AppLocalizations.of(context)
          .chainSemantics(marks.length, done, _mended(marks)),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: _glow,
          builder: (context, _) => CustomPaint(
            painter: _ChainPainter(
              marks: marks,
              stone: scheme.primary,
              outline: scheme.outlineVariant,
              risk: scheme.error,
              gold: AppColors.gold(context),
              halo: scheme.surface,
              glow: _glow.isAnimating ? _glow.value : 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChainPainter extends CustomPainter {
  _ChainPainter({
    required this.marks,
    required this.stone,
    required this.outline,
    required this.risk,
    required this.gold,
    required this.halo,
    required this.glow,
  });

  final List<DayMark> marks;
  final Color stone, outline, risk, gold, halo;

  /// 0..1 progress of the one-off glow on the newest mended seam.
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    if (marks.isEmpty) return;
    const gap = 3.0;
    final w = (size.width - gap * (marks.length - 1)) / marks.length;
    final radius = Radius.circular(w.clamp(2, 6).toDouble());
    final newest = marks.lastIndexOf(DayMark.mended);
    for (var i = 0; i < marks.length; i++) {
      final r = RRect.fromRectAndRadius(
          Rect.fromLTWH(i * (w + gap), 0, w, size.height), radius);
      final fill = Paint()..style = PaintingStyle.fill;
      final line = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      switch (marks[i]) {
        case DayMark.done:
          canvas.drawRRect(r, fill..color = stone.withValues(alpha: 0.85));
        case DayMark.mended:
          canvas.drawRRect(r, fill..color = stone.withValues(alpha: 0.55));
          _seam(canvas, r.outerRect, i == newest ? glow : 0);
        case DayMark.atRisk:
          canvas.drawRRect(r, line..color = risk.withValues(alpha: 0.8));
        case DayMark.missed:
          canvas.drawRRect(r, line..color = outline.withValues(alpha: 0.5));
        case DayMark.open:
          canvas.drawRRect(r, line..color = stone.withValues(alpha: 0.6));
      }
    }
  }

  /// A jagged gold crack from top to bottom, on a surface-coloured halo so it
  /// reads against the stone tile in both themes.
  void _seam(Canvas canvas, Rect r, double glow) {
    final p = Path()
      ..moveTo(r.left + r.width * 0.55, r.top)
      ..lineTo(r.left + r.width * 0.3, r.top + r.height * 0.35)
      ..lineTo(r.left + r.width * 0.7, r.top + r.height * 0.6)
      ..lineTo(r.left + r.width * 0.4, r.bottom);
    Paint stroke(double width, Color c) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = c;
    if (glow > 0) {
      // Rises then fades: peaks at the midpoint of the animation.
      final a = (1 - (2 * glow - 1).abs()) * 0.7;
      canvas.drawPath(
          p,
          stroke(10, gold.withValues(alpha: a))
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    }
    canvas.drawPath(p, stroke(3.5, halo.withValues(alpha: 0.7)));
    canvas.drawPath(p, stroke(2, gold));
  }

  @override
  bool shouldRepaint(_ChainPainter old) =>
      old.glow != glow ||
      old.stone != stone ||
      old.gold != gold ||
      old.marks.length != marks.length ||
      !_sameMarks(old.marks, marks);

  static bool _sameMarks(List<DayMark> a, List<DayMark> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Compact summary, e.g. "12 days · 2 mended".
class ChainChip extends StatelessWidget {
  const ChainChip({super.key, required this.days, required this.mended, this.atRisk = false});
  final int days;
  final int mended;
  final bool atRisk;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = atRisk ? scheme.error : scheme.primary;
    final l10n = AppLocalizations.of(context);
    final text = [
      l10n.chainDays(days),
      if (mended > 0) l10n.chainMended(mended),
      if (atRisk) l10n.chainAtRisk,
    ].join(l10n.summarySeparator);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Insets.sm, vertical: Insets.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.link, size: 16, color: mended > 0 ? AppColors.gold(context) : color),
          const SizedBox(width: Insets.xs),
          Flexible(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
