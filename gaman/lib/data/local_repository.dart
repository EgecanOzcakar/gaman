import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart' show DateUtils, ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'repository.dart';
import 'sync_status.dart';

/// SharedPreferences-backed [Repository]. Holds everything in memory, mirrors
/// writes to prefs using the app's existing keys and formats (see the plan's
/// Global Constraints), and pushes each change to a broadcast stream.
class LocalRepository implements Repository {
  LocalRepository({SharedPreferences? prefs}) {
    ready = _init(prefs);
  }

  late final Future<void> ready;
  late SharedPreferences _prefs;

  final _journal = StreamController<List<JournalEntry>>.broadcast();
  final _activity = StreamController<List<ActivityEvent>>.broadcast();
  final _settings = StreamController<AppSettings>.broadcast();
  final _tasks = <String, StreamController<List<TodoTask>>>{};

  List<JournalEntry> _journalCache = [];
  List<ActivityEvent> _activityCache = [];
  AppSettings _settingsCache = const AppSettings();
  final _taskCache = <String, List<TodoTask>>{};

  static String _dayKey(DateTime day) {
    final d = DateUtils.dateOnly(day);
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$dd';
  }

  Future<void> _init(SharedPreferences? injected) async {
    _prefs = injected ?? await SharedPreferences.getInstance();

    _journalCache = _decodeList(
        'journal_entries', (m) => JournalEntry.fromJson(m))
      ..sort((a, b) => b.date.compareTo(a.date));
    _activityCache = _decodeList('activity_log', (m) => ActivityEvent.fromJson(m))
      ..sort((a, b) => a.at.compareTo(b.at));
    _settingsCache = _readSettings();

    _journal.add(_journalCache);
    _activity.add(_activityCache);
    _settings.add(_settingsCache);
  }

  /// Emits [current] immediately on listen, then every value from [updates].
  /// Subscribes to [updates] synchronously in `onListen` so a write that lands
  /// right after `watch*()` returns is not missed (a plain `async*` generator
  /// would still be between its first `yield` and `yield*` at that point).
  static Stream<T> _watch<T>(T Function() current, Stream<T> updates) {
    late final StreamController<T> controller;
    StreamSubscription<T>? sub;
    controller = StreamController<T>(
      onListen: () {
        controller.add(current());
        sub = updates.listen(controller.add, onError: controller.addError);
      },
      onPause: () => sub?.pause(),
      onResume: () => sub?.resume(),
      onCancel: () => sub?.cancel(),
    );
    return controller.stream;
  }

