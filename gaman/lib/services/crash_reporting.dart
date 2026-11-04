import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Opt-in crash reporting via Crashlytics. Off until the user turns it on in
/// Settings (collection is also disabled in the Android manifest / iOS
/// Info.plist so nothing is sent before consent). Every call is a safe no-op
/// when Firebase isn't configured or on web, where Crashlytics doesn't exist.
class CrashReporting extends ChangeNotifier {
  static const prefsKey = 'crash_reporting_opt_in';

  bool _enabled = false;
  bool get enabled => _enabled;
  bool get available => !kIsWeb && Firebase.apps.isNotEmpty;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(prefsKey) ?? false;
    notifyListeners();
    if (!available) return;
    await _apply();
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      previous?.call(details);
      if (_enabled) {
        _safe(() => FirebaseCrashlytics.instance.recordFlutterFatalError(details));
      }
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      if (_enabled) {
        _safe(() =>
            FirebaseCrashlytics.instance.recordError(error, stack, fatal: true));
      }
      return false; // keep the default logging
    };
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKey, value);
    if (available) await _apply();
  }

  Future<void> _apply() => _safe(() =>
      FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(_enabled));

  static Future<void> _safe(Future<void> Function() f) async {
    try {
      await f();
    } catch (e) {
      debugPrint('Crashlytics unavailable: $e');
    }
  }
}
