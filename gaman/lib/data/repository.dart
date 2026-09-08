import 'models.dart';
import 'sync_status.dart';

/// One home for every piece of user data. `LocalRepository` (SharedPreferences)
/// is the implementation now; a Firestore one arrives later without any change
/// to the providers and screens that depend on this interface.
///
/// Every `watch*` returns a broadcast stream that emits the current value on
/// listen and again on every write.
abstract class Repository {
  Stream<List<JournalEntry>> watchJournal();
  Future<void> upsertJournalEntry(JournalEntry entry);
  Future<void> deleteJournalEntry(String id);

  /// Tasks for one calendar day, keyed by `DateUtils.dateOnly(day)`.
  Stream<List<TodoTask>> watchTasks(DateTime day);
  Future<void> saveTasks(DateTime day, List<TodoTask> tasks);

  /// Append-only. Emitted oldest-first.
  Stream<List<ActivityEvent>> watchActivity();
  Future<void> addActivity(ActivityEvent event);

  Stream<AppSettings> watchSettings();
  Future<void> saveSettings(AppSettings settings);

  /// Whether writes have reached the server. `localOnly` when there is no
  /// cloud backend.
  Stream<SyncStatus> watchSyncStatus();

  Future<void> dispose();
}
