import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../widgets/persistent_audio_control.dart';
import '../services/gemini_service.dart';
import '../widgets/generate_tasks_dialog.dart';
import 'settings_screen.dart';

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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'isMainTask': isMainTask,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TodoTask.fromJson(Map<String, dynamic> json) {
    return TodoTask(
      id: json['id'],
      title: json['title'],
      isCompleted: json['isCompleted'] ?? false,
      isMainTask: json['isMainTask'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final List<TodoTask> _tasks = [];
  final _mainTaskController = TextEditingController();
  final List<TextEditingController> _cruiseTaskControllers = [];
  final GeminiService _geminiService = GeminiService();
  bool _isGeneratingTasks = false;
  bool _isAiConfigured = false;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _checkAiConfiguration();
  }

  Future<void> _checkAiConfiguration() async {
    try {
      final isConfigured = await _geminiService.isConfigured();
      if (mounted) {
        setState(() {
          _isAiConfigured = isConfigured;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAiConfigured = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _mainTaskController.dispose();
    for (var controller in _cruiseTaskControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final tasksJson = prefs.getStringList('todo_tasks_$today') ?? [];
    
    setState(() {
      _tasks.clear();
      if (tasksJson.isNotEmpty) {
        for (final taskJson in tasksJson) {
          try {
            final task = TodoTask.fromJson(Map<String, dynamic>.from(
              Map.fromEntries(
                taskJson.split(',').map((e) {
                  final parts = e.split(':');
                  return MapEntry(parts[0], parts[1]);
                }),
              ),
            ));
            _tasks.add(task);
          } catch (e) {
            debugPrint('Error loading task: $e');
          }
        }
      } else {
        // Initialize with main task and one cruise task
        _tasks.addAll([
          TodoTask(
            id: 'main_${DateTime.now().millisecondsSinceEpoch}',
            title: '',
            isMainTask: true,
            createdAt: DateTime.now(),
          ),
          TodoTask(
            id: 'cruise_1_${DateTime.now().millisecondsSinceEpoch}',
            title: '',
            isMainTask: false,
            createdAt: DateTime.now(),
          ),
        ]);
      }
    });

    // Initialize controllers
    _initializeControllers();
  }

  void _initializeControllers() {
    // Dispose existing controllers
    for (var controller in _cruiseTaskControllers) {
      controller.dispose();
    }
    _cruiseTaskControllers.clear();

    // Create new controllers
    if (_tasks.isNotEmpty) {
      final mainTask = _tasks.firstWhere((task) => task.isMainTask, orElse: () => _tasks.first);
      _mainTaskController.text = mainTask.title;
      
      final cruiseTasks = _tasks.where((task) => !task.isMainTask).toList();
      for (int i = 0; i < cruiseTasks.length; i++) {
        final controller = TextEditingController(text: cruiseTasks[i].title);
        _cruiseTaskControllers.add(controller);
      }
    }
  }

  void _addCruiseTask() {
    setState(() {
      final newTask = TodoTask(
        id: 'cruise_${_tasks.where((task) => !task.isMainTask).length + 1}_${DateTime.now().millisecondsSinceEpoch}',
        title: '',
        isMainTask: false,
        createdAt: DateTime.now(),
      );
      _tasks.add(newTask);
      
      // Add controller for new task
      _cruiseTaskControllers.add(TextEditingController());
    });
    _saveTasks();
  }

  void _removeCruiseTask(int index) {
    if (_tasks.where((task) => !task.isMainTask).length > 1) {
      setState(() {
        final cruiseTasks = _tasks.where((task) => !task.isMainTask).toList();
        final taskToRemove = cruiseTasks[index];
        _tasks.remove(taskToRemove);
        
        // Remove controller
        if (index < _cruiseTaskControllers.length) {
          _cruiseTaskControllers[index].dispose();
          _cruiseTaskControllers.removeAt(index);
        }
      });
      _saveTasks();
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final tasksJson = _tasks.map((task) => task.toJson().entries
        .map((e) => '${e.key}:${e.value}')
        .join(',')).toList();
    await prefs.setStringList('todo_tasks_$today', tasksJson);
  }

  void _toggleTask(TodoTask task) {
    setState(() {
      task.isCompleted = !task.isCompleted;
    });
    _saveTasks();
  }

  void _updateTaskTitle(TodoTask task, String newTitle) {
    setState(() {
      task.title = newTitle;
    });
    _saveTasks();
  }

  Future<void> _generateTasksWithAI() async {
    final isConfigured = await _geminiService.isConfigured();
    if (!isConfigured) {
      final shouldGoToSettings = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text('AI Task Generation'),
            ],
          ),
          content: const Text(
            'To generate AI-powered tasks, you need to configure your Gemini API key first. Would you like to go to Settings to set it up?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Go to Settings'),
            ),
          ],
        ),
      );

      if (shouldGoToSettings == true) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SettingsScreen(),
          ),
        );
        // Check if AI is now configured after returning from settings
        await _checkAiConfiguration();
      }
      return;
    }

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const GenerateTasksDialog(),
    );

    if (result == null) return;

    setState(() {
      _isGeneratingTasks = true;
    });

    try {
      final generatedTasks = await _geminiService.generateTasks(
        userRole: result['role']!,
        currentFocus: result['focus']!,
        timeOfDay: result['timeOfDay']!,
      );

      setState(() {
        _tasks.clear();
        
        // Add main task
        if (generatedTasks['main_task']!.isNotEmpty) {
          _tasks.add(TodoTask(
            id: 'main_${DateTime.now().millisecondsSinceEpoch}',
            title: generatedTasks['main_task']!.first,
            isMainTask: true,
            createdAt: DateTime.now(),
          ));
        }

        // Add cruise tasks
        for (int i = 0; i < generatedTasks['cruise_tasks']!.length; i++) {
          _tasks.add(TodoTask(
            id: 'cruise_${i + 1}_${DateTime.now().millisecondsSinceEpoch}',
            title: generatedTasks['cruise_tasks']![i],
            isMainTask: false,
            createdAt: DateTime.now(),
          ));
        }
      });

      _initializeControllers();
      await _saveTasks();
      _showSnackBar('Tasks generated successfully!');
    } catch (e) {
      _showSnackBar('Failed to generate tasks: $e');
    } finally {
      setState(() {
        _isGeneratingTasks = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mainTask = _tasks.firstWhere((task) => task.isMainTask, orElse: () => _tasks.first);
    final cruiseTasks = _tasks.where((task) => !task.isMainTask).toList();

    // Calculate progress: main task = 50%, remaining 50% divided among cruise tasks
    double progress = 0.0;
    if (mainTask.isCompleted) progress += 0.5;
    
    if (cruiseTasks.isNotEmpty) {
      final cruiseTaskWeight = 0.5 / cruiseTasks.length;
      for (final task in cruiseTasks) {
        if (task.isCompleted) progress += cruiseTaskWeight;
      }
    }

    // Ensure 100% when all tasks are completed
    final allTasksCompleted = mainTask.isCompleted && 
        cruiseTasks.every((task) => task.isCompleted);
    if (allTasksCompleted) {
      progress = 1.0;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Goals'),
        actions: [
          IconButton(
            icon: _isGeneratingTasks
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Stack(
                    children: [
                      const Icon(Icons.auto_awesome),
                      if (_isAiConfigured)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                    ],
                  ),
            onPressed: _isGeneratingTasks ? null : _generateTasksWithAI,
            tooltip: _isAiConfigured ? 'Generate AI Tasks' : 'Configure AI (Settings)',
          ),
        ],
      ),
      body: Column(
        children: [
          // Scrollable content area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main "Eat the Frog" Task
                  Text(
                    '🐸 Eat the Frog',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: TextField(
                        controller: _mainTaskController,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          decoration: mainTask.isCompleted ? TextDecoration.lineThrough : null,
                          color: mainTask.isCompleted 
                              ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                              : null,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'What\'s your most important task today?',
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                        onChanged: (value) => _updateTaskTitle(mainTask, value),
                      ),
                      trailing: Checkbox(
                        value: mainTask.isCompleted,
                        onChanged: (_) => _toggleTask(mainTask),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Cruise Tasks Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '... and Cruise',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _addCruiseTask,
                        tooltip: 'Add task',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Cruise Tasks
                  ...cruiseTasks.asMap().entries.map((entry) {
                    final index = entry.key;
                    final task = entry.value;
                    final controller = index < _cruiseTaskControllers.length 
                        ? _cruiseTaskControllers[index] 
                        : TextEditingController();
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        title: TextField(
                          controller: controller,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                            color: task.isCompleted 
                                ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                                : null,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Small task ${index + 1}',
                            hintStyle: const TextStyle(color: Colors.grey),
                          ),
                          onChanged: (value) => _updateTaskTitle(task, value),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: task.isCompleted,
                              onChanged: (_) => _toggleTask(task),
                            ),
                            if (cruiseTasks.length > 1)
                              IconButton(
                                icon: const Icon(Icons.remove, size: 20),
                                onPressed: () => _removeCruiseTask(index),
                                tooltip: 'Remove task',
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          
          // Fixed progress bar at bottom
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          
          // Persistent Audio Control at the very bottom
          const PersistentAudioControl(),
        ],
      ),
    );
  }
} 