import 'dart:convert';

import 'package:flutter/material.dart' show ChangeNotifier, DateUtils;
import 'package:shared_preferences/shared_preferences.dart';

enum ActivityType { meditation, focus, journal, taskDone }

class ActivityEvent {
  final ActivityType type;
  final DateTime at;
  final int durationSeconds;
  final Map<String, dynamic> meta;

  ActivityEvent({
    required this.type,
    required this.at,
    this.durationSeconds = 0,
    this.meta = const {},
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'at': at.toIso8601String(),
        'dur': durationSeconds,
        if (meta.isNotEmpty) 'meta': meta,
      };

  factory ActivityEvent.fromJson(Map<String, dynamic> j) => ActivityEvent(
        type: ActivityType.values.byName(j['type'] as String),
        at: DateTime.parse(j['at'] as String),
        durationSeconds: (j['dur'] as num?)?.toInt() ?? 0,
        meta: (j['meta'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
}

/// Append-only log of things the user did. Every stats surface (streaks,
/// dashboard, weekly review) reads from here instead of rolling its own store.
/// SharedPreferences + JSON — no database needed at this size.
class ActivityLog with ChangeNotifier {
  static const _key = 'activity_log';

  List<ActivityEvent> _events = [];
  List<ActivityEvent> get events => List.unmodifiable(_events);

  ActivityLog() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _events = (prefs.getStringList(_key) ?? [])
        .map((s) {
          try {
            return ActivityEvent.fromJson(jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<ActivityEvent>()
        .toList()
      ..sort((a, b) => a.at.compareTo(b.at));
    notifyListeners();
  }

  Future<void> log(
    ActivityType type, {
    int durationSeconds = 0,
    Map<String, dynamic> meta = const {},
    DateTime? at,
  }) async {
    _events.add(ActivityEvent(
      type: type,
      at: at ?? DateTime.now(),
      durationSeconds: durationSeconds,
      meta: meta,
    ));
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _key, _events.map((e) => jsonEncode(e.toJson())).toList());
  }

  // --- queries -------------------------------------------------------------

  Iterable<ActivityEvent> onDay(DateTime day) {
    final d = DateUtils.dateOnly(day);
    return _events.where((e) => DateUtils.dateOnly(e.at) == d);
  }

  Iterable<ActivityEvent> since(DateTime from) =>
      _events.where((e) => e.at.isAfter(from));

  bool didAnythingOn(DateTime day) => onDay(day).isNotEmpty;

  /// Consecutive days up to today (or yesterday, if today is still empty) that
  /// have at least one logged activity.
  int get currentStreak {
    var day = DateTime.now();
    if (!didAnythingOn(day)) day = day.subtract(const Duration(days: 1));
    var streak = 0;
    while (didAnythingOn(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int countThisWeek(ActivityType type) {
    final weekStart = DateUtils.dateOnly(
        DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)));
    return since(weekStart.subtract(const Duration(seconds: 1)))
        .where((e) => e.type == type)
        .length;
  }

  int minutesThisWeek(ActivityType type) {
    final weekStart = DateUtils.dateOnly(
        DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)));
    return since(weekStart.subtract(const Duration(seconds: 1)))
            .where((e) => e.type == type)
            .fold(0, (sum, e) => sum + e.durationSeconds) ~/
        60;
  }
}
