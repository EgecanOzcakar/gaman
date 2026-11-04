import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import '../data/models.dart';
import '../data/repository.dart';

class NotificationProvider with ChangeNotifier {
  NotificationProvider(this._repo) {
    _initializeNotifications();
  }

  final Repository _repo;
  StreamSubscription<AppSettings>? _settingsSub;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isEnabled = true;
  TimeOfDay? _scheduledTime;

  bool get isEnabled => _isEnabled;
  TimeOfDay? get scheduledTime => _scheduledTime;

  /// Plugin + timezone setup runs once per process, however many times the
  /// provider is created.
  static Future<void>? _pluginReady;

  static Future<void> _setUpPlugin(FlutterLocalNotificationsPlugin plugin) async {
    tz.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (e) {
      // Unknown zone id: tz.local stays UTC, so reminders may be off by the
      // UTC offset — better than not scheduling at all.
      debugPrint('Could not resolve local timezone: $e');
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    // Permission is asked for at the end of onboarding, not on launch.
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await plugin.initialize(initSettings);
  }

  /// Asks the OS for notification permission (Android 13+, iOS). Called once,
  /// from the end of onboarding.
  static Future<void> requestPermission() async {
    if (kIsWeb) return;
    final plugin = FlutterLocalNotificationsPlugin();
    await (_pluginReady ??= _setUpPlugin(plugin));
    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> _initializeNotifications() async {
    if (!kIsWeb) {
      await (_pluginReady ??= _setUpPlugin(_notifications));
    }
    await _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    _settingsSub = _repo.watchSettings().listen((s) {
      _isEnabled = s.reminderEnabled;
      _scheduledTime = (s.reminderHour != null && s.reminderMinute != null)
          ? TimeOfDay(hour: s.reminderHour!, minute: s.reminderMinute!)
          : null;
      notifyListeners();
    });

    // First-run: pick a random reminder time if none is stored.
    final first = await _repo.watchSettings().first;
    if (first.reminderHour == null) {
      await _scheduleRandomTime();
    }
  }

  Future<void> _scheduleRandomTime() async {
    final random = Random();
    // Schedule between 8 AM and 6 PM
    final hour = random.nextInt(11) + 8; // 8 to 18
    final minute = random.nextInt(60); // 0 to 59

    _scheduledTime = TimeOfDay(hour: hour, minute: minute);

    final current = await _repo.watchSettings().first;
    await _repo.saveSettings(current.copyWith(
      reminderHour: _scheduledTime!.hour,
      reminderMinute: _scheduledTime!.minute,
    ));

    await _scheduleNotification();
    notifyListeners();
  }

  Future<void> toggleNotifications(bool enabled) async {
    if (_isEnabled == enabled) return;

    _isEnabled = enabled;
    final current = await _repo.watchSettings().first;
    await _repo.saveSettings(current.copyWith(reminderEnabled: enabled));

    if (enabled) {
      await _scheduleNotification();
    } else {
      await _notifications.cancelAll();
    }

    notifyListeners();
  }

  Future<void> _scheduleNotification() async {
    if (kIsWeb || !_isEnabled || _scheduledTime == null) return;
    await _pluginReady;

    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      _scheduledTime!.hour,
      _scheduledTime!.minute,
    );

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      0,
      'Time for Reflection',
      'Take 10 minutes to reflect on your day and practice mindfulness.',
      tz.TZDateTime(tz.local, scheduledDate.year, scheduledDate.month,
          scheduledDate.day, scheduledDate.hour, scheduledDate.minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reflection_channel',
          'Daily Reflection',
          channelDescription: 'Notifications for daily reflection time',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      // A reflection nudge doesn't need to-the-minute precision, and inexact
      // avoids the SCHEDULE_EXACT_ALARM permission.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> rescheduleNotification() async {
    await _scheduleRandomTime();
  }

  /// Set an explicit reminder time (from the settings screen).
  Future<void> setTime(TimeOfDay time) async {
    _scheduledTime = time;
    final current = await _repo.watchSettings().first;
    await _repo.saveSettings(current.copyWith(
        reminderHour: time.hour, reminderMinute: time.minute));
    await _notifications.cancelAll();
    await _scheduleNotification();
    notifyListeners();
  }

  @override
  void dispose() {
    _settingsSub?.cancel();
    super.dispose();
  }
}
