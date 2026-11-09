import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../endurance.dart';
import '../l10n/app_localizations.dart';
import '../providers/activity_log.dart';
import '../services/entitlement_service.dart';
import '../widgets/kintsugi_chain.dart';
import 'paywall_screen.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';

/// Endurance, not activity: urges held, trials done, the chain. Premium adds
/// patterns (triggers, hardest time, trials by level, week-over-week).
final _chainKey = GlobalKey();

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final log = context.watch<ActivityLog>();
    final now = DateTime.now();
    final tomorrow = DateUtils.dateOnly(now).add(const Duration(days: 1));
    final thisWeek = ActivityLog.weekStart();
    final lastWeek = thisWeek.subtract(const Duration(days: 7));
    final week = log.inRange(thisWeek, tomorrow).toList();

    final urges = urgeStats(week);
    final trialsDone = trialsByLevel(week).values.fold(0, (a, b) => a + b);
    final journalDays = week
        .where((e) => e.type == ActivityType.journal)
        .map((e) => DateUtils.dateOnly(e.at))
        .toSet()
        .length;
    final focusN = log.count(ActivityType.focus, thisWeek, tomorrow);
    final medMin = log.minutes(ActivityType.meditation, thisWeek, tomorrow);
    final tasksN = log.count(ActivityType.taskDone, thisWeek, tomorrow);
    final premium =
        context.watch<EntitlementService>().has(PremiumFeature.advancedInsights);
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(Insets.lg, Insets.lg, Insets.lg, Insets.xxl),
      children: [
        FadeSlideIn(
          child: Row(children: [
            Expanded(
              child: Text(l10n.insightsTitle,
                  style: Theme.of(context).textTheme.headlineMedium),
            ),
            if (log.chain.days > 0)
              IconButton(
                tooltip: l10n.shareChain,
                icon: const Icon(Icons.ios_share),
                onPressed: () => _shareChain(context, log.chain.days),
              ),
          ]),
        ),
        const SizedBox(height: Insets.lg),
        FadeSlideIn(
          delay: const Duration(milliseconds: 60),
          child: RepaintBoundary(
            key: _chainKey,
            child: ColoredBox(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: _ChainCard(log: log),
            ),
          ),
        ),
        const SizedBox(height: Insets.lg),
        FadeSlideIn(
          delay: const Duration(milliseconds: 120),
          child: Text(l10n.insightsThisWeek, style: Theme.of(context).textTheme.titleLarge),
        ),
        const SizedBox(height: Insets.md),
        FadeSlideIn(
          delay: const Duration(milliseconds: 160),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: Insets.md,
            crossAxisSpacing: Insets.md,
            childAspectRatio: 1.7,
            children: [
              _Stat(label: l10n.statUrgesHeld, value: '${urges.held}', unit: l10n.statOf(urges.total)),
              _Stat(label: l10n.statTrialsDone, value: '$trialsDone', unit: ''),
              _Stat(label: l10n.statJournalDays, value: '$journalDays', unit: l10n.statOf(7)),
              _Stat(label: l10n.statFocusSessions, value: '$focusN', unit: ''),
            ],
          ),
        ),
        const SizedBox(height: Insets.lg),
        FadeSlideIn(
          delay: const Duration(milliseconds: 220),
          child: !premium
              ? const _LockedPatternsCard()
              : _PatternsCard(
                  urges: urges,
                  byLevel: trialsByLevel(week),
                  summary: _summary(l10n, urges, trialsDone, focusN, medMin, journalDays, tasksN),
                  trend: _trend(
                    context,
                    thisWeekActive: log.activeDays(thisWeek, tomorrow),
                    lastWeekActive: log.activeDays(lastWeek, thisWeek),
                  ),
                ),
        ),
      ],
    );
  }

  /// Shares the chain card as an image: what users post is the marketing.
  Future<void> _shareChain(BuildContext context, int days) async {
    final text = AppLocalizations.of(context).shareChainText(days);
    final boundary =
        _chainKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    try {
      final image = await boundary.toImage(pixelRatio: 3);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      if (png == null) return;
      await Share.shareXFiles([
        XFile.fromData(png.buffer.asUint8List(),
            name: 'gaman-chain.png', mimeType: 'image/png'),
      ], text: text);
    } catch (e) {
      debugPrint('Sharing the chain failed: $e');
    }
  }

  String _summary(AppLocalizations l10n, UrgeStats urges, int trials, int focusN,
      int medMin, int journalDays, int tasksN) {
    final parts = <String>[
      if (urges.total > 0) l10n.summaryUrges(urges.held, urges.total),
      if (trials > 0) l10n.summaryTrials(trials),
      if (focusN > 0) l10n.summaryFocus(focusN),
      if (medMin > 0) l10n.summaryMeditation(medMin),
      if (journalDays > 0) l10n.summaryJournal(journalDays),
      if (tasksN > 0) l10n.summaryTasks(tasksN),
    ];
    if (parts.isEmpty) return l10n.summaryEmpty;
    return l10n.summaryWeek(l10n.joinList(parts));
  }

  Widget _trend(BuildContext context,
      {required int thisWeekActive, required int lastWeekActive}) {
    final l10n = AppLocalizations.of(context);
    final delta = thisWeekActive - lastWeekActive;
    final (icon, text, color) = switch (delta) {
      > 0 => (Icons.trending_up, l10n.trendUp(thisWeekActive), Colors.green),
      < 0 => (Icons.trending_down, l10n.trendDown(thisWeekActive), Theme.of(context).colorScheme.error),
      _ => (Icons.trending_flat, l10n.trendSame(thisWeekActive), Theme.of(context).colorScheme.onSurface),
    };
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: Insets.sm),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    );
  }
}

