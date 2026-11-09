import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../endurance.dart';
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(Insets.lg, Insets.lg, Insets.lg, Insets.xxl),
      children: [
        FadeSlideIn(child: Text('Endure', style: text.headlineMedium)),
        const SizedBox(height: Insets.xs),
        Text('我慢: bearing what is hard, with patience and dignity.',
            style: text.bodyMedium?.copyWith(color: scheme.onSurface.withValues(alpha: 0.7))),
        const SizedBox(height: Insets.lg),
        FadeSlideIn(
          delay: const Duration(milliseconds: 60),
          child: Semantics(
            button: true,
            label: 'I have an urge',
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
                        Text('I have an urge',
                            style: text.titleLarge?.copyWith(color: scheme.onPrimary)),
                        Text(
                          todayUrges.total == 0
                              ? 'Ride it out for ten minutes before you decide.'
                              : 'Today: ${todayUrges.held} of ${todayUrges.total} held.',
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
        Text('Programs', style: text.titleLarge),
        const SizedBox(height: Insets.sm),
        const _Programs(),
        if (features.isEnabled('meditation') || features.isEnabled('binaural')) ...[
          const SizedBox(height: Insets.lg),
          Text('Tools for the hard moments', style: text.titleLarge),
          const SizedBox(height: Insets.sm),
          Card(
            child: Column(children: [
              if (features.isEnabled('meditation'))
                ListTile(
                  leading: const Icon(Icons.air),
                  title: const Text('Breathe'),
                  subtitle: const Text('A short guided sit'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const MeditationScreen())),
                ),
              if (features.isEnabled('binaural'))
                ListTile(
                  leading: const Icon(Icons.graphic_eq),
                  title: const Text('Sound'),
                  subtitle: const Text('Ambient tracks to sit or work with'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const BinauralBeatsScreen())),
                ),
            ]),
          ),
        ],
        const SizedBox(height: Insets.lg),
        Text(trialSafetyNote, style: text.bodySmall),
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
                        Expanded(child: Text(p.title, style: text.titleMedium)),
                        Text('${p.days} days', style: text.labelMedium),
                      ]),
                      const SizedBox(height: Insets.xs),
                      Text(p.blurb, style: text.bodyMedium),
                      const SizedBox(height: Insets.sm),
                      if (active && day != null) ...[
                        LinearProgressIndicator(value: day / p.days),
                        const SizedBox(height: Insets.sm),
                        Row(children: [
                          Expanded(child: Text('Day $day of ${p.days}')),
                          TextButton(
                              onPressed: settings.stopProgram,
                              child: const Text('Stop')),
                        ]),
                      ] else if (active) ...[
                        Row(children: [
                          const Icon(Icons.check_circle, color: AppColors.gold),
                          const SizedBox(width: Insets.sm),
                          const Expanded(child: Text('Completed')),
                          TextButton(
                              onPressed: settings.stopProgram,
                              child: const Text('Clear')),
                        ]),
                      ] else if (!unlocked)
                        TextButton.icon(
                          onPressed: () => PaywallScreen.show(context),
                          icon: const Icon(Icons.lock_outline),
                          label: const Text('Premium'),
                        )
                      else
                        FilledButton.tonal(
                          onPressed: () => settings.startProgram(p.id),
                          child: Text(settings.programId.isEmpty
                              ? 'Start'
                              : 'Switch to this'),
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
