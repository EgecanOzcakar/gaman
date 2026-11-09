import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../data/models.dart';
import '../data/repository.dart';
import '../endurance.dart';
import '../journal_templates.dart';
import '../l10n/app_localizations.dart';
import '../providers/activity_log.dart';
import '../providers/feature_prefs.dart';
import '../providers/quote_provider.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../widgets/kintsugi_chain.dart';
import '../widgets/trial_card.dart';
import 'journal_prompt_screen.dart';
import 'settings_screen.dart';

/// The daily loop: morning premeditatio, today's trial, one task that
/// matters, evening review.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final log = context.watch<ActivityLog>();
    final chain = log.chain;
    final features = context.watch<FeaturePrefs>();
    final now = DateTime.now();
    final urges = urgeStats(log.onDay(now));
    final trial = log.trialOn(now);
    final text = Theme.of(context).textTheme;

    final eveningBits = <String>[
      if (urges.total > 0) '${urges.held} of ${urges.total} urges held',
      if (trial.id != null) trial.done ? 'trial done' : 'trial still open',
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(Insets.lg, Insets.md, Insets.lg, Insets.xxl),
      children: [
        FadeSlideIn(
          child: Row(
            children: [
              Expanded(child: Text(_greeting, style: text.headlineMedium)),
              IconButton(
                tooltip: AppLocalizations.of(context).navSettings,
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen())),
              ),
            ],
          ),
        ),
        const SizedBox(height: Insets.sm),
        FadeSlideIn(
          delay: const Duration(milliseconds: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (chain.days > 0 || chain.atRisk)
                ChainChip(days: chain.days, mended: chain.mended, atRisk: chain.atRisk),
              const SizedBox(height: Insets.sm),
              KintsugiChain(marks: log.recentMarks(14), height: 14),
            ],
          ),
        ),
        const SizedBox(height: Insets.lg),
        const FadeSlideIn(delay: Duration(milliseconds: 60), child: _QuoteCard()),
        const SizedBox(height: Insets.lg),
        Text('Today\'s practice', style: text.titleLarge),
        const SizedBox(height: Insets.md),
        if (features.isEnabled('journal')) ...[
          _StepCard(
            icon: Icons.wb_sunny_outlined,
            title: 'Morning: premeditatio',
            subtitle: 'What could go wrong today, and how will you meet it?',
            done: log.wroteTemplateOn(now, 'premeditatio'),
            onTap: () => writeFromTemplate(context, templateById('premeditatio')!),
          ),
          const SizedBox(height: Insets.md),
        ],
        const TrialCard(),
        if (features.isEnabled('todo')) ...[
          const SizedBox(height: Insets.md),
          const _OneTaskCard(),
        ],
        if (features.isEnabled('journal')) ...[
          const SizedBox(height: Insets.md),
          _StepCard(
            icon: Icons.nightlight_outlined,
            title: 'Evening review',
            subtitle: eveningBits.isEmpty
                ? 'What went well, what could be better, what was left undone.'
                : 'Today: ${eveningBits.join(' · ')}.',
            done: log.wroteTemplateOn(now, 'evening'),
            onTap: () => writeFromTemplate(context, templateById('evening')!),
          ),
        ],
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.done,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: Insets.md, vertical: Insets.xs),
          leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: done
              ? const Icon(Icons.check_circle, color: AppColors.gold, semanticLabel: 'Done')
              : const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
}

/// The one task that matters today (the old "eat the frog" main task).
class _OneTaskCard extends StatefulWidget {
  const _OneTaskCard();

  @override
  State<_OneTaskCard> createState() => _OneTaskCardState();
}

class _OneTaskCardState extends State<_OneTaskCard> {
  late final Stream<List<TodoTask>> _tasks =
      context.read<Repository>().watchTasks(DateTime.now());

  static TodoTask? _main(List<TodoTask> tasks) {
    for (final t in tasks) {
      if (t.isMainTask) return t;
    }
    return null;
  }

  Future<void> _edit(BuildContext context, List<TodoTask> tasks) async {
    final current = _main(tasks);
    final controller = TextEditingController(text: current?.title ?? '');
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('The one task that matters today'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Do the hard thing first'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();
    if (title == null || !context.mounted) return;
    final now = DateTime.now();
    final next = [
      for (final t in tasks) if (!t.isMainTask) t,
      TodoTask(
        id: current?.id ?? 'main_${now.millisecondsSinceEpoch}',
        title: title.trim(),
        isMainTask: true,
        isCompleted: current?.isCompleted ?? false,
        createdAt: current?.createdAt ?? now,
      ),
    ];
    await context.read<Repository>().saveTasks(now, next);
  }

  Future<void> _toggle(BuildContext context, List<TodoTask> tasks, TodoTask task) async {
    task.isCompleted = !task.isCompleted;
    HapticFeedback.selectionClick();
    if (task.isCompleted) {
      context.read<ActivityLog>().log(ActivityType.taskDone,
          meta: {'title': task.title, 'frog': true});
    }
    await context.read<Repository>().saveTasks(DateTime.now(), tasks);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TodoTask>>(
      stream: _tasks,
      builder: (context, snap) {
        final tasks = snap.data ?? const <TodoTask>[];
        final main = _main(tasks);
        final hasTask = main != null && main.title.isNotEmpty;
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: Insets.md, vertical: Insets.xs),
            leading: hasTask
                ? Checkbox(
                    value: main.isCompleted,
                    onChanged: (_) => _toggle(context, [...tasks], main),
                  )
                : Icon(Icons.flag_outlined, color: Theme.of(context).colorScheme.primary),
            title: Text(hasTask ? main.title : 'One task that matters'),
            subtitle: Text(hasTask ? 'Tap to change' : 'Not set. Tap to choose it.'),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () => _edit(context, tasks),
          ),
        );
      },
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard();

  @override
  Widget build(BuildContext context) {
    return Consumer<QuoteProvider>(
      builder: (context, provider, _) {
        final quote = provider.currentQuote;
        if (quote == null) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(Insets.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(Insets.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quote.text,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(height: 1.5),
                ),
                const SizedBox(height: Insets.sm),
                Text(
                  '— ${quote.author}, ${quote.source}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                Text(
                  AppLocalizations.of(context).translatedBy(quote.translator),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
