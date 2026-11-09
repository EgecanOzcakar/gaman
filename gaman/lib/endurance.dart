import 'data/models.dart';

/// Gaman's core practice: enduring small hard things on purpose.
/// Urges (in-the-moment), trials (one chosen discomfort a day) and programs
/// (multi-week sequences of trials, Premium). Pure data + pure functions so
/// the logic is testable without widgets.

const urgeMinutes = 10;

const urgeTags = ['Phone', 'Food', 'Smoking', 'Drink', 'Anger', 'Quitting', 'Other'];

/// Rotates every couple of minutes during an urge. Urge-surfing guidance plus
/// a little Stoicism; no medical claims.
const urgeGuidance = [
  'Notice where you feel it. Name it: "this is an urge."',
  'Urges are waves. They rise, peak and fall, usually within minutes.',
  'Breathe out longer than you breathe in.',
  '"No one is free who is a slave to the body." (Seneca)',
  'You don\'t have to win forever. Just these ten minutes.',
  'It is already weaker than when you started.',
];

String guidanceAt(Duration elapsed) =>
    urgeGuidance[(elapsed.inSeconds ~/ 100) % urgeGuidance.length];

/// Mild, voluntary discomforts. Kept deliberately gentle: no fasting, nothing
/// that needs medical judgement beyond the [caution] shown with it.
class Trial {
  final String id;
  final String title;

  /// 1 gentle, 2 firm, 3 hard.
  final int level;
  final String? caution;
  const Trial(this.id, this.title, this.level, [this.caution]);
}

const _coldCaution =
    'Skip this if you have a heart condition, are pregnant or feel unwell.';

const trials = <Trial>[
  Trial('phone_first_hour', 'Keep your phone in another room for the first hour of the day', 1),
  Trial('stairs', 'Take the stairs all day', 1),
  Trial('screenless_meal', 'Eat one meal with no screen', 1),
  Trial('snack_wait', 'Wait ten minutes before any snack', 1),
  Trial('nothing_later', 'Make your bed and leave no dish for later', 1),
  Trial('cold_finish', 'Finish your shower with 30 seconds of cold water', 2, _coldCaution),
  Trial('no_social', 'No social media today', 2),
  Trial('avoided_first', 'Do the task you\'re avoiding before anything else', 2),
  Trial('eat_plain', 'Eat plainly today: no sweets, no snacks', 2),
  Trial('walk_weather', 'Walk 30 minutes, whatever the weather (dress for it)', 2),
  Trial('awkward_thing', 'Say the awkward thing you\'ve been putting off, kindly', 2),
  Trial('practise_poverty', 'Eat simply and dress simply. Ask: is this what I feared? (Seneca)', 2),
  Trial('phone_bedroom', 'Sleep with your phone outside the bedroom', 3),
  Trial('no_complaining', 'A full day without complaining. Slip? Start again.', 3),
  Trial('cold_full', 'A full two-minute cold shower', 3, _coldCaution),
  Trial('phone_day', 'A day with no browser or social apps (calls and messages are fine)', 3),
  Trial('one_thing', 'A day of doing one thing at a time: no multitasking', 3),
];

const levelNames = {1: 'Gentle', 2: 'Firm', 3: 'Hard'};

const trialSafetyNote =
    'Trials should feel uncomfortable, never harmful. Skip any that don\'t suit '
    'your health and stop if something feels wrong. This isn\'t medical advice.';

Trial? trialById(String? id) {
  for (final t in trials) {
    if (t.id == id) return t;
  }
  return null;
}

/// A multi-week sequence of trials. Premium.
class Program {
  final String id;
  final String title;
  final String blurb;
  final int days;
  final List<String> sequence;
  const Program(this.id, this.title, this.blurb, this.days, this.sequence);

  /// Trial for 1-based [day], cycling through [sequence].
  Trial trialForDay(int day) => trialById(sequence[(day - 1) % sequence.length])!;
}

const programs = <Program>[
  Program('thirty_days', '30 days of gaman',
      'A month that starts gentle and ends hard, one trial a day.', 30, [
    'phone_first_hour', 'stairs', 'screenless_meal', 'snack_wait', 'nothing_later',
    'cold_finish', 'no_social', 'avoided_first', 'eat_plain', 'walk_weather',
    'awkward_thing', 'practise_poverty', 'phone_bedroom', 'no_complaining',
    'cold_full', 'phone_day', 'one_thing',
  ]),
  Program('phone_fast', 'The phone fast',
      'Two weeks to loosen the phone\'s grip, a little more each day.', 14, [
    'phone_first_hour', 'screenless_meal', 'no_social', 'phone_bedroom',
    'phone_first_hour', 'no_social', 'phone_day',
  ]),
  Program('senecas_month', 'Seneca\'s three weeks',
      'Voluntary simplicity: rehearse having less, so you fear it less.', 21, [
    'practise_poverty', 'eat_plain', 'walk_weather', 'no_complaining',
    'nothing_later', 'one_thing', 'cold_finish',
  ]),
];

Program? programById(String? id) {
  for (final p in programs) {
    if (p.id == id) return p;
  }
  return null;
}

/// 1-based day of a program started on [startedOn], or null once finished.
int? programDay(Program p, DateTime startedOn, DateTime today) {
  final d = DateTime(today.year, today.month, today.day)
          .difference(DateTime(startedOn.year, startedOn.month, startedOn.day))
          .inDays +
      1;
  return d >= 1 && d <= p.days ? d : null;
}

/// Urge outcomes over some events, for Insights.
class UrgeStats {
  int held = 0;
  int total = 0;

  /// tag -> (held, total)
  final Map<String, ({int held, int total})> byTag = {};

  /// Part of day with the most urges given in to, or null if none.
  String? hardestTime;

  double get holdRate => total == 0 ? 0 : held / total;
}

String partOfDay(DateTime t) => switch (t.hour) {
      < 5 => 'night',
      < 12 => 'morning',
      < 17 => 'afternoon',
      < 22 => 'evening',
      _ => 'night',
    };

UrgeStats urgeStats(Iterable<ActivityEvent> events) {
  final s = UrgeStats();
  final gaveIn = <String, int>{};
  for (final e in events.where((e) => e.type == ActivityType.urge)) {
    final held = e.meta['held'] == true;
    final tag = (e.meta['tag'] as String?) ?? 'Other';
    s.total++;
    if (held) s.held++;
    final prev = s.byTag[tag] ?? (held: 0, total: 0);
    s.byTag[tag] = (held: prev.held + (held ? 1 : 0), total: prev.total + 1);
    if (!held) gaveIn.update(partOfDay(e.at), (n) => n + 1, ifAbsent: () => 1);
  }
  if (gaveIn.isNotEmpty) {
    s.hardestTime =
        gaveIn.entries.reduce((a, b) => b.value > a.value ? b : a).key;
  }
  return s;
}

/// Completed trials per level.
Map<int, int> trialsByLevel(Iterable<ActivityEvent> events) {
  final out = {1: 0, 2: 0, 3: 0};
  for (final e in events) {
    if (e.type != ActivityType.trial || e.meta['status'] != 'done') continue;
    final t = trialById(e.meta['id'] as String?);
    if (t != null) out[t.level] = out[t.level]! + 1;
  }
  return out;
}
