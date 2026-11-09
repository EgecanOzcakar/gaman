import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gaman/data/local_repository.dart';
import 'package:gaman/providers/activity_log.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  DateTime daysAgo(int n) => DateTime.now().subtract(Duration(days: n));

  Future<ActivityLog> makeLog([LocalRepository? repo]) async {
    final r = repo ?? LocalRepository();
    await r.ready;
    final log = ActivityLog(r);
    await log.ready;
    return log;
  }

  /// Let the repository's broadcast stream deliver its latest event to the
  /// provider before assertions read [ActivityLog] queries.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('never miss twice: a single gap is mended, two in a row end it',
      () async {
    final log = await makeLog();
    await log.log(ActivityType.journal, at: DateTime.now());
    await log.log(ActivityType.focus, at: daysAgo(1));
    await log.log(ActivityType.meditation, at: daysAgo(2));
    // single gap on day 3: mended
    await log.log(ActivityType.journal, at: daysAgo(4));
    // two-day gap on days 5-6: chain ends
    await log.log(ActivityType.journal, at: daysAgo(7));
    await settle();

    expect(log.chain, (days: 4, mended: 1, atRisk: false));
    expect(log.currentStreak, 4);
    expect(log.recentMarks(8), [
      DayMark.done, DayMark.missed, DayMark.missed, DayMark.done,
      DayMark.mended, DayMark.done, DayMark.done, DayMark.done,
    ]);
  });

  test('a missed yesterday puts the chain at risk until today is practised',
      () async {
    final log = await makeLog();
    await log.log(ActivityType.focus, at: daysAgo(2));
    await log.log(ActivityType.focus, at: daysAgo(3));
    await settle();

    expect(log.chain, (days: 2, mended: 0, atRisk: true));
    expect(log.recentMarks(2), [DayMark.atRisk, DayMark.open]);

    await log.log(ActivityType.urge, meta: {'tag': 'Phone', 'held': true});
    await settle();
    expect(log.chain, (days: 3, mended: 1, atRisk: false));
  });

  test('choosing a trial is not practice; doing it is', () async {
    final log = await makeLog();
    await log.log(ActivityType.trial, meta: {'id': 'stairs', 'status': 'chosen'});
    await settle();
    expect(log.didAnythingOn(DateTime.now()), isFalse);
    expect(log.trialOn(DateTime.now()), (id: 'stairs', done: false));

    await log.log(ActivityType.trial, meta: {'id': 'stairs', 'status': 'done'});
    await settle();
    expect(log.didAnythingOn(DateTime.now()), isTrue);
    expect(log.trialOn(DateTime.now()), (id: 'stairs', done: true));
  });

  test('streak still counts when today is empty but yesterday was active',
      () async {
    final log = await makeLog();
    await log.log(ActivityType.focus, at: daysAgo(1));
    await log.log(ActivityType.focus, at: daysAgo(2));
    await settle();

    expect(log.currentStreak, 2);
  });

  test('streak is zero when the last activity was more than a day ago',
      () async {
    final log = await makeLog();
    await log.log(ActivityType.focus, at: daysAgo(3));
    await settle();

    expect(log.currentStreak, 0);
  });

  test('minutesThisWeek sums durations for one type', () async {
    final log = await makeLog();
    await log.log(ActivityType.meditation, durationSeconds: 600);
    await log.log(ActivityType.meditation, durationSeconds: 300);
    await log.log(ActivityType.focus, durationSeconds: 1500);
    await settle();

    expect(log.minutesThisWeek(ActivityType.meditation), 15);
  });

  test('count / activeDays over an explicit range', () async {
    final log = await makeLog();
    await log.log(ActivityType.focus, at: daysAgo(1));
    await log.log(ActivityType.focus, at: daysAgo(1)); // same day
    await log.log(ActivityType.focus, at: daysAgo(2));
    await log.log(ActivityType.focus, at: daysAgo(30)); // outside range
    await settle();

    final from = ActivityLog.weekStart().subtract(const Duration(days: 7));
    final to = DateTime.now().add(const Duration(days: 1));
    expect(log.count(ActivityType.focus, from, to), 3);
    expect(log.activeDays(from, to), 2);
  });

  test('events survive a reload (JSON round-trip)', () async {
    SharedPreferences.setMockInitialValues({});
    final a = await makeLog();
    await a.log(ActivityType.journal, meta: {'note': 'has, commas: and colons'});
    await settle();

    final b = await makeLog();
    expect(b.events, hasLength(1));
    expect(b.events.first.meta['note'], 'has, commas: and colons');
  });
}
