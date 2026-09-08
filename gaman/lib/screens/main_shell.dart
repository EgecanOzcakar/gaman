import 'package:flutter/material.dart';
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
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.wb_sunny_outlined),
                  selectedIcon: Icon(Icons.wb_sunny),
                  label: 'Today'),
              NavigationDestination(
                  icon: Icon(Icons.edit_note_outlined),
                  selectedIcon: Icon(Icons.edit_note),
                  label: 'Journal'),
              NavigationDestination(
                  icon: Icon(Icons.timelapse_outlined),
                  selectedIcon: Icon(Icons.timelapse),
                  label: 'Focus'),
              NavigationDestination(
                  icon: Icon(Icons.insights_outlined),
                  selectedIcon: Icon(Icons.insights),
                  label: 'Insights'),
              NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: 'Settings'),
            ],
          ),
        ],
      ),
    );
  }
}
