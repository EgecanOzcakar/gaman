import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/splash_screen.dart';

// Import providers
import 'providers/quote_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/audio_provider.dart';
import 'providers/activity_log.dart';
import 'providers/feature_prefs.dart';
import 'providers/settings_provider.dart';
import 'data/local_repository.dart';
import 'data/repository.dart';
import 'data/firestore_repository.dart';
import 'data/local_to_firestore_migration.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init failed; running local-only: $e');
  }

  final auth = AuthService();
  await auth.ensureSignedIn();
  final Repository repository = auth.uid != null
      ? FirestoreRepository(uid: auth.uid!)
      : LocalRepository();

  if (repository is FirestoreRepository) {
    try {
      await LocalToFirestoreMigration(remote: repository).run();
    } catch (e) {
      debugPrint('Local→Firestore migration failed (will retry next launch): $e');
    }
  }

  // Initialize notifications (only on mobile platforms)
  if (!kIsWeb) {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Initialize WorkManager for background tasks (only on mobile platforms)
    await Workmanager().initialize(callbackDispatcher);
    
    // Request necessary permissions (only on mobile platforms)
    await Permission.notification.request();
  }
  
  runApp(MyApp(repository: repository, auth: auth));
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Handle background tasks here
    return Future.value(true);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.repository, required this.auth});

  final Repository repository;
  final AuthService auth;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<Repository>.value(value: repository),
        ChangeNotifierProvider<AuthService>.value(value: auth),
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
            title: 'Gaman',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(), // Changed from HomeScreen to SplashScreen
          );
        },
      ),
    );
  }
}
