import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../providers/activity_log.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/timer_ring.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

/// Seconds actually spent focused in a phase of [totalSeconds] that ends at
/// [endsAt], measured at [ref] (the moment the user left, or now). Clamped so
/// a late return can't report more than the whole phase.
int focusedSeconds({
  required int totalSeconds,
  required DateTime endsAt,
  required DateTime ref,
}) {
  final remaining = endsAt.difference(ref).inSeconds.clamp(0, totalSeconds);
  return totalSeconds - remaining;
}

class _FocusScreenState extends State<FocusScreen>
    with WidgetsBindingObserver {
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

  final _intentionController = TextEditingController();
  List<String> _todayTasks = [];
  String? _selectedTask;

  /// Wall-clock end of the running phase — the countdown is derived from this
  /// so it stays honest if the app is suspended in the background.
  DateTime? _endsAt;

  /// Set while the app is backgrounded during a focus phase.
  DateTime? _leftAt;
  bool _handlingReturn = false;

  bool get _isLongBreak =>
      _completedPomodoros % _pomodorosUntilLongBreak == 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
    _loadTodayTasks();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    WakelockPlus.disable();
    _intentionController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isPlaying || _isBreak) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _leftAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed && _leftAt != null) {
      _onReturnFromAway();
    }
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

  Future<void> _loadTodayTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final titles = <String>[];
    for (final s in prefs.getStringList('todo_tasks_$today') ?? const []) {
      try {
        final t = jsonDecode(s) as Map<String, dynamic>;
        final title = (t['title'] as String?)?.trim() ?? '';
        if (title.isNotEmpty) titles.add(title);
      } catch (_) {}
    }
    if (mounted) setState(() => _todayTasks = titles);
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pomodoro_duration', _selectedDuration);
    await prefs.setInt('completed_pomodoros', _completedPomodoros);
  }

  int get _totalSeconds =>
      (_isBreak
          ? (_isLongBreak ? _longBreakDuration : _breakDuration)
          : _selectedDuration) *
      60;

  void _startTimer() {
    HapticFeedback.selectionClick();
    if (_isPlaying) {
      // Deliberate early stop.
      if (_isBreak) {
        _resetToIdle();
      } else {
        _finishFocus(completed: false);
      }
      return;
    }
    _beginPhase();
  }

  void _beginPhase() {
    final total = _totalSeconds;
    setState(() {
      _isPlaying = true;
      _leftAt = null;
      _remainingSeconds = total;
      _endsAt = DateTime.now().add(Duration(seconds: total));
    });
    if (!_isBreak) WakelockPlus.enable();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final endsAt = _endsAt;
    if (endsAt == null) return;
    final remaining = endsAt.difference(DateTime.now()).inSeconds;
    setState(() => _remainingSeconds = remaining.clamp(0, _totalSeconds));
    if (remaining > 0) return;
    if (_leftAt != null) return; // away — resolved in _onReturnFromAway
    _timer?.cancel();
    if (_isBreak) {
      _endBreak();
    } else {
      _finishFocus(completed: true);
    }
  }

  /// Seconds actually spent focused, measured up to [_leftAt] if the user is
  /// away, otherwise up to now.
  int _focusedSoFar() {
    final endsAt = _endsAt;
    if (endsAt == null) return 0;
    return focusedSeconds(
      totalSeconds: _selectedDuration * 60,
      endsAt: endsAt,
      ref: _leftAt ?? DateTime.now(),
    );
  }

  void _finishFocus({required bool completed}) {
    _timer?.cancel();
    WakelockPlus.disable();
    final focused = completed ? _selectedDuration * 60 : _focusedSoFar();
    if (completed || focused >= 60) {
      context.read<ActivityLog>().log(
        ActivityType.focus,
        durationSeconds: focused,
        meta: {
          if (_selectedTask != null) 'task': _selectedTask,
          if (_intentionController.text.trim().isNotEmpty)
            'intention': _intentionController.text.trim(),
          if (!completed) 'abandoned': true,
        },
      );
    }
    setState(() {
      _isPlaying = false;
      _leftAt = null;
      _endsAt = null;
      if (completed) {
        _completedPomodoros++;
        _saveSettings();
        _isBreak = true;
        _remainingSeconds = _totalSeconds;
      } else {
        _remainingSeconds = _selectedDuration * 60;
      }
    });
    if (completed) {
      _dialog('Focus complete',
          'Nice work. Time for a ${_isLongBreak ? 'long' : 'short'} break.');
    }
  }

  void _endBreak() {
    WakelockPlus.disable();
    setState(() {
      _isPlaying = false;
      _isBreak = false;
      _endsAt = null;
      _remainingSeconds = _selectedDuration * 60;
    });
    _dialog('Break over', 'Ready for another focus session?');
  }

  void _resetToIdle() {
    _timer?.cancel();
    WakelockPlus.disable();
    setState(() {
      _isPlaying = false;
      _endsAt = null;
      _remainingSeconds = _totalSeconds;
    });
  }

  Future<void> _onReturnFromAway() async {
    if (_handlingReturn) return;
    _handlingReturn = true;
    final endsAt = _endsAt;
    final ranOut = endsAt != null && !DateTime.now().isBefore(endsAt);

    if (ranOut) {
      _finishFocus(completed: false); // clears _leftAt
      _handlingReturn = false;
      return;
    }

    final remaining = endsAt!.difference(DateTime.now()).inSeconds;
    if (!mounted) {
      _handlingReturn = false;
      return;
    }
    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('You left the session'),
        content: Text(
          'Your focus block is still running — ${_formatTime(remaining)} left. '
          'The clock kept going. End it now and it\'s logged as unfinished.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'end'),
            child: const Text('End session'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'resume'),
            child: const Text('Resume'),
          ),
        ],
      ),
    );
    _leftAt = null;
    _handlingReturn = false;
    if (choice == 'end') {
      _finishFocus(completed: false);
    } else {
      // Clock kept running while away; just make sure the ticker is live.
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
      _tick();
    }
  }

  void _dialog(String title, String body) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
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
      body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: Insets.xl),
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
                            : _isBreak
                                ? const SizedBox.shrink()
                                : Padding(
                                    key: const ValueKey('hint'),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: Insets.xl),
                                    child: Text(
                                      'Stay in the app. Leaving logs the session as unfinished.',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: scheme.onSurface
                                                .withOpacity(0.6),
                                          ),
                                    ),
                                  ),
                      ),
                      if (!_isPlaying && !_isBreak) ...[
                        const SizedBox(height: Insets.lg),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 360),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
                            child: Column(
                              children: [
                                if (_todayTasks.isNotEmpty)
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedTask,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Working on',
                                      isDense: true,
                                    ),
                                    items: [
                                      const DropdownMenuItem(
                                          value: null,
                                          child: Text('No specific task')),
                                      for (final t in _todayTasks)
                                        DropdownMenuItem(
                                            value: t,
                                            child: Text(t,
                                                overflow: TextOverflow.ellipsis)),
                                    ],
                                    onChanged: (v) =>
                                        setState(() => _selectedTask = v),
                                  ),
                                const SizedBox(height: Insets.sm),
                                TextField(
                                  controller: _intentionController,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  decoration: const InputDecoration(
                                    labelText: 'What will done look like?',
                                    isDense: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
    );
  }
} 