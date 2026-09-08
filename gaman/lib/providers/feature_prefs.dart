import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/models.dart';
import '../data/repository.dart';

/// Which practices show on the home screen. Everything is on by default;
/// turning one off just hides its card (state is untouched).
class FeaturePrefs with ChangeNotifier {
  FeaturePrefs(this._repo) {
    ready = _subscribe();
  }

  static const ids = ['meditation', 'journal', 'binaural', 'focus', 'todo'];

  final Repository _repo;
  late final Future<void> ready;
  StreamSubscription<AppSettings>? _sub;
  AppSettings _s = const AppSettings();

  bool isEnabled(String id) => !_s.disabledFeatures.contains(id);

  Future<void> _subscribe() async {
    final c = Completer<void>();
    _sub = _repo.watchSettings().listen((s) {
      _s = s;
      notifyListeners();
      if (!c.isCompleted) c.complete();
    });
    return c.future;
  }

  Future<void> setEnabled(String id, bool enabled) {
    final next = {..._s.disabledFeatures};
    if (enabled) {
      next.remove(id);
    } else {
      next.add(id);
    }
    return _repo.saveSettings(_s.copyWith(disabledFeatures: next));
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
