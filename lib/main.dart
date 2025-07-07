import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:google_fonts/google_fonts.dart';  // Commenting out until we have fonts
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

// Import screens
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/meditation_screen.dart';
import 'screens/journal_screen.dart';
import 'screens/binaural_beats_screen.dart';
import 'screens/focus_screen.dart';

// Import providers
import 'providers/quote_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/theme_provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => QuoteProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          // Define our duck egg blue color palette
          const duckEggBlue = Color(0xFF8FB3B3);
          const darkDuckEggBlue = Color(0xFF6B8A8A);
          const lightDuckEggBlue = Color(0xFFB3D9D9);
          const accentColor = Color(0xFF2C3E50);

          return MaterialApp(
            title: 'Gaman',
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: duckEggBlue,
                primary: duckEggBlue,
                secondary: accentColor,
                tertiary: lightDuckEggBlue,
                surface: Colors.white,
                background: Colors.white,
                brightness: Brightness.light,
              ),
              appBarTheme: AppBarTheme(
                centerTitle: true,
                elevation: 0,
                backgroundColor: Colors.transparent,
                foregroundColor: accentColor,
                iconTheme: IconThemeData(color: accentColor),
              ),
              cardTheme: CardTheme(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
                surfaceTintColor: duckEggBlue.withOpacity(0.1),
              ),
              dividerTheme: DividerThemeData(
                color: duckEggBlue.withOpacity(0.2),
                thickness: 1,
              ),
              iconTheme: IconThemeData(
                color: accentColor,
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: duckEggBlue,
                primary: duckEggBlue,
                secondary: accentColor,
                tertiary: darkDuckEggBlue,
                surface: const Color(0xFF1A1A1A),
                background: const Color(0xFF121212),
                brightness: Brightness.dark,
              ),
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                elevation: 0,
                backgroundColor: Colors.transparent,
              ),
              cardTheme: CardTheme(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: const Color(0xFF1A1A1A),
                surfaceTintColor: duckEggBlue.withOpacity(0.1),
              ),
              dividerTheme: DividerThemeData(
                color: duckEggBlue.withOpacity(0.2),
                thickness: 1,
              ),
              iconTheme: IconThemeData(
                color: duckEggBlue,
              ),
            ),
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(), // Changed from HomeScreen to SplashScreen
          );
        },
      ),
    );
  }
} 