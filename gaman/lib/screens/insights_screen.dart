import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/activity_log.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final log = context.watch<ActivityLog>();
    final now = DateTime.now();
    final tomorrow = DateUtils.dateOnly(now).add(const Duration(days: 1));
    final thisWeek = ActivityLog.weekStart();
    final lastWeek = thisWeek.subtract(const Duration(days: 7));

    final medMin = log.minutes(ActivityType.meditation, thisWeek, tomorrow);
    final focusN = log.count(ActivityType.focus, thisWeek, tomorrow);
    final journalDays = log
        .inRange(thisWeek, tomorrow)
        .where((e) => e.type == ActivityType.journal)
        .map((e) => DateUtils.dateOnly(e.at))
        .toSet()
        .length;
    final tasksN = log.count(ActivityType.taskDone, thisWeek, tomorrow);

    return ListView(
      padding: const EdgeInsets.fromLTRB(Insets.lg, Insets.lg, Insets.lg, Insets.xxl),
      children: [
        FadeSlideIn(
          child: Text('Insights', style: Theme.of(context).textTheme.headlineMedium),
        ),
        const SizedBox(height: Insets.lg),
        FadeSlideIn(
          delay: const Duration(milliseconds: 60),
          child: _StreakCard(streak: log.currentStreak),
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
              _Stat(label: 'Meditation', value: '$medMin', unit: 'min'),
              _Stat(label: 'Focus sessions', value: '$focusN', unit: ''),
              _Stat(label: 'Journal days', value: '$journalDays', unit: 'of 7'),
              _Stat(label: 'Tasks done', value: '$tasksN', unit: ''),
            ],
          ),
        ),
        const SizedBox(height: Insets.lg),
        FadeSlideIn(
          delay: const Duration(milliseconds: 220),
          child: _WeeklyReviewCard(
            summary: _summary(medMin, focusN, journalDays, tasksN),
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

  String _summary(int medMin, int focusN, int journalDays, int tasksN) {
    if (medMin == 0 && focusN == 0 && journalDays == 0 && tasksN == 0) {
      return 'Nothing logged yet this week. Start with one small thing today.';
    }
    final parts = <String>[
      if (focusN > 0) '$focusN focus session${focusN == 1 ? '' : 's'}',
      if (medMin > 0) '$medMin minutes of meditation',
      if (journalDays > 0) 'journalled $journalDays day${journalDays == 1 ? '' : 's'}',
      if (tasksN > 0) 'finished $tasksN task${tasksN == 1 ? '' : 's'}',
    ];
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
      > 0 => (Icons.trending_up, 'more active than last week', Colors.green),
      < 0 => (Icons.trending_down, 'less active than last week', Theme.of(context).colorScheme.error),
      _ => (Icons.trending_flat, 'about the same as last week', Theme.of(context).colorScheme.onSurface),
    };
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: Insets.sm),
        Text('$thisWeekActive active day${thisWeekActive == 1 ? '' : 's'} — $text',
            style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}


class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Insets.lg),
        child: Row(
          children: [
            const Text('🔥', style: TextStyle(fontSize: 32)),
            const SizedBox(width: Insets.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$streak',
                    style: Theme.of(context).textTheme.displaySmall),
                Text(
                  streak == 0
                      ? 'No streak yet — do one thing today'
                      : 'day streak',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
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

class _WeeklyReviewCard extends StatelessWidget {
  const _WeeklyReviewCard({required this.summary, required this.trend});
  final String summary;
  final Widget trend;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Insets.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weekly review',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: Insets.sm),
            Text(summary,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5)),
            const SizedBox(height: Insets.md),
            trend,
          ],
        ),
      ),
    );
  }
}
