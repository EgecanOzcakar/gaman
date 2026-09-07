import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../screens/binaural_beats_screen.dart';
import '../theme/motion.dart';

class PersistentAudioControl extends StatelessWidget {
  const PersistentAudioControl({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        final active = audioProvider.hasActiveAudio;
        return AnimatedSlide(
          offset: active ? Offset.zero : const Offset(0, 1),
          duration: Motion.reduced(context) ? Duration.zero : Motion.base,
          curve: Motion.curve,
          child: AnimatedOpacity(
            opacity: active ? 1 : 0,
            duration: Motion.reduced(context) ? Duration.zero : Motion.base,
            child: !active
                ? const SizedBox(width: double.infinity)
                : _bar(context, audioProvider),
          ),
        );
      },
    );
  }

  Widget _bar(BuildContext context, AudioProvider audioProvider) {
    return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Audio Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.waves,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Beat Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          audioProvider.currentBeat!.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${audioProvider.currentBeat!.frequency} Hz',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Volume Slider
                  SizedBox(
                    width: 80,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                        activeTrackColor: Theme.of(context).colorScheme.primary,
                        inactiveTrackColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        thumbColor: Theme.of(context).colorScheme.primary,
                        overlayColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      ),
                      child: Slider(
                        value: audioProvider.volume,
                        onChanged: (value) {
                          // Immediate feedback - no debouncing for UI
                          audioProvider.setVolume(value);
                        },
                        onChangeStart: (value) {
                          // Optional: Add haptic feedback or visual indicator
                        },
                        onChangeEnd: (value) {
                          // Optional: Add completion feedback
                        },
                        min: 0.0,
                        max: 1.0,
                        divisions: 20, // More granular control
                      ),
                    ),
                  ),
                  
                  IconButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      if (audioProvider.isPlaying) {
                        audioProvider.pause();
                      } else {
                        audioProvider.resume();
                      }
                    },
                    color: Theme.of(context).colorScheme.primary,
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (c, a) =>
                          ScaleTransition(scale: a, child: c),
                      child: Icon(
                        audioProvider.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        key: ValueKey(audioProvider.isPlaying),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: audioProvider.stop,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    icon: const Icon(Icons.stop_rounded),
                  ),
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BinauralBeatsScreen(),
                      ),
                    ),
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    icon: const Icon(Icons.open_in_new_rounded, size: 20),
                  ),
                ],
              ),
            ),
          ),
        );
  }
}