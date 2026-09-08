import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gaman/data/local_repository.dart';
import 'package:gaman/data/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<LocalRepository> repo() async {
    final r = LocalRepository();
    await r.ready;
    return r;
  }

  test('journal: upsert then watch emits it', () async {
    final r = await repo();
    await r.upsertJournalEntry(JournalEntry(
      id: '1', content: 'hi', date: DateTime(2026, 1, 1), mood: '😊'));
    expect((await r.watchJournal().first).single.content, 'hi');
    await r.dispose();
  });

  test('journal: upsert with an existing id replaces, not appends', () async {
    final r = await repo();
    final e = JournalEntry(
      id: '1', content: 'a', date: DateTime(2026, 1, 1), mood: '😊');
    await r.upsertJournalEntry(e);
    await r.upsertJournalEntry(JournalEntry(
      id: '1', content: 'b', date: e.date, mood: '😊'));
    final list = await r.watchJournal().first;
    expect(list, hasLength(1));
    expect(list.single.content, 'b');
    await r.dispose();
  });

  test('journal: delete removes and re-emits', () async {
    final r = await repo();
    await r.upsertJournalEntry(JournalEntry(
      id: '1', content: 'a', date: DateTime(2026), mood: '😊'));
    final emissions = <int>[];
    final sub = r.watchJournal().listen((l) => emissions.add(l.length));
    await Future<void>.delayed(Duration.zero);
    await r.deleteJournalEntry('1');
    await Future<void>.delayed(Duration.zero);
    expect(emissions.last, 0);
    await sub.cancel();
    await r.dispose();
  });

  test('journal: reads what the old format wrote', () async {
    SharedPreferences.setMockInitialValues({
      'journal_entries': [
        jsonEncode({
          'id': 'x', 'content': 'legacy', 'mood': '😐',
          'date': DateTime(2025, 6, 1).toIso8601String(), 'type': 'free',
        }),
      ],
    });
    final r = await repo();
    expect((await r.watchJournal().first).single.content, 'legacy');
    await r.dispose();
  });
}
