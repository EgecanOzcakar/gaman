import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'models.dart';
import 'repository.dart';
import 'sync_status.dart';

/// [Repository] backed by Cloud Firestore under `users/{uid}/…`.
/// Firestore's local cache provides offline reads/writes — this class does no
/// sync bookkeeping of its own.
///
/// [Repository] writes return once Firestore has queued them locally, not
/// when the server acknowledges them — a `set()` future only completes on the
/// server ack, which never comes while offline. Use [flush] where you really
/// need the ack (the local→cloud migration).
class FirestoreRepository implements Repository {
  FirestoreRepository({required String uid, FirebaseFirestore? firestore})
      : _uid = uid,
        _db = firestore ?? FirebaseFirestore.instance;

  final String _uid;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _journalCol =>
      _db.collection('users/$_uid/journal');
  DocumentReference<Map<String, dynamic>> get _settingsDoc =>
      _db.doc('users/$_uid/profile/settings');
  CollectionReference<Map<String, dynamic>> get _activityCol =>
      _db.collection('users/$_uid/activity');
  DocumentReference<Map<String, dynamic>> get _migrationDoc =>
      _db.doc('users/$_uid/profile/migration');

  Future<bool> hasMigrated() async => (await _migrationDoc.get()).exists;

  Future<void> markMigrated() => _queued(_migrationDoc.set({
        'done': true,
        'at': FieldValue.serverTimestamp(),
      }));

  Future<void> putActivityAt(String id, ActivityEvent event) =>
      _queued(_activityCol.doc(id).set(event.toJson()));

  /// Completes when every queued write has reached the server.
  Future<void> flush() => _db.waitForPendingWrites();

  static Future<void> _queued(Future<void> write) {
    write.catchError((Object e) => debugPrint('Firestore write failed: $e'));
    return Future.value();
  }

  /// The task day documents' ids are `yyyy-MM-dd`.
  CollectionReference<Map<String, dynamic>> get _tasksCol =>
      _db.collection('users/$_uid/tasks');

  /// Every subcollection the app writes under `users/{uid}`. Client SDKs
  /// cannot list subcollections, so keep this in step with the paths above.
  List<CollectionReference<Map<String, dynamic>>> get _allCollections =>
      [_journalCol, _activityCol, _tasksCol, _db.collection('users/$_uid/profile')];

  /// Deletes all of this user's documents. Awaits the server: used by account
  /// deletion, which must not report success before the data is gone.
  Future<void> deleteAllUserData() async {
    for (final col in _allCollections) {
      final snap = await col.get();
      for (var i = 0; i < snap.docs.length; i += 400) {
        final batch = _db.batch();
        for (final d in snap.docs.skip(i).take(400)) {
          batch.delete(d.reference);
        }
        await batch.commit();
      }
    }
    await _db.doc('users/$_uid').delete();
  }

  @override
  Future<Map<String, Object?>> exportData() async {
    List<Map<String, dynamic>> docs(QuerySnapshot<Map<String, dynamic>> s) =>
        s.docs.map((d) => _plain(d.data())).toList();
    final tasks = await _tasksCol.get();
    return {
      'journal': docs(await _journalCol.orderBy('date', descending: true).get()),
      'tasks': {for (final d in tasks.docs) d.id: _plain(d.data())['tasks']},
      'activity': docs(await _activityCol.orderBy('at').get()),
      'settings': _plain((await _settingsDoc.get()).data() ?? const {}),
    };
  }

  /// Drops Firestore-only fields (server timestamps) so the export is JSON.
  static Map<String, dynamic> _plain(Map<String, dynamic> m) =>
      {...m}..remove('updatedAt');

  static String _dayKey(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$dd';
  }

  // --- journal ----------------------------------------------------------

  @override
  Stream<List<JournalEntry>> watchJournal() =>
      _journalCol.orderBy('date', descending: true).snapshots().map((snap) =>
          snap.docs.map((d) => JournalEntry.fromJson(d.data())).toList())
          .asBroadcastStream();

  @override
  Future<void> upsertJournalEntry(JournalEntry entry) =>
      _queued(_journalCol.doc(entry.id).set({
        ...entry.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      }));

  @override
  Future<void> deleteJournalEntry(String id) =>
      _queued(_journalCol.doc(id).delete());

  // --- settings -------------------------------------------------------

  @override
  Stream<AppSettings> watchSettings() => _settingsDoc.snapshots().map(
      (d) => AppSettings.fromJson(d.data() ?? const {})).asBroadcastStream();

  @override
  Future<void> saveSettings(AppSettings settings) =>
      _queued(_settingsDoc.set({
        ...settings.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      }));

  // --- tasks + activity -------------------------------------------------

  @override
  Stream<List<TodoTask>> watchTasks(DateTime day) => _tasksCol
      .doc(_dayKey(day))
      .snapshots()
      .map((d) => ((d.data()?['tasks'] as List?) ?? const [])
          .map((e) => TodoTask.fromJson((e as Map).cast<String, dynamic>()))
          .toList())
      .asBroadcastStream();

  @override
  Future<void> saveTasks(DateTime day, List<TodoTask> tasks) =>
      _queued(_tasksCol.doc(_dayKey(day)).set({
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }));

  @override
  Stream<List<ActivityEvent>> watchActivity() =>
      _activityCol.orderBy('at').snapshots().map((snap) =>
          snap.docs.map((d) => ActivityEvent.fromJson(d.data())).toList())
          .asBroadcastStream();

  @override
  Future<void> addActivity(ActivityEvent event) =>
      _queued(_activityCol.doc().set(event.toJson()));

  @override
  Stream<SyncStatus> watchSyncStatus() => _settingsDoc
      .snapshots(includeMetadataChanges: true)
      .map((s) => statusFromMetadata((
            hasPendingWrites: s.metadata.hasPendingWrites,
            isFromCache: s.metadata.isFromCache,
          )))
      .asBroadcastStream();

  @override
  Future<void> dispose() async {}
}
