import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../endurance.dart';
import '../l10n/app_localizations.dart';
import '../providers/activity_log.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

/// Today's trial: pick one small discomfort in the morning, confirm it in the
/// evening. Follows the active program when there is one.
class TrialCard extends StatelessWidget {
  const TrialCard({super.key});

  @override
  Widget build(BuildContext context) {
    final log = context.watch<ActivityLog>();
    final settings = context.watch<SettingsProvider>();
    final today = DateTime.now();
    final state = log.trialOn(today);
    final chosen = trialById(state.id);
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    final program = programById(settings.programId);
    final started = settings.programStartedOn;
    final day = (program != null && started != null)
        ? programDay(program, started, today)
        : null;
    final suggested = day == null ? null : program!.trialForDay(day);

    void choose(Trial t) {
      HapticFeedback.selectionClick();
      log.log(ActivityType.trial, meta: {
        'id': t.id,
        'status': 'chosen',
        if (t.id == suggested?.id) 'program': program!.id,
      });
    }

    final List<Widget> body;
    if (chosen == null) {
      body = [
        if (suggested != null) ...[
          Text(l10n.trialProgramDay(day!, l10n.programTitle(program!.id)),
              style: text.labelMedium),
          const SizedBox(height: Insets.xs),
          Text(l10n.trialTitle(suggested.id), style: text.titleMedium),
          _Caution(suggested),
          const SizedBox(height: Insets.md),
          Row(children: [
            FilledButton(
                onPressed: () => choose(suggested), child: Text(l10n.trialAccept)),
            const SizedBox(width: Insets.sm),
            TextButton(
                onPressed: () => _pick(context, choose),
                child: Text(l10n.trialChooseAnother)),
          ]),
        ] else ...[
          Text(l10n.trialEmptyBody, style: text.bodyMedium),
          const SizedBox(height: Insets.md),
          FilledButton.tonal(
              onPressed: () => _pick(context, choose),
              child: Text(l10n.trialChoose)),
        ],
      ];
    } else {
      body = [
        Text(l10n.trialLevelLabel(l10n.levelName(chosen.level)),
            style: text.labelMedium),
        const SizedBox(height: Insets.xs),
        Text(l10n.trialTitle(chosen.id), style: text.titleMedium),
        _Caution(chosen),
        const SizedBox(height: Insets.md),
        if (state.done)
          Row(children: [
            const Icon(Icons.check_circle, color: AppColors.gold),
            const SizedBox(width: Insets.sm),
            Text(l10n.trialDoneLabel, style: text.titleSmall),
          ])
        else
          Row(children: [
            FilledButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                log.log(ActivityType.trial, meta: {
                  'id': chosen.id,
                  'status': 'done',
                  'level': chosen.level,
                });
              },
              child: Text(l10n.trialIDidIt),
            ),
            const SizedBox(width: Insets.sm),
            TextButton(
                onPressed: () => _pick(context, choose),
                child: Text(l10n.trialChange)),
          ]),
      ];
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Insets.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.terrain_outlined, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: Insets.sm),
              Text(l10n.trialCardTitle, style: text.titleSmall),
            ]),
            const SizedBox(height: Insets.sm),
            ...body,
          ],
        ),
      ),
    );
  }

  static Future<void> _pick(BuildContext context, void Function(Trial) onPick) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (ctx) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          builder: (ctx, scroll) {
            final l10n = AppLocalizations.of(ctx);
            return ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(Insets.md, 0, Insets.md, Insets.lg),
            children: [
              Text(l10n.trialSafetyNote, style: Theme.of(ctx).textTheme.bodySmall),
              for (final level in [1, 2, 3]) ...[
                const SizedBox(height: Insets.md),
                Text(l10n.levelName(level), style: Theme.of(ctx).textTheme.titleMedium),
                for (final t in trials.where((t) => t.level == level))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.trialTitle(t.id)),
                    subtitle: t.cold ? Text(l10n.trialColdCaution) : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      onPick(t);
                    },
                  ),
              ],
            ],
          );
          },
        ),
      );
}

class _Caution extends StatelessWidget {
  const _Caution(this.trial);
  final Trial trial;

  @override
  Widget build(BuildContext context) => !trial.cold
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: Insets.xs),
          child: Text(AppLocalizations.of(context).trialColdCaution,
              style: Theme.of(context).textTheme.bodySmall),
        );
}
