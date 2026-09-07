// Smoke tests for the UI-polish theme + motion layer.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:gaman/theme/app_theme.dart';
import 'package:gaman/theme/motion.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('theme palette keeps a cool (blue-green) accent, not warm terracotta', () {
    // Guards against drifting back to the generic cream/terracotta look.
    expect(HSLColor.fromColor(AppColors.water).hue, greaterThan(140));
    expect(HSLColor.fromColor(AppColors.water).hue, lessThan(200));
    expect(AppColors.mist.blue, greaterThanOrEqualTo(AppColors.mist.red - 8));
  });

  testWidgets('FadeSlideIn shows its child immediately under reduced motion',
      (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: FadeSlideIn(child: Text('content')),
        ),
      ),
    );

    expect(find.text('content'), findsOneWidget);
    // No opacity wrapper animating it in.
    expect(find.byType(AnimatedOpacity), findsNothing);
  });

  testWidgets('PressScale shrinks on tap-down and restores on release',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PressScale(onTap: () {}, child: const Text('tap me')),
          ),
        ),
      ),
    );

    double scaleOf() =>
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;

    expect(scaleOf(), 1.0);
    final gesture = await tester.startGesture(tester.getCenter(find.text('tap me')));
    await tester.pump();
    expect(scaleOf(), lessThan(1.0));
    await gesture.up();
    await tester.pump();
    expect(scaleOf(), 1.0);
  });
}
