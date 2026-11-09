import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../providers/activity_log.dart';
import '../theme/app_theme.dart';

/// The practice chain as a strip of stone tiles. A missed day between two
/// practised days is mended with a gold seam (kintsugi) instead of breaking
/// the chain; two missed days leave a gap.
class KintsugiChain extends StatelessWidget {
  const KintsugiChain({super.key, required this.marks, this.height = 28});

  final List<DayMark> marks;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final done = marks.where((m) => m == DayMark.done).length;
    final mended = marks.where((m) => m == DayMark.mended).length;
    return Semantics(
      label: AppLocalizations.of(context).chainSemantics(marks.length, done, mended),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _ChainPainter(
            marks: marks,
            stone: scheme.primary,
            outline: scheme.outlineVariant,
            risk: scheme.error,
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
  });

  final List<DayMark> marks;
  final Color stone, outline, risk;

  @override
  void paint(Canvas canvas, Size size) {
    if (marks.isEmpty) return;
    const gap = 3.0;
    final w = (size.width - gap * (marks.length - 1)) / marks.length;
    final radius = Radius.circular(w.clamp(2, 6).toDouble());
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
          _seam(canvas, r.outerRect);
        case DayMark.atRisk:
          canvas.drawRRect(r, line..color = risk.withValues(alpha: 0.8));
        case DayMark.missed:
          canvas.drawRRect(r, line..color = outline.withValues(alpha: 0.5));
        case DayMark.open:
          canvas.drawRRect(r, line..color = stone.withValues(alpha: 0.6));
      }
    }
  }

  /// A jagged gold crack from top to bottom.
  void _seam(Canvas canvas, Rect r) {
    final p = Path()
      ..moveTo(r.left + r.width * 0.55, r.top)
      ..lineTo(r.left + r.width * 0.3, r.top + r.height * 0.35)
      ..lineTo(r.left + r.width * 0.7, r.top + r.height * 0.6)
      ..lineTo(r.left + r.width * 0.4, r.bottom);
    canvas.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..color = AppColors.gold);
  }

  @override
  bool shouldRepaint(_ChainPainter old) =>
      old.marks != marks || old.stone != stone;
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
          Icon(Icons.link, size: 16, color: mended > 0 ? AppColors.gold : color),
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
