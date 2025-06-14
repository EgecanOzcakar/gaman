import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/quote_provider.dart';

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
  final int _pomodorosUntilLongBreak = 4;

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
    setState(() {
      _selectedDuration = prefs.getInt('pomodoro_duration') ?? 25;
      _completedPomodoros = prefs.getInt('completed_pomodoros') ?? 0;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pomodoro_duration', _selectedDuration);
    await prefs.setInt('completed_pomodoros', _completedPomodoros);
  }

  void _startTimer() {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Timer'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isBreak ? 'Break Time' : 'Focus Time',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _formatTime(_remainingSeconds),
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  const SizedBox(height: 24),
                  if (!_isPlaying) ...[
                    Text(
                      'Choose Duration',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _pomodoroDurations.map((minutes) {
                        return ChoiceChip(
                          label: Text('${minutes}m'),
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
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Completed Pomodoros: $_completedPomodoros',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isPlaying)
                  ElevatedButton.icon(
                    onPressed: _startTimer,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _startTimer,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(_isBreak ? 'Start Break' : 'Start Focus'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 