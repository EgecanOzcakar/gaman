import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

  Future<void> _initializeNotifications() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
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
    if (!_isEnabled || _scheduledTime == null) return;

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
      tz.TZDateTime.from(scheduledDate, tz.local),
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
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
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
