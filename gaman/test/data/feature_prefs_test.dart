import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gaman/data/local_repository.dart';
import 'package:gaman/providers/feature_prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('all enabled by default; disabling one persists', () async {
    final repo = LocalRepository();
    await repo.ready;
    final f = FeaturePrefs(repo);
    await f.ready;

    expect(f.isEnabled('journal'), isTrue);
    await f.setEnabled('journal', false);
    await settle();
    expect(f.isEnabled('journal'), isFalse);

    final f2 = FeaturePrefs(repo);
    await f2.ready;
    expect(f2.isEnabled('journal'), isFalse);
    expect(f2.isEnabled('focus'), isTrue);
    await repo.dispose();
  });
}
