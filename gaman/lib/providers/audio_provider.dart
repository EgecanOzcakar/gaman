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

class AudioProvider with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  BinauralBeat? _currentBeat;
  bool _isPlaying = false;
  double _volume = 0.5;
  Timer? _volumeSaveTimer;
  final Map<String, AudioSource?> _preloadedAudio = {};

  // Getters
  BinauralBeat? get currentBeat => _currentBeat;
  bool get isPlaying => _isPlaying;
  double get volume => _volume;
  bool get hasActiveAudio => _currentBeat != null;

  // Available beats
  final List<BinauralBeat> beats = [
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

  AudioProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadVolume();
    _preloadAudioAssets();
    
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _isPlaying = false;
        notifyListeners();
      }
    });
  }

  Future<void> _loadVolume() async {
    final prefs = await SharedPreferences.getInstance();
    _volume = prefs.getDouble('binaural_volume') ?? 0.5;
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
    if (kIsWeb) {
      for (final beat in beats) {
        try {
          _preloadedAudio[beat.audioAsset] = AudioSource.asset(beat.audioAsset);
        } catch (e) {
          debugPrint('Failed to preload ${beat.audioAsset}: $e');
        }
      }
    }
  }

  Future<void> playBeat(BinauralBeat beat) async {
    // Immediate UI feedback
    if (_currentBeat == beat && _isPlaying) {
      _isPlaying = false;
      notifyListeners();
      await _audioPlayer.pause();
      return;
    }
    
    if (_currentBeat == beat && !_isPlaying) {
      _isPlaying = true;
      notifyListeners();
      await _audioPlayer.play();
      return;
    }
    
    if (_currentBeat != beat) {
      // Immediate UI feedback
      _currentBeat = beat;
      _isPlaying = true;
      notifyListeners();
      
      // Stop current audio if playing
      if (_isPlaying) {
        await _audioPlayer.stop();
      }
      
      try {
        final audioSource = _preloadedAudio[beat.audioAsset] ?? AudioSource.asset(beat.audioAsset);
        await _audioPlayer.setAudioSource(audioSource);
        _audioPlayer.setVolume(_volume);
        await _audioPlayer.play();
      } catch (e) {
        debugPrint('Error playing audio: $e');
        _isPlaying = false;
        notifyListeners();
        rethrow;
      }
    }
  }

  Future<void> pause() async {
    if (_isPlaying) {
      _isPlaying = false;
      notifyListeners();
      await _audioPlayer.pause();
    }
  }

  Future<void> resume() async {
    if (_currentBeat != null && !_isPlaying) {
      _isPlaying = true;
      notifyListeners();
      await _audioPlayer.play();
    }
  }

  Future<void> stop() async {
    _currentBeat = null;
    _isPlaying = false;
    notifyListeners();
    await _audioPlayer.stop();
  }

  void setVolume(double volume) {
    _volume = volume;
    _audioPlayer.setVolume(volume);
    // Always notify listeners for immediate UI feedback
    notifyListeners();
    // Debounce only the save operation
    _saveVolume();
  }

  @override
  void dispose() {
    _volumeSaveTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
} 