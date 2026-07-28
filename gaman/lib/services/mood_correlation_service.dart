import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CorrelationResult {
  final double avgMoodHighCompletion;
  final double avgMoodLowCompletion;
  final int highCompletionDays;
  final int lowCompletionDays;
  final bool hasEnoughData;

  CorrelationResult({
    required this.avgMoodHighCompletion,
    required this.avgMoodLowCompletion,
    required this.highCompletionDays,
    required this.lowCompletionDays,
    required this.hasEnoughData,
  });
}

class MoodCorrelationService {
  static const int _minDaysPerGroup = 3;
  static const int _minTotalDays = 10;

  Future<CorrelationResult> computeTaskMoodCorrelation() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    final todoKeys = keys.where((k) => k.startsWith('todo_tasks_'));
    final moodKeys = keys.where((k) => k.startsWith('mood_scores_'));
    final moodDates = moodKeys.map((k) => k.substring('mood_scores_'.length)).toSet();

    final List<double> highCompletionMoods = [];
    final List<double> lowCompletionMoods = [];

    for (final todoKey in todoKeys) {
      final date = todoKey.substring('todo_tasks_'.length);
      if (!moodDates.contains(date)) continue;

      final taskStrings = prefs.getStringList(todoKey) ?? [];
      if (taskStrings.isEmpty) continue;

      int completed = 0;
      for (final taskStr in taskStrings) {
        final fields = <String, String>{};
        for (final part in taskStr.split(',')) {
          final kv = part.split(':');
          if (kv.length >= 2) {
            fields[kv[0]] = kv.sublist(1).join(':');
          }
        }
        if (fields['isCompleted'] == 'true') completed++;
      }
      final completionRate = completed / taskStrings.length;

      final moodJsonList = prefs.getStringList('mood_scores_$date') ?? [];
      if (moodJsonList.isEmpty) continue;
      final scores = moodJsonList.map((s) {
        final decoded = jsonDecode(s) as Map<String, dynamic>;
        return (decoded['score'] as num).toDouble();
      }).toList();
      final avgMoodForDay = scores.reduce((a, b) => a + b) / scores.length;

      if (completionRate >= 0.99) {
        highCompletionMoods.add(avgMoodForDay);
      } else if (completionRate <= 0.34) {
        lowCompletionMoods.add(avgMoodForDay);
      }
    }

    double avgOf(List<double> list) =>
        list.isEmpty ? 0 : list.reduce((a, b) => a + b) / list.length;

    return CorrelationResult(
      avgMoodHighCompletion: avgOf(highCompletionMoods),
      avgMoodLowCompletion: avgOf(lowCompletionMoods),
      highCompletionDays: highCompletionMoods.length,
      lowCompletionDays: lowCompletionMoods.length,
      hasEnoughData: highCompletionMoods.length >= _minDaysPerGroup &&
          lowCompletionMoods.length >= _minDaysPerGroup &&
          (highCompletionMoods.length + lowCompletionMoods.length) >= _minTotalDays,
    );
  }
}