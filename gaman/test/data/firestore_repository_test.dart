import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaman/data/firestore_repository.dart';
import 'package:gaman/data/models.dart';

void main() {
  late FakeFirebaseFirestore db;
  late FirestoreRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = FirestoreRepository(uid: 'u1', firestore: db);
  });

  test('journal: upsert then watch emits it, newest first', () async {
    await repo.upsertJournalEntry(JournalEntry(
        id: 'a', content: 'older', date: DateTime(2026, 1, 1), mood: '😊'));
    await repo.upsertJournalEntry(JournalEntry(
        id: 'b', content: 'newer', date: DateTime(2026, 2, 1), mood: '😊'));
    final list = await repo.watchJournal().first;
    expect(list.map((e) => e.content), ['newer', 'older']);
  });

  test('journal: upsert same id replaces', () async {
    final e = JournalEntry(
        id: 'a', content: 'v1', date: DateTime(2026), mood: '😊');
    await repo.upsertJournalEntry(e);
    await repo.upsertJournalEntry(JournalEntry(
        id: 'a', content: 'v2', date: e.date, mood: '😊'));
    expect((await repo.watchJournal().first).single.content, 'v2');
  });

  test('journal: delete removes', () async {
    await repo.upsertJournalEntry(JournalEntry(
        id: 'a', content: 'x', date: DateTime(2026), mood: '😊'));
    await repo.deleteJournalEntry('a');
    expect(await repo.watchJournal().first, isEmpty);
  });

  test('journal doc has the model toJson shape plus updatedAt', () async {
    await repo.upsertJournalEntry(JournalEntry(
        id: 'a', content: 'x', date: DateTime(2026, 3, 4), mood: '😐',
        type: 'woop', sections: {'Wish': 'ship'}));
    final raw = (await db.doc('users/u1/journal/a').get()).data()!;
    expect(raw['content'], 'x');
    expect(raw['type'], 'woop');
    expect(raw['sections'], {'Wish': 'ship'});
    expect(raw.containsKey('updatedAt'), isTrue);
  });

  test('settings: default when the doc is absent', () async {
    final s = await repo.watchSettings().first;
    expect(s.themeMode, ThemeMode.system);
    expect(s.focusMinutes, 25);
  });

  test('settings: save then read back', () async {
    await repo.saveSettings(const AppSettings()
        .copyWith(focusMinutes: 40, disabledFeatures: {'journal'}));
    final s = await repo.watchSettings().first;
    expect(s.focusMinutes, 40);
    expect(s.disabledFeatures, {'journal'});
  });

  test('tasks: save then watch same calendar day', () async {
    final day = DateTime(2026, 3, 4, 15);
    await repo.saveTasks(day, [
      TodoTask(id: 'm', title: 'frog', isMainTask: true, createdAt: day),
    ]);
    final list = await repo.watchTasks(DateTime(2026, 3, 4, 8)).first;
    expect(list.single.title, 'frog');
  });

  test('tasks: absent day is empty', () async {
    expect(await repo.watchTasks(DateTime(2026, 5, 5)).first, isEmpty);
  });

  test('tasks doc shape: {tasks: [...], updatedAt}', () async {
    final day = DateTime(2026, 3, 4);
    await repo.saveTasks(day, [
      TodoTask(id: 'm', title: 'frog', isMainTask: true, createdAt: day),
    ]);
    final raw = (await db.doc('users/u1/tasks/2026-03-04').get()).data()!;
    expect(raw.keys.toSet(), {'tasks', 'updatedAt'});
    expect((raw['tasks'] as List).single['title'], 'frog');
  });

  test('settings doc shape matches AppSettings.toJson + updatedAt', () async {
    await repo.saveSettings(const AppSettings().copyWith(focusMinutes: 40));
    final raw = (await db.doc('users/u1/profile/settings').get()).data()!;
    expect(raw['focusMinutes'], 40);
    expect(raw['themeMode'], 'system');
    expect(raw.containsKey('updatedAt'), isTrue);
  });

  test('activity: add appends, watch is oldest-first', () async {
    await repo.addActivity(ActivityEvent(
        type: ActivityType.focus, at: DateTime(2026, 1, 2), durationSeconds: 1500));
    await repo.addActivity(ActivityEvent(
        type: ActivityType.journal, at: DateTime(2026, 1, 1)));
    final list = await repo.watchActivity().first;
    expect(list.map((e) => e.type),
        [ActivityType.journal, ActivityType.focus]);
  });

  test('hasMigrated is false until markMigrated', () async {
    expect(await repo.hasMigrated(), isFalse);
    await repo.markMigrated();
    expect(await repo.hasMigrated(), isTrue);
    final raw = (await db.doc('users/u1/profile/migration').get()).data()!;
    expect(raw['done'], isTrue);
  });

  test('putActivityAt writes at a fixed id (re-run overwrites)', () async {
    final ev = ActivityEvent(
        type: ActivityType.focus, at: DateTime(2026, 1, 1), durationSeconds: 60);
    await repo.putActivityAt('fixed-1', ev);
    await repo.putActivityAt('fixed-1', ev);
    expect(await repo.watchActivity().first, hasLength(1));
  });
}
