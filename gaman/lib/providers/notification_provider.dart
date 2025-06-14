import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationProvider with ChangeNotifier {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static const String _notificationTimeKey = 'notification_time';
  static const String _notificationEnabledKey = 'notification_enabled';

  bool _isEnabled = true;
  TimeOfDay? _scheduledTime;

  bool get isEnabled => _isEnabled;
  TimeOfDay? get scheduledTime => _scheduledTime;

  NotificationProvider() {
    _initializeNotifications();
  }

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
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool(_notificationEnabledKey) ?? true;
    final savedTime = prefs.getString(_notificationTimeKey);
    
    if (savedTime != null) {
      final parts = savedTime.split(':');
      _scheduledTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } else {
      await _scheduleRandomTime();
    }
    
    notifyListeners();
  }

  Future<void> _scheduleRandomTime() async {
    final random = Random();
    // Schedule between 8 AM and 6 PM
    final hour = random.nextInt(11) + 8; // 8 to 18
    final minute = random.nextInt(60); // 0 to 59
    
    _scheduledTime = TimeOfDay(hour: hour, minute: minute);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _notificationTimeKey,
      '${_scheduledTime!.hour}:${_scheduledTime!.minute}',
    );
    
    await _scheduleNotification();
    notifyListeners();
  }

  Future<void> toggleNotifications(bool enabled) async {
    if (_isEnabled == enabled) return;
    
    _isEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationEnabledKey, enabled);
    
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
} 