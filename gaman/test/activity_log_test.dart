import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gaman/providers/activity_log.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  DateTime daysAgo(int n) => DateTime.now().subtract(Duration(days: n));

  test('streak counts consecutive days and stops at the first gap', () async {
    final log = ActivityLog();
    await log.log(ActivityType.journal, at: DateTime.now());
    await log.log(ActivityType.focus, at: daysAgo(1));
    await log.log(ActivityType.meditation, at: daysAgo(2));
    // gap on day 3
    await log.log(ActivityType.journal, at: daysAgo(4));

    expect(log.currentStreak, 3);
  });

  test('streak still counts when today is empty but yesterday was active',
      () async {
    final log = ActivityLog();
    await log.log(ActivityType.focus, at: daysAgo(1));
    await log.log(ActivityType.focus, at: daysAgo(2));

    expect(log.currentStreak, 2);
  });

  test('streak is zero when the last activity was more than a day ago',
      () async {
    final log = ActivityLog();
    await log.log(ActivityType.focus, at: daysAgo(3));

    expect(log.currentStreak, 0);
  });

  test('minutesThisWeek sums durations for one type', () async {
    final log = ActivityLog();
    await log.log(ActivityType.meditation, durationSeconds: 600);
    await log.log(ActivityType.meditation, durationSeconds: 300);
    await log.log(ActivityType.focus, durationSeconds: 1500);

    expect(log.minutesThisWeek(ActivityType.meditation), 15);
  });

  test('events survive a reload (JSON round-trip)', () async {
    final a = ActivityLog();
    await a.log(ActivityType.journal, meta: {'note': 'has, commas: and colons'});

    final b = ActivityLog();
    await Future<void>.delayed(Duration.zero);
    expect(b.events, hasLength(1));
    expect(b.events.first.meta['note'], 'has, commas: and colons');
  });
}
