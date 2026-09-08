import 'package:cloud_firestore/cloud_firestore.dart';

import 'models.dart';
import 'repository.dart';

/// [Repository] backed by Cloud Firestore under `users/{uid}/…`.
/// Firestore's local cache provides offline reads/writes — this class does no
/// sync bookkeeping of its own.
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
          snap.docs.map((d) => JournalEntry.fromJson(d.data())).toList());

  @override
  Future<void> upsertJournalEntry(JournalEntry entry) =>
      _journalCol.doc(entry.id).set({
        ...entry.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> deleteJournalEntry(String id) => _journalCol.doc(id).delete();

  // --- settings -------------------------------------------------------

  @override
  Stream<AppSettings> watchSettings() => _settingsDoc.snapshots().map(
      (d) => AppSettings.fromJson(d.data() ?? const {}));

  @override
  Future<void> saveSettings(AppSettings settings) => _settingsDoc.set({
        ...settings.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  // --- tasks + activity -------------------------------------------------

  @override
  Stream<List<TodoTask>> watchTasks(DateTime day) => _db
      .doc('users/$_uid/tasks/${_dayKey(day)}')
      .snapshots()
      .map((d) => ((d.data()?['tasks'] as List?) ?? const [])
          .map((e) => TodoTask.fromJson((e as Map).cast<String, dynamic>()))
          .toList());

  @override
  Future<void> saveTasks(DateTime day, List<TodoTask> tasks) =>
      _db.doc('users/$_uid/tasks/${_dayKey(day)}').set({
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  @override
  Stream<List<ActivityEvent>> watchActivity() =>
      _activityCol.orderBy('at').snapshots().map((snap) =>
          snap.docs.map((d) => ActivityEvent.fromJson(d.data())).toList());

  @override
  Future<void> addActivity(ActivityEvent event) =>
      _activityCol.add(event.toJson());

  @override
  Future<void> dispose() async {}
}
