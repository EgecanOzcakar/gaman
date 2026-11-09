import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaman/providers/activity_log.dart' show DayMark;
import 'package:gaman/theme/app_theme.dart';
import 'package:gaman/widgets/enso.dart';
import 'package:gaman/widgets/kintsugi_chain.dart';
import 'package:gaman/widgets/urge_wave.dart';
import 'package:gaman/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('urge wave rises to a peak at 25%, then falls to calm', () {
    expect(UrgeWave.envelope(0), 0);
    expect(UrgeWave.envelope(0.25), closeTo(1, 1e-9));
    expect(UrgeWave.envelope(1), 0);
    expect(UrgeWave.envelope(0.5), lessThan(UrgeWave.envelope(0.3)));
    expect(UrgeWave.envelope(2), 0, reason: 'clamped');
  });

  testWidgets('ensō, wave and chain paint (also under reduced motion)', (t) async {
    for (final reduced in [false, true]) {
      await t.pumpWidget(MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: const Scaffold(
            body: Column(children: [
              Enso(progress: 0.6),
              UrgeWave(progress: 0.4),
              KintsugiChain(marks: [DayMark.done, DayMark.mended, DayMark.done, DayMark.open]),
            ]),
          ),
        ),
      ));
      await t.pump(const Duration(milliseconds: 500));
      expect(t.takeException(), isNull);
    }
  });
}
