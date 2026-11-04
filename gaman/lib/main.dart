import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';
import 'data/active_repository.dart';
import 'data/firestore_repository.dart';
import 'data/local_repository.dart';
import 'data/local_to_firestore_migration.dart';
import 'data/repository.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'providers/activity_log.dart';
import 'providers/audio_provider.dart';
import 'providers/feature_prefs.dart';
import 'providers/notification_provider.dart';
import 'providers/quote_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/crash_reporting.dart';
import 'services/entitlement_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fonts ship in assets/google_fonts (OFL); never fetch at runtime.
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(() async* {
    for (final f in ['EBGaramond', 'Manrope']) {
      yield LicenseEntryWithLineBreaks([f],
          await rootBundle.loadString('assets/google_fonts/OFL-$f.txt'));
    }
  });

  // Local only (reads bundled config), no network round-trip.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init failed; running local-only: $e');
  }
  if (AppConfig.appCheck && Firebase.apps.isNotEmpty && !kIsWeb) {
    unawaited(FirebaseAppCheck.instance
        .activate(
          providerAndroid: kDebugMode
              ? const AndroidDebugProvider()
              : const AndroidPlayIntegrityProvider(),
          providerApple: kDebugMode
              ? const AppleDebugProvider()
              : const AppleAppAttestWithDeviceCheckFallbackProvider(),
        )
        .catchError((Object e) => debugPrint('App Check failed: $e')));
  }
  // The removed Gemini feature stored a user API key; don't leave it behind.
  unawaited(SharedPreferences.getInstance().then((p) => p.remove('gemini_api_key')));

  final crash = CrashReporting();
  unawaited(crash.init());

  // Returning users already have a cached uid; first launch starts local and
  // switches to Firestore once the background anonymous sign-in lands.
  final auth = AuthService();
  final repository = ActiveRepository.followAuth(
    auth,
    build: (uid) =>
        uid == null ? LocalRepository() : FirestoreRepository(uid: uid),
    onSignedIn: (repo) => unawaited(
      LocalToFirestoreMigration(remote: repo as FirestoreRepository)
          .run()
          .catchError((Object e) {
        debugPrint('Local→Firestore migration failed (retries next sign-in): $e');
        return false;
      }),
    ),
  );

  runApp(MyApp(repository: repository, auth: auth, crash: crash));
  unawaited(auth.ensureSignedIn());
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.repository,
    required this.auth,
    required this.crash,
  });

  final Repository repository;
  final AuthService auth;
  final CrashReporting crash;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<Repository>.value(value: repository),
        ChangeNotifierProvider<AuthService>.value(value: auth),
        ChangeNotifierProvider<CrashReporting>.value(value: crash),
        ChangeNotifierProvider(create: (_) => EntitlementService()),
        ChangeNotifierProvider(create: (_) => QuoteProvider()),
        ChangeNotifierProvider(
            create: (ctx) => NotificationProvider(ctx.read<Repository>())),
        ChangeNotifierProvider(
            create: (ctx) => ThemeProvider(ctx.read<Repository>())),
        ChangeNotifierProvider(create: (_) => AudioProvider()),
        ChangeNotifierProvider(
            create: (ctx) => ActivityLog(ctx.read<Repository>())),
        ChangeNotifierProvider(
            create: (ctx) => FeaturePrefs(ctx.read<Repository>())),
        ChangeNotifierProvider(
            create: (ctx) => SettingsProvider(ctx.read<Repository>())),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appTitle,
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
