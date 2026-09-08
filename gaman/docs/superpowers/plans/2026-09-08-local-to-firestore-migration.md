# Local → Firestore Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development or superpowers:executing-plans. Steps use `- [ ]`.

**Goal:** The first time a user signs in on a device that has local data, copy that data into their Firestore account once, mark it done, and clear the local copies.

**Architecture:** `LocalToFirestoreMigration.run()` — reads the legacy `SharedPreferences` keys (via a throwaway `LocalRepository` for journal/activity/settings, and directly for the day-keyed task lists), writes everything into a `FirestoreRepository`, writes a `users/{uid}/profile/migration` marker doc, then removes the migrated `SharedPreferences` keys. Guarded by that marker doc so it runs at most once. Called from `main()` after `FirestoreRepository` is chosen. Idempotent-safe: journal/tasks/settings writes are keyed and overwrite; activity writes use a deterministic doc id.

**Tech Stack:** `cloud_firestore`, `shared_preferences`, `fake_cloud_firestore` (dev).

**Spec:** `docs/superpowers/specs/2026-09-07-cloud-sync-and-auth-design.md` (rollout PR 4). Branches off `feat/firestore-repository` (PR #39).

## Global Constraints

- Still no Firebase project → `auth.uid` is `null` → `FirestoreRepository` is never chosen → migration never runs → behaviour byte-identical to PR 3.
- Migration runs **only** when `users/{uid}/profile/migration` does not exist. After a successful run it must never run again.
- **Idempotency:** if a re-run somehow happens (marker write failed), journal (`doc(id).set`), tasks (`doc(dayKey).set`), and settings (`doc.set`) overwrite harmlessly. Activity events have no model id, so migration writes them at a **deterministic** doc id — `sanitize('${at.toIso8601String()}_${type.name}_${durationSeconds}')` — so a re-run overwrites rather than duplicates.
- After the marker is written, remove exactly these keys from `SharedPreferences`: `journal_entries`, every key matching `todo_tasks_*`, `activity_log`, `theme_mode`, `settings_meditation_minutes`, `settings_breath_seconds`, `settings_focus_minutes`, `settings_long_break_every`, `pomodoro_duration`, `completed_pomodoros`, `disabled_features`, `notification_enabled`, `notification_time`. Leave `binaural_volume`, the quote cache keys, and the Gemini key.
- `flutter analyze --no-fatal-infos` (0 errors/warnings), `flutter test`, `flutter build web --no-tree-shake-icons` pass.
- Commit style: imperative lower-case first word, no period, blank line, `Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>`.

---

## File Structure

**Create**
- `lib/data/local_to_firestore_migration.dart` — `LocalToFirestoreMigration`.
- `test/data/local_to_firestore_migration_test.dart`

**Modify**
- `lib/data/firestore_repository.dart` — expose what migration needs without leaking Firestore types: add `Future<bool> hasMigrated()`, `Future<void> markMigrated()`, and `Future<void> putActivityAt(String id, ActivityEvent event)` (deterministic-id activity write).
- `lib/main.dart` — after `FirestoreRepository` is chosen, `await LocalToFirestoreMigration(remote: repository as FirestoreRepository).run();` (guarded by a type check).

---

## Task 1: FirestoreRepository migration hooks

**Files:**
- Modify: `lib/data/firestore_repository.dart`, `test/data/firestore_repository_test.dart`

**Interfaces:**
- Consumes: existing `FirestoreRepository`.
- Produces on `FirestoreRepository`:
  - `Future<bool> hasMigrated()` — true iff `users/{uid}/profile/migration` exists.
  - `Future<void> markMigrated()` — `set` that doc to `{'done': true, 'at': FieldValue.serverTimestamp()}`.
  - `Future<void> putActivityAt(String id, ActivityEvent event)` — `_activityCol.doc(id).set(event.toJson())`.

- [ ] **Step 1: Add failing tests**

Append to `test/data/firestore_repository_test.dart`:

```dart
  test('hasMigrated is false until markMigrated', () async {
    expect(await repo.hasMigrated(), isFalse);
    await repo.markMigrated();
    expect(await repo.hasMigrated(), isTrue);
    final raw = (await db.doc('users/u1/profile/migration').get()).data()!;
    expect(raw['done'], isTrue);
  });

  test('putActivityAt writes at a fixed id (re-run overwrites)', () async {
    final ev = ActivityEvent(
        type: ActivityType.focus, at: DateTime(2026, 1, 1), durationSeconds: 60);
    await repo.putActivityAt('fixed-1', ev);
    await repo.putActivityAt('fixed-1', ev);
    expect(await repo.watchActivity().first, hasLength(1));
  });
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/data/firestore_repository_test.dart` → the 2 new tests FAIL (methods missing).

- [ ] **Step 3: Add the three methods to `lib/data/firestore_repository.dart`**

After `_settingsDoc`:

```dart
  DocumentReference<Map<String, dynamic>> get _migrationDoc =>
      _db.doc('users/$_uid/profile/migration');

  Future<bool> hasMigrated() async => (await _migrationDoc.get()).exists;

  Future<void> markMigrated() => _migrationDoc.set({
        'done': true,
        'at': FieldValue.serverTimestamp(),
      });

  Future<void> putActivityAt(String id, ActivityEvent event) =>
      _activityCol.doc(id).set(event.toJson());
```

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/data/firestore_repository_test.dart` → all PASS (13).

- [ ] **Step 5: Commit**

```bash
git add lib/data/firestore_repository.dart test/data/firestore_repository_test.dart
git commit -m "add migration hooks to FirestoreRepository

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 2: LocalToFirestoreMigration

**Files:**
- Create: `lib/data/local_to_firestore_migration.dart`, `test/data/local_to_firestore_migration_test.dart`

**Interfaces:**
- Consumes: `FirestoreRepository` (Task 1 methods), `LocalRepository`, models, `shared_preferences`.
- Produces:
  - `class LocalToFirestoreMigration`
  - `LocalToFirestoreMigration({required FirestoreRepository remote, SharedPreferences? prefs, LocalRepository? local})` — `prefs`/`local` default to real instances; tests inject.
  - `Future<bool> run()` — returns true if it did a migration this call, false if already done / nothing to do. Steps:
    1. `if (await remote.hasMigrated()) return false;`
    2. Build a `LocalRepository` (injected or `LocalRepository()..ready`). Read one-shot: `journal = await local.watchJournal().first`, `activity = await local.watchActivity().first`, `settings = await local.watchSettings().first`.
    3. `for (final e in journal) await remote.upsertJournalEntry(e);`
    4. For tasks: `for (final key in prefs.getKeys().where((k) => k.startsWith('todo_tasks_')))` — parse the date from the suffix (`todo_tasks_2026-03-04` → `DateTime(2026,3,4)`; skip on parse failure), `final tasks = await local.watchTasks(date).first`, `if (tasks.isNotEmpty) await remote.saveTasks(date, tasks);`
    5. `for (final ev in activity) await remote.putActivityAt(_activityId(ev), ev);` where `_activityId(ev) = '${ev.at.toIso8601String()}_${ev.type.name}_${ev.durationSeconds}'.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '-')`
    6. `await remote.saveSettings(settings);`
    7. `await remote.markMigrated();`
    8. Remove the legacy keys (the exact list in Global Constraints; tasks: `prefs.getKeys().where((k) => k.startsWith('todo_tasks_'))`).
    9. `return true;`
  - Wrap steps 2–8 so a thrown error leaves the marker unwritten (do not catch-and-mark). Let `run()` propagate; the caller logs and continues.

- [ ] **Step 1: Write the failing test**

Create `test/data/local_to_firestore_migration_test.dart`:

```dart
import 'dart:convert';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gaman/data/firestore_repository.dart';
import 'package:gaman/data/local_repository.dart';
import 'package:gaman/data/local_to_firestore_migration.dart';
import 'package:gaman/data/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore db;
  late FirestoreRepository remote;

  setUp(() {
    db = FakeFirebaseFirestore();
    remote = FirestoreRepository(uid: 'u1', firestore: db);
  });

  Future<LocalToFirestoreMigration> build() async {
    final prefs = await SharedPreferences.getInstance();
    final local = LocalRepository(prefs: prefs);
    await local.ready;
    return LocalToFirestoreMigration(remote: remote, prefs: prefs, local: local);
  }

  test('copies journal, tasks, activity and settings, then marks + clears', () async {
    SharedPreferences.setMockInitialValues({
      'journal_entries': [
        jsonEncode({
          'id': 'j1', 'content': 'hello', 'mood': '😊', 'type': 'free',
          'date': DateTime(2026, 1, 1).toIso8601String(),
        }),
      ],
      'todo_tasks_2026-03-04': [
        jsonEncode({
          'id': 'm', 'title': 'frog', 'isCompleted': false, 'isMainTask': true,
          'createdAt': DateTime(2026, 3, 4).toIso8601String(),
        }),
      ],
      'activity_log': [
        jsonEncode({
          'type': 'focus', 'at': DateTime(2026, 2, 1).toIso8601String(),
          'dur': 1500,
        }),
      ],
      'settings_focus_minutes': 40,
      'theme_mode': 'ThemeMode.dark',
      'binaural_volume': 0.7,
    });

    final did = await (await build()).run();
    expect(did, isTrue);

    expect((await remote.watchJournal().first).single.content, 'hello');
    expect((await remote.watchTasks(DateTime(2026, 3, 4)).first).single.title, 'frog');
    expect((await remote.watchActivity().first).single.durationSeconds, 1500);
    final s = await remote.watchSettings().first;
    expect(s.focusMinutes, 40);
    expect(s.themeMode, ThemeMode.dark);

    expect(await remote.hasMigrated(), isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys().contains('journal_entries'), isFalse);
    expect(prefs.getKeys().contains('todo_tasks_2026-03-04'), isFalse);
    expect(prefs.getKeys().contains('settings_focus_minutes'), isFalse);
    expect(prefs.getDouble('binaural_volume'), 0.7); // untouched
  });

  test('does nothing when already migrated', () async {
    SharedPreferences.setMockInitialValues({
      'journal_entries': [
        jsonEncode({
          'id': 'j1', 'content': 'x', 'mood': '😊', 'type': 'free',
          'date': DateTime(2026).toIso8601String(),
        }),
      ],
    });
    await remote.markMigrated();
    final did = await (await build()).run();
    expect(did, isFalse);
    expect(await remote.watchJournal().first, isEmpty);
  });

  test('re-run after a lost marker does not duplicate activity', () async {
    SharedPreferences.setMockInitialValues({
      'activity_log': [
        jsonEncode({
          'type': 'meditation', 'at': DateTime(2026, 5, 1).toIso8601String(),
          'dur': 600,
        }),
      ],
    });
    await (await build()).run();
    // simulate the marker never landing: delete it, keep prefs already cleared
    await db.doc('users/u1/profile/migration').delete();
    SharedPreferences.setMockInitialValues({
      'activity_log': [
        jsonEncode({
          'type': 'meditation', 'at': DateTime(2026, 5, 1).toIso8601String(),
          'dur': 600,
        }),
      ],
    });
    await (await build()).run();
    expect(await remote.watchActivity().first, hasLength(1));
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/data/local_to_firestore_migration_test.dart` → FAIL (class missing).

- [ ] **Step 3: Write `lib/data/local_to_firestore_migration.dart`**

```dart
import 'package:shared_preferences/shared_preferences.dart';

import 'firestore_repository.dart';
import 'local_repository.dart';
import 'models.dart';

/// Copies a device's local data into the signed-in user's Firestore account,
/// exactly once. Guarded by `users/{uid}/profile/migration`.
class LocalToFirestoreMigration {
  LocalToFirestoreMigration({
    required this.remote,
    SharedPreferences? prefs,
    LocalRepository? local,
  })  : _injectedPrefs = prefs,
        _injectedLocal = local;

  final FirestoreRepository remote;
  final SharedPreferences? _injectedPrefs;
  final LocalRepository? _injectedLocal;

  static const _settingsKeys = [
    'theme_mode',
    'settings_meditation_minutes',
    'settings_breath_seconds',
    'settings_focus_minutes',
    'settings_long_break_every',
    'pomodoro_duration',
    'completed_pomodoros',
    'disabled_features',
    'notification_enabled',
    'notification_time',
  ];

  Future<bool> run() async {
    if (await remote.hasMigrated()) return false;

    final prefs = _injectedPrefs ?? await SharedPreferences.getInstance();
    final local = _injectedLocal ?? (LocalRepository(prefs: prefs));
    await local.ready;

    final journal = await local.watchJournal().first;
    final activity = await local.watchActivity().first;
    final settings = await local.watchSettings().first;

    for (final e in journal) {
      await remote.upsertJournalEntry(e);
    }

    final taskKeys =
        prefs.getKeys().where((k) => k.startsWith('todo_tasks_')).toList();
    for (final key in taskKeys) {
      final date = DateTime.tryParse(key.substring('todo_tasks_'.length));
      if (date == null) continue;
      final tasks = await local.watchTasks(date).first;
      if (tasks.isNotEmpty) await remote.saveTasks(date, tasks);
    }

    for (final ev in activity) {
      await remote.putActivityAt(_activityId(ev), ev);
    }

    await remote.saveSettings(settings);
    await remote.markMigrated();

    for (final k in [
      'journal_entries',
      'activity_log',
      ..._settingsKeys,
      ...taskKeys,
    ]) {
      await prefs.remove(k);
    }

    return true;
  }

  static String _activityId(ActivityEvent e) =>
      '${e.at.toIso8601String()}_${e.type.name}_${e.durationSeconds}'
          .replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '-');
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/data/local_to_firestore_migration_test.dart` → all 3 PASS.

- [ ] **Step 5: Full suite + commit**

```bash
flutter test
flutter analyze --no-fatal-infos
git add lib/data/local_to_firestore_migration.dart test/data/local_to_firestore_migration_test.dart
git commit -m "add one-time local to Firestore migration

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 3: Run migration at startup

**Files:**
- Modify: `lib/main.dart`

**Interfaces:**
- Consumes: `LocalToFirestoreMigration` (Task 2).
- Produces: nothing.

- [ ] **Step 1: Edit `lib/main.dart`**

Add `import 'data/local_to_firestore_migration.dart';`.

Right after the repository is chosen:

```dart
  final Repository repository = auth.uid != null
      ? FirestoreRepository(uid: auth.uid!)
      : LocalRepository();

  if (repository is FirestoreRepository) {
    try {
      await LocalToFirestoreMigration(remote: repository).run();
    } catch (e) {
      debugPrint('Local→Firestore migration failed (will retry next launch): $e');
    }
  }
```

- [ ] **Step 2: Verify**

```bash
flutter analyze --no-fatal-infos
flutter test
flutter build web --no-tree-shake-icons
```
All green. Without a Firebase project, `repository is FirestoreRepository` is false → migration is never constructed → no behaviour change.

- [ ] **Step 3: Commit**

```bash
git add lib/main.dart
git commit -m "run local to Firestore migration on first authenticated launch

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 4: Verify and open the PR (controller)

- [ ] `flutter analyze --no-fatal-infos` (0/0), `flutter test` (all green, ~58), `flutter build web` succeeds.
- [ ] Confirm no `firebase_options.dart` / `DefaultFirebaseOptions` snuck in.
- [ ] `git push -u origin feat/local-to-firestore-migration`; PR against `feat/firestore-repository`. Body: one-time migration behind `users/{uid}/profile/migration`; idempotent (deterministic activity ids); clears the migrated `SharedPreferences` keys (leaves `binaural_volume` / quote cache / Gemini key); inert without a project. Note: PR 3 + PR 4 should merge together so the first cloud sign-in isn't empty.

## Self-Review

**Spec coverage** (rollout PR 4: "One-time copy of legacy SharedPreferences data to Firestore under the uid; set `migrated`; clear legacy keys."):
- one-time copy → Task 2 `run()`, guarded by `hasMigrated()` (Task 1) ✓
- all data domains → journal, tasks (day-keyed enumeration), activity, settings ✓
- set migrated → `markMigrated()` writes `users/{uid}/profile/migration` ✓ (a separate doc, not a field on `AppSettings` — the spec's data-model sketch put `migrated` inside `profile/settings`; a dedicated doc avoids adding a field to `AppSettings` and touching both repos + models. Functionally equivalent — noted for the reviewer.)
- clear legacy keys → Task 2 step 8, explicit key list ✓
- runs at startup after auth → Task 3 ✓

**Placeholder scan:** none.

**Type consistency:** `FirestoreRepository.hasMigrated()` / `markMigrated()` / `putActivityAt(String, ActivityEvent)` defined in Task 1, consumed in Task 2. `LocalToFirestoreMigration({required FirestoreRepository remote, SharedPreferences? prefs, LocalRepository? local})` — Task 2 tests use all three params; Task 3 `main.dart` uses the one-arg form. `LocalRepository(prefs:)` + `.ready` — matches PR 1's constructor. `_activityId` deterministic-id format matches between the plan's Global Constraints and Task 2 Step 3.
