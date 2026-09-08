import 'dart:async';

import 'package:flutter/material.dart' show ChangeNotifier, DateUtils;

import '../data/models.dart';
import '../data/repository.dart';

export '../data/models.dart' show ActivityType, ActivityEvent;

/// Read model over [Repository.watchActivity]. Keeps every query the dashboard
/// and Insights screens use; writes go straight to the repository.
class ActivityLog with ChangeNotifier {
  ActivityLog(this._repo) {
    ready = _subscribe();
  }

  final Repository _repo;
  late final Future<void> ready;
  StreamSubscription<List<ActivityEvent>>? _sub;
  List<ActivityEvent> _events = [];

  List<ActivityEvent> get events => List.unmodifiable(_events);

  Future<void> _subscribe() async {
    final completer = Completer<void>();
    _sub = _repo.watchActivity().listen((events) {
      _events = events;
      notifyListeners();
      if (!completer.isCompleted) completer.complete();
    });
    return completer.future;
  }

  Future<void> log(
    ActivityType type, {
    int durationSeconds = 0,
    Map<String, dynamic> meta = const {},
    DateTime? at,
  }) =>
      _repo.addActivity(ActivityEvent(
        type: type,
        at: at ?? DateTime.now(),
        durationSeconds: durationSeconds,
        meta: meta,
      ));

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // --- queries (unchanged) ----------------------------------------------

  Iterable<ActivityEvent> onDay(DateTime day) {
    final d = DateUtils.dateOnly(day);
    return _events.where((e) => DateUtils.dateOnly(e.at) == d);
  }

  Iterable<ActivityEvent> since(DateTime from) =>
      _events.where((e) => e.at.isAfter(from));

  bool didAnythingOn(DateTime day) => onDay(day).isNotEmpty;

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

  Iterable<ActivityEvent> inRange(DateTime from, DateTime to) =>
      _events.where((e) => !e.at.isBefore(from) && e.at.isBefore(to));

  int count(ActivityType type, DateTime from, DateTime to) =>
      inRange(from, to).where((e) => e.type == type).length;

  int minutes(ActivityType type, DateTime from, DateTime to) =>
      inRange(from, to)
          .where((e) => e.type == type)
          .fold<int>(0, (sum, e) => sum + e.durationSeconds) ~/
      60;

  int activeDays(DateTime from, DateTime to) => inRange(from, to)
      .map((e) => DateUtils.dateOnly(e.at))
      .toSet()
      .length;

  static DateTime weekStart([DateTime? day]) {
    final d = day ?? DateTime.now();
    return DateUtils.dateOnly(d.subtract(Duration(days: d.weekday - 1)));
  }

  int countThisWeek(ActivityType type) =>
      count(type, weekStart(), DateTime.now().add(const Duration(days: 1)));

  int minutesThisWeek(ActivityType type) =>
      minutes(type, weekStart(), DateTime.now().add(const Duration(days: 1)));
}
