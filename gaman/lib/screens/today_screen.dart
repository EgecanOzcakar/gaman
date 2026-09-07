import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../providers/activity_log.dart';
import '../providers/quote_provider.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import 'binaural_beats_screen.dart';
import 'meditation_screen.dart';
import 'todo_screen.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  Future<String?> _loadFrog() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    for (final s in prefs.getStringList('todo_tasks_$today') ?? const []) {
      try {
        final t = jsonDecode(s) as Map<String, dynamic>;
        if (t['isMainTask'] == true &&
            (t['title'] as String?)?.trim().isNotEmpty == true) {
          return t['title'] as String;
        }
      } catch (_) {}
    }
    return null;
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final streak = context.watch<ActivityLog>().currentStreak;

    return ListView(
      padding: const EdgeInsets.fromLTRB(Insets.lg, Insets.lg, Insets.lg, Insets.xxl),
      children: [
        FadeSlideIn(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_greeting, style: Theme.of(context).textTheme.headlineMedium),
              if (streak > 0) _StreakChip(streak: streak),
            ],
          ),
        ),
        const SizedBox(height: Insets.lg),
        const FadeSlideIn(delay: Duration(milliseconds: 60), child: _QuoteCard()),
        const SizedBox(height: Insets.lg),
        FadeSlideIn(
          delay: const Duration(milliseconds: 120),
          child: FutureBuilder<String?>(
            future: _loadFrog(),
            builder: (context, snap) => _FrogCard(
              frog: snap.data,
              onOpen: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const TodoScreen()));
                setState(() {}); // refresh the frog after editing
              },
            ),
          ),
        ),
        const SizedBox(height: Insets.lg),
        FadeSlideIn(
          delay: const Duration(milliseconds: 180),
          child: Text('Begin', style: Theme.of(context).textTheme.titleLarge),
        ),
        const SizedBox(height: Insets.md),
        FadeSlideIn(
          delay: const Duration(milliseconds: 220),
          child: Row(
            children: [
              _QuickAction(
                label: 'Meditate',
                icon: Icons.self_improvement,
                color: Theme.of(context).colorScheme.primary,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const MeditationScreen())),
              ),
              const SizedBox(width: Insets.md),
              _QuickAction(
                label: 'Binaural',
                icon: Icons.graphic_eq,
                color: Theme.of(context).colorScheme.tertiary,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const BinauralBeatsScreen())),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Insets.sm, vertical: Insets.xs),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 14)),
          const SizedBox(width: Insets.xs),
          Text(
            '$streak day${streak == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
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
                  '— ${quote.author}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FrogCard extends StatelessWidget {
  const _FrogCard({required this.frog, required this.onOpen});
  final String? frog;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(Radii.card),
        child: Padding(
          padding: const EdgeInsets.all(Insets.md),
          child: Row(
            children: [
              const Text('🐸', style: TextStyle(fontSize: 24)),
              const SizedBox(width: Insets.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Today\'s most important task',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            )),
                    const SizedBox(height: 2),
                    Text(
                      frog ?? 'Not set — tap to choose one',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: PressScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: Insets.lg),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(Radii.card),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: Insets.sm),
              Text(label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      )),
            ],
          ),
        ),
      ),
    );
  }
}
