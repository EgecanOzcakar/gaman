# Repository Layer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Put every piece of user data (journal, tasks, activity log, settings) behind one `Repository` interface with a `SharedPreferences` implementation, so a Firestore implementation can be dropped in later without touching screens or providers.

**Architecture:** New `lib/data/` module: `models.dart` (plain data classes moved out of screen files), `repository.dart` (abstract interface, stream-per-domain), `local_repository.dart` (`SharedPreferences` + in-memory cache + broadcast streams, reading and writing the *exact* keys the app uses today so there is no migration and no behaviour change). Providers and screens take a `Repository` by constructor / `context.read` and subscribe to its streams.

**Tech Stack:** Flutter, `provider`, `shared_preferences`, `flutter_test`. No new dependencies.

**Spec:** `docs/superpowers/specs/2026-09-07-cloud-sync-and-auth-design.md` (this plan implements rollout PR #1: "Repository layer, no backend").

## Global Constraints

- No new dependencies. (`firebase_*` arrives in the next plan.)
- No behaviour change and no data migration: `LocalRepository` reads and writes the existing `SharedPreferences` keys in their existing formats. Keys and formats, verbatim from the current code:
  - `journal_entries`: `List<String>`, each a `jsonEncode`d `JournalEntry.toJson()`
  - `todo_tasks_<yyyy-MM-dd>`: `List<String>`, each a `jsonEncode`d `TodoTask.toJson()`
  - `activity_log`: `List<String>`, each a `jsonEncode`d `ActivityEvent.toJson()`
  - `theme_mode`: `String`, value is `ThemeMode.<name>.toString()` (e.g. `"ThemeMode.dark"`)
  - `settings_meditation_minutes`, `settings_breath_seconds`, `settings_focus_minutes`, `settings_long_break_every`: `int`
  - `pomodoro_duration`, `completed_pomodoros`: `int`
  - `disabled_features`: `List<String>`
  - `notification_enabled`: `bool`; `notification_time`: `String` `"<hour>:<minute>"`
- `flutter analyze --no-fatal-infos` must pass (matches CI in `.github/workflows/check.yml`).
- `flutter test` must stay green at every commit.
- Every task ends with a commit. Commit message style: imperative, lower-case first word, no trailing period (matches repo history), then a blank line and `Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>`.
- Dart: null-safe, `const` where the analyzer asks, single quotes.

---

## File Structure

**Create**
- `lib/data/models.dart` — `JournalEntry`, `TodoTask`, `ActivityType`, `ActivityEvent`, `AppSettings`. Plain data classes. Imports only `package:flutter/material.dart` (for `ThemeMode`).
- `lib/data/repository.dart` — abstract `Repository`.
- `lib/data/local_repository.dart` — `LocalRepository implements Repository`.
- `test/data/models_test.dart`
- `test/data/local_repository_test.dart`

**Modify**
- `lib/providers/activity_log.dart` — take a `Repository`, subscribe to `watchActivity()`, keep every query getter.
- `lib/providers/settings_provider.dart` — take a `Repository`, back `meditation/breath/focus/longBreak` by `AppSettings`.
- `lib/providers/feature_prefs.dart` — take a `Repository`, back `disabledFeatures` by `AppSettings`.
- `lib/providers/theme_provider.dart` — take a `Repository`, back `themeMode` by `AppSettings`.
- `lib/providers/notification_provider.dart` — persistence of `isEnabled` / `scheduledTime` moves to the repo; scheduling logic unchanged.
- `lib/screens/journal_screen.dart` — remove the `JournalEntry` class (import from models); read via `repo.watchJournal()`, write via `repo.upsertJournalEntry` / `repo.deleteJournalEntry`.
- `lib/screens/journal_prompt_screen.dart` — import `JournalEntry` from models.
- `lib/screens/todo_screen.dart` — remove the `TodoTask` class (import from models); read via `repo.watchTasks(day)`, write via `repo.saveTasks(day, list)`.
- `lib/screens/today_screen.dart` — `_loadFrog` reads via the repo.
- `lib/screens/focus_screen.dart` — `_loadTodayTasks` reads via the repo; `_selectedDuration` / `_completedPomodoros` read & write via `SettingsProvider` instead of raw prefs keys.
- `lib/main.dart` — create one `LocalRepository`, expose it with `Provider<Repository>`, pass it into every provider.
- `test/activity_log_test.dart`, `test/journal_entry_test.dart`, `test/focus_session_test.dart`, `test/widget_test.dart` — update import paths and constructor calls.

**Delete (end of plan, once nothing references them)**
- The inline `JournalEntry` class in `journal_screen.dart`, the inline `TodoTask` class in `todo_screen.dart`, and the direct `SharedPreferences` calls in the five providers and four screens listed above.

---

## Task 1: Data models

**Files:**
- Create: `lib/data/models.dart`
- Test: `test/data/models_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `class JournalEntry { final String id; final String content; final DateTime date; final String mood; final String type; final Map<String,String>? sections; JournalEntry({required id, required content, required date, required mood, type='free', sections}); Map<String,dynamic> toJson(); factory JournalEntry.fromJson(Map<String,dynamic>); }`
  - `class TodoTask { final String id; String title; bool isCompleted; final bool isMainTask; final DateTime createdAt; TodoTask({required id, required title, isCompleted=false, required isMainTask, required createdAt}); Map<String,dynamic> toJson(); factory TodoTask.fromJson(Map<String,dynamic>); }`
  - `enum ActivityType { meditation, focus, journal, taskDone }`
  - `class ActivityEvent { final ActivityType type; final DateTime at; final int durationSeconds; final Map<String,dynamic> meta; ActivityEvent({required type, required at, durationSeconds=0, meta=const{}}); Map<String,dynamic> toJson(); factory ActivityEvent.fromJson(Map<String,dynamic>); }`
  - `class AppSettings { final ThemeMode themeMode; final int meditationMinutes; final int breathSeconds; final int focusMinutes; final int longBreakEvery; final int completedPomodoros; final bool reminderEnabled; final int? reminderHour; final int? reminderMinute; final Set<String> disabledFeatures; const AppSettings({...all with defaults...}); AppSettings copyWith({...}); Map<String,dynamic> toJson(); factory AppSettings.fromJson(Map<String,dynamic>); }`

- [ ] **Step 1: Write the failing test**

Create `test/data/models_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaman/data/models.dart';

void main() {
  test('JournalEntry free entry round-trips, defaults type', () {
    final e = JournalEntry(
      id: '1', content: 'has, comma: colon',
      date: DateTime(2026, 1, 2, 3, 4), mood: '😐',
    );
    final back = JournalEntry.fromJson(e.toJson());
    expect(back.content, e.content);
    expect(back.type, 'free');
    expect(back.sections, isNull);
  });

  test('JournalEntry structured entry keeps sections', () {
    final e = JournalEntry(
      id: '2', content: 'joined', date: DateTime(2026, 1, 2), mood: '😊',
      type: 'woop', sections: {'Wish': 'ship', 'Obstacle': 'scope'},
    );
    expect(JournalEntry.fromJson(e.toJson()).sections,
        {'Wish': 'ship', 'Obstacle': 'scope'});
  });

  test('TodoTask round-trips', () {
    final t = TodoTask(
      id: 'a', title: 'frog', isMainTask: true, createdAt: DateTime(2026));
    final back = TodoTask.fromJson(t.toJson());
    expect(back.title, 'frog');
    expect(back.isMainTask, isTrue);
    expect(back.isCompleted, isFalse);
  });

  test('ActivityEvent round-trips and omits empty meta', () {
    final ev = ActivityEvent(
      type: ActivityType.focus, at: DateTime(2026, 5, 1), durationSeconds: 1500);
    expect(ev.toJson().containsKey('meta'), isFalse);
    final back = ActivityEvent.fromJson(ev.toJson());
    expect(back.type, ActivityType.focus);
    expect(back.durationSeconds, 1500);
  });

  test('AppSettings copyWith + round-trip', () {
    const s = AppSettings();
    expect(s.themeMode, ThemeMode.system);
    expect(s.focusMinutes, 25);
    final s2 = s.copyWith(focusMinutes: 30, disabledFeatures: {'journal'});
    expect(s2.focusMinutes, 30);
    expect(s2.meditationMinutes, 10);
    final back = AppSettings.fromJson(s2.toJson());
    expect(back.focusMinutes, 30);
    expect(back.disabledFeatures, {'journal'});
    expect(back.themeMode, ThemeMode.system);
  });

  test('AppSettings.fromJson tolerates missing keys', () {
    final back = AppSettings.fromJson({'focusMinutes': 45});
    expect(back.focusMinutes, 45);
    expect(back.breathSeconds, 4);
    expect(back.reminderEnabled, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/models_test.dart`
Expected: FAIL — `Error: Couldn't resolve the package 'gaman' ... data/models.dart` / "Target of URI doesn't exist".

- [ ] **Step 3: Write the implementation**

Create `lib/data/models.dart`:

```dart
import 'package:flutter/material.dart' show ThemeMode;

class JournalEntry {
  final String id;
  final String content;
  final DateTime date;
  final String mood;

  /// 'free', 'gratitude', 'evening', 'thought_record', 'woop'.
  final String type;

  /// Structured entries: ordered label -> answer. Null for free text.
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

  factory JournalEntry.fromJson(Map<String, dynamic> j) => JournalEntry(
        id: j['id'] as String,
        content: j['content'] as String,
        date: DateTime.parse(j['date'] as String),
        mood: j['mood'] as String,
        type: j['type'] as String? ?? 'free',
        sections: (j['sections'] as Map?)
            ?.map((k, v) => MapEntry(k.toString(), v.toString())),
      );
}

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

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
        'isMainTask': isMainTask,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TodoTask.fromJson(Map<String, dynamic> j) => TodoTask(
        id: j['id'] as String,
        title: j['title'] as String,
        isCompleted: j['isCompleted'] as bool? ?? false,
        isMainTask: j['isMainTask'] as bool? ?? false,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}

enum ActivityType { meditation, focus, journal, taskDone }

class ActivityEvent {
  final ActivityType type;
  final DateTime at;
  final int durationSeconds;
  final Map<String, dynamic> meta;

  ActivityEvent({
    required this.type,
    required this.at,
    this.durationSeconds = 0,
    this.meta = const {},
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'at': at.toIso8601String(),
        'dur': durationSeconds,
        if (meta.isNotEmpty) 'meta': meta,
      };

  factory ActivityEvent.fromJson(Map<String, dynamic> j) => ActivityEvent(
        type: ActivityType.values.byName(j['type'] as String),
        at: DateTime.parse(j['at'] as String),
        durationSeconds: (j['dur'] as num?)?.toInt() ?? 0,
        meta: (j['meta'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
}

class AppSettings {
  final ThemeMode themeMode;
  final int meditationMinutes;
  final int breathSeconds;
  final int focusMinutes;
  final int longBreakEvery;
  final int completedPomodoros;
  final bool reminderEnabled;
  final int? reminderHour;
  final int? reminderMinute;
  final Set<String> disabledFeatures;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.meditationMinutes = 10,
    this.breathSeconds = 4,
    this.focusMinutes = 25,
    this.longBreakEvery = 4,
    this.completedPomodoros = 0,
    this.reminderEnabled = true,
    this.reminderHour,
    this.reminderMinute,
    this.disabledFeatures = const {},
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    int? meditationMinutes,
    int? breathSeconds,
    int? focusMinutes,
    int? longBreakEvery,
    int? completedPomodoros,
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
    Set<String>? disabledFeatures,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        meditationMinutes: meditationMinutes ?? this.meditationMinutes,
        breathSeconds: breathSeconds ?? this.breathSeconds,
        focusMinutes: focusMinutes ?? this.focusMinutes,
        longBreakEvery: longBreakEvery ?? this.longBreakEvery,
        completedPomodoros: completedPomodoros ?? this.completedPomodoros,
        reminderEnabled: reminderEnabled ?? this.reminderEnabled,
        reminderHour: reminderHour ?? this.reminderHour,
        reminderMinute: reminderMinute ?? this.reminderMinute,
        disabledFeatures: disabledFeatures ?? this.disabledFeatures,
      );

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.name,
        'meditationMinutes': meditationMinutes,
        'breathSeconds': breathSeconds,
        'focusMinutes': focusMinutes,
        'longBreakEvery': longBreakEvery,
        'completedPomodoros': completedPomodoros,
        'reminderEnabled': reminderEnabled,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'disabledFeatures': disabledFeatures.toList(),
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) {
    const d = AppSettings();
    return AppSettings(
      themeMode: ThemeMode.values.asNameMap()[j['themeMode']] ?? d.themeMode,
      meditationMinutes: (j['meditationMinutes'] as num?)?.toInt() ?? d.meditationMinutes,
      breathSeconds: (j['breathSeconds'] as num?)?.toInt() ?? d.breathSeconds,
      focusMinutes: (j['focusMinutes'] as num?)?.toInt() ?? d.focusMinutes,
      longBreakEvery: (j['longBreakEvery'] as num?)?.toInt() ?? d.longBreakEvery,
      completedPomodoros: (j['completedPomodoros'] as num?)?.toInt() ?? d.completedPomodoros,
      reminderEnabled: j['reminderEnabled'] as bool? ?? d.reminderEnabled,
      reminderHour: (j['reminderHour'] as num?)?.toInt(),
      reminderMinute: (j['reminderMinute'] as num?)?.toInt(),
      disabledFeatures: ((j['disabledFeatures'] as List?) ?? const [])
          .map((e) => e.toString())
          .toSet(),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/models_test.dart`
Expected: PASS (6 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/data/models.dart test/data/models_test.dart
git commit -m "add data models for the repository layer

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 2: Repository interface

**Files:**
- Create: `lib/data/repository.dart`

**Interfaces:**
- Consumes: `lib/data/models.dart` (Task 1).
- Produces:
  - `abstract class Repository` with:
    - `Stream<List<JournalEntry>> watchJournal()`
    - `Future<void> upsertJournalEntry(JournalEntry entry)`
    - `Future<void> deleteJournalEntry(String id)`
    - `Stream<List<TodoTask>> watchTasks(DateTime day)`
    - `Future<void> saveTasks(DateTime day, List<TodoTask> tasks)`
    - `Stream<List<ActivityEvent>> watchActivity()`
    - `Future<void> addActivity(ActivityEvent event)`
    - `Stream<AppSettings> watchSettings()`
    - `Future<void> saveSettings(AppSettings settings)`
    - `Future<void> dispose()`

- [ ] **Step 1: Write the file**

Create `lib/data/repository.dart`:

```dart
import 'models.dart';

/// One home for every piece of user data. `LocalRepository` (SharedPreferences)
/// is the implementation now; a Firestore one arrives later without any change
/// to the providers and screens that depend on this interface.
///
/// Every `watch*` returns a broadcast stream that emits the current value on
/// listen and again on every write.
abstract class Repository {
  Stream<List<JournalEntry>> watchJournal();
  Future<void> upsertJournalEntry(JournalEntry entry);
  Future<void> deleteJournalEntry(String id);

  /// Tasks for one calendar day, keyed by `DateUtils.dateOnly(day)`.
  Stream<List<TodoTask>> watchTasks(DateTime day);
  Future<void> saveTasks(DateTime day, List<TodoTask> tasks);

  /// Append-only. Emitted oldest-first.
  Stream<List<ActivityEvent>> watchActivity();
  Future<void> addActivity(ActivityEvent event);

  Stream<AppSettings> watchSettings();
  Future<void> saveSettings(AppSettings settings);

  Future<void> dispose();
}
```

- [ ] **Step 2: Verify it analyzes**

Run: `flutter analyze lib/data/repository.dart`
Expected: "No issues found."

- [ ] **Step 3: Commit**

```bash
git add lib/data/repository.dart
git commit -m "add abstract Repository interface

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 3: LocalRepository — journal

**Files:**
- Create: `lib/data/local_repository.dart`
- Test: `test/data/local_repository_test.dart`

**Interfaces:**
- Consumes: `Repository` (Task 2), models (Task 1), `package:shared_preferences/shared_preferences.dart`.
- Produces:
  - `class LocalRepository implements Repository`
  - `LocalRepository({SharedPreferences? prefs})` — if `prefs` is null it calls `SharedPreferences.getInstance()` lazily; tests pass a mock instance.
  - `Future<void> ready` — completes when the initial load from prefs is done. `watch*` streams emit `[]` / `AppSettings()` immediately and the real value once `ready` completes.

- [ ] **Step 1: Write the failing test**

Create `test/data/local_repository_test.dart`:

```dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gaman/data/local_repository.dart';
import 'package:gaman/data/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<LocalRepository> repo() async {
    final r = LocalRepository();
    await r.ready;
    return r;
  }

  test('journal: upsert then watch emits it', () async {
    final r = await repo();
    await r.upsertJournalEntry(JournalEntry(
      id: '1', content: 'hi', date: DateTime(2026, 1, 1), mood: '😊'));
    expect((await r.watchJournal().first).single.content, 'hi');
    await r.dispose();
  });

  test('journal: upsert with an existing id replaces, not appends', () async {
    final r = await repo();
    final e = JournalEntry(
      id: '1', content: 'a', date: DateTime(2026, 1, 1), mood: '😊');
    await r.upsertJournalEntry(e);
    await r.upsertJournalEntry(JournalEntry(
      id: '1', content: 'b', date: e.date, mood: '😊'));
    final list = await r.watchJournal().first;
    expect(list, hasLength(1));
    expect(list.single.content, 'b');
    await r.dispose();
  });

  test('journal: delete removes and re-emits', () async {
    final r = await repo();
    await r.upsertJournalEntry(JournalEntry(
      id: '1', content: 'a', date: DateTime(2026), mood: '😊'));
    final emissions = <int>[];
    final sub = r.watchJournal().listen((l) => emissions.add(l.length));
    await Future<void>.delayed(Duration.zero);
    await r.deleteJournalEntry('1');
    await Future<void>.delayed(Duration.zero);
    expect(emissions.last, 0);
    await sub.cancel();
    await r.dispose();
  });

  test('journal: reads what the old format wrote', () async {
    SharedPreferences.setMockInitialValues({
      'journal_entries': [
        jsonEncode({
          'id': 'x', 'content': 'legacy', 'mood': '😐',
          'date': DateTime(2025, 6, 1).toIso8601String(), 'type': 'free',
        }),
      ],
    });
    final r = await repo();
    expect((await r.watchJournal().first).single.content, 'legacy');
    await r.dispose();
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/local_repository_test.dart`
Expected: FAIL — "Target of URI doesn't exist: 'package:gaman/data/local_repository.dart'".

- [ ] **Step 3: Write the implementation**

Create `lib/data/local_repository.dart`:

```dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart' show DateUtils, ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'repository.dart';

/// SharedPreferences-backed [Repository]. Holds everything in memory, mirrors
/// writes to prefs using the app's existing keys and formats (see the plan's
/// Global Constraints), and pushes each change to a broadcast stream.
class LocalRepository implements Repository {
  LocalRepository({SharedPreferences? prefs}) {
    ready = _init(prefs);
  }

  late final Future<void> ready;
  late SharedPreferences _prefs;

  final _journal = StreamController<List<JournalEntry>>.broadcast();
  final _activity = StreamController<List<ActivityEvent>>.broadcast();
  final _settings = StreamController<AppSettings>.broadcast();
  final _tasks = <String, StreamController<List<TodoTask>>>{};

  List<JournalEntry> _journalCache = [];
  List<ActivityEvent> _activityCache = [];
  AppSettings _settingsCache = const AppSettings();
  final _taskCache = <String, List<TodoTask>>{};

  static String _dayKey(DateTime day) {
    final d = DateUtils.dateOnly(day);
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$dd';
  }

  Future<void> _init(SharedPreferences? injected) async {
    _prefs = injected ?? await SharedPreferences.getInstance();

    _journalCache = _decodeList(
        'journal_entries', (m) => JournalEntry.fromJson(m))
      ..sort((a, b) => b.date.compareTo(a.date));
    _activityCache = _decodeList('activity_log', (m) => ActivityEvent.fromJson(m))
      ..sort((a, b) => a.at.compareTo(b.at));
    _settingsCache = _readSettings();

    _journal.add(_journalCache);
    _activity.add(_activityCache);
    _settings.add(_settingsCache);
  }

  List<T> _decodeList<T>(String key, T Function(Map<String, dynamic>) fromJson) =>
      (_prefs.getStringList(key) ?? [])
          .map((s) {
            try {
              return fromJson(jsonDecode(s) as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          })
          .whereType<T>()
          .toList();

  // --- journal ------------------------------------------------------------

  @override
  Stream<List<JournalEntry>> watchJournal() async* {
    yield _journalCache;
    yield* _journal.stream;
  }

  @override
  Future<void> upsertJournalEntry(JournalEntry entry) async {
    _journalCache = [
      entry,
      ..._journalCache.where((e) => e.id != entry.id),
    ]..sort((a, b) => b.date.compareTo(a.date));
    await _persistJournal();
  }

  @override
  Future<void> deleteJournalEntry(String id) async {
    _journalCache = _journalCache.where((e) => e.id != id).toList();
    await _persistJournal();
  }

  Future<void> _persistJournal() async {
    _journal.add(_journalCache);
    await _prefs.setStringList('journal_entries',
        _journalCache.map((e) => jsonEncode(e.toJson())).toList());
  }

  // --- tasks -------------------------------------------------------------

  StreamController<List<TodoTask>> _taskController(String key) =>
      _tasks.putIfAbsent(key, () => StreamController.broadcast());

  @override
  Stream<List<TodoTask>> watchTasks(DateTime day) async* {
    final key = _dayKey(day);
    _taskCache[key] ??=
        _decodeList('todo_tasks_$key', (m) => TodoTask.fromJson(m));
    yield _taskCache[key]!;
    yield* _taskController(key).stream;
  }

  @override
  Future<void> saveTasks(DateTime day, List<TodoTask> tasks) async {
    final key = _dayKey(day);
    _taskCache[key] = List.of(tasks);
    _taskController(key).add(_taskCache[key]!);
    await _prefs.setStringList('todo_tasks_$key',
        tasks.map((t) => jsonEncode(t.toJson())).toList());
  }

  // --- activity --------------------------------------------------------

  @override
  Stream<List<ActivityEvent>> watchActivity() async* {
    yield _activityCache;
    yield* _activity.stream;
  }

  @override
  Future<void> addActivity(ActivityEvent event) async {
    _activityCache = [..._activityCache, event]
      ..sort((a, b) => a.at.compareTo(b.at));
    _activity.add(_activityCache);
    await _prefs.setStringList('activity_log',
        _activityCache.map((e) => jsonEncode(e.toJson())).toList());
  }

  // --- settings -------------------------------------------------------

  @override
  Stream<AppSettings> watchSettings() async* {
    yield _settingsCache;
    yield* _settings.stream;
  }

  @override
  Future<void> saveSettings(AppSettings s) async {
    _settingsCache = s;
    _settings.add(s);
    await _prefs.setString('theme_mode', s.themeMode.toString());
    await _prefs.setInt('settings_meditation_minutes', s.meditationMinutes);
    await _prefs.setInt('settings_breath_seconds', s.breathSeconds);
    await _prefs.setInt('settings_focus_minutes', s.focusMinutes);
    await _prefs.setInt('settings_long_break_every', s.longBreakEvery);
    await _prefs.setInt('pomodoro_duration', s.focusMinutes);
    await _prefs.setInt('completed_pomodoros', s.completedPomodoros);
    await _prefs.setStringList(
        'disabled_features', s.disabledFeatures.toList());
    await _prefs.setBool('notification_enabled', s.reminderEnabled);
    if (s.reminderHour != null && s.reminderMinute != null) {
      await _prefs.setString(
          'notification_time', '${s.reminderHour}:${s.reminderMinute}');
    }
  }

  AppSettings _readSettings() {
    const d = AppSettings();
    final themeStr = _prefs.getString('theme_mode');
    final themeMode = ThemeMode.values.firstWhere(
      (m) => m.toString() == themeStr,
      orElse: () => d.themeMode,
    );
    int? h, min;
    final t = _prefs.getString('notification_time');
    if (t != null && t.contains(':')) {
      final parts = t.split(':');
      h = int.tryParse(parts[0]);
      min = int.tryParse(parts[1]);
    }
    return AppSettings(
      themeMode: themeMode,
      meditationMinutes:
          _prefs.getInt('settings_meditation_minutes') ?? d.meditationMinutes,
      breathSeconds: _prefs.getInt('settings_breath_seconds') ?? d.breathSeconds,
      focusMinutes: _prefs.getInt('settings_focus_minutes') ??
          _prefs.getInt('pomodoro_duration') ??
          d.focusMinutes,
      longBreakEvery:
          _prefs.getInt('settings_long_break_every') ?? d.longBreakEvery,
      completedPomodoros:
          _prefs.getInt('completed_pomodoros') ?? d.completedPomodoros,
      reminderEnabled:
          _prefs.getBool('notification_enabled') ?? d.reminderEnabled,
      reminderHour: h,
      reminderMinute: min,
      disabledFeatures:
          (_prefs.getStringList('disabled_features') ?? const []).toSet(),
    );
  }

  // --- teardown -----------------------------------------------------

  @override
  Future<void> dispose() async {
    await _journal.close();
    await _activity.close();
    await _settings.close();
    for (final c in _tasks.values) {
      await c.close();
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/local_repository_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/data/local_repository.dart test/data/local_repository_test.dart
git commit -m "add LocalRepository with journal storage

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 4: LocalRepository — tasks, activity, settings contract tests

**Files:**
- Test: `test/data/local_repository_test.dart` (extend)

**Interfaces:**
- Consumes: `LocalRepository` (Task 3).
- Produces: nothing new — Task 3's implementation already covers these methods; this task proves it.

- [ ] **Step 1: Add failing tests**

Append to `test/data/local_repository_test.dart` inside `main()`:

```dart
  test('tasks: save then watch for the same day', () async {
    final r = await repo();
    final day = DateTime(2026, 3, 4, 15);
    await r.saveTasks(day, [
      TodoTask(id: 'm', title: 'frog', isMainTask: true, createdAt: day),
    ]);
    final list = await r.watchTasks(DateTime(2026, 3, 4, 8)).first;
    expect(list.single.title, 'frog');
    await r.dispose();
  });

  test('tasks: different days are independent', () async {
    final r = await repo();
    await r.saveTasks(DateTime(2026, 3, 4),
        [TodoTask(id: 'a', title: 'x', isMainTask: true, createdAt: DateTime(2026))]);
    expect(await r.watchTasks(DateTime(2026, 3, 5)).first, isEmpty);
    await r.dispose();
  });

  test('activity: addActivity appends and keeps oldest-first', () async {
    final r = await repo();
    await r.addActivity(ActivityEvent(
        type: ActivityType.focus, at: DateTime(2026, 1, 2)));
    await r.addActivity(ActivityEvent(
        type: ActivityType.journal, at: DateTime(2026, 1, 1)));
    final list = await r.watchActivity().first;
    expect(list.map((e) => e.type),
        [ActivityType.journal, ActivityType.focus]);
    await r.dispose();
  });

  test('settings: saveSettings round-trips through a fresh repo', () async {
    final r = await repo();
    await r.saveSettings(const AppSettings()
        .copyWith(focusMinutes: 40, disabledFeatures: {'binaural'},
                  reminderHour: 7, reminderMinute: 30));
    await r.dispose();

    final r2 = await repo();
    final s = await r2.watchSettings().first;
    expect(s.focusMinutes, 40);
    expect(s.disabledFeatures, {'binaural'});
    expect(s.reminderHour, 7);
    await r2.dispose();
  });

  test('settings: reads legacy individual keys', () async {
    SharedPreferences.setMockInitialValues({
      'theme_mode': 'ThemeMode.dark',
      'settings_focus_minutes': 45,
      'disabled_features': ['journal'],
      'notification_enabled': false,
    });
    final r = await repo();
    final s = await r.watchSettings().first;
    expect(s.themeMode, ThemeMode.dark);
    expect(s.focusMinutes, 45);
    expect(s.disabledFeatures, {'journal'});
    expect(s.reminderEnabled, isFalse);
    await r.dispose();
  });
```

Add `import 'package:flutter/material.dart';` at the top of the test file if not already present (needed for `ThemeMode`).

- [ ] **Step 2: Run test to verify it fails, then passes**

Run: `flutter test test/data/local_repository_test.dart`
Expected: the five new tests PASS (implementation from Task 3 already covers them). If any fail, fix `local_repository.dart` — do not weaken the test.

- [ ] **Step 3: Commit**

```bash
git add test/data/local_repository_test.dart
git commit -m "cover LocalRepository tasks, activity and settings

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 5: Wire the Repository into main.dart

**Files:**
- Modify: `lib/main.dart`

**Interfaces:**
- Consumes: `LocalRepository` (Task 3).
- Produces: a `Provider<Repository>` above the `ChangeNotifierProvider`s, available as `context.read<Repository>()`. Provider constructors change in Tasks 6–10; until those land, providers still build with no args — so this task keeps them as-is and only *adds* the `Repository` provider.

- [ ] **Step 1: Edit `lib/main.dart`**

Add imports near the other `providers/` imports:

```dart
import 'data/local_repository.dart';
import 'data/repository.dart';
```

Change the `MultiProvider`'s `providers:` list. It currently starts with `ChangeNotifierProvider`s; put a plain `Provider<Repository>` first and keep the rest unchanged for now:

```dart
      providers: [
        Provider<Repository>(
          create: (_) => LocalRepository(),
          dispose: (_, r) => r.dispose(),
        ),
        ChangeNotifierProvider(create: (_) => QuoteProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AudioProvider()),
        ChangeNotifierProvider(create: (_) => ActivityLog()),
        ChangeNotifierProvider(create: (_) => FeaturePrefs()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
```

- [ ] **Step 2: Verify**

Run: `flutter analyze lib/main.dart` → "No issues found."
Run: `flutter test` → all green (nothing consumes the new provider yet).

- [ ] **Step 3: Commit**

```bash
git add lib/main.dart
git commit -m "provide a LocalRepository at the app root

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 6: ActivityLog onto the Repository

**Files:**
- Modify: `lib/providers/activity_log.dart`, `lib/main.dart`
- Test: `test/activity_log_test.dart`

**Interfaces:**
- Consumes: `Repository` (Task 2), `ActivityEvent` / `ActivityType` from `lib/data/models.dart` (Task 1).
- Produces: `ActivityLog(Repository repo)`. All existing getters keep their exact names and signatures: `events`, `log(ActivityType, {int durationSeconds, Map<String,dynamic> meta, DateTime? at})`, `onDay`, `since`, `didAnythingOn`, `currentStreak`, `inRange`, `count`, `minutes`, `activeDays`, `weekStart` (static), `countThisWeek`, `minutesThisWeek`.

- [ ] **Step 1: Update the test**

In `test/activity_log_test.dart`: change the import from `package:gaman/providers/activity_log.dart` to keep it, but note `ActivityType` now comes from models. Replace the top:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gaman/data/local_repository.dart';
import 'package:gaman/data/models.dart';
import 'package:gaman/providers/activity_log.dart';
```

Replace the helper that builds an `ActivityLog`:

```dart
  Future<ActivityLog> makeLog() async {
    final repo = LocalRepository();
    await repo.ready;
    final log = ActivityLog(repo);
    await log.ready;           // see Step 3
    return log;
  }
```

Update each test body to `final log = await makeLog();` and replace `log.log(...)` calls — the signature is unchanged, so only the construction changes. For the "JSON round-trip" test, build a second `ActivityLog` from a second `LocalRepository` over the same mock prefs.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/activity_log_test.dart`
Expected: FAIL — `ActivityLog` has no unnamed-with-repo constructor / no `ready`.

- [ ] **Step 3: Rewrite `lib/providers/activity_log.dart`**

```dart
import 'dart:async';

import 'package:flutter/material.dart' show ChangeNotifier, DateUtils;

import '../data/models.dart';
import '../data/repository.dart';

export '../data/models.dart' show ActivityType, ActivityEvent;

/// Read model over [Repository.watchActivity]. Keeps every query the dashboard
/// and Insights screens use; writes go straight to the repository.
class ActivityLog with ChangeNotifier {
  ActivityLog(this._repo) {
    ready = _subscribe();
  }

  final Repository _repo;
  late final Future<void> ready;
  StreamSubscription<List<ActivityEvent>>? _sub;
  List<ActivityEvent> _events = [];

  List<ActivityEvent> get events => List.unmodifiable(_events);

  Future<void> _subscribe() async {
    final completer = Completer<void>();
    _sub = _repo.watchActivity().listen((events) {
      _events = events;
      notifyListeners();
      if (!completer.isCompleted) completer.complete();
    });
    return completer.future;
  }

  Future<void> log(
    ActivityType type, {
    int durationSeconds = 0,
    Map<String, dynamic> meta = const {},
    DateTime? at,
  }) =>
      _repo.addActivity(ActivityEvent(
        type: type,
        at: at ?? DateTime.now(),
        durationSeconds: durationSeconds,
        meta: meta,
      ));

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // --- queries (unchanged) ----------------------------------------------

  Iterable<ActivityEvent> onDay(DateTime day) {
    final d = DateUtils.dateOnly(day);
    return _events.where((e) => DateUtils.dateOnly(e.at) == d);
  }

  Iterable<ActivityEvent> since(DateTime from) =>
      _events.where((e) => e.at.isAfter(from));

  bool didAnythingOn(DateTime day) => onDay(day).isNotEmpty;

  int get currentStreak {
    var day = DateTime.now();
    if (!didAnythingOn(day)) day = day.subtract(const Duration(days: 1));
    var streak = 0;
    while (didAnythingOn(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Iterable<ActivityEvent> inRange(DateTime from, DateTime to) =>
      _events.where((e) => !e.at.isBefore(from) && e.at.isBefore(to));

  int count(ActivityType type, DateTime from, DateTime to) =>
      inRange(from, to).where((e) => e.type == type).length;

  int minutes(ActivityType type, DateTime from, DateTime to) =>
      inRange(from, to)
          .where((e) => e.type == type)
          .fold<int>(0, (sum, e) => sum + e.durationSeconds) ~/
      60;

  int activeDays(DateTime from, DateTime to) => inRange(from, to)
      .map((e) => DateUtils.dateOnly(e.at))
      .toSet()
      .length;

  static DateTime weekStart([DateTime? day]) {
    final d = day ?? DateTime.now();
    return DateUtils.dateOnly(d.subtract(Duration(days: d.weekday - 1)));
  }

  int countThisWeek(ActivityType type) =>
      count(type, weekStart(), DateTime.now().add(const Duration(days: 1)));

  int minutesThisWeek(ActivityType type) =>
      minutes(type, weekStart(), DateTime.now().add(const Duration(days: 1)));
}
```

Note: the `export` line means files doing `import '../providers/activity_log.dart'` still see `ActivityType` / `ActivityEvent` — no churn in `focus_screen.dart`, `journal_screen.dart`, `insights_screen.dart`, `today_screen.dart`, etc.

- [ ] **Step 4: Update `lib/main.dart`**

```dart
        ChangeNotifierProvider(
          create: (ctx) => ActivityLog(ctx.read<Repository>())),
```

- [ ] **Step 5: Run tests**

Run: `flutter test test/activity_log_test.dart` → PASS.
Run: `flutter test` → all green.
Run: `flutter analyze --no-fatal-infos` → no errors/warnings.

- [ ] **Step 6: Commit**

```bash
git add lib/providers/activity_log.dart lib/main.dart test/activity_log_test.dart
git commit -m "back ActivityLog with the Repository

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 7: SettingsProvider onto the Repository

**Files:**
- Modify: `lib/providers/settings_provider.dart`, `lib/main.dart`
- Test: `test/data/settings_provider_test.dart` (create)

**Interfaces:**
- Consumes: `Repository` (Task 2), `AppSettings` (Task 1).
- Produces: `SettingsProvider(Repository repo)`. Getters unchanged: `meditationMinutes`, `breathSeconds`, `focusMinutes`, `longBreakEvery`. Setters unchanged: `setMeditationMinutes(int)`, `setBreathSeconds(int)`, `setFocusMinutes(int)`, `setLongBreakEvery(int)`. New: `int get completedPomodoros`, `Future<void> setCompletedPomodoros(int)` (used by `focus_screen` in Task 12).

- [ ] **Step 1: Write the failing test**

Create `test/data/settings_provider_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gaman/data/local_repository.dart';
import 'package:gaman/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('defaults, then a setter persists and notifies', () async {
    final repo = LocalRepository();
    await repo.ready;
    final s = SettingsProvider(repo);
    await s.ready;

    expect(s.focusMinutes, 25);
    var notified = 0;
    s.addListener(() => notified++);

    await s.setFocusMinutes(45);
    expect(s.focusMinutes, 45);
    expect(notified, greaterThan(0));

    final s2 = SettingsProvider(repo);
    await s2.ready;
    expect(s2.focusMinutes, 45);
    await repo.dispose();
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/settings_provider_test.dart`
Expected: FAIL — no `SettingsProvider(repo)` / no `ready`.

- [ ] **Step 3: Rewrite `lib/providers/settings_provider.dart`**

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/models.dart';
import '../data/repository.dart';

/// Timer defaults, backed by [Repository.watchSettings].
class SettingsProvider with ChangeNotifier {
  SettingsProvider(this._repo) {
    ready = _subscribe();
  }

  final Repository _repo;
  late final Future<void> ready;
  StreamSubscription<AppSettings>? _sub;
  AppSettings _s = const AppSettings();

  int get meditationMinutes => _s.meditationMinutes;
  int get breathSeconds => _s.breathSeconds;
  int get focusMinutes => _s.focusMinutes;
  int get longBreakEvery => _s.longBreakEvery;
  int get completedPomodoros => _s.completedPomodoros;

  Future<void> _subscribe() async {
    final c = Completer<void>();
    _sub = _repo.watchSettings().listen((s) {
      _s = s;
      notifyListeners();
      if (!c.isCompleted) c.complete();
    });
    return c.future;
  }

  Future<void> setMeditationMinutes(int v) =>
      _repo.saveSettings(_s.copyWith(meditationMinutes: v));
  Future<void> setBreathSeconds(int v) =>
      _repo.saveSettings(_s.copyWith(breathSeconds: v));
  Future<void> setFocusMinutes(int v) =>
      _repo.saveSettings(_s.copyWith(focusMinutes: v));
  Future<void> setLongBreakEvery(int v) =>
      _repo.saveSettings(_s.copyWith(longBreakEvery: v));
  Future<void> setCompletedPomodoros(int v) =>
      _repo.saveSettings(_s.copyWith(completedPomodoros: v));

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
```

- [ ] **Step 4: Update `lib/main.dart`**

```dart
        ChangeNotifierProvider(
          create: (ctx) => SettingsProvider(ctx.read<Repository>())),
```

- [ ] **Step 5: Run tests**

Run: `flutter test` → all green. `flutter analyze --no-fatal-infos` → clean.

- [ ] **Step 6: Commit**

```bash
git add lib/providers/settings_provider.dart lib/main.dart test/data/settings_provider_test.dart
git commit -m "back SettingsProvider with the Repository

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 8: FeaturePrefs onto the Repository

**Files:**
- Modify: `lib/providers/feature_prefs.dart`, `lib/main.dart`
- Test: `test/data/feature_prefs_test.dart` (create)

**Interfaces:**
- Consumes: `Repository` (Task 2), `AppSettings` (Task 1).
- Produces: `FeaturePrefs(Repository repo)`. Unchanged: `static const ids`, `bool isEnabled(String id)`, `Future<void> setEnabled(String id, bool enabled)`.

- [ ] **Step 1: Write the failing test**

Create `test/data/feature_prefs_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gaman/data/local_repository.dart';
import 'package:gaman/providers/feature_prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('all enabled by default; disabling one persists', () async {
    final repo = LocalRepository();
    await repo.ready;
    final f = FeaturePrefs(repo);
    await f.ready;

    expect(f.isEnabled('journal'), isTrue);
    await f.setEnabled('journal', false);
    expect(f.isEnabled('journal'), isFalse);

    final f2 = FeaturePrefs(repo);
    await f2.ready;
    expect(f2.isEnabled('journal'), isFalse);
    expect(f2.isEnabled('focus'), isTrue);
    await repo.dispose();
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/data/feature_prefs_test.dart` → FAIL (no repo constructor).

- [ ] **Step 3: Rewrite `lib/providers/feature_prefs.dart`**

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/models.dart';
import '../data/repository.dart';

/// Which practices show on the Today screen. All on by default.
class FeaturePrefs with ChangeNotifier {
  FeaturePrefs(this._repo) {
    ready = _subscribe();
  }

  static const ids = ['meditation', 'journal', 'binaural', 'focus', 'todo'];

  final Repository _repo;
  late final Future<void> ready;
  StreamSubscription<AppSettings>? _sub;
  AppSettings _s = const AppSettings();

  bool isEnabled(String id) => !_s.disabledFeatures.contains(id);

  Future<void> _subscribe() async {
    final c = Completer<void>();
    _sub = _repo.watchSettings().listen((s) {
      _s = s;
      notifyListeners();
      if (!c.isCompleted) c.complete();
    });
    return c.future;
  }

  Future<void> setEnabled(String id, bool enabled) {
    final next = {..._s.disabledFeatures};
    if (enabled) {
      next.remove(id);
    } else {
      next.add(id);
    }
    return _repo.saveSettings(_s.copyWith(disabledFeatures: next));
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
```

- [ ] **Step 4: Update `lib/main.dart`**

```dart
        ChangeNotifierProvider(
          create: (ctx) => FeaturePrefs(ctx.read<Repository>())),
```

- [ ] **Step 5: Run tests** → `flutter test` green, `flutter analyze --no-fatal-infos` clean.

- [ ] **Step 6: Commit**

```bash
git add lib/providers/feature_prefs.dart lib/main.dart test/data/feature_prefs_test.dart
git commit -m "back FeaturePrefs with the Repository

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 9: ThemeProvider onto the Repository

**Files:**
- Modify: `lib/providers/theme_provider.dart`, `lib/main.dart`
- Test: `test/data/theme_provider_test.dart` (create)

**Interfaces:**
- Consumes: `Repository` (Task 2), `AppSettings` (Task 1).
- Produces: `ThemeProvider(Repository repo)`. Unchanged: `ThemeMode get themeMode`, `Future<void> setThemeMode(ThemeMode)`, `bool get isDarkMode`, `Future<void> toggle()`.

- [ ] **Step 1: Write the failing test**

Create `test/data/theme_provider_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gaman/data/local_repository.dart';
import 'package:gaman/providers/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('defaults to system; setThemeMode persists', () async {
    final repo = LocalRepository();
    await repo.ready;
    final t = ThemeProvider(repo);
    await t.ready;
    expect(t.themeMode, ThemeMode.system);

    await t.setThemeMode(ThemeMode.dark);
    expect(t.themeMode, ThemeMode.dark);

    final t2 = ThemeProvider(repo);
    await t2.ready;
    expect(t2.themeMode, ThemeMode.dark);
    await repo.dispose();
  });

  test('toggle flips light/dark', () async {
    final repo = LocalRepository();
    await repo.ready;
    final t = ThemeProvider(repo);
    await t.ready;
    await t.setThemeMode(ThemeMode.light);
    await t.toggle();
    expect(t.themeMode, ThemeMode.dark);
    await repo.dispose();
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/data/theme_provider_test.dart` → FAIL.

- [ ] **Step 3: Rewrite `lib/providers/theme_provider.dart`**

```dart
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/repository.dart';

class ThemeProvider with ChangeNotifier {
  ThemeProvider(this._repo) {
    ready = _subscribe();
  }

  final Repository _repo;
  late final Future<void> ready;
  StreamSubscription<AppSettings>? _sub;
  AppSettings _s = const AppSettings();

  ThemeMode get themeMode => _s.themeMode;

  Future<void> _subscribe() async {
    final c = Completer<void>();
    _sub = _repo.watchSettings().listen((s) {
      _s = s;
      notifyListeners();
      if (!c.isCompleted) c.complete();
    });
    return c.future;
  }

  Future<void> setThemeMode(ThemeMode mode) {
    if (mode == _s.themeMode) return Future.value();
    return _repo.saveSettings(_s.copyWith(themeMode: mode));
  }

  bool get isDarkMode {
    if (_s.themeMode == ThemeMode.system) {
      return PlatformDispatcher.instance.platformBrightness == Brightness.dark;
    }
    return _s.themeMode == ThemeMode.dark;
  }

  Future<void> toggle() =>
      setThemeMode(isDarkMode ? ThemeMode.light : ThemeMode.dark);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
```

- [ ] **Step 4: Update `lib/main.dart`**

```dart
        ChangeNotifierProvider(
          create: (ctx) => ThemeProvider(ctx.read<Repository>())),
```

The `Consumer<ThemeProvider>` in `MyApp.build` is unchanged.

- [ ] **Step 5: Run tests** → `flutter test` green, `flutter analyze --no-fatal-infos` clean.

- [ ] **Step 6: Commit**

```bash
git add lib/providers/theme_provider.dart lib/main.dart test/data/theme_provider_test.dart
git commit -m "back ThemeProvider with the Repository

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 10: NotificationProvider persistence onto the Repository

**Files:**
- Modify: `lib/providers/notification_provider.dart`, `lib/main.dart`

**Interfaces:**
- Consumes: `Repository` (Task 2), `AppSettings` (Task 1).
- Produces: `NotificationProvider(Repository repo)`. Unchanged public surface: `bool get isEnabled`, `TimeOfDay? get scheduledTime`, `Future<void> toggleNotifications(bool)`, `Future<void> setTime(TimeOfDay)`, `Future<void> rescheduleNotification()`. The `flutter_local_notifications` / `timezone` scheduling code is unchanged — only the read/write of `isEnabled` and `scheduledTime` moves to the repo.

- [ ] **Step 1: Edit `lib/providers/notification_provider.dart`**

Add near the top:

```dart
import 'dart:async';
import '../data/models.dart';
import '../data/repository.dart';
```

Change the class head and constructor:

```dart
class NotificationProvider with ChangeNotifier {
  NotificationProvider(this._repo) {
    _initializeNotifications();
  }

  final Repository _repo;
  StreamSubscription<AppSettings>? _settingsSub;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isEnabled = true;
  TimeOfDay? _scheduledTime;

  bool get isEnabled => _isEnabled;
  TimeOfDay? get scheduledTime => _scheduledTime;
```

Delete the two `static const String _notificationTimeKey` / `_notificationEnabledKey` fields and the `_loadNotificationSettings()` body that reads `SharedPreferences`. Replace `_loadNotificationSettings` with a repo subscription:

```dart
  Future<void> _loadNotificationSettings() async {
    _settingsSub = _repo.watchSettings().listen((s) {
      _isEnabled = s.reminderEnabled;
      _scheduledTime = (s.reminderHour != null && s.reminderMinute != null)
          ? TimeOfDay(hour: s.reminderHour!, minute: s.reminderMinute!)
          : null;
      notifyListeners();
    });

    // First-run: pick a random reminder time if none is stored.
    final first = await _repo.watchSettings().first;
    if (first.reminderHour == null) {
      await _scheduleRandomTime();
    }
  }
```

In `_scheduleRandomTime()`, replace the `prefs.setString(_notificationTimeKey, ...)` write with:

```dart
    final current = await _repo.watchSettings().first;
    await _repo.saveSettings(current.copyWith(
      reminderHour: _scheduledTime!.hour,
      reminderMinute: _scheduledTime!.minute,
    ));
```

In `toggleNotifications(bool enabled)`, replace the `prefs.setBool(...)` write with:

```dart
    final current = await _repo.watchSettings().first;
    await _repo.saveSettings(current.copyWith(reminderEnabled: enabled));
```

In `setTime(TimeOfDay time)`, replace the `prefs.setString(...)` write with:

```dart
    final current = await _repo.watchSettings().first;
    await _repo.saveSettings(current.copyWith(
      reminderHour: time.hour, reminderMinute: time.minute));
```

Add to `dispose`:

```dart
  @override
  void dispose() {
    _settingsSub?.cancel();
    super.dispose();
  }
```

Remove the now-unused `import 'package:shared_preferences/shared_preferences.dart';` if nothing else in the file uses it.

- [ ] **Step 2: Update `lib/main.dart`**

```dart
        ChangeNotifierProvider(
          create: (ctx) => NotificationProvider(ctx.read<Repository>())),
```

- [ ] **Step 3: Verify**

Run: `flutter analyze --no-fatal-infos` → no errors/warnings.
Run: `flutter test` → all green.

- [ ] **Step 4: Commit**

```bash
git add lib/providers/notification_provider.dart lib/main.dart
git commit -m "back NotificationProvider settings with the Repository

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 11: journal_screen onto the Repository

**Files:**
- Modify: `lib/screens/journal_screen.dart`, `lib/screens/journal_prompt_screen.dart`
- Test: `test/journal_entry_test.dart`

**Interfaces:**
- Consumes: `Repository` (Task 2), `JournalEntry` from `lib/data/models.dart` (Task 1).
- Produces: no new interface. `journal_screen.dart` no longer defines `JournalEntry`.

- [ ] **Step 1: Update `test/journal_entry_test.dart`**

Change the import from `package:gaman/screens/journal_screen.dart` to `package:gaman/data/models.dart`. The test bodies are unchanged (`JournalEntry` API is identical).

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/journal_entry_test.dart`
Expected: FAIL — the models import works, but until Step 3 both files export `JournalEntry` and `journal_prompt_screen.dart` still imports the screen's copy. Actually it should PASS at this step (models.dart already has JournalEntry). If it PASSES, proceed; the failing gate is the analyzer in Step 4 once the duplicate is removed.

- [ ] **Step 3: Edit `lib/screens/journal_screen.dart`**

Remove the entire `class JournalEntry { ... }` block (lines defining it near the top).

Update imports:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models.dart';
import '../data/repository.dart';
import '../journal_templates.dart';
import '../providers/activity_log.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import 'journal_prompt_screen.dart';
```

(Drop `dart:convert`, `shared_preferences`, `intl` if now unused — check with the analyzer. `intl` is still used by `_formatDate`; keep it.)

In `_JournalScreenState`:

- Add `StreamSubscription<List<JournalEntry>>? _sub;` and `import 'dart:async';`.
- Replace `initState`'s `_loadEntries()` call with:

```dart
  @override
  void initState() {
    super.initState();
    _sub = context.read<Repository>().watchJournal().listen((entries) {
      if (mounted) setState(() {
        _entries
          ..clear()
          ..addAll(entries);
        _isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _contentController.dispose();
    super.dispose();
  }
```

- Delete `_loadEntries()` and `_persist()`.
- `_saveEntry()`: replace the local list mutation + `_persist()` with:

```dart
  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;
    final entry = JournalEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: _contentController.text,
      date: DateTime.now(),
      mood: _selectedMood,
    );
    _contentController.clear();
    _selectedMood = '😊';
    context.read<ActivityLog>().log(ActivityType.journal);
    await context.read<Repository>().upsertJournalEntry(entry);
  }
```

- `_addFromPrompt(JournalTemplate template)`: replace the local insert + `_persist()` with:

```dart
    if (entry == null) return;
    if (mounted) context.read<ActivityLog>().log(ActivityType.journal);
    await context.read<Repository>().upsertJournalEntry(entry);
```

- `_deleteEntry(JournalEntry entry)`:

```dart
  Future<void> _deleteEntry(JournalEntry entry) =>
      context.read<Repository>().deleteJournalEntry(entry.id);
```

- [ ] **Step 4: Edit `lib/screens/journal_prompt_screen.dart`**

Change `import 'journal_screen.dart';` to `import '../data/models.dart';`.

- [ ] **Step 5: Verify**

Run: `flutter analyze --no-fatal-infos` → no errors/warnings (fix any unused-import the analyzer flags).
Run: `flutter test` → all green.

- [ ] **Step 6: Manual check**

Run: `flutter run -d chrome`. Open Journal. Add a free entry → it appears in the list. Add a WOOP prompt entry → appears with its label. Delete one → it disappears. Hot-restart → entries persist.

- [ ] **Step 7: Commit**

```bash
git add lib/screens/journal_screen.dart lib/screens/journal_prompt_screen.dart test/journal_entry_test.dart
git commit -m "read and write journal entries through the Repository

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 12: todo_screen and focus/today task reads onto the Repository

**Files:**
- Modify: `lib/screens/todo_screen.dart`, `lib/screens/focus_screen.dart`, `lib/screens/today_screen.dart`

**Interfaces:**
- Consumes: `Repository` (Task 2), `SettingsProvider` (Task 7), `TodoTask` from `lib/data/models.dart` (Task 1).
- Produces: no new interface. `todo_screen.dart` no longer defines `TodoTask`.

- [ ] **Step 1: Edit `lib/screens/todo_screen.dart`**

Remove the `class TodoTask { ... }` block near the top. Update imports:

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../data/models.dart';
import '../data/repository.dart';
import '../providers/activity_log.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../services/gemini_service.dart';
import '../widgets/generate_tasks_dialog.dart';
import 'settings_screen.dart';
```

(Drop `dart:convert` and `shared_preferences` if unused after this.)

In `_TodoScreenState`:

- Add `StreamSubscription<List<TodoTask>>? _sub;` and `DateTime get _today => DateTime.now();`.
- Replace `_loadTasks()`'s `SharedPreferences` read with a subscription in `initState`:

```dart
  @override
  void initState() {
    super.initState();
    _checkAiConfiguration();
    _sub = context.read<Repository>().watchTasks(_today).listen((tasks) {
      if (!mounted) return;
      setState(() {
        _tasks
          ..clear()
          ..addAll(tasks.isEmpty ? _seedTasks() : tasks);
      });
      _initializeControllers();
    });
  }

  List<TodoTask> _seedTasks() => [
        TodoTask(
          id: 'main_${DateTime.now().millisecondsSinceEpoch}',
          title: '', isMainTask: true, createdAt: DateTime.now()),
        TodoTask(
          id: 'cruise_1_${DateTime.now().millisecondsSinceEpoch}',
          title: '', isMainTask: false, createdAt: DateTime.now()),
      ];
```

- Add to `dispose()`: `_sub?.cancel();`.
- Delete `_loadTasks()`.
- Replace `_saveTasks()`:

```dart
  Future<void> _saveTasks() =>
      context.read<Repository>().saveTasks(_today, _tasks);
```

- `_toggleTask`, `_updateTaskTitle`, `_addCruiseTask`, `_removeCruiseTask`, and the AI-generation success path already call `_saveTasks()` after mutating `_tasks` — leave those call sites, they now write through the repo. Keep the `setState` in each so the UI updates immediately (the stream will re-emit the same data).

- [ ] **Step 2: Edit `lib/screens/focus_screen.dart`**

`_loadTodayTasks()` currently reads `todo_tasks_$today` from `SharedPreferences`. Replace with a one-shot repo read:

```dart
  Future<void> _loadTodayTasks() async {
    final tasks = await context.read<Repository>().watchTasks(DateTime.now()).first;
    if (mounted) {
      setState(() => _todayTasks = tasks
          .map((t) => t.title.trim())
          .where((s) => s.isNotEmpty)
          .toList());
    }
  }
```

Add `import '../data/repository.dart';`. Drop `dart:convert` and `intl` and `shared_preferences` imports if now unused (check analyzer).

`_loadSettings()` / `_saveSettings()` currently use `pomodoro_duration` and `completed_pomodoros` prefs keys. Replace them with `SettingsProvider`:

```dart
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = context.read<SettingsProvider>();
    _selectedDuration = s.focusMinutes;
    _completedPomodoros = s.completedPomodoros;
  }
```

Remove `_loadSettings()` and its `initState` call. In `_saveSettings()` (called after a pomodoro completes):

```dart
  Future<void> _saveSettings() =>
      context.read<SettingsProvider>().setCompletedPomodoros(_completedPomodoros);
```

Where `_selectedDuration` is changed by a chip tap, also persist:

```dart
  onSelected: (selected) {
    if (selected) {
      setState(() {
        _selectedDuration = minutes;
        _remainingSeconds = minutes * 60;
      });
      context.read<SettingsProvider>().setFocusMinutes(minutes);
    }
  },
```

Add `import '../providers/settings_provider.dart';`.

- [ ] **Step 3: Edit `lib/screens/today_screen.dart`**

`_loadFrog()` reads `todo_tasks_$today` from `SharedPreferences`. Replace:

```dart
  Future<String?> _loadFrog() async {
    final tasks = await context.read<Repository>().watchTasks(DateTime.now()).first;
    for (final t in tasks) {
      if (t.isMainTask && t.title.trim().isNotEmpty) return t.title;
    }
    return null;
  }
```

Add `import '../data/repository.dart';`. Drop `dart:convert`, `intl`, `shared_preferences` if now unused.

- [ ] **Step 4: Verify**

Run: `flutter analyze --no-fatal-infos` → no errors/warnings.
Run: `flutter test` → all green.

- [ ] **Step 5: Manual check**

Run: `flutter run -d chrome`. Daily Goals: type a frog task, add a cruise task, check one → hot-restart → all persist. Today tab shows the frog. Focus tab: the frog + cruise tasks appear in the "Working on" dropdown. Complete a focus session → the "N sessions completed" count survives a hot-restart.

- [ ] **Step 6: Commit**

```bash
git add lib/screens/todo_screen.dart lib/screens/focus_screen.dart lib/screens/today_screen.dart
git commit -m "read tasks and pomodoro state through the Repository

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 13: Sweep for stray SharedPreferences use; final verification

**Files:**
- Modify: any file still importing `shared_preferences` that shouldn't (per the grep below)
- Test: `test/widget_test.dart` (only if it references a changed constructor)

**Interfaces:**
- Consumes: everything above.
- Produces: nothing — this is the closing gate.

- [ ] **Step 1: Grep for direct persistence outside the data layer**

Run:

```bash
grep -rn "SharedPreferences\|shared_preferences" lib/ --include=*.dart | grep -v "lib/data/"
```

Expected remaining hits (allowed): `lib/providers/quote_provider.dart` (daily quote cache — out of scope), `lib/services/gemini_service.dart` (API key — out of scope). Anything else in `lib/screens/` or `lib/providers/` is a miss — fix it by routing through the repo or a provider.

- [ ] **Step 2: Check the widget smoke test still builds `MyApp`**

Open `test/widget_test.dart`. It does not construct providers directly (it tests `AppTheme` / motion widgets), so no change is expected. If it imports `package:gaman/main.dart` and builds `MyApp`, run it:

Run: `flutter test test/widget_test.dart`
Expected: PASS. If it fails because `MyApp` now needs a real `SharedPreferences`, wrap the test body with `SharedPreferences.setMockInitialValues({});` in `setUp`.

- [ ] **Step 3: Full verification**

Run each, all must succeed:

```bash
flutter analyze --no-fatal-infos
flutter test
flutter build web --no-tree-shake-icons
```

- [ ] **Step 4: Full manual pass**

Run: `flutter run -d chrome`. Walk every tab: Today (greeting, streak, quote, frog, quick actions), Journal (add/prompt/delete), Focus (start a 1-min session, leave and return, complete), Insights (streak + week stats reflect what you just did), Settings (flip theme, toggle a practice, change a timer default, set a reminder time, export). Hot-restart and confirm all of it persisted.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "finish routing all user data through the Repository

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

- [ ] **Step 6: Open the PR**

```bash
git push -u origin feat/repository-layer
gh pr create --base main --head feat/repository-layer \
  --title "Repository layer (cloud-sync PR 1 of 6)" \
  --body "First step of the cloud-sync spec (docs/superpowers/specs/2026-09-07-cloud-sync-and-auth-design.md). Puts every piece of user data behind \`lib/data/repository.dart\`, with a \`LocalRepository\` that reads and writes the existing SharedPreferences keys — no behaviour change, no migration. Providers and screens now depend on \`Repository\`, so a \`FirestoreRepository\` drops in next with no further screen changes.

flutter analyze clean · flutter test green · flutter build web ok · full manual pass done.

🤖 Generated with [Claude Code](https://claude.com/claude-code)"
```

---

## Self-Review

**1. Spec coverage** (against the spec's "Rollout PR 1"):
- "`models.dart` (move JournalEntry / TodoTask / ActivityEvent out of the screen files)" → Tasks 1, 11, 12. ✓
- "`Repository` interface" → Task 2. ✓
- "`LocalRepository` (SharedPreferences, wrapping today's logic)" → Tasks 3–4. ✓
- "Refactor `ActivityLog` / `SettingsProvider` / `FeaturePrefs` / `ThemeProvider` / notification fields onto it" → Tasks 6–10. ✓
- "Still offline-only, no user-visible change" → guaranteed by the Global Constraint of reusing existing keys/formats; verified in Tasks 11–13 manual checks. ✓
- `AppSettings` fields cover every setting the spec's data model lists for `profile/settings` (themeMode, meditation/breath/focus/longBreak, reminder enabled/hour/minute, disabledFeatures). ✓ Plus `completedPomodoros` (existing app state, not in the spec doc — noted so the spec's PR 3 author adds it to the Firestore doc).

**2. Placeholder scan:** no "TBD"/"handle edge cases"/"similar to Task N". Each refactor task repeats its provider's full code. The one "see Step 3" cross-reference (Task 6 Step 1 → Step 3) is within the same task.

**3. Type consistency:**
- `LocalRepository` constructor `({SharedPreferences? prefs})` and `Future<void> ready` — used consistently in Tasks 3, 4, 6–10.
- `Repository` method names — `watchJournal` / `upsertJournalEntry` / `deleteJournalEntry` / `watchTasks` / `saveTasks` / `watchActivity` / `addActivity` / `watchSettings` / `saveSettings` / `dispose` — identical everywhere they appear (Tasks 2, 3, 6, 7, 8, 9, 10, 11, 12).
- `ActivityLog.log(ActivityType, {int durationSeconds, Map<String,dynamic> meta, DateTime? at})` — unchanged from current code, matches call sites in `focus_screen`, `journal_screen`, `meditation_screen`, `todo_screen`.
- Provider constructors all become `X(Repository repo)` with a `Future<void> ready` — consistent (Tasks 6–10).
- `SettingsProvider.setCompletedPomodoros` / `.completedPomodoros` defined in Task 7, consumed in Task 12. ✓
- `AppSettings.copyWith` parameter names match the field names and are used with those names in Tasks 7–10. ✓
