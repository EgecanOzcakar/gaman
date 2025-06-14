import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

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

  void _showEntryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Journal Entry'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _contentController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'How are you feeling today?',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please write something';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'How are you feeling?',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _moods.map((mood) {
                  return ChoiceChip(
                    label: Text(mood),
                    selected: _selectedMood == mood,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedMood = mood);
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              _saveEntry();
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'No entries yet',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start your journaling journey today',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _entries.length,
                  itemBuilder: (context, index) {
                    final entry = _entries[index];
                    return Dismissible(
                      key: Key(entry.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => _deleteEntry(entry),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat.yMMMd().add_jm().format(entry.date),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  Text(
                                    entry.mood,
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                entry.content,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showEntryDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
} 