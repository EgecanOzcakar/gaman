import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../widgets/persistent_audio_control.dart';
import 'focus_screen.dart';
import 'insights_screen.dart';
import 'journal_screen.dart';
import 'settings_screen.dart';
import 'today_screen.dart';

/// The app's home after the splash: five tabs plus the persistent audio bar,
/// which now lives here once instead of being stacked into every screen.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index = widget.initialIndex;

  static const _tabs = [
    TodayScreen(),
    JournalScreen(),
    FocusScreen(),
    InsightsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _index, children: _tabs),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PersistentAudioControl(),
          NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: [
              NavigationDestination(
                  icon: const Icon(Icons.wb_sunny_outlined),
                  selectedIcon: const Icon(Icons.wb_sunny),
                  label: l10n.navToday),
              NavigationDestination(
                  icon: const Icon(Icons.edit_note_outlined),
                  selectedIcon: const Icon(Icons.edit_note),
                  label: l10n.navJournal),
              NavigationDestination(
                  icon: const Icon(Icons.timelapse_outlined),
                  selectedIcon: const Icon(Icons.timelapse),
                  label: l10n.navFocus),
              NavigationDestination(
                  icon: const Icon(Icons.insights_outlined),
                  selectedIcon: const Icon(Icons.insights),
                  label: l10n.navInsights),
              NavigationDestination(
                  icon: const Icon(Icons.settings_outlined),
                  selectedIcon: const Icon(Icons.settings),
                  label: l10n.navSettings),
            ],
          ),
        ],
      ),
    );
  }
}
