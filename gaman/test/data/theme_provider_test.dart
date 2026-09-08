import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gaman/data/local_repository.dart';
import 'package:gaman/providers/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('defaults to system; setThemeMode persists', () async {
    final repo = LocalRepository();
    await repo.ready;
    final t = ThemeProvider(repo);
    await t.ready;
    expect(t.themeMode, ThemeMode.system);

    await t.setThemeMode(ThemeMode.dark);
    await settle();
    expect(t.themeMode, ThemeMode.dark);

    final t2 = ThemeProvider(repo);
    await t2.ready;
    expect(t2.themeMode, ThemeMode.dark);
    await repo.dispose();
  });

  test('toggle flips light/dark', () async {
    final repo = LocalRepository();
    await repo.ready;
    final t = ThemeProvider(repo);
    await t.ready;
    await t.setThemeMode(ThemeMode.light);
    await settle();
    await t.toggle();
    await settle();
    expect(t.themeMode, ThemeMode.dark);
    await repo.dispose();
  });
}
