import 'dart:convert';
import 'package:flutter/material.dart';
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

  test('tasks: save then watch for the same day', () async {
    final r = await repo();
    final day = DateTime(2026, 3, 4, 15);
    await r.saveTasks(day, [
      TodoTask(id: 'm', title: 'frog', isMainTask: true, createdAt: day),
    ]);
    final list = await r.watchTasks(DateTime(2026, 3, 4, 8)).first;
    expect(list.single.title, 'frog');
    await r.dispose();
  });

  test('tasks: different days are independent', () async {
    final r = await repo();
    await r.saveTasks(DateTime(2026, 3, 4),
        [TodoTask(id: 'a', title: 'x', isMainTask: true, createdAt: DateTime(2026))]);
    expect(await r.watchTasks(DateTime(2026, 3, 5)).first, isEmpty);
    await r.dispose();
  });

  test('activity: addActivity appends and keeps oldest-first', () async {
    final r = await repo();
    await r.addActivity(ActivityEvent(
        type: ActivityType.focus, at: DateTime(2026, 1, 2)));
    await r.addActivity(ActivityEvent(
        type: ActivityType.journal, at: DateTime(2026, 1, 1)));
    final list = await r.watchActivity().first;
    expect(list.map((e) => e.type),
        [ActivityType.journal, ActivityType.focus]);
    await r.dispose();
  });

  test('settings: saveSettings round-trips through a fresh repo', () async {
    final r = await repo();
    await r.saveSettings(const AppSettings()
        .copyWith(focusMinutes: 40, disabledFeatures: {'binaural'},
                  reminderHour: 7, reminderMinute: 30));
    await r.dispose();

    final r2 = await repo();
    final s = await r2.watchSettings().first;
    expect(s.focusMinutes, 40);
    expect(s.disabledFeatures, {'binaural'});
    expect(s.reminderHour, 7);
    await r2.dispose();
  });

  test('settings: reads legacy individual keys', () async {
    SharedPreferences.setMockInitialValues({
      'theme_mode': 'ThemeMode.dark',
      'settings_focus_minutes': 45,
      'disabled_features': ['journal'],
      'notification_enabled': false,
    });
    final r = await repo();
    final s = await r.watchSettings().first;
    expect(s.themeMode, ThemeMode.dark);
    expect(s.focusMinutes, 45);
    expect(s.disabledFeatures, {'journal'});
    expect(s.reminderEnabled, isFalse);
    await r.dispose();
  });
}
