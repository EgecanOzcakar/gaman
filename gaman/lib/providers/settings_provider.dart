import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User-tunable defaults for the meditation and focus timers.
/// Theme lives in [ThemeProvider]; the daily reminder lives in
/// [NotificationProvider]. This only holds what those don't.
class SettingsProvider with ChangeNotifier {
  static const _kMeditationMinutes = 'settings_meditation_minutes';
  static const _kBreathSeconds = 'settings_breath_seconds';
  static const _kFocusMinutes = 'settings_focus_minutes';
  static const _kLongBreakEvery = 'settings_long_break_every';

  int _meditationMinutes = 10;
  int _breathSeconds = 4;
  int _focusMinutes = 25;
  int _longBreakEvery = 4;

  int get meditationMinutes => _meditationMinutes;
  int get breathSeconds => _breathSeconds;
  int get focusMinutes => _focusMinutes;
  int get longBreakEvery => _longBreakEvery;

  SettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _meditationMinutes = prefs.getInt(_kMeditationMinutes) ?? _meditationMinutes;
    _breathSeconds = prefs.getInt(_kBreathSeconds) ?? _breathSeconds;
    _focusMinutes = prefs.getInt(_kFocusMinutes) ?? _focusMinutes;
    _longBreakEvery = prefs.getInt(_kLongBreakEvery) ?? _longBreakEvery;
    notifyListeners();
  }

  Future<void> _set(String key, int value, void Function() apply) async {
    apply();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  Future<void> setMeditationMinutes(int v) =>
      _set(_kMeditationMinutes, v, () => _meditationMinutes = v);
  Future<void> setBreathSeconds(int v) =>
      _set(_kBreathSeconds, v, () => _breathSeconds = v);
  Future<void> setFocusMinutes(int v) =>
      _set(_kFocusMinutes, v, () => _focusMinutes = v);
  Future<void> setLongBreakEvery(int v) =>
      _set(_kLongBreakEvery, v, () => _longBreakEvery = v);
}
