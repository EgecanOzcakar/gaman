import 'dart:convert';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaman/data/active_repository.dart';
import 'package:gaman/data/firestore_repository.dart';
import 'package:gaman/data/local_repository.dart';
import 'package:gaman/data/models.dart';
import 'package:gaman/services/data_export.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('exports the active (Firestore) repository, not device prefs', () async {
    SharedPreferences.setMockInitialValues({
      'journal_entries': ['{"stale":"local"}'],
      'gemini_api_key': 'secret-from-an-old-version',
    });
    final db = FakeFirebaseFirestore();
    final repo = ActiveRepository(FirestoreRepository(uid: 'u1', firestore: db));
    await repo.upsertJournalEntry(JournalEntry(
        id: 'j', content: 'cloud entry', date: DateTime(2026, 2, 2), mood: '😊'));
    await repo.saveTasks(DateTime(2026, 2, 2), [
      TodoTask(id: 't', title: 'frog', isMainTask: true, createdAt: DateTime(2026, 2, 2)),
    ]);

    final out = await buildExport(repo);
    final data = (jsonDecode(out) as Map)['data'] as Map;

    expect((data['journal'] as List).single['content'], 'cloud entry');
    expect(((data['tasks'] as Map)['2026-02-02'] as List).single['title'], 'frog');
    expect(out, isNot(contains('secret')));
    expect(out, isNot(contains('stale')));
  });

  test('local repository export has journal, tasks, activity and settings', () async {
    SharedPreferences.setMockInitialValues({
      'todo_tasks_2026-03-04': [
        jsonEncode({'id': 'm', 'title': 'frog', 'isMainTask': true,
          'createdAt': DateTime(2026, 3, 4).toIso8601String()}),
      ],
      'gemini_api_key': 'secret',
    });
    final local = LocalRepository();
    final out = await buildExport(local);
    final data = (jsonDecode(out) as Map)['data'] as Map;
    expect(data.keys, containsAll(['journal', 'tasks', 'activity', 'settings']));
    expect(((data['tasks'] as Map)['2026-03-04'] as List).single['title'], 'frog');
    expect(out, isNot(contains('secret')));
  });
}
