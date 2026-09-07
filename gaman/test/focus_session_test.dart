import 'package:flutter_test/flutter_test.dart';
import 'package:gaman/screens/focus_screen.dart';

void main() {
  final start = DateTime(2026, 1, 1, 9, 0, 0);
  const total = 25 * 60;
  final endsAt = start.add(const Duration(seconds: total));

  test('left 10 minutes in -> 10 minutes focused', () {
    final f = focusedSeconds(
      totalSeconds: total,
      endsAt: endsAt,
      ref: start.add(const Duration(minutes: 10)),
    );
    expect(f, 10 * 60);
  });

  test('returned after the phase ran out -> whole phase, not more', () {
    final f = focusedSeconds(
      totalSeconds: total,
      endsAt: endsAt,
      ref: start.add(const Duration(minutes: 40)),
    );
    expect(f, total);
  });

  test('left before it started -> zero, never negative', () {
    final f = focusedSeconds(
      totalSeconds: total,
      endsAt: endsAt,
      ref: start.subtract(const Duration(minutes: 5)),
    );
    expect(f, 0);
  });
}
