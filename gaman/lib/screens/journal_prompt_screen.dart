import 'package:flutter/material.dart';
import '../journal_templates.dart';
import '../theme/app_theme.dart';
import 'journal_screen.dart';

/// Compose a structured journal entry from a [JournalTemplate]. Pops with the
/// finished [JournalEntry], or null if cancelled.
class JournalPromptScreen extends StatefulWidget {
  const JournalPromptScreen({super.key, required this.template});

  final JournalTemplate template;

  @override
  State<JournalPromptScreen> createState() => _JournalPromptScreenState();
}

class _JournalPromptScreenState extends State<JournalPromptScreen> {
  late final List<TextEditingController> _controllers = [
    for (final _ in widget.template.fields) TextEditingController()
  ];
  String _mood = '😊';

  static const _moods = ['😊', '😐', '😢', '😡', '😴', '🤔'];

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final sections = <String, String>{};
    for (var i = 0; i < widget.template.fields.length; i++) {
      final text = _controllers[i].text.trim();
      if (text.isNotEmpty) sections[widget.template.fields[i]] = text;
    }
    if (sections.isEmpty) {
      Navigator.pop(context);
      return;
    }
    final content =
        sections.entries.map((e) => '${e.key}\n${e.value}').join('\n\n');
    Navigator.pop(
      context,
      JournalEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        date: DateTime.now(),
        mood: _mood,
        type: widget.template.id,
        sections: sections,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.template;
    return Scaffold(
      appBar: AppBar(title: Text(t.title)),
      body: ListView(
        padding: const EdgeInsets.all(Insets.lg),
        children: [
          Text(t.blurb, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: Insets.lg),
          for (var i = 0; i < t.fields.length; i++) ...[
            Text(t.fields[i], style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: Insets.sm),
            TextField(
              controller: _controllers[i],
              maxLines: null,
              minLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: Insets.lg),
          ],
          Text('Mood', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: Insets.sm),
          Wrap(
            spacing: Insets.sm,
            children: [
              for (final m in _moods)
                ChoiceChip(
                  label: Text(m, style: const TextStyle(fontSize: 20)),
                  selected: _mood == m,
                  onSelected: (_) => setState(() => _mood = m),
                ),
            ],
          ),
          const SizedBox(height: Insets.xl),
          FilledButton(onPressed: _save, child: const Text('Save entry')),
        ],
      ),
    );
  }
}