class _ChainCard extends StatelessWidget {
  const _ChainCard({required this.log});
  final ActivityLog log;

  @override
  Widget build(BuildContext context) {
    final chain = log.chain;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Insets.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('${chain.days}', style: text.displaySmall),
                const SizedBox(width: Insets.sm),
                Expanded(
                  child: Text(
                    chain.days == 0
                        ? l10n.chainCardEmpty
                        : chain.mended > 0
                            ? l10n.chainCardDaysMended(chain.mended)
                            : l10n.chainCardDays,
                    style: text.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Insets.md),
            KintsugiChain(marks: log.recentMarks(28)),
            const SizedBox(height: Insets.sm),
            Text(
              chain.atRisk ? l10n.chainCardAtRisk : l10n.chainCardExplain,
              style: text.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Endurance patterns are a Premium feature.
class _LockedPatternsCard extends StatelessWidget {
  const _LockedPatternsCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(Insets.md),
        leading: const Icon(Icons.lock_outline),
        title: Text(l10n.weeklyReviewLockedTitle),
        subtitle: Text(l10n.weeklyReviewLockedBody),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => PaywallScreen.show(context),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.unit});
  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Insets.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value, style: Theme.of(context).textTheme.headlineMedium),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: Insets.xs),
                  Text(unit, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
            const SizedBox(height: Insets.xs),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _PatternsCard extends StatelessWidget {
  const _PatternsCard({
    required this.urges,
    required this.byLevel,
    required this.summary,
    required this.trend,
  });

  final UrgeStats urges;
  final Map<int, int> byLevel;
  final String summary;
  final Widget trend;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final tags = urges.byTag.entries.toList()
      ..sort((a, b) => b.value.total.compareTo(a.value.total));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Insets.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.patternsTitle, style: text.titleMedium),
            const SizedBox(height: Insets.sm),
            Text(summary, style: text.bodyLarge?.copyWith(height: 1.5)),
            const SizedBox(height: Insets.md),
            trend,
            if (tags.isNotEmpty) ...[
              const SizedBox(height: Insets.lg),
              Text(l10n.patternsTriggers, style: text.titleSmall),
              const SizedBox(height: Insets.xs),
              for (final t in tags.take(4))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Insets.xs),
                  child: Row(children: [
                    Expanded(child: Text(l10n.urgeTag(t.key))),
                    Text(l10n.patternsTagHeld(t.value.held, t.value.total)),
                  ]),
                ),
            ],
            if (urges.hardestTime != null) ...[
              const SizedBox(height: Insets.md),
              Text(l10n.patternsHardestTime(l10n.partOfDayName(urges.hardestTime!)),
                  style: text.bodyMedium),
            ],
            const SizedBox(height: Insets.lg),
            Text(l10n.patternsByLevel, style: text.titleSmall),
            const SizedBox(height: Insets.xs),
            Row(children: [
              for (final l in [1, 2, 3])
                Expanded(
                  child: Column(children: [
                    Text('${byLevel[l] ?? 0}', style: text.headlineSmall),
                    Text(l10n.levelName(l), style: text.bodySmall),
                  ]),
                ),
            ]),
          ],
        ),
      ),
    );
  }
}
