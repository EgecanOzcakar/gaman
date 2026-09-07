import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/persistent_audio_control.dart';

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
  String _cue = 'Breathe in';

  late final List<int> _presetDurations;

  @override
  void initState() {
    super.initState();
    final defaultMinutes = context.read<SettingsProvider>().meditationMinutes;
    _presetDurations = {5, 10, 15, 20, 30, defaultMinutes}.toList()..sort();
    _breathingController = AnimationController(
      duration: Duration(seconds: context.read<SettingsProvider>().breathSeconds),
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
        if (mounted) setState(() => _cue = 'Breathe out');
        HapticFeedback.lightImpact();
      } else if (status == AnimationStatus.dismissed) {
        _breathingController.forward();
        if (mounted) setState(() => _cue = 'Breathe in');
        HapticFeedback.lightImpact();
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
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _breathingAnimation,
                    builder: (context, child) {
                      final scheme = Theme.of(context).colorScheme;
                      return Transform.scale(
                        scale: _isBreathing ? _breathingAnimation.value : 1.0,
                        child: Container(
                          width: 220,
                          height: 220,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: scheme.primary.withOpacity(0.10),
                            border: Border.all(color: scheme.primary, width: 2),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              _isBreathing
                                  ? _cue
                                  : _isPlaying
                                      ? _formatTime(_remainingSeconds)
                                      : 'Be still',
                              key: ValueKey(_isBreathing
                                  ? _cue
                                  : _isPlaying
                                      ? 'time'
                                      : 'still'),
                              style: Theme.of(context).textTheme.headlineSmall,
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
                        'Set a duration',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: Insets.md),
                      Wrap(
                        spacing: Insets.sm,
                        runSpacing: Insets.sm,
                        alignment: WrapAlignment.center,
                        children: _presetDurations.map((minutes) {
                          return ActionChip(
                            label: Text('$minutes min'),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              _startTimer(minutes);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: Insets.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isPlaying) ...[
                          OutlinedButton.icon(
                            onPressed: _stopTimer,
                            icon: const Icon(Icons.stop_rounded),
                            label: const Text('Stop'),
                          ),
                          const SizedBox(width: Insets.md),
                        ],
                        _isBreathing
                            ? FilledButton.icon(
                                onPressed: _toggleBreathing,
                                icon: const Icon(Icons.pause_rounded),
                                label: const Text('Pause breathing'),
                              )
                            : FilledButton.tonalIcon(
                                onPressed: _toggleBreathing,
                                icon: const Icon(Icons.air_rounded),
                                label: const Text('Guide my breath'),
                              ),
                      ],
                    ),
                  ],
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