  List<T> _decodeList<T>(String key, T Function(Map<String, dynamic>) fromJson) =>
      (_prefs.getStringList(key) ?? [])
          .map((s) {
            try {
              return fromJson(jsonDecode(s) as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          })
          .whereType<T>()
          .toList();

  // --- journal ------------------------------------------------------------

  @override
  Stream<List<JournalEntry>> watchJournal() =>
      _watch(() => _journalCache, _journal.stream);

  @override
  Future<void> upsertJournalEntry(JournalEntry entry) async {
    _journalCache = [
      entry,
      ..._journalCache.where((e) => e.id != entry.id),
    ]..sort((a, b) => b.date.compareTo(a.date));
    await _persistJournal();
  }

  @override
  Future<void> deleteJournalEntry(String id) async {
    _journalCache = _journalCache.where((e) => e.id != id).toList();
    await _persistJournal();
  }

  Future<void> _persistJournal() async {
    _journal.add(_journalCache);
    await _prefs.setStringList('journal_entries',
        _journalCache.map((e) => jsonEncode(e.toJson())).toList());
  }

  // --- tasks -------------------------------------------------------------

  StreamController<List<TodoTask>> _taskController(String key) =>
      _tasks.putIfAbsent(key, () => StreamController.broadcast());

  @override
  Stream<List<TodoTask>> watchTasks(DateTime day) {
    final key = _dayKey(day);
    _taskCache[key] ??=
        _decodeList('todo_tasks_$key', (m) => TodoTask.fromJson(m));
    return _watch(() => _taskCache[key]!, _taskController(key).stream);
  }

  @override
  Future<void> saveTasks(DateTime day, List<TodoTask> tasks) async {
    final key = _dayKey(day);
    _taskCache[key] = List.of(tasks);
    _taskController(key).add(_taskCache[key]!);
    await _prefs.setStringList('todo_tasks_$key',
        tasks.map((t) => jsonEncode(t.toJson())).toList());
  }

  // --- activity --------------------------------------------------------

  @override
  Stream<List<ActivityEvent>> watchActivity() =>
      _watch(() => _activityCache, _activity.stream);

  @override
  Future<void> addActivity(ActivityEvent event) async {
    _activityCache = [..._activityCache, event]
      ..sort((a, b) => a.at.compareTo(b.at));
    _activity.add(_activityCache);
    await _prefs.setStringList('activity_log',
        _activityCache.map((e) => jsonEncode(e.toJson())).toList());
  }

  // --- settings -------------------------------------------------------

  @override
  Stream<AppSettings> watchSettings() =>
      _watch(() => _settingsCache, _settings.stream);

  @override
  Future<void> saveSettings(AppSettings s) async {
    _settingsCache = s;
    _settings.add(s);
    await _prefs.setString('theme_mode', s.themeMode.toString());
    await _prefs.setInt('settings_meditation_minutes', s.meditationMinutes);
    await _prefs.setInt('settings_breath_seconds', s.breathSeconds);
    await _prefs.setInt('settings_focus_minutes', s.focusMinutes);
    await _prefs.setInt('settings_long_break_every', s.longBreakEvery);
    await _prefs.setInt('pomodoro_duration', s.focusMinutes);
    await _prefs.setInt('completed_pomodoros', s.completedPomodoros);
    await _prefs.setStringList(
        'disabled_features', s.disabledFeatures.toList());
    await _prefs.setBool('notification_enabled', s.reminderEnabled);
    if (s.reminderHour != null && s.reminderMinute != null) {
      await _prefs.setString(
          'notification_time', '${s.reminderHour}:${s.reminderMinute}');
    }
  }

  AppSettings _readSettings() {
    const d = AppSettings();
    final themeStr = _prefs.getString('theme_mode');
    final themeMode = ThemeMode.values.firstWhere(
      (m) => m.toString() == themeStr,
      orElse: () => d.themeMode,
    );
    int? h, min;
    final t = _prefs.getString('notification_time');
    if (t != null && t.contains(':')) {
      final parts = t.split(':');
      h = int.tryParse(parts[0]);
      min = int.tryParse(parts[1]);
    }
    return AppSettings(
      themeMode: themeMode,
      meditationMinutes:
          _prefs.getInt('settings_meditation_minutes') ?? d.meditationMinutes,
      breathSeconds: _prefs.getInt('settings_breath_seconds') ?? d.breathSeconds,
      focusMinutes: _prefs.getInt('settings_focus_minutes') ??
          _prefs.getInt('pomodoro_duration') ??
          d.focusMinutes,
      longBreakEvery:
          _prefs.getInt('settings_long_break_every') ?? d.longBreakEvery,
      completedPomodoros:
          _prefs.getInt('completed_pomodoros') ?? d.completedPomodoros,
      reminderEnabled:
          _prefs.getBool('notification_enabled') ?? d.reminderEnabled,
      reminderHour: h,
      reminderMinute: min,
      disabledFeatures:
          (_prefs.getStringList('disabled_features') ?? const []).toSet(),
    );
  }

  @override
  Stream<SyncStatus> watchSyncStatus() =>
      Stream<SyncStatus>.value(SyncStatus.localOnly);

  // --- teardown -----------------------------------------------------

  @override
  Future<void> dispose() async {
    await _journal.close();
    await _activity.close();
    await _settings.close();
    for (final c in _tasks.values) {
      await c.close();
    }
  }
}
