import 'dart:convert';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gaman/data/firestore_repository.dart';
import 'package:gaman/data/local_repository.dart';
import 'package:gaman/data/local_to_firestore_migration.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore db;
  late FirestoreRepository remote;

  setUp(() {
    db = FakeFirebaseFirestore();
    remote = FirestoreRepository(uid: 'u1', firestore: db);
  });

  Future<LocalToFirestoreMigration> build() async {
    final prefs = await SharedPreferences.getInstance();
    final local = LocalRepository(prefs: prefs);
    await local.ready;
    return LocalToFirestoreMigration(remote: remote, prefs: prefs, local: local);
  }

  test('copies journal, tasks, activity and settings, then marks + clears', () async {
    SharedPreferences.setMockInitialValues({
      'journal_entries': [
        jsonEncode({
          'id': 'j1', 'content': 'hello', 'mood': '😊', 'type': 'free',
          'date': DateTime(2026, 1, 1).toIso8601String(),
        }),
      ],
      'todo_tasks_2026-03-04': [
        jsonEncode({
          'id': 'm', 'title': 'frog', 'isCompleted': false, 'isMainTask': true,
          'createdAt': DateTime(2026, 3, 4).toIso8601String(),
        }),
      ],
      'activity_log': [
        jsonEncode({
          'type': 'focus', 'at': DateTime(2026, 2, 1).toIso8601String(),
          'dur': 1500,
        }),
      ],
      'settings_focus_minutes': 40,
      'theme_mode': 'ThemeMode.dark',
      'binaural_volume': 0.7,
    });

    final did = await (await build()).run();
    expect(did, isTrue);

    expect((await remote.watchJournal().first).single.content, 'hello');
    expect((await remote.watchTasks(DateTime(2026, 3, 4)).first).single.title, 'frog');
    expect((await remote.watchActivity().first).single.durationSeconds, 1500);
    final s = await remote.watchSettings().first;
    expect(s.focusMinutes, 40);
    expect(s.themeMode, ThemeMode.dark);

    expect(await remote.hasMigrated(), isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys().contains('journal_entries'), isFalse);
    expect(prefs.getKeys().contains('todo_tasks_2026-03-04'), isFalse);
    expect(prefs.getKeys().contains('settings_focus_minutes'), isFalse);
    expect(prefs.getDouble('binaural_volume'), 0.7); // untouched
  });

  test('does nothing when already migrated', () async {
    SharedPreferences.setMockInitialValues({
      'journal_entries': [
        jsonEncode({
          'id': 'j1', 'content': 'x', 'mood': '😊', 'type': 'free',
          'date': DateTime(2026).toIso8601String(),
        }),
      ],
    });
    await remote.markMigrated();
    final did = await (await build()).run();
    expect(did, isFalse);
    expect(await remote.watchJournal().first, isEmpty);
  });

  test('re-run after a lost marker does not duplicate activity', () async {
    SharedPreferences.setMockInitialValues({
      'activity_log': [
        jsonEncode({
          'type': 'meditation', 'at': DateTime(2026, 5, 1).toIso8601String(),
          'dur': 600,
        }),
      ],
    });
    await (await build()).run();
    // simulate the marker never landing: delete it, keep prefs already cleared
    await db.doc('users/u1/profile/migration').delete();
    SharedPreferences.setMockInitialValues({
      'activity_log': [
        jsonEncode({
          'type': 'meditation', 'at': DateTime(2026, 5, 1).toIso8601String(),
          'dur': 600,
        }),
      ],
    });
    await (await build()).run();
    expect(await remote.watchActivity().first, hasLength(1));
  });
}
