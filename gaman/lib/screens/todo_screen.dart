import 'dart:async';

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../data/models.dart';
import '../data/repository.dart';
import '../providers/activity_log.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../widgets/persistent_audio_control.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final List<TodoTask> _tasks = [];
  final _mainTaskController = TextEditingController();
  final List<TextEditingController> _cruiseTaskControllers = [];
  StreamSubscription<List<TodoTask>>? _sub;

  DateTime get _today => DateTime.now();

  @override
  void initState() {
    super.initState();
    _sub = context.read<Repository>().watchTasks(_today).listen((tasks) {
      if (!mounted) return;
      final next = tasks.isEmpty ? _seedTasks() : tasks;
      var sameStructure = _tasks.length == next.length;
      for (var i = 0; sameStructure && i < next.length; i++) {
        sameStructure = _tasks[i].id == next[i].id;
      }
      if (sameStructure) {
        // Echo of our own write — refresh fields in place, leave the live
        // TextEditingControllers alone so typing doesn't lose the cursor.
        setState(() {
          for (var i = 0; i < next.length; i++) {
            _tasks[i].title = next[i].title;
            _tasks[i].isCompleted = next[i].isCompleted;
          }
        });
      } else {
        setState(() {
          _tasks
            ..clear()
            ..addAll(next);
        });
        _initializeControllers();
      }
    });
  }

  List<TodoTask> _seedTasks() => [
        TodoTask(
            id: 'main_${DateTime.now().millisecondsSinceEpoch}',
            title: '',
            isMainTask: true,
            createdAt: DateTime.now()),
        TodoTask(
            id: 'cruise_1_${DateTime.now().millisecondsSinceEpoch}',
            title: '',
            isMainTask: false,
            createdAt: DateTime.now()),
      ];

  @override
  void dispose() {
    _sub?.cancel();
    _mainTaskController.dispose();
    for (var controller in _cruiseTaskControllers) {
      controller.dispose();
    }
    super.dispose();
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

  Future<void> _saveTasks() =>
      context.read<Repository>().saveTasks(_today, _tasks);

  void _toggleTask(TodoTask task) {
    setState(() => task.isCompleted = !task.isCompleted);
    HapticFeedback.selectionClick();
    if (task.isCompleted) {
      context.read<ActivityLog>().log(
        ActivityType.taskDone,
        meta: {'title': task.title, 'frog': task.isMainTask},
      );
    }
    _saveTasks();
  }

  void _updateTaskTitle(TodoTask task, String newTitle) {
    setState(() {
      task.title = newTitle;
    });
    _saveTasks();
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
                        semanticLabel: AppLocalizations.of(context).markMainTaskDone,
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
                              semanticLabel: AppLocalizations.of(context)
                                  .markTaskDone(index + 1),
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
                const SizedBox(height: Insets.sm),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: Motion.reduced(context) ? Duration.zero : Motion.base,
                  curve: Motion.curve,
                  builder: (context, value, _) => ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor:
                          Theme.of(context).colorScheme.primary.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
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