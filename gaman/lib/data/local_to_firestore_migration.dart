import 'package:shared_preferences/shared_preferences.dart';

import 'firestore_repository.dart';
import 'local_repository.dart';
import 'models.dart';

/// Copies a device's local data into the signed-in user's Firestore account,
/// exactly once. Guarded by `users/{uid}/profile/migration`.
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

  Future<bool> run() async {
    if (await remote.hasMigrated()) return false;

    final prefs = _injectedPrefs ?? await SharedPreferences.getInstance();
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

    await remote.saveSettings(settings);
    await remote.markMigrated();

    for (final k in [
      'journal_entries',
      'activity_log',
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
