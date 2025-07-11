import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../providers/quote_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/notification_provider.dart';
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
                    icon: const Icon(Icons.brightness_6),
                    onPressed: () {
                      final themeProvider = context.read<ThemeProvider>();
                      themeProvider.setThemeMode(
                        themeProvider.themeMode == ThemeMode.light
                            ? ThemeMode.dark
                            : ThemeMode.light,
                      );
                    },
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
                      Consumer<QuoteProvider>(
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
                      const SizedBox(height: 32),
                      Text(
                        'Features',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.8,
                        children: [
                          _FeatureCard(
                            title: 'Meditation',
                            icon: Icons.self_improvement,
                            color: Theme.of(context).colorScheme.primary,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MeditationScreen(),
                              ),
                            ),
                          ),
                          _FeatureCard(
                            title: 'Journal',
                            icon: Icons.book,
                            color: Theme.of(context).colorScheme.secondary,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const JournalScreen(),
                              ),
                            ),
                          ),
                          _FeatureCard(
                            title: 'Binaural Beats',
                            icon: Icons.waves,
                            color: Theme.of(context).colorScheme.tertiary,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BinauralBeatsScreen(),
                              ),
                            ),
                          ),
                          _FeatureCard(
                            title: 'Focus Timer',
                            icon: Icons.timer,
                            color: Theme.of(context).colorScheme.error,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FocusScreen(),
                              ),
                            ),
                          ),
                          _FeatureCard(
                            title: 'Todo Goals',
                            icon: Icons.task_alt,
                            color: Theme.of(context).colorScheme.primary,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TodoScreen(),
                              ),
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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
      ),
    );
  }
} 