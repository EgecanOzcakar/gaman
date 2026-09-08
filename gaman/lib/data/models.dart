import 'package:flutter/material.dart' show ThemeMode;

class JournalEntry {
  final String id;
  final String content;
  final DateTime date;
  final String mood;

  /// 'free', 'gratitude', 'evening', 'thought_record', 'woop'.
  final String type;

  /// Structured entries: ordered label -> answer. Null for free text.
  final Map<String, String>? sections;

  JournalEntry({
    required this.id,
    required this.content,
    required this.date,
    required this.mood,
    this.type = 'free',
    this.sections,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'date': date.toIso8601String(),
        'mood': mood,
        'type': type,
        if (sections != null) 'sections': sections,
      };

  factory JournalEntry.fromJson(Map<String, dynamic> j) => JournalEntry(
        id: j['id'] as String,
        content: j['content'] as String,
        date: DateTime.parse(j['date'] as String),
        mood: j['mood'] as String,
        type: j['type'] as String? ?? 'free',
        sections: (j['sections'] as Map?)
            ?.map((k, v) => MapEntry(k.toString(), v.toString())),
      );
}

class TodoTask {
  final String id;
  String title;
  bool isCompleted;
  final bool isMainTask;
  final DateTime createdAt;

  TodoTask({
    required this.id,
    required this.title,
    this.isCompleted = false,
    required this.isMainTask,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
        'isMainTask': isMainTask,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TodoTask.fromJson(Map<String, dynamic> j) => TodoTask(
        id: j['id'] as String,
        title: j['title'] as String,
        isCompleted: j['isCompleted'] as bool? ?? false,
        isMainTask: j['isMainTask'] as bool? ?? false,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}

enum ActivityType { meditation, focus, journal, taskDone }

class ActivityEvent {
  final ActivityType type;
  final DateTime at;
  final int durationSeconds;
  final Map<String, dynamic> meta;

  ActivityEvent({
    required this.type,
    required this.at,
    this.durationSeconds = 0,
    this.meta = const {},
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'at': at.toIso8601String(),
        'dur': durationSeconds,
        if (meta.isNotEmpty) 'meta': meta,
      };

  factory ActivityEvent.fromJson(Map<String, dynamic> j) => ActivityEvent(
        type: ActivityType.values.byName(j['type'] as String),
        at: DateTime.parse(j['at'] as String),
        durationSeconds: (j['dur'] as num?)?.toInt() ?? 0,
        meta: (j['meta'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
}

class AppSettings {
  final ThemeMode themeMode;
  final int meditationMinutes;
  final int breathSeconds;
  final int focusMinutes;
  final int longBreakEvery;
  final int completedPomodoros;
  final bool reminderEnabled;
  final int? reminderHour;
  final int? reminderMinute;
  final Set<String> disabledFeatures;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.meditationMinutes = 10,
    this.breathSeconds = 4,
    this.focusMinutes = 25,
    this.longBreakEvery = 4,
    this.completedPomodoros = 0,
    this.reminderEnabled = true,
    this.reminderHour,
    this.reminderMinute,
    this.disabledFeatures = const {},
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    int? meditationMinutes,
    int? breathSeconds,
    int? focusMinutes,
    int? longBreakEvery,
    int? completedPomodoros,
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
    Set<String>? disabledFeatures,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        meditationMinutes: meditationMinutes ?? this.meditationMinutes,
        breathSeconds: breathSeconds ?? this.breathSeconds,
        focusMinutes: focusMinutes ?? this.focusMinutes,
        longBreakEvery: longBreakEvery ?? this.longBreakEvery,
        completedPomodoros: completedPomodoros ?? this.completedPomodoros,
        reminderEnabled: reminderEnabled ?? this.reminderEnabled,
        reminderHour: reminderHour ?? this.reminderHour,
        reminderMinute: reminderMinute ?? this.reminderMinute,
        disabledFeatures: disabledFeatures ?? this.disabledFeatures,
      );

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.name,
        'meditationMinutes': meditationMinutes,
        'breathSeconds': breathSeconds,
        'focusMinutes': focusMinutes,
        'longBreakEvery': longBreakEvery,
        'completedPomodoros': completedPomodoros,
        'reminderEnabled': reminderEnabled,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'disabledFeatures': disabledFeatures.toList(),
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) {
    const d = AppSettings();
    return AppSettings(
      themeMode: ThemeMode.values.asNameMap()[j['themeMode']] ?? d.themeMode,
      meditationMinutes: (j['meditationMinutes'] as num?)?.toInt() ?? d.meditationMinutes,
      breathSeconds: (j['breathSeconds'] as num?)?.toInt() ?? d.breathSeconds,
      focusMinutes: (j['focusMinutes'] as num?)?.toInt() ?? d.focusMinutes,
      longBreakEvery: (j['longBreakEvery'] as num?)?.toInt() ?? d.longBreakEvery,
      completedPomodoros: (j['completedPomodoros'] as num?)?.toInt() ?? d.completedPomodoros,
      reminderEnabled: j['reminderEnabled'] as bool? ?? d.reminderEnabled,
      reminderHour: (j['reminderHour'] as num?)?.toInt(),
      reminderMinute: (j['reminderMinute'] as num?)?.toInt(),
      disabledFeatures: ((j['disabledFeatures'] as List?) ?? const [])
          .map((e) => e.toString())
          .toSet(),
    );
  }
}
