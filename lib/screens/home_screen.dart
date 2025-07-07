import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/quote_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/error_handling_image.dart';
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
                                  child: ErrorHandlingImage(
                                    imageUrl: quote.authorImageUrl!,
                                    fit: BoxFit.cover,
                                    opacity: 0.1,
                                    placeholder: const SizedBox(),
                                  ),
                                ),
                              ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Daily Quote',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.refresh),
                                          onPressed: () => quoteProvider.fetchNewQuote(),
                                          tooltip: 'New Quote',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.share),
                                          onPressed: () {
                                            Share.share(
                                              '${quote.text}\n\n- ${quote.author}',
                                              subject: 'Daily Stoic Quote',
                                            );
                                          },
                                          tooltip: 'Share Quote',
                                        ),
                                      ],
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
                                        child: ErrorHandlingImage(
                                          imageUrl: quote.authorImageUrl!,
                                          isAvatar: true,
                                          width: 32,
                                          height: 32,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
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
                  // Rest of the existing code...
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 