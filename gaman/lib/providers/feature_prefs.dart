import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which practices show on the home screen. Everything is on by default;
/// turning one off just hides its card (state is untouched).
class FeaturePrefs with ChangeNotifier {
  static const ids = ['meditation', 'journal', 'binaural', 'focus', 'todo'];

  final Set<String> _disabled = {};

  bool isEnabled(String id) => !_disabled.contains(id);

  FeaturePrefs() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _disabled
      ..clear()
      ..addAll(prefs.getStringList('disabled_features') ?? const []);
    notifyListeners();
  }

  Future<void> setEnabled(String id, bool enabled) async {
    if (enabled) {
      _disabled.remove(id);
    } else {
      _disabled.add(id);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('disabled_features', _disabled.toList());
  }
}
