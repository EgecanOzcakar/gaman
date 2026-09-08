import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../journal_templates.dart';
import '../providers/activity_log.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import 'journal_prompt_screen.dart';

class JournalEntry {
  final String id;
  final String content;
  final DateTime date;
  final String mood;

  /// Template id: 'free', 'gratitude', 'evening', 'thought_record', 'woop'.
  final String type;

  /// For structured entries: label -> answer, in order. Null for free text.
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

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
        id: json['id'],
        content: json['content'],
        date: DateTime.parse(json['date']),
        mood: json['mood'],
        type: json['type'] as String? ?? 'free',
        sections: (json['sections'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), v.toString())),
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
      final stored = prefs.getStringList('journal_entries') ?? [];
      setState(() {
        _entries
          ..clear()
          ..addAll(stored.map((s) {
            try {
              return JournalEntry.fromJson(
                  jsonDecode(s) as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          }).whereType<JournalEntry>())
          ..sort((a, b) => b.date.compareTo(a.date));
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading entries: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('journal_entries',
        _entries.map((e) => jsonEncode(e.toJson())).toList());
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

    context.read<ActivityLog>().log(ActivityType.journal);

    try {
      await _persist();
    } catch (e) {
      debugPrint('Error saving entry: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save the entry')),
        );
      }
    }
  }

  Future<void> _addFromPrompt(JournalTemplate template) async {
    final entry = await Navigator.push<JournalEntry>(
      context,
      MaterialPageRoute(
          builder: (_) => JournalPromptScreen(template: template)),
    );
    if (entry == null) return;
    setState(() => _entries.insert(0, entry));
    if (mounted) context.read<ActivityLog>().log(ActivityType.journal);
    try {
      await _persist();
    } catch (e) {
      debugPrint('Error saving entry: $e');
    }
  }

  Future<void> _deleteEntry(JournalEntry entry) async {
    setState(() => _entries.removeWhere((e) => e.id == entry.id));
    try {
      await _persist();
    } catch (e) {
      debugPrint('Error deleting entry: $e');
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
      body: Column(
            children: [
              SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: Insets.md, vertical: Insets.sm),
                  children: [
                    for (final t in journalTemplates)
                      Padding(
                        padding: const EdgeInsets.only(right: Insets.sm),
                        child: ActionChip(
                          avatar: Icon(t.icon, size: 18),
                          label: Text(t.title),
                          onPressed: () => _addFromPrompt(t),
                        ),
                      ),
                  ],
                ),
              ),
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
                              return FadeSlideIn(
                                delay: Duration(milliseconds: (index * 50).clamp(0, 400)),
                                child: Card(
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
                                            if (templateById(entry.type) case final tpl?) ...[
                                              Row(
                                                children: [
                                                  Icon(tpl.icon, size: 14,
                                                      color: Theme.of(context).colorScheme.primary),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    tpl.title,
                                                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                                      color: Theme.of(context).colorScheme.primary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                            ],
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
                          final selected = _selectedMood == mood;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedMood = mood),
                            child: AnimatedContainer(
                              duration: Motion.quick,
                              curve: Motion.curve,
                              margin: const EdgeInsets.only(right: Insets.sm),
                              padding: const EdgeInsets.all(Insets.sm),
                              decoration: BoxDecoration(
                                color: selected
                                    ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(Radii.control),
                                border: Border.all(
                                  color: selected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.outlineVariant,
                                ),
                              ),
                              child: AnimatedScale(
                                scale: selected ? 1.15 : 1,
                                duration: Motion.quick,
                                curve: Motion.curve,
                                child: Text(mood, style: const TextStyle(fontSize: 24)),
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
                        child: FilledButton(
                          onPressed: _saveEntry,
                          child: const Text('Save entry'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
      ),
    );
  }
}