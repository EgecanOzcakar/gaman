import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeminiService {
  static const String _apiKeyKey = 'gemini_api_key';
  late final GenerativeModel _model;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString(_apiKeyKey);
    
    if (apiKey != null && apiKey.isNotEmpty) {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
      );
      _isInitialized = true;
    }
  }

  Future<void> setApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyKey, apiKey);
    
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );
    _isInitialized = true;
  }

  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyKey);
  }

  Future<bool> isConfigured() async {
    await initialize();
    return _isInitialized;
  }

  Future<Map<String, List<String>>> generateTasks({
    required String userRole,
    required String currentFocus,
    required String timeOfDay,
  }) async {
    if (!_isInitialized) {
      throw Exception('Gemini service not initialized. Please set API key first.');
    }

    final prompt = '''
You are a productivity coach helping someone plan their day. Based on the following information, suggest:

1. ONE main "eat the frog" task (most important, challenging task that should be done first)
2. 3-5 smaller "cruise" tasks (easier, less critical tasks that can be done throughout the day)

User context:
- Role: $userRole
- Current focus/goal: $currentFocus
- Time of day: $timeOfDay

Guidelines:
- Main task should be specific, actionable, and the most impactful
- Cruise tasks should be smaller, easier wins that support the main goal
- Keep tasks concise (max 50 characters each)
- Make them realistic for the given time context
- Focus on professional/work-related tasks

Respond in this exact JSON format:
{
  "main_task": "Your main task here",
  "cruise_tasks": ["task 1", "task 2", "task 3", "task 4"]
}
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final responseText = response.text;
      
      if (responseText == null) {
        throw Exception('No response from Gemini');
      }

      // Extract JSON from response
      final jsonStart = responseText.indexOf('{');
      final jsonEnd = responseText.lastIndexOf('}') + 1;
      
      if (jsonStart == -1 || jsonEnd == 0) {
        throw Exception('Invalid response format from Gemini');
      }

      final jsonString = responseText.substring(jsonStart, jsonEnd);
      
      // Simple JSON parsing (you might want to use dart:convert for production)
      final mainTaskMatch = RegExp(r'"main_task":\s*"([^"]+)"').firstMatch(jsonString);
      final cruiseTasksMatch = RegExp(r'"cruise_tasks":\s*\[(.*?)\]').firstMatch(jsonString);
      
      String? mainTask;
      List<String> cruiseTasks = [];
      
      if (mainTaskMatch != null) {
        mainTask = mainTaskMatch.group(1);
      }
      
      if (cruiseTasksMatch != null) {
        final cruiseTasksString = cruiseTasksMatch.group(1)!;
        final taskMatches = RegExp(r'"([^"]+)"').allMatches(cruiseTasksString);
        cruiseTasks = taskMatches.map((match) => match.group(1)!).toList();
      }

      return {
        'main_task': mainTask != null ? [mainTask] : [],
        'cruise_tasks': cruiseTasks,
      };
    } catch (e) {
      throw Exception('Failed to generate tasks: $e');
    }
  }
} 