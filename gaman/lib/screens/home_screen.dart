import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
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
          padding: const EdgeInsets.all(20),
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
                size: 40,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
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