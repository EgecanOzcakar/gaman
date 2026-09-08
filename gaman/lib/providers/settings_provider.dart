import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/models.dart';
import '../data/repository.dart';

/// Timer defaults, backed by [Repository.watchSettings].
class SettingsProvider with ChangeNotifier {
  SettingsProvider(this._repo) {
    ready = _subscribe();
  }

  final Repository _repo;
  late final Future<void> ready;
  StreamSubscription<AppSettings>? _sub;
  AppSettings _s = const AppSettings();

  int get meditationMinutes => _s.meditationMinutes;
  int get breathSeconds => _s.breathSeconds;
  int get focusMinutes => _s.focusMinutes;
  int get longBreakEvery => _s.longBreakEvery;
  int get completedPomodoros => _s.completedPomodoros;

  Future<void> _subscribe() async {
    final c = Completer<void>();
    _sub = _repo.watchSettings().listen((s) {
      _s = s;
      notifyListeners();
      if (!c.isCompleted) c.complete();
    });
    return c.future;
  }

  Future<void> setMeditationMinutes(int v) =>
      _repo.saveSettings(_s.copyWith(meditationMinutes: v));
  Future<void> setBreathSeconds(int v) =>
      _repo.saveSettings(_s.copyWith(breathSeconds: v));
  Future<void> setFocusMinutes(int v) =>
      _repo.saveSettings(_s.copyWith(focusMinutes: v));
  Future<void> setLongBreakEvery(int v) =>
      _repo.saveSettings(_s.copyWith(longBreakEvery: v));
  Future<void> setCompletedPomodoros(int v) =>
      _repo.saveSettings(_s.copyWith(completedPomodoros: v));

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
