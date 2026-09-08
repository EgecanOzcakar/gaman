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

  test('streak counts consecutive days and stops at the first gap', () async {
    final log = await makeLog();
    await log.log(ActivityType.journal, at: DateTime.now());
    await log.log(ActivityType.focus, at: daysAgo(1));
    await log.log(ActivityType.meditation, at: daysAgo(2));
    // gap on day 3
    await log.log(ActivityType.journal, at: daysAgo(4));
    await settle();

    expect(log.currentStreak, 3);
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
