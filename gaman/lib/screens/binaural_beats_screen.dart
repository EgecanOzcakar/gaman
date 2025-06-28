import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../widgets/persistent_audio_control.dart';

class BinauralBeatsScreen extends StatefulWidget {
  const BinauralBeatsScreen({super.key});

  @override
  State<BinauralBeatsScreen> createState() => _BinauralBeatsScreenState();
}

class _BinauralBeatsScreenState extends State<BinauralBeatsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Binaural Beats'),
      ),
      body: Stack(
        children: [
          Consumer<AudioProvider>(
            builder: (context, audioProvider, child) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Volume',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Row(
                          children: [
                            const Icon(Icons.volume_down),
                            Expanded(
                              child: Slider(
                                value: audioProvider.volume,
                                onChanged: (value) {
                                  // Immediate feedback
                                  audioProvider.setVolume(value);
                                },
                              ),
                            ),
                            const Icon(Icons.volume_up),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: audioProvider.beats.length,
                      itemBuilder: (context, index) {
                        final beat = audioProvider.beats[index];
                        final isSelected = audioProvider.currentBeat == beat;
                        final isPlaying = isSelected && audioProvider.isPlaying;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        beat.name,
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${beat.frequency} Hz',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    // Immediate feedback
                                    audioProvider.playBeat(beat);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(
                                      isPlaying && isSelected ? Icons.pause : Icons.play_arrow,
                                      color: isSelected
                                          ? Theme.of(context).colorScheme.primary
                                          : null,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(beat.description),
                            ),
                            selected: isSelected,
                            selectedTileColor:
                                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
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