import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../widgets/persistent_audio_control.dart';

class JournalEntry {
  final String id;
  final String content;
  final DateTime date;
  final String mood;

  JournalEntry({
    required this.id,
    required this.content,
    required this.date,
    required this.mood,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'date': date.toIso8601String(),
        'mood': mood,
      };

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
        id: json['id'],
        content: json['content'],
        date: DateTime.parse(json['date']),
        mood: json['mood'],
      );
}

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final List<JournalEntry> _entries = [];
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  String _selectedMood = '😊';
  bool _isLoading = true;

  final List<String> _moods = ['😊', '😐', '😢', '😡', '😴', '🤔'];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final entriesJson = prefs.getStringList('journal_entries') ?? [];
      setState(() {
        _entries.clear();
        _entries.addAll(
          entriesJson
              .map((e) => JournalEntry.fromJson(Map<String, dynamic>.from(
                    Map<String, dynamic>.from(
                      Map.castFrom<dynamic, dynamic, String, dynamic>(
                        Map.fromEntries(
                          e.split(',').map((e) {
                            final parts = e.split(':');
                            return MapEntry(parts[0], parts[1]);
                          }),
                        ),
                      ),
                    ),
                  )))
              .toList(),
        );
        _entries.sort((a, b) => b.date.compareTo(a.date));
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading entries: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;

    final entry = JournalEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: _contentController.text,
      date: DateTime.now(),
      mood: _selectedMood,
    );

    setState(() {
      _entries.insert(0, entry);
    });

    _contentController.clear();
    _selectedMood = '😊';

    try {
      final prefs = await SharedPreferences.getInstance();
      final entriesJson = _entries
          .map((e) => e.toJson().entries
              .map((e) => '${e.key}:${e.value}')
              .join(','))
          .toList();
      await prefs.setStringList('journal_entries', entriesJson);
    } catch (e) {
      debugPrint('Error saving entry: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save entry')),
      );
    }
  }

  Future<void> _deleteEntry(JournalEntry entry) async {
    setState(() {
      _entries.removeWhere((e) => e.id == entry.id);
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final entriesJson = _entries
          .map((e) => e.toJson().entries
              .map((e) => '${e.key}:${e.value}')
              .join(','))
          .toList();
      await prefs.setStringList('journal_entries', entriesJson);
    } catch (e) {
      debugPrint('Error deleting entry: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete entry')),
      );
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat.yMMMd().add_jm().format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal'),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _entries.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.book_outlined,
                                  size: 64,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No journal entries yet',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Start writing to reflect on your day',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _entries.length,
                            itemBuilder: (context, index) {
                              final entry = _entries[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  title: Row(
                                    children: [
                                      Text(
                                        entry.mood,
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              entry.content,
                                              style: Theme.of(context).textTheme.bodyLarge,
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              _formatDate(entry.date),
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _deleteEntry(entry),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How are you feeling?',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: _moods.map((mood) {
                          return GestureDetector(
                            onTap: () => setState(() => _selectedMood = mood),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _selectedMood == mood
                                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _selectedMood == mood
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.transparent,
                                ),
                              ),
                              child: Text(
                                mood,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _contentController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Write about your day...',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please write something';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveEntry,
                          child: const Text('Save Entry'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Persistent Audio Control at the bottom
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: PersistentAudioControl(),
          ),
        ],
      ),
    );
  }
} 