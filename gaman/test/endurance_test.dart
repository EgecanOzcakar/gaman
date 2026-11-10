import 'package:flutter_test/flutter_test.dart';
import 'package:gaman/data/models.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:gaman/endurance.dart';
import 'package:gaman/l10n/app_localizations.dart';

ActivityEvent urge(String tag, bool held, int hour) => ActivityEvent(
    type: ActivityType.urge,
    at: DateTime(2026, 1, 5, hour),
    meta: {'tag': tag, 'held': held});

void main() {
  test('every program step and trial id resolves', () {
    for (final p in programs) {
      for (final id in p.sequence) {
        expect(trialById(id), isNotNull, reason: '${p.id}: $id');
      }
      expect(p.trialForDay(p.days).id, isNotEmpty);
    }
    expect(trials.map((t) => t.id).toSet(), hasLength(trials.length));
  });

  test('programDay is 1-based and null outside the program', () {
    final p = programById('phone_fast')!;
    final start = DateTime(2026, 3, 1);
    expect(programDay(p, start, DateTime(2026, 3, 1, 23)), 1);
    expect(programDay(p, start, DateTime(2026, 3, 14)), 14);
    expect(programDay(p, start, DateTime(2026, 3, 15)), isNull);
    expect(programDay(p, start, DateTime(2026, 2, 28)), isNull);
  });

  test('urgeStats: hold rate, per-tag counts, hardest time', () {
    final s = urgeStats([
      urge('Phone', true, 9),
      urge('Phone', false, 22),
      urge('Phone', false, 23),
      urge('Food', true, 15),
      urge('Food', false, 10),
    ]);
    expect((s.held, s.total), (2, 5));
    expect(s.byTag['Phone'], (held: 1, total: 3));
    expect(s.hardestTime, 'night');
    expect(urgeStats(const []).hardestTime, isNull);
  });

  test('trialsByLevel counts only completed trials', () {
    ActivityEvent t(String id, String status) => ActivityEvent(
        type: ActivityType.trial, at: DateTime(2026), meta: {'id': id, 'status': status});
    expect(trialsByLevel([
      t('stairs', 'chosen'),
      t('stairs', 'done'),
      t('cold_full', 'done'),
      t('unknown', 'done'),
    ]), {1: 1, 2: 0, 3: 1});
  });

  test('every catalogue id has a translated string (no raw-id fallbacks)', () {
    final l = lookupAppLocalizations(const Locale('en'));
    for (final t in trials) {
      expect(l.trialTitle(t.id), isNot(t.id), reason: t.id);
    }
    for (final p in programs) {
      expect(l.programTitle(p.id), isNot(p.id), reason: p.id);
      expect(l.programBlurb(p.id), isNotEmpty, reason: p.id);
    }
    expect({for (final t in urgeTags) l.urgeTag(t)}, hasLength(urgeTags.length));
    expect({for (var i = 0; i < urgeGuidanceCount; i++) l.urgeGuidance(i)},
        hasLength(urgeGuidanceCount));
    expect(l.joinList(['a', 'b', 'c']), 'a, b and c');
  });
}
