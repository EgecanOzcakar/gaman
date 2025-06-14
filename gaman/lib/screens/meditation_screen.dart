import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class MeditationScreen extends StatefulWidget {
  const MeditationScreen({super.key});

  @override
  State<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isPlaying = false;
  bool _isBreathing = false;

  final List<int> _presetDurations = [5, 10, 15, 20, 30];

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _breathingAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _breathingController,
        curve: Curves.easeInOut,
      ),
    );

    _breathingController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _breathingController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _breathingController.forward();
      }
    });
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startTimer(int minutes) {
    setState(() {
      _remainingSeconds = minutes * 60;
      _isPlaying = true;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _stopTimer();
        }
      });
    });
  }

  void _stopTimer() {
    setState(() {
      _isPlaying = false;
      _isBreathing = false;
      _breathingController.stop();
    });
    _timer?.cancel();
  }

  void _toggleBreathing() {
    setState(() {
      _isBreathing = !_isBreathing;
      if (_isBreathing) {
        _breathingController.forward();
      } else {
        _breathingController.stop();
        _breathingController.reset();
      }
    });
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
        title: const Text('Meditation'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: _breathingAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isBreathing ? _breathingAnimation.value : 1.0,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _isPlaying ? _formatTime(_remainingSeconds) : '00:00',
                          style: Theme.of(context).textTheme.displayLarge,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (!_isPlaying) ...[
                  Text(
                    'Choose Duration',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _presetDurations.map((minutes) {
                      return ElevatedButton(
                        onPressed: () => _startTimer(minutes),
                        child: Text('${minutes}m'),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isPlaying)
                      ElevatedButton.icon(
                        onPressed: _stopTimer,
                        icon: const Icon(Icons.stop),
                        label: const Text('Stop'),
                      ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _toggleBreathing,
                      icon: Icon(_isBreathing ? Icons.pause : Icons.play_arrow),
                      label: Text(_isBreathing ? 'Stop Breathing' : 'Start Breathing'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isBreathing
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        foregroundColor: _isBreathing
                            ? Theme.of(context).colorScheme.onPrimary
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 