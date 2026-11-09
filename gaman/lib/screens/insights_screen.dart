import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(Insets.lg, Insets.lg, Insets.lg, Insets.xxl),
      children: [
        FadeSlideIn(
          child: Text('Insights', style: Theme.of(context).textTheme.headlineMedium),
        ),
        const SizedBox(height: Insets.lg),
        FadeSlideIn(
          delay: const Duration(milliseconds: 60),
          child: _ChainCard(log: log),
        ),
        const SizedBox(height: Insets.lg),
        FadeSlideIn(
          delay: const Duration(milliseconds: 120),
          child: Text('This week', style: Theme.of(context).textTheme.titleLarge),
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
              _Stat(label: 'Urges held', value: '${urges.held}', unit: 'of ${urges.total}'),
              _Stat(label: 'Trials done', value: '$trialsDone', unit: ''),
              _Stat(label: 'Journal days', value: '$journalDays', unit: 'of 7'),
              _Stat(label: 'Focus sessions', value: '$focusN', unit: ''),
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
                  summary: _summary(urges, trialsDone, focusN, medMin, journalDays, tasksN),
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

  String _summary(UrgeStats urges, int trials, int focusN, int medMin,
      int journalDays, int tasksN) {
    final parts = <String>[
      if (urges.total > 0) 'held ${urges.held} of ${urges.total} urges',
      if (trials > 0) 'completed $trials trial${trials == 1 ? '' : 's'}',
      if (focusN > 0) 'did $focusN focus session${focusN == 1 ? '' : 's'}',
      if (medMin > 0) 'sat for $medMin minutes',
      if (journalDays > 0) 'journalled $journalDays day${journalDays == 1 ? '' : 's'}',
      if (tasksN > 0) 'finished $tasksN task${tasksN == 1 ? '' : 's'}',
    ];
    if (parts.isEmpty) {
      return 'Nothing logged yet this week. Start with one small hard thing today.';
    }
    return 'So far this week you\'ve ${_join(parts)}.';
  }

  String _join(List<String> parts) {
    if (parts.length == 1) return parts.first;
    return '${parts.sublist(0, parts.length - 1).join(', ')} and ${parts.last}';
  }

  Widget _trend(BuildContext context,
      {required int thisWeekActive, required int lastWeekActive}) {
    final delta = thisWeekActive - lastWeekActive;
    final (icon, text, color) = switch (delta) {
      > 0 => (Icons.trending_up, 'more than last week', Colors.green),
      < 0 => (Icons.trending_down, 'fewer than last week', Theme.of(context).colorScheme.error),
      _ => (Icons.trending_flat, 'the same as last week', Theme.of(context).colorScheme.onSurface),
    };
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: Insets.sm),
        Expanded(
          child: Text('$thisWeekActive practised day${thisWeekActive == 1 ? '' : 's'}, $text',
              style: Theme.of(context).textTheme.bodyMedium),
        ),
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
                        ? 'No chain yet. Practise once today.'
                        : 'day chain${chain.mended > 0 ? ', ${chain.mended} mended' : ''}',
                    style: text.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Insets.md),
            KintsugiChain(marks: log.recentMarks(28)),
            const SizedBox(height: Insets.sm),
            Text(
              chain.atRisk
                  ? 'You missed yesterday. Practise today and it\'s mended in gold.'
                  : 'Never miss twice: a single missed day is mended in gold, not lost.',
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
    final tags = urges.byTag.entries.toList()
      ..sort((a, b) => b.value.total.compareTo(a.value.total));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Insets.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Endurance patterns', style: text.titleMedium),
            const SizedBox(height: Insets.sm),
            Text(summary, style: text.bodyLarge?.copyWith(height: 1.5)),
            const SizedBox(height: Insets.md),
            trend,
            if (tags.isNotEmpty) ...[
              const SizedBox(height: Insets.lg),
              Text('Triggers', style: text.titleSmall),
              const SizedBox(height: Insets.xs),
              for (final t in tags.take(4))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Insets.xs),
                  child: Row(children: [
                    Expanded(child: Text(t.key)),
                    Text('${t.value.held} of ${t.value.total} held'),
                  ]),
                ),
            ],
            if (urges.hardestTime != null) ...[
              const SizedBox(height: Insets.md),
              Text('Hardest time: the ${urges.hardestTime}. Plan for it in your premeditatio.',
                  style: text.bodyMedium),
            ],
            const SizedBox(height: Insets.lg),
            Text('Trials by level', style: text.titleSmall),
            const SizedBox(height: Insets.xs),
            Row(children: [
              for (final l in [1, 2, 3])
                Expanded(
                  child: Column(children: [
                    Text('${byLevel[l] ?? 0}', style: text.headlineSmall),
                    Text(levelNames[l]!, style: text.bodySmall),
                  ]),
                ),
            ]),
          ],
        ),
      ),
    );
  }
}
