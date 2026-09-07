import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/activity_log.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/persistent_audio_control.dart';
import '../widgets/timer_ring.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isPlaying = false;
  bool _isBreak = false;
  int _completedPomodoros = 0;
  int _selectedDuration = 25; // Default Pomodoro duration in minutes

  final List<int> _pomodoroDurations = [15, 25, 30, 45, 60];
  final int _breakDuration = 5; // Short break duration in minutes
  final int _longBreakDuration = 15; // Long break duration in minutes

  int get _pomodorosUntilLongBreak =>
      context.read<SettingsProvider>().longBreakEvery;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _selectedDuration = prefs.getInt('pomodoro_duration') ??
          context.read<SettingsProvider>().focusMinutes;
      _completedPomodoros = prefs.getInt('completed_pomodoros') ?? 0;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pomodoro_duration', _selectedDuration);
    await prefs.setInt('completed_pomodoros', _completedPomodoros);
  }

  int get _totalSeconds =>
      (_isBreak
          ? (_completedPomodoros % _pomodorosUntilLongBreak == 0
              ? _longBreakDuration
              : _breakDuration)
          : _selectedDuration) *
      60;

  void _startTimer() {
    HapticFeedback.selectionClick();
    if (_isPlaying) {
      _timer?.cancel();
      setState(() => _isPlaying = false);
      return;
    }

    setState(() {
      _isPlaying = true;
      _remainingSeconds = (_isBreak ? _breakDuration : _selectedDuration) * 60;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          _handleTimerComplete();
        }
      });
    });
  }

  void _handleTimerComplete() {
    if (!_isBreak) {
      context.read<ActivityLog>().log(ActivityType.focus,
          durationSeconds: _selectedDuration * 60);
    }
    setState(() {
      _isPlaying = false;
      if (!_isBreak) {
        _completedPomodoros++;
        _saveSettings();
        _isBreak = true;
        _remainingSeconds = _completedPomodoros % _pomodorosUntilLongBreak == 0
            ? _longBreakDuration * 60
            : _breakDuration * 60;
      } else {
        _isBreak = false;
        _remainingSeconds = _selectedDuration * 60;
      }
    });

    _showCompletionDialog();
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isBreak ? 'Break Time!' : 'Focus Session Complete!'),
        content: Text(
          _isBreak
              ? 'Take a ${_completedPomodoros % _pomodorosUntilLongBreak == 0 ? 'long' : 'short'} break.'
              : 'Great job! You\'ve completed another focus session.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final displaySeconds =
        (_isPlaying || _remainingSeconds > 0) ? _remainingSeconds : _totalSeconds;
    final ringColor = _isBreak ? scheme.tertiary : scheme.primary;
    final progress =
        _totalSeconds == 0 ? 0.0 : 1 - (displaySeconds / _totalSeconds);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Timer'),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isBreak ? 'Rest' : 'Focus',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: ringColor,
                              letterSpacing: 1,
                            ),
                      ),
                      const SizedBox(height: Insets.xl),
                      TimerRing(
                        progress: progress,
                        color: ringColor,
                        child: Text(
                          _formatTime(displaySeconds),
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                      ),
                      const SizedBox(height: Insets.xl),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: !_isPlaying
                            ? Wrap(
                                key: const ValueKey('chips'),
                                spacing: Insets.sm,
                                runSpacing: Insets.sm,
                                children: _pomodoroDurations.map((minutes) {
                                  return ChoiceChip(
                                    label: Text('$minutes min'),
                                    selected: _selectedDuration == minutes,
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() {
                                          _selectedDuration = minutes;
                                          _remainingSeconds = minutes * 60;
                                        });
                                        _saveSettings();
                                      }
                                    },
                                  );
                                }).toList(),
                              )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(height: Insets.lg),
                      Text(
                        '$_completedPomodoros session${_completedPomodoros == 1 ? '' : 's'} completed',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurface.withOpacity(0.6),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(Insets.md),
                child: FilledButton.icon(
                  onPressed: _startTimer,
                  icon: Icon(_isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded),
                  label: Text(_isPlaying
                      ? 'Stop'
                      : _isBreak
                          ? 'Start rest'
                          : 'Start focus'),
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