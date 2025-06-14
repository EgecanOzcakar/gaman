import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quote_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/notification_provider.dart';
import 'meditation_screen.dart';
import 'journal_screen.dart';
import 'binaural_beats_screen.dart';
import 'focus_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Gaman'),
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
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  final notificationProvider =
                      context.read<NotificationProvider>();
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Daily Reflection'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Notifications are currently ${notificationProvider.isEnabled ? 'enabled' : 'disabled'}',
                          ),
                          if (notificationProvider.scheduledTime != null)
                            Text(
                              'Next notification at: ${notificationProvider.scheduledTime!.format(context)}',
                            ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            notificationProvider.toggleNotifications(
                              !notificationProvider.isEnabled,
                            );
                            Navigator.pop(context);
                          },
                          child: Text(
                            notificationProvider.isEnabled
                                ? 'Disable Notifications'
                                : 'Enable Notifications',
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            notificationProvider.rescheduleNotification();
                            Navigator.pop(context);
                          },
                          child: const Text('Reschedule'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
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
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Daily Quote',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                quote.text,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '- ${quote.author}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Features',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      _FeatureCard(
                        title: 'Meditation',
                        icon: Icons.self_improvement,
                        color: Colors.blue,
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
                        color: Colors.green,
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
                        color: Colors.purple,
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
                        color: Colors.orange,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FocusScreen(),
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.7),
                color,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Colors.white,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 