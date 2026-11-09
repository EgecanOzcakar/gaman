import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../endurance.dart';
import '../l10n/app_localizations.dart';
import '../providers/activity_log.dart';
import '../providers/feature_prefs.dart';
import '../providers/settings_provider.dart';
import '../services/entitlement_service.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../widgets/trial_card.dart';
import 'binaural_beats_screen.dart';
import 'meditation_screen.dart';
import 'paywall_screen.dart';
import 'urge_screen.dart';

/// The practice that makes Gaman different: enduring small hard things on
/// purpose. Urges in the moment, a trial a day, programs over weeks.
class EndureScreen extends StatelessWidget {
  const EndureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final log = context.watch<ActivityLog>();
    final todayUrges = urgeStats(log.onDay(DateTime.now()));
    final features = context.watch<FeaturePrefs>();
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(Insets.lg, Insets.lg, Insets.lg, Insets.xxl),
      children: [
        FadeSlideIn(child: Text(l10n.navEndure, style: text.headlineMedium)),
        const SizedBox(height: Insets.xs),
        Text(l10n.endureSubtitle,
            style: text.bodyMedium?.copyWith(color: scheme.onSurface.withValues(alpha: 0.7))),
        const SizedBox(height: Insets.lg),
        FadeSlideIn(
          delay: const Duration(milliseconds: 60),
          child: Semantics(
            button: true,
            label: l10n.urgeButton,
            excludeSemantics: true,
            child: PressScale(
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const UrgeScreen())),
            child: Container(
              padding: const EdgeInsets.all(Insets.lg),
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(Radii.card),
              ),
              child: Row(
                children: [
                  Icon(Icons.waves, color: scheme.onPrimary, size: 36),
                  const SizedBox(width: Insets.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.urgeButton,
                            style: text.titleLarge?.copyWith(color: scheme.onPrimary)),
                        Text(
                          todayUrges.total == 0
                              ? l10n.urgeButtonEmpty
                              : l10n.urgeButtonToday(todayUrges.held, todayUrges.total),
                          style: text.bodyMedium?.copyWith(color: scheme.onPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          ),
        ),
        const SizedBox(height: Insets.lg),
        const FadeSlideIn(delay: Duration(milliseconds: 120), child: TrialCard()),
        const SizedBox(height: Insets.lg),
        Text(l10n.programsTitle, style: text.titleLarge),
        const SizedBox(height: Insets.sm),
        const _Programs(),
        if (features.isEnabled('meditation') || features.isEnabled('binaural')) ...[
          const SizedBox(height: Insets.lg),
          Text(l10n.toolsTitle, style: text.titleLarge),
          const SizedBox(height: Insets.sm),
          Card(
            child: Column(children: [
              if (features.isEnabled('meditation'))
                ListTile(
                  leading: const Icon(Icons.air),
                  title: Text(l10n.toolBreathe),
                  subtitle: Text(l10n.toolBreatheBody),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const MeditationScreen())),
                ),
              if (features.isEnabled('binaural'))
                ListTile(
                  leading: const Icon(Icons.graphic_eq),
                  title: Text(l10n.toolSound),
                  subtitle: Text(l10n.toolSoundBody),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const BinauralBeatsScreen())),
                ),
            ]),
          ),
        ],
        const SizedBox(height: Insets.lg),
        Text(l10n.trialSafetyNote, style: text.bodySmall),
      ],
    );
  }
}

class _Programs extends StatelessWidget {
  const _Programs();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final unlocked = context.watch<EntitlementService>().has(PremiumFeature.programs);
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();

    return Column(
      children: [
        for (final p in programs)
          Padding(
            padding: const EdgeInsets.only(bottom: Insets.sm),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(Insets.md),
                child: Builder(builder: (context) {
                  final active = settings.programId == p.id;
                  final started = settings.programStartedOn;
                  final day = active && started != null
                      ? programDay(p, started, now)
                      : null;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(child: Text(l10n.programTitle(p.id), style: text.titleMedium)),
                        Text(l10n.programDays(p.days), style: text.labelMedium),
                      ]),
                      const SizedBox(height: Insets.xs),
                      Text(l10n.programBlurb(p.id), style: text.bodyMedium),
                      const SizedBox(height: Insets.sm),
                      if (active && day != null) ...[
                        LinearProgressIndicator(value: day / p.days),
                        const SizedBox(height: Insets.sm),
                        Row(children: [
                          Expanded(child: Text(l10n.programDayOf(day, p.days))),
                          TextButton(
                              onPressed: settings.stopProgram,
                              child: Text(l10n.programStop)),
                        ]),
                      ] else if (active) ...[
                        Row(children: [
                          Icon(Icons.check_circle, color: AppColors.gold(context)),
                          const SizedBox(width: Insets.sm),
                          Expanded(child: Text(l10n.programCompleted)),
                          TextButton(
                              onPressed: settings.stopProgram,
                              child: Text(l10n.programClear)),
                        ]),
                      ] else if (!unlocked)
                        TextButton.icon(
                          onPressed: () => PaywallScreen.show(context),
                          icon: const Icon(Icons.lock_outline),
                          label: Text(l10n.programPremium),
                        )
                      else
                        FilledButton.tonal(
                          onPressed: () => settings.startProgram(p.id),
                          child: Text(settings.programId.isEmpty
                              ? l10n.programStart
                              : l10n.programSwitch),
                        ),
                    ],
                  );
                }),
              ),
            ),
          ),
      ],
    );
  }
}
