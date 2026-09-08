import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gaman/data/local_repository.dart';
import 'package:gaman/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('defaults, then a setter persists and notifies', () async {
    final repo = LocalRepository();
    await repo.ready;
    final s = SettingsProvider(repo);
    await s.ready;

    expect(s.focusMinutes, 25);
    var notified = 0;
    s.addListener(() => notified++);

    await s.setFocusMinutes(45);
    await settle();
    expect(s.focusMinutes, 45);
    expect(notified, greaterThan(0));

    final s2 = SettingsProvider(repo);
    await s2.ready;
    expect(s2.focusMinutes, 45);
    await repo.dispose();
  });
}
