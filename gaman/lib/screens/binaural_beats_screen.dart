import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;

class BinauralBeat {
  final String name;
  final String description;
  final int frequency;
  final String audioAsset;

  const BinauralBeat({
    required this.name,
    required this.description,
    required this.frequency,
    required this.audioAsset,
  });
}

class BinauralBeatsScreen extends StatefulWidget {
  const BinauralBeatsScreen({super.key});

  @override
  State<BinauralBeatsScreen> createState() => _BinauralBeatsScreenState();
}

class _BinauralBeatsScreenState extends State<BinauralBeatsScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  BinauralBeat? _selectedBeat;
  bool _isPlaying = false;
  double _volume = 0.5;
  Timer? _volumeSaveTimer; // For debouncing volume saves
  final Map<String, AudioSource?> _preloadedAudio = {}; // Cache for audio sources

  final List<BinauralBeat> _beats = [
    const BinauralBeat(
      name: 'Deep Sleep',
      description: 'Delta waves (0.5-4 Hz) for deep sleep and healing',
      frequency: 2,
      audioAsset: 'assets/audio/delta.mp3',
    ),
    const BinauralBeat(
      name: 'Meditation',
      description: 'Theta waves (4-8 Hz) for deep meditation and creativity',
      frequency: 6,
      audioAsset: 'assets/audio/theta.mp3',
    ),
    const BinauralBeat(
      name: 'Focus',
      description: 'Alpha waves (8-13 Hz) for focus and relaxation',
      frequency: 10,
      audioAsset: 'assets/audio/alpha.mp3',
    ),
    const BinauralBeat(
      name: 'Energy',
      description: 'Beta waves (13-30 Hz) for energy and concentration',
      frequency: 20,
      audioAsset: 'assets/audio/beta.mp3',
    ),
    const BinauralBeat(
      name: 'Insight',
      description: 'Gamma waves (30-100 Hz) for insight and high-level processing',
      frequency: 40,
      audioAsset: 'assets/audio/gamma.mp3',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadVolume();
    _preloadAudioAssets(); // Preload audio for better performance
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        setState(() => _isPlaying = false);
      }
    });
  }

  @override
  void dispose() {
    _volumeSaveTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadVolume() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _volume = prefs.getDouble('binaural_volume') ?? 0.5;
    });
    _audioPlayer.setVolume(_volume);
  }

  Future<void> _saveVolume() async {
    _volumeSaveTimer?.cancel();
    _volumeSaveTimer = Timer(const Duration(milliseconds: 500), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('binaural_volume', _volume);
    });
  }

  Future<void> _preloadAudioAssets() async {
    // Preload audio assets for better performance on web
    if (kIsWeb) {
      for (final beat in _beats) {
        try {
          _preloadedAudio[beat.audioAsset] = AudioSource.asset(beat.audioAsset);
        } catch (e) {
          debugPrint('Failed to preload ${beat.audioAsset}: $e');
        }
      }
    }
  }

  Future<void> _playBeat(BinauralBeat beat) async {
    // Immediate UI feedback for better responsiveness
    if (_selectedBeat == beat && _isPlaying) {
      setState(() => _isPlaying = false);
      await _audioPlayer.pause();
      return;
    }
    
    if (_selectedBeat == beat && !_isPlaying) {
      setState(() => _isPlaying = true);
      await _audioPlayer.play();
      return;
    }
    
    if (_selectedBeat != beat) {
      // Immediate UI feedback
      setState(() {
        _selectedBeat = beat;
        _isPlaying = true;
      });
      
      // Stop current audio if playing
      if (_isPlaying) {
        await _audioPlayer.stop();
      }
      
      try {
        // Use preloaded audio source if available
        final audioSource = _preloadedAudio[beat.audioAsset] ?? AudioSource.asset(beat.audioAsset);
        await _audioPlayer.setAudioSource(audioSource);
        _audioPlayer.setVolume(_volume);
        await _audioPlayer.play();
      } catch (e) {
        debugPrint('Error playing audio: $e');
        setState(() => _isPlaying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to play audio. Please try again.'),
          ),
        );
      }
    }

    debugPrint('DEBUG: _playBeat - beat: ${beat.name}, isPlaying: $_isPlaying, selectedBeat: ${_selectedBeat?.name}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Binaural Beats'),
      ),
      body: Column(
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
                        value: _volume,
                        onChanged: (value) {
                          setState(() => _volume = value);
                          _audioPlayer.setVolume(value);
                          _saveVolume(); // Debounced save
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
              itemCount: _beats.length,
              itemBuilder: (context, index) {
                final beat = _beats[index];
                final isSelected = _selectedBeat == beat;
                final isPlaying = isSelected && _isPlaying;

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
                        IconButton(
                          icon: Icon(
                            isPlaying && isSelected ? Icons.pause : Icons.play_arrow,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          onPressed: () => _playBeat(beat),
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
      ),
    );
  }
} 