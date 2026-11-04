import 'package:shared_preferences/shared_preferences.dart';

import 'firestore_repository.dart';
import 'local_repository.dart';
import 'models.dart';

/// Copies a device's local data into the signed-in user's Firestore account.
///
/// The first run for a uid copies everything, settings included, and sets
/// `users/{uid}/profile/migration`. Later runs still pick up journal, task and
/// activity data that was written locally after that (e.g. a launch where
/// Firebase was unreachable) — the marker alone would strand it. Settings are
/// only copied on the first run: after that the cloud copy wins.
///
/// Local keys are cleared only after the server has acknowledged the writes.
class LocalToFirestoreMigration {
  LocalToFirestoreMigration({
    required this.remote,
    SharedPreferences? prefs,
    LocalRepository? local,
  })  : _injectedPrefs = prefs,
        _injectedLocal = local;

  final FirestoreRepository remote;
  final SharedPreferences? _injectedPrefs;
  final LocalRepository? _injectedLocal;

  static const _settingsKeys = [
    'theme_mode',
    'settings_meditation_minutes',
    'settings_breath_seconds',
    'settings_focus_minutes',
    'settings_long_break_every',
    'pomodoro_duration',
    'completed_pomodoros',
    'disabled_features',
    'notification_enabled',
    'notification_time',
  ];

  static const _dataKeys = ['journal_entries', 'activity_log'];

  static bool _isDataKey(String k) =>
      _dataKeys.contains(k) || k.startsWith('todo_tasks_');

  Future<bool> run() async {
    final prefs = _injectedPrefs ?? await SharedPreferences.getInstance();
    final migrated = await remote.hasMigrated();
    if (migrated && !prefs.getKeys().any(_isDataKey)) return false;

    final local = _injectedLocal ?? (LocalRepository(prefs: prefs));
    await local.ready;

    final journal = await local.watchJournal().first;
    final activity = await local.watchActivity().first;
    final settings = await local.watchSettings().first;

    for (final e in journal) {
      await remote.upsertJournalEntry(e);
    }

    final taskKeys =
        prefs.getKeys().where((k) => k.startsWith('todo_tasks_')).toList();
    for (final key in taskKeys) {
      final date = DateTime.tryParse(key.substring('todo_tasks_'.length));
      if (date == null) continue;
      final tasks = await local.watchTasks(date).first;
      if (tasks.isNotEmpty) await remote.saveTasks(date, tasks);
    }

    for (final ev in activity) {
      await remote.putActivityAt(_activityId(ev), ev);
    }

    if (!migrated) {
      await remote.saveSettings(settings);
      await remote.markMigrated();
    }
    await remote.flush();

    for (final k in [
      ..._dataKeys,
      ..._settingsKeys,
      ...taskKeys,
    ]) {
      await prefs.remove(k);
    }

    return true;
  }

  static String _activityId(ActivityEvent e) =>
      '${e.at.toIso8601String()}_${e.type.name}_${e.durationSeconds}'
          .replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '-');
}
