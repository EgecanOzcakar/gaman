import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../providers/quote_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../widgets/persistent_audio_control.dart';
import 'meditation_screen.dart';
import 'journal_screen.dart';
import 'binaural_beats_screen.dart';
import 'focus_screen.dart';
import 'todo_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasShownReminder = false;

  @override
  void initState() {
    super.initState();
    _checkAndShowReminder();
  }

  Future<void> _checkAndShowReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastReminderDate = prefs.getString('last_todo_reminder_date');
    
    if (lastReminderDate != today && !_hasShownReminder) {
      _hasShownReminder = true;
      await prefs.setString('last_todo_reminder_date', today);
      
      // Show reminder after a short delay to ensure the screen is loaded
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _showTodoReminder();
        }
      });
    }
  }

  void _showTodoReminder() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.task_alt,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('Set Your Daily Goals'),
          ],
        ),
        content: const Text(
          'Take a moment to set your "eat the frog" task and three smaller tasks for today. This will help you stay focused and productive!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TodoScreen(),
                ),
              );
            },
            child: const Text('Set Goals Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar.large(
                title: const Text('Gaman'),
                floating: true,
                actions: [
                  IconButton(
                    icon: Icon(
                      context.watch<ThemeProvider>().isDarkMode
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                    ),
                    onPressed: () => context.read<ThemeProvider>().toggle(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeSlideIn(
                       child: Consumer<QuoteProvider>(
                        builder: (context, quoteProvider, child) {
                          final quote = quoteProvider.currentQuote;
                          if (quote == null) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24.0),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  Theme.of(context).colorScheme.primary.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Stack(
                              children: [
                                if (quote.authorImageUrl != null)
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: Opacity(
                                        opacity: 0.1,
                                        child: CachedNetworkImage(
                                          imageUrl: quote.authorImageUrl!,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => const SizedBox(),
                                          errorWidget: (context, url, error) => const SizedBox(),
                                        ),
                                      ),
                                    ),
                                  ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.format_quote,
                                              color: Theme.of(context).colorScheme.primary,
                                              size: 32,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Daily Quote',
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                color: Theme.of(context).colorScheme.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.share,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                          onPressed: () {
                                            Share.share(
                                              '${quote.text}\n\n- ${quote.author}\n\nShared from Gaman App',
                                              subject: 'Daily Stoic Quote',
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      quote.text,
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        height: 1.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '- ${quote.author}',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontStyle: FontStyle.italic,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                        if (quote.authorImageUrl != null)
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundImage: CachedNetworkImageProvider(quote.authorImageUrl!),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                       ),
                      ),
                      const SizedBox(height: Insets.xl),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 90),
                        child: Text(
                          'Practices',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(height: Insets.md),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        mainAxisSpacing: Insets.md,
                        crossAxisSpacing: Insets.md,
                        childAspectRatio: 0.8,
                        children: [
                          for (final (i, f) in <_Feature>[
                            _Feature('Meditation', Icons.self_improvement,
                                Theme.of(context).colorScheme.primary,
                                () => const MeditationScreen()),
                            _Feature('Journal', Icons.edit_note,
                                Theme.of(context).colorScheme.secondary,
                                () => const JournalScreen()),
                            _Feature('Binaural Beats', Icons.graphic_eq,
                                Theme.of(context).colorScheme.tertiary,
                                () => const BinauralBeatsScreen()),
                            _Feature('Focus Timer', Icons.timelapse,
                                Theme.of(context).colorScheme.error,
                                () => const FocusScreen()),
                            _Feature('Daily Goals', Icons.flag_outlined,
                                Theme.of(context).colorScheme.primary,
                                () => const TodoScreen()),
                          ].indexed)
                            FadeSlideIn(
                              delay: Duration(milliseconds: 140 + i * 70),
                              child: _FeatureCard(
                                title: f.title,
                                icon: f.icon,
                                color: f.color,
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => f.screen())),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Persistent Audio Control at the bottom
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: PersistentAudioControl(),
          ),
        ],
      ),
    );
  }
}

class _Feature {
  const _Feature(this.title, this.icon, this.color, this.screen);
  final String title;
  final IconData icon;
  final Color color;
  final Widget Function() screen;
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Insets.md),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(Radii.card),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: Insets.sm),
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
} 