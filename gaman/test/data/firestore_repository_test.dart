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
}
