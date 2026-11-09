import 'dart:async';

import 'package:flutter/material.dart' show ChangeNotifier, DateUtils;

import '../data/models.dart';
import '../data/repository.dart';

export '../data/models.dart' show ActivityType, ActivityEvent;

/// One day on the kintsugi strip.
enum DayMark { done, mended, atRisk, missed, open }

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

  /// Practice, as opposed to bookkeeping (choosing a trial isn't doing it).
  static bool counts(ActivityEvent e) =>
      e.type != ActivityType.trial || e.meta['status'] == 'done';

  Set<DateTime> get _activeDays => _events
      .where(counts)
      .map((e) => DateUtils.dateOnly(e.at))
      .toSet();

  bool didAnythingOn(DateTime day) => onDay(day).any(counts);

  /// "Never miss twice": one missed day between practised days is mended
  /// (kintsugi), two in a row end the chain. An unpractised today is still
  /// open, and a missed yesterday is [atRisk] until today is practised.
  ({int days, int mended, bool atRisk}) get chain {
    final active = _activeDays;
    final today = DateUtils.dateOnly(DateTime.now());
    final yesterday = DateUtils.addDaysToDate(today, -1);
    var d = active.contains(today) ? today : yesterday;
    var days = 0, mended = 0, atRisk = false;
    while (true) {
      if (active.contains(d)) {
        days++;
      } else {
        if (!active.contains(DateUtils.addDaysToDate(d, -1))) break;
        if (d == yesterday && !active.contains(today)) {
          atRisk = true;
        } else {
          mended++;
        }
      }
      d = DateUtils.addDaysToDate(d, -1);
    }
    return (days: days, mended: mended, atRisk: atRisk);
  }

  /// Practised days in the current chain.
  int get currentStreak => chain.days;

  /// The last [n] days, oldest first, for the kintsugi strip.
  List<DayMark> recentMarks(int n) {
    final active = _activeDays;
    final today = DateUtils.dateOnly(DateTime.now());
    bool on(DateTime d) => active.contains(d);
    return [
      for (var i = n - 1; i >= 0; i--)
        () {
          final d = DateUtils.addDaysToDate(today, -i);
          if (on(d)) return DayMark.done;
          if (i == 0) return DayMark.open;
          final prev = DateUtils.addDaysToDate(d, -1);
          final next = DateUtils.addDaysToDate(d, 1);
          if (!on(prev)) return DayMark.missed;
          if (on(next)) return DayMark.mended;
          return i == 1 ? DayMark.atRisk : DayMark.missed;
        }(),
    ];
  }

  /// Today's chosen trial and whether it's done.
  ({String? id, bool done}) trialOn(DateTime day) {
    String? id;
    final done = <String>{};
    for (final e in onDay(day).where((e) => e.type == ActivityType.trial)) {
      final tid = e.meta['id'] as String?;
      if (e.meta['status'] == 'done') {
        if (tid != null) done.add(tid);
      } else {
        id = tid;
      }
    }
    return (id: id, done: id != null && done.contains(id));
  }

  /// Whether a journal entry from [templateId] was written on [day].
  bool wroteTemplateOn(DateTime day, String templateId) => onDay(day).any(
      (e) => e.type == ActivityType.journal && e.meta['template'] == templateId);

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
      .where(counts)
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
