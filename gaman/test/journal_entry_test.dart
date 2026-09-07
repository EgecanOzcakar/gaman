import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gaman/screens/journal_screen.dart';

void main() {
  test('free entry round-trips and defaults type to "free"', () {
    final e = JournalEntry(
      id: '1',
      content: 'thought with, a comma: and colon',
      date: DateTime(2026, 1, 2, 3, 4),
      mood: '😐',
    );
    final back = JournalEntry.fromJson(jsonDecode(jsonEncode(e.toJson())));
    expect(back.content, e.content);
    expect(back.type, 'free');
    expect(back.sections, isNull);
  });

  test('structured entry keeps its sections through a round-trip', () {
    final e = JournalEntry(
      id: '2',
      content: 'joined',
      date: DateTime(2026, 1, 2),
      mood: '😊',
      type: 'woop',
      sections: {'Wish': 'ship it', 'Obstacle': 'scope creep'},
    );
    final back = JournalEntry.fromJson(jsonDecode(jsonEncode(e.toJson())));
    expect(back.type, 'woop');
    expect(back.sections, {'Wish': 'ship it', 'Obstacle': 'scope creep'});
  });

  test('old entries without a type field still parse', () {
    final legacy = {
      'id': '3',
      'content': 'old',
      'date': DateTime(2025).toIso8601String(),
      'mood': '😴',
    };
    expect(JournalEntry.fromJson(legacy).type, 'free');
  });
}
