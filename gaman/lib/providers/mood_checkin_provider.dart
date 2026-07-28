import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/intl.dart';

class MoodCheckinProvider with ChangeNotifier {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final GlobalKey<NavigatorState> navigatorKey;

  static const String _wakeTimeKey = 'mood_checkin_wake_time';
  static const String _enabledKey = 'mood_checkin_enabled';
  static const List<int> _notificationIds = [100, 101, 102];
  static const List<Duration> _offsets = [
    Duration(minutes: 15),
    Duration(hours: 6),
    Duration(hours: 14),
  ];

  TimeOfDay? _wakeTime;
  bool _isEnabled = true;

  TimeOfDay? get wakeTime => _wakeTime;
  bool get isEnabled => _isEnabled;

  MoodCheckinProvider({required this.navigatorKey}) {
    _initialize();
  }

  Future<void> _initialize() async {
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

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload == 'mood_checkin') {
          navigatorKey.currentState?.pushNamed('/mood-checkin');
        }
      },
    );

    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool(_enabledKey) ?? true;
    final saved = prefs.getString(_wakeTimeKey);

    if (saved != null) {
      final parts = saved.split(':');
      _wakeTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      if (_isEnabled) await _scheduleAll();
    }

    notifyListeners();
  }

  Future<void> setWakeTime(TimeOfDay time) async {
    _wakeTime = time;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_wakeTimeKey, '${time.hour}:${time.minute}');
    if (_isEnabled) await _scheduleAll();
    notifyListeners();
  }

  Future<void> toggleEnabled(bool enabled) async {
    _isEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);

    if (enabled) {
      await _scheduleAll();
    } else {
      for (final id in _notificationIds) {
        await _notifications.cancel(id);
      }
    }

    notifyListeners();
  }

  Future<void> _scheduleAll() async {
    if (_wakeTime == null) return;

    final now = DateTime.now();
    final wakeToday = DateTime(
      now.year, now.month, now.day, _wakeTime!.hour, _wakeTime!.minute,
    );

    for (int i = 0; i < _offsets.length; i++) {
      var scheduled = wakeToday.add(_offsets[i]);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      await _notifications.zonedSchedule(
        _notificationIds[i],
        'Şu an ruh halin nasıl?',
        'Bir dakikanı ayırıp kendini 1-5 arası puanla.',
        tz.TZDateTime.from(scheduled, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'mood_checkin_channel',
            'Mood Check-in',
            channelDescription: 'Periodic mood check-in reminders',
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
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'mood_checkin',
      );
    }
  }

  Future<void> saveMoodScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final key = 'mood_scores_$today';
    final existing = prefs.getStringList(key) ?? [];
    existing.add(jsonEncode({
      'score': score,
      'timestamp': DateTime.now().toIso8601String(),
    }));
    await prefs.setStringList(key, existing);
  }
}