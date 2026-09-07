import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// "Stone & still water" — a cool, quiet palette for a Stoic practice app.
/// Deliberately not the warm-cream/serif/terracotta default: backgrounds are
/// grey-green, the accent is deep duck-egg, decoration is hairline borders
/// rather than drop shadows.
class AppColors {
  static const ink = Color(0xFF1C2B2B); // primary text, dark surface
  static const slate = Color(0xFF33484A); // secondary text / containers
  static const water = Color(0xFF5F8F8C); // primary accent
  static const waterDark = Color(0xFF8FBDBA); // accent on dark
  static const reed = Color(0xFF7C8C52); // secondary (journal)
  static const brass = Color(0xFF9C7F4E); // tertiary (binaural), used sparingly
  static const clayError = Color(0xFFB5654A); // focus timer / errors

  static const mist = Color(0xFFECEDE8); // light background
  static const paper = Color(0xFFF6F6F2); // light surface
  static const nightBg = Color(0xFF131C1C); // dark background
  static const nightSurface = Color(0xFF1C2B2B); // dark surface
}

/// Spacing scale. One set of steps, used everywhere instead of ad-hoc numbers.
class Insets {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

class Radii {
  static const control = 12.0;
  static const card = 20.0;
}

class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.water,
      brightness: brightness,
    ).copyWith(
      primary: isDark ? AppColors.waterDark : AppColors.water,
      secondary: AppColors.reed,
      tertiary: AppColors.brass,
      error: AppColors.clayError,
      surface: isDark ? AppColors.nightSurface : AppColors.paper,
      surfaceContainerLowest: isDark ? AppColors.nightBg : AppColors.mist,
    );

    final base = ThemeData(useMaterial3: true, brightness: brightness, colorScheme: scheme);

    // EB Garamond carries the personality (titles, quotes); Manrope is the
    // quiet workhorse for everything interactive.
    final display = GoogleFonts.ebGaramondTextTheme(base.textTheme);
    final body = GoogleFonts.manropeTextTheme(base.textTheme);
    final textTheme = body.copyWith(
      displayLarge: display.displayLarge?.copyWith(fontWeight: FontWeight.w500, letterSpacing: 0.5),
      displayMedium: display.displayMedium?.copyWith(fontWeight: FontWeight.w500),
      displaySmall: display.displaySmall?.copyWith(fontWeight: FontWeight.w500),
      headlineLarge: display.headlineLarge?.copyWith(fontWeight: FontWeight.w500),
      headlineMedium: display.headlineMedium?.copyWith(fontWeight: FontWeight.w500),
      headlineSmall: display.headlineSmall?.copyWith(fontWeight: FontWeight.w500, height: 1.4),
      titleLarge: display.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    ).apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surfaceContainerLowest,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        titleTextStyle: textTheme.headlineSmall,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.card),
          side: BorderSide(color: scheme.outlineVariant.withOpacity(0.6)),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: Insets.lg, vertical: Insets.md),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.control)),
          textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.control),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.control),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.linux: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.windows: FadeThroughPageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// A quiet fade-through page transition (no reliance on the `animations`
/// package). Outgoing view fades out, incoming fades in with a small rise.
class FadeThroughPageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeThroughPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.02), end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  }
}
