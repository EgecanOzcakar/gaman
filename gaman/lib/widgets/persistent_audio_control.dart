import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../screens/binaural_beats_screen.dart';

class PersistentAudioControl extends StatelessWidget {
  const PersistentAudioControl({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        if (!audioProvider.hasActiveAudio) {
          return const SizedBox.shrink();
        }

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
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                      ),
                      child: Slider(
                        value: audioProvider.volume,
                        onChanged: (value) {
                          // Immediate feedback
                          audioProvider.setVolume(value);
                        },
                        min: 0.0,
                        max: 1.0,
                      ),
                    ),
                  ),
                  
                  // Play/Pause Button
                  GestureDetector(
                    onTap: () {
                      // Immediate feedback
                      if (audioProvider.isPlaying) {
                        audioProvider.pause();
                      } else {
                        audioProvider.resume();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        audioProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                    ),
                  ),
                  
                  // Stop Button
                  GestureDetector(
                    onTap: () {
                      // Immediate feedback
                      audioProvider.stop();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.stop,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        size: 24,
                      ),
                    ),
                  ),
                  
                  // Open Binaural Beats Screen
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BinauralBeatsScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.open_in_new,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
} 