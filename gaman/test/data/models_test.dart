import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaman/data/models.dart';

void main() {
  test('JournalEntry free entry round-trips, defaults type', () {
    final e = JournalEntry(
      id: '1', content: 'has, comma: colon',
      date: DateTime(2026, 1, 2, 3, 4), mood: '😐',
    );
    final back = JournalEntry.fromJson(e.toJson());
    expect(back.content, e.content);
    expect(back.type, 'free');
    expect(back.sections, isNull);
  });

  test('JournalEntry structured entry keeps sections', () {
    final e = JournalEntry(
      id: '2', content: 'joined', date: DateTime(2026, 1, 2), mood: '😊',
      type: 'woop', sections: {'Wish': 'ship', 'Obstacle': 'scope'},
    );
    expect(JournalEntry.fromJson(e.toJson()).sections,
        {'Wish': 'ship', 'Obstacle': 'scope'});
  });

  test('TodoTask round-trips', () {
    final t = TodoTask(
      id: 'a', title: 'frog', isMainTask: true, createdAt: DateTime(2026));
    final back = TodoTask.fromJson(t.toJson());
    expect(back.title, 'frog');
    expect(back.isMainTask, isTrue);
    expect(back.isCompleted, isFalse);
  });

  test('ActivityEvent round-trips and omits empty meta', () {
    final ev = ActivityEvent(
      type: ActivityType.focus, at: DateTime(2026, 5, 1), durationSeconds: 1500);
    expect(ev.toJson().containsKey('meta'), isFalse);
    final back = ActivityEvent.fromJson(ev.toJson());
    expect(back.type, ActivityType.focus);
    expect(back.durationSeconds, 1500);
  });

  test('AppSettings copyWith + round-trip', () {
    const s = AppSettings();
    expect(s.themeMode, ThemeMode.system);
    expect(s.focusMinutes, 25);
    final s2 = s.copyWith(focusMinutes: 30, disabledFeatures: {'journal'});
    expect(s2.focusMinutes, 30);
    expect(s2.meditationMinutes, 10);
    final back = AppSettings.fromJson(s2.toJson());
    expect(back.focusMinutes, 30);
    expect(back.disabledFeatures, {'journal'});
    expect(back.themeMode, ThemeMode.system);
  });

  test('AppSettings.fromJson tolerates missing keys', () {
    final back = AppSettings.fromJson({'focusMinutes': 45});
    expect(back.focusMinutes, 45);
    expect(back.breathSeconds, 4);
    expect(back.reminderEnabled, isTrue);
  });
}
