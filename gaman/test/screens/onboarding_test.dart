import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaman/l10n/app_localizations.dart';
import 'package:gaman/screens/onboarding_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('first run: not done; after markDone: done', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await Onboarding.isDone(), isFalse);
    await Onboarding.markDone();
    expect(await Onboarding.isDone(), isTrue);
  });

  testWidgets('three pages, then marks done, asks for permission, goes home',
      (t) async {
    SharedPreferences.setMockInitialValues({});
    var asked = 0;
    await t.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: OnboardingScreen(
        requestPermission: () async => asked++,
        next: (_) => const Text('HOME'),
      ),
    ));

    expect(find.text('Gaman: patient endurance'), findsOneWidget);
    await t.tap(find.text('Next'));
    await t.pumpAndSettle();
    await t.tap(find.text('Next'));
    await t.pumpAndSettle();
    await t.tap(find.text('Get started'));
    await t.pumpAndSettle();

    expect(find.text('HOME'), findsOneWidget);
    expect(asked, 1);
    expect(await Onboarding.isDone(), isTrue);
  });
}
