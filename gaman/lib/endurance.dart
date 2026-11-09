import 'data/models.dart';
import 'l10n/app_localizations.dart';

/// Gaman's core practice: enduring small hard things on purpose.
/// Urges (in-the-moment), trials (one chosen discomfort a day) and programs
/// (multi-week sequences of trials, Premium). Pure data + pure functions so
/// the logic is testable without widgets.

const urgeMinutes = 10;

/// Stored on urge events as stable keys; shown via [EnduranceL10n.urgeTag].
const urgeTags = ['Phone', 'Food', 'Smoking', 'Drink', 'Anger', 'Quitting', 'Other'];

/// Index of the guidance line to show; rotates every 100 s. Lines are
/// urge-surfing guidance plus a little Stoicism; no medical claims.
const urgeGuidanceCount = 6;

int guidanceIndexAt(Duration elapsed) =>
    (elapsed.inSeconds ~/ 100) % urgeGuidanceCount;

/// Mild, voluntary discomforts. Kept deliberately gentle: no fasting, nothing
/// that needs medical judgement beyond the caution shown with it.
/// Titles live in the ARB file (see [EnduranceL10n.trialTitle]).
class Trial {
  final String id;

  /// 1 gentle, 2 firm, 3 hard.
  final int level;

  /// Cold-water trials show [AppLocalizations.trialColdCaution].
  final bool cold;
  const Trial(this.id, this.level, {this.cold = false});
}

const trials = <Trial>[
  Trial('phone_first_hour', 1),
  Trial('stairs', 1),
  Trial('screenless_meal', 1),
  Trial('snack_wait', 1),
  Trial('nothing_later', 1),
  Trial('cold_finish', 2, cold: true),
  Trial('no_social', 2),
  Trial('avoided_first', 2),
  Trial('eat_plain', 2),
  Trial('walk_weather', 2),
  Trial('awkward_thing', 2),
  Trial('practise_poverty', 2),
  Trial('phone_bedroom', 3),
  Trial('no_complaining', 3),
  Trial('cold_full', 3, cold: true),
  Trial('phone_day', 3),
  Trial('one_thing', 3),
];

Trial? trialById(String? id) {
  for (final t in trials) {
    if (t.id == id) return t;
  }
  return null;
}

/// A multi-week sequence of trials. Premium.
/// Titles and blurbs live in the ARB file (see [EnduranceL10n]).
class Program {
  final String id;
  final int days;
  final List<String> sequence;
  const Program(this.id, this.days, this.sequence);

  /// Trial for 1-based [day], cycling through [sequence].
  Trial trialForDay(int day) => trialById(sequence[(day - 1) % sequence.length])!;
}

const programs = <Program>[
  Program('thirty_days', 30, [
    'phone_first_hour', 'stairs', 'screenless_meal', 'snack_wait', 'nothing_later',
    'cold_finish', 'no_social', 'avoided_first', 'eat_plain', 'walk_weather',
    'awkward_thing', 'practise_poverty', 'phone_bedroom', 'no_complaining',
    'cold_full', 'phone_day', 'one_thing',
  ]),
  Program('phone_fast', 14, [
    'phone_first_hour', 'screenless_meal', 'no_social', 'phone_bedroom',
    'phone_first_hour', 'no_social', 'phone_day',
  ]),
  Program('senecas_month', 21, [
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

/// Display text for catalogue ids. Unknown ids fall back to the id itself.
extension EnduranceL10n on AppLocalizations {
  String urgeTag(String tag) => switch (tag) {
        'Phone' => urgeTagPhone,
        'Food' => urgeTagFood,
        'Smoking' => urgeTagSmoking,
        'Drink' => urgeTagDrink,
        'Anger' => urgeTagAnger,
        'Quitting' => urgeTagQuitting,
        'Other' => urgeTagOther,
        _ => tag,
      };

  String urgeGuidance(int i) => switch (i) {
        0 => urgeGuidance0,
        1 => urgeGuidance1,
        2 => urgeGuidance2,
        3 => urgeGuidance3,
        4 => urgeGuidance4,
        _ => urgeGuidance5,
      };

  String levelName(int level) => switch (level) {
        1 => levelGentle,
        2 => levelFirm,
        _ => levelHard,
      };

  String trialTitle(String id) => switch (id) {
        'phone_first_hour' => trialPhoneFirstHour,
        'stairs' => trialStairs,
        'screenless_meal' => trialScreenlessMeal,
        'snack_wait' => trialSnackWait,
        'nothing_later' => trialNothingLater,
        'cold_finish' => trialColdFinish,
        'no_social' => trialNoSocial,
        'avoided_first' => trialAvoidedFirst,
        'eat_plain' => trialEatPlain,
        'walk_weather' => trialWalkWeather,
        'awkward_thing' => trialAwkwardThing,
        'practise_poverty' => trialPractisePoverty,
        'phone_bedroom' => trialPhoneBedroom,
        'no_complaining' => trialNoComplaining,
        'cold_full' => trialColdFull,
        'phone_day' => trialPhoneDay,
        'one_thing' => trialOneThing,
        _ => id,
      };

  String? trialCaution(Trial t) => t.cold ? trialColdCaution : null;

  String programTitle(String id) => switch (id) {
        'thirty_days' => programThirtyDays,
        'phone_fast' => programPhoneFast,
        'senecas_month' => programSenecasMonth,
        _ => id,
      };

  String programBlurb(String id) => switch (id) {
        'thirty_days' => programThirtyDaysBlurb,
        'phone_fast' => programPhoneFastBlurb,
        'senecas_month' => programSenecasMonthBlurb,
        _ => '',
      };

  String partOfDayName(String part) => switch (part) {
        'morning' => partMorning,
        'afternoon' => partAfternoon,
        'evening' => partEvening,
        _ => partNight,
      };

  /// "a, b and c" using the locale's separators.
  String joinList(List<String> parts) => parts.length < 2
      ? parts.join()
      : '${parts.sublist(0, parts.length - 1).join(listSeparator)}'
          '$listLastSeparator${parts.last}';
}
