import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaman/l10n/app_localizations.dart';
import 'package:gaman/providers/activity_log.dart';
import 'package:gaman/screens/insights_screen.dart';
import 'package:gaman/services/entitlement_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gaman/data/local_repository.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('defaults to free; nothing premium is unlocked', () {
    final e = EntitlementService();
    expect(e.isPremium, isFalse);
    for (final f in PremiumFeature.values) {
      expect(e.has(f), isFalse);
    }
  });

  test('mock purchase does not grant premium (no billing yet)', () async {
    final e = EntitlementService();
    expect(await e.purchase(premiumPlans.first.id), isFalse);
    expect(e.isPremium, isFalse);
  });

  test('debug toggle unlocks every premium feature', () {
    final e = EntitlementService()..setDebugPremium(true);
    expect(e.has(PremiumFeature.advancedInsights), isTrue);
    expect(e.has(PremiumFeature.extraBeats), isTrue);
  });

  Future<void> pumpInsights(WidgetTester t, EntitlementService e) async {
    SharedPreferences.setMockInitialValues({});
    t.view.physicalSize = const Size(1200, 4000); // whole list on screen
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final repo = LocalRepository();
    await t.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: e),
        ChangeNotifierProvider(create: (_) => ActivityLog(repo)),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(body: InsightsScreen()),
      ),
    ));
    await t.pumpAndSettle();
  }

  testWidgets('free users see the weekly review locked', (t) async {
    await pumpInsights(t, EntitlementService());
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(find.textContaining('Included with Premium'), findsOneWidget);
  });

  testWidgets('premium users get the weekly review', (t) async {
    await pumpInsights(t, EntitlementService(premium: true));
    expect(find.byIcon(Icons.lock_outline), findsNothing);
    expect(find.textContaining('Nothing logged yet'), findsOneWidget);
  });
}
