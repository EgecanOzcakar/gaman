import 'package:flutter/material.dart';

/// An evidence-based journalling prompt. Each has an ordered list of fields;
/// answers are stored as a label -> text map plus a joined [content] string
/// for previews and export.
class JournalTemplate {
  final String id;
  final String title;
  final String blurb;
  final IconData icon;
  final List<String> fields;

  const JournalTemplate({
    required this.id,
    required this.title,
    required this.blurb,
    required this.icon,
    required this.fields,
  });
}

const journalTemplates = <JournalTemplate>[
  JournalTemplate(
    id: 'gratitude',
    title: 'Three good things',
    blurb: 'Note three things that went well today and why. (Seligman)',
    icon: Icons.wb_twilight,
    fields: ['One', 'Two', 'Three'],
  ),
  JournalTemplate(
    id: 'evening',
    title: 'Evening review',
    blurb: 'A Stoic end-of-day check-in. (Seneca)',
    icon: Icons.nightlight_round,
    fields: ['What did I do well?', 'What could I do better?', 'What did I leave undone?'],
  ),
  JournalTemplate(
    id: 'thought_record',
    title: 'Thought record',
    blurb: 'Catch a hot thought and reframe it. (CBT)',
    icon: Icons.psychology_alt,
    fields: ['Situation', 'Automatic thought', 'A more balanced thought'],
  ),
  JournalTemplate(
    id: 'woop',
    title: 'WOOP',
    blurb: 'Turn a wish into a plan. (Oettingen)',
    icon: Icons.flag_circle,
    fields: ['Wish', 'Outcome', 'Obstacle', 'Plan (if obstacle, then…)'],
  ),
];

JournalTemplate? templateById(String id) {
  for (final t in journalTemplates) {
    if (t.id == id) return t;
  }
  return null;
}
