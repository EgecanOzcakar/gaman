import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/repository.dart';

class ThemeProvider with ChangeNotifier {
  ThemeProvider(this._repo) {
    ready = _subscribe();
  }

  final Repository _repo;
  late final Future<void> ready;
  StreamSubscription<AppSettings>? _sub;
  AppSettings _s = const AppSettings();

  ThemeMode get themeMode => _s.themeMode;

  Future<void> _subscribe() async {
    final c = Completer<void>();
    _sub = _repo.watchSettings().listen((s) {
      _s = s;
      notifyListeners();
      if (!c.isCompleted) c.complete();
    });
    return c.future;
  }

  Future<void> setThemeMode(ThemeMode mode) {
    if (mode == _s.themeMode) return Future.value();
    return _repo.saveSettings(_s.copyWith(themeMode: mode));
  }

  bool get isDarkMode {
    if (_s.themeMode == ThemeMode.system) {
      return PlatformDispatcher.instance.platformBrightness == Brightness.dark;
    }
    return _s.themeMode == ThemeMode.dark;
  }

  /// Flip to the opposite of what's currently on screen (resolving "system").
  Future<void> toggle() =>
      setThemeMode(isDarkMode ? ThemeMode.light : ThemeMode.dark);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
