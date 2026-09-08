# Firestore Repository Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development or superpowers:executing-plans. Steps use `- [ ]`.

**Goal:** A `FirestoreRepository` implementing the existing `Repository` interface against the spec's per-user Firestore layout, selected at startup when an authenticated `uid` is available, with security rules committed. Still inert until `flutterfire configure` runs (no `uid` → `LocalRepository`).

**Architecture:** `FirestoreRepository(uid)` maps each domain to `users/{uid}/…` collections/docs and turns Firestore snapshot streams into the `Repository`'s `Stream`s. Firestore's own offline cache is the sync layer. `main()` awaits auth, then picks `FirestoreRepository` vs `LocalRepository` and passes it into `MyApp`.

**Tech Stack:** `cloud_firestore`; `fake_cloud_firestore` (dev) for tests. Firebase Firestore security rules.

**Spec:** `docs/superpowers/specs/2026-09-07-cloud-sync-and-auth-design.md` (rollout PR 3). Branches off `feat/firebase-bootstrap` (PR #38).

## Global Constraints

- No `flutterfire configure` / `firebase_options.dart` / `google-services.json` in this PR (still no project). Without a real project `AuthService.uid` is `null` at startup → `LocalRepository` is chosen → **behaviour byte-identical to PR 2**.
- Firestore document field names are **exactly** the `toJson()` shapes the models already produce (`AppSettings.toJson`, `JournalEntry.toJson`, `TodoTask.toJson`, `ActivityEvent.toJson`) — PR 1's tests lock these. Add only `updatedAt: FieldValue.serverTimestamp()` on writes.
- `ActivityEvent` has no `id` field and gets none — `FirestoreRepository.addActivity` uses an auto-id (`collection.add(...)` or `.doc()` with no path). Activity is append-only, never updated or deleted, so the id is never referenced.
- Migration of existing `SharedPreferences` data into Firestore is **PR 4, not here**. A freshly-authenticated user gets an empty `FirestoreRepository` until PR 4 lands; note it in the PR body.
- `flutter analyze --no-fatal-infos` (0 errors/warnings), `flutter test`, `flutter build web --no-tree-shake-icons` all pass.
- `cloud_firestore` version: let `flutter pub add` resolve against the pinned SDK. If it conflicts with the `firebase_core`/`firebase_auth` already present, STOP and report.
- Commit style: imperative lower-case first word, no period, blank line, `Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>`.

---

## File Structure

**Create**
- `lib/data/firestore_repository.dart` — `FirestoreRepository implements Repository`.
- `test/data/firestore_repository_test.dart` — contract tests via `fake_cloud_firestore`.
- `firestore.rules` — security rules.
- `firebase.json` — points the Firebase CLI at `firestore.rules`.
- `docs/cloud-sync-firebase-setup.md` — the maintainer's console + `flutterfire configure` steps and the rules-deploy command (consolidates what's scattered across PR bodies).

**Modify**
- `pubspec.yaml` — add `cloud_firestore`; dev-add `fake_cloud_firestore`.
- `lib/main.dart` — after `Firebase.initializeApp()`, build `AuthService`, `await auth.ensureSignedIn()`, pick the repository, pass `repository` + `auth` into `MyApp`.
- `lib/main.dart` `MyApp` — take `Repository repository` and `AuthService auth` as constructor args; `MultiProvider` uses `Provider<Repository>.value` and `ChangeNotifierProvider<AuthService>.value`.

---

## Task 1: FirestoreRepository — journal + settings

**Files:**
- Create: `lib/data/firestore_repository.dart`, `test/data/firestore_repository_test.dart`
- Modify: `pubspec.yaml`

**Interfaces:**
- Consumes: `Repository`, models (PR 1), `cloud_firestore`.
- Produces:
  - `class FirestoreRepository implements Repository`
  - `FirestoreRepository({required String uid, FirebaseFirestore? firestore})` — `firestore` defaults to `FirebaseFirestore.instance`; tests pass a `FakeFirebaseFirestore`.
  - `DocumentReference<Map<String,dynamic>> get _settingsDoc` → `_db.doc('users/$uid/profile/settings')`
  - `CollectionReference<Map<String,dynamic>> get _journalCol` → `_db.collection('users/$uid/journal')`

- [ ] **Step 1: Add packages**

```bash
flutter pub add cloud_firestore
flutter pub add dev:fake_cloud_firestore
```
If resolution fails, STOP and report.

- [ ] **Step 2: Write the failing test**

Create `test/data/firestore_repository_test.dart`:

```dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaman/data/firestore_repository.dart';
import 'package:gaman/data/models.dart';

void main() {
  late FakeFirebaseFirestore db;
  late FirestoreRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = FirestoreRepository(uid: 'u1', firestore: db);
  });

  test('journal: upsert then watch emits it, newest first', () async {
    await repo.upsertJournalEntry(JournalEntry(
        id: 'a', content: 'older', date: DateTime(2026, 1, 1), mood: '😊'));
    await repo.upsertJournalEntry(JournalEntry(
        id: 'b', content: 'newer', date: DateTime(2026, 2, 1), mood: '😊'));
    final list = await repo.watchJournal().first;
    expect(list.map((e) => e.content), ['newer', 'older']);
  });

  test('journal: upsert same id replaces', () async {
    final e = JournalEntry(
        id: 'a', content: 'v1', date: DateTime(2026), mood: '😊');
    await repo.upsertJournalEntry(e);
    await repo.upsertJournalEntry(JournalEntry(
        id: 'a', content: 'v2', date: e.date, mood: '😊'));
    expect((await repo.watchJournal().first).single.content, 'v2');
  });

  test('journal: delete removes', () async {
    await repo.upsertJournalEntry(JournalEntry(
        id: 'a', content: 'x', date: DateTime(2026), mood: '😊'));
    await repo.deleteJournalEntry('a');
    expect(await repo.watchJournal().first, isEmpty);
  });

  test('journal doc has the model toJson shape plus updatedAt', () async {
    await repo.upsertJournalEntry(JournalEntry(
        id: 'a', content: 'x', date: DateTime(2026, 3, 4), mood: '😐',
        type: 'woop', sections: {'Wish': 'ship'}));
    final raw = (await db.doc('users/u1/journal/a').get()).data()!;
    expect(raw['content'], 'x');
    expect(raw['type'], 'woop');
    expect(raw['sections'], {'Wish': 'ship'});
    expect(raw.containsKey('updatedAt'), isTrue);
  });

  test('settings: default when the doc is absent', () async {
    final s = await repo.watchSettings().first;
    expect(s.themeMode, ThemeMode.system);
    expect(s.focusMinutes, 25);
  });

  test('settings: save then read back', () async {
    await repo.saveSettings(const AppSettings()
        .copyWith(focusMinutes: 40, disabledFeatures: {'journal'}));
    final s = await repo.watchSettings().first;
    expect(s.focusMinutes, 40);
    expect(s.disabledFeatures, {'journal'});
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/data/firestore_repository_test.dart` → FAIL (no `firestore_repository.dart`).

- [ ] **Step 4: Write `lib/data/firestore_repository.dart` (journal + settings; other methods stubbed with `UnimplementedError` for now)**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

import 'models.dart';
import 'repository.dart';

/// [Repository] backed by Cloud Firestore under `users/{uid}/…`.
/// Firestore's local cache provides offline reads/writes — this class does no
/// sync bookkeeping of its own.
class FirestoreRepository implements Repository {
  FirestoreRepository({required String uid, FirebaseFirestore? firestore})
      : _uid = uid,
        _db = firestore ?? FirebaseFirestore.instance;

  final String _uid;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _journalCol =>
      _db.collection('users/$_uid/journal');
  DocumentReference<Map<String, dynamic>> get _settingsDoc =>
      _db.doc('users/$_uid/profile/settings');

  // --- journal ----------------------------------------------------------

  @override
  Stream<List<JournalEntry>> watchJournal() =>
      _journalCol.orderBy('date', descending: true).snapshots().map((snap) =>
          snap.docs.map((d) => JournalEntry.fromJson(d.data())).toList());

  @override
  Future<void> upsertJournalEntry(JournalEntry entry) =>
      _journalCol.doc(entry.id).set({
        ...entry.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> deleteJournalEntry(String id) => _journalCol.doc(id).delete();

  // --- settings -------------------------------------------------------

  @override
  Stream<AppSettings> watchSettings() => _settingsDoc.snapshots().map(
      (d) => AppSettings.fromJson(d.data() ?? const {}));

  @override
  Future<void> saveSettings(AppSettings settings) => _settingsDoc.set({
        ...settings.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  // --- filled in by Task 2 -----------------------------------------

  @override
  Stream<List<TodoTask>> watchTasks(DateTime day) =>
      throw UnimplementedError();
  @override
  Future<void> saveTasks(DateTime day, List<TodoTask> tasks) =>
      throw UnimplementedError();
  @override
  Stream<List<ActivityEvent>> watchActivity() => throw UnimplementedError();
  @override
  Future<void> addActivity(ActivityEvent event) => throw UnimplementedError();

  @override
  Future<void> dispose() async {}
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/data/firestore_repository_test.dart` → the 6 journal+settings tests PASS. (`orderBy('date')` works in `fake_cloud_firestore`; `date` is stored as an ISO string, which sorts lexicographically = chronologically for ISO-8601.)

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/data/firestore_repository.dart test/data/firestore_repository_test.dart
git commit -m "add FirestoreRepository journal and settings

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 2: FirestoreRepository — tasks + activity

**Files:**
- Modify: `lib/data/firestore_repository.dart`, `test/data/firestore_repository_test.dart`

**Interfaces:**
- Consumes: Task 1's class.
- Produces: real `watchTasks` / `saveTasks` / `watchActivity` / `addActivity`.
  - Tasks doc key: `_dayKey(day)` = `yyyy-MM-dd` (zero-padded) — must match `LocalRepository._dayKey` and the app's `DateFormat('yyyy-MM-dd')`.
  - `watchTasks` reads `users/{uid}/tasks/{key}`, field `tasks` is a `List` of `TodoTask.toJson()` maps; missing doc → `[]`.
  - `watchActivity` reads `users/{uid}/activity` ordered by `at` ascending; missing → `[]`.
  - `addActivity` → `_activityCol.add({...event.toJson()})` (auto-id).

- [ ] **Step 1: Add failing tests**

Append to `test/data/firestore_repository_test.dart`:

```dart
  test('tasks: save then watch same calendar day', () async {
    final day = DateTime(2026, 3, 4, 15);
    await repo.saveTasks(day, [
      TodoTask(id: 'm', title: 'frog', isMainTask: true, createdAt: day),
    ]);
    final list = await repo.watchTasks(DateTime(2026, 3, 4, 8)).first;
    expect(list.single.title, 'frog');
  });

  test('tasks: absent day is empty', () async {
    expect(await repo.watchTasks(DateTime(2026, 5, 5)).first, isEmpty);
  });

  test('activity: add appends, watch is oldest-first', () async {
    await repo.addActivity(ActivityEvent(
        type: ActivityType.focus, at: DateTime(2026, 1, 2), durationSeconds: 1500));
    await repo.addActivity(ActivityEvent(
        type: ActivityType.journal, at: DateTime(2026, 1, 1)));
    final list = await repo.watchActivity().first;
    expect(list.map((e) => e.type),
        [ActivityType.journal, ActivityType.focus]);
  });
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/data/firestore_repository_test.dart` → the 3 new tests FAIL with `UnimplementedError`.

- [ ] **Step 3: Replace the stubbed methods**

In `lib/data/firestore_repository.dart`, add imports and helpers and replace the four stubs:

```dart
  CollectionReference<Map<String, dynamic>> get _activityCol =>
      _db.collection('users/$_uid/activity');

  static String _dayKey(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$dd';
  }

  @override
  Stream<List<TodoTask>> watchTasks(DateTime day) => _db
      .doc('users/$_uid/tasks/${_dayKey(day)}')
      .snapshots()
      .map((d) => ((d.data()?['tasks'] as List?) ?? const [])
          .map((e) => TodoTask.fromJson((e as Map).cast<String, dynamic>()))
          .toList());

  @override
  Future<void> saveTasks(DateTime day, List<TodoTask> tasks) =>
      _db.doc('users/$_uid/tasks/${_dayKey(day)}').set({
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  @override
  Stream<List<ActivityEvent>> watchActivity() =>
      _activityCol.orderBy('at').snapshots().map((snap) =>
          snap.docs.map((d) => ActivityEvent.fromJson(d.data())).toList());

  @override
  Future<void> addActivity(ActivityEvent event) =>
      _activityCol.add(event.toJson());
```

Delete the four `throw UnimplementedError()` lines.

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/data/firestore_repository_test.dart` → all 9 PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/data/firestore_repository.dart test/data/firestore_repository_test.dart
git commit -m "complete FirestoreRepository tasks and activity

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 3: Select the repository at startup

**Files:**
- Modify: `lib/main.dart`

**Interfaces:**
- Consumes: `FirestoreRepository` (Tasks 1–2), `AuthService` (PR 2), `LocalRepository` (PR 1).
- Produces: `MyApp({required Repository repository, required AuthService auth})`.

- [ ] **Step 1: Rewrite the tail of `main()` and `MyApp`'s constructor**

In `main()`, after the `Firebase.initializeApp()` try/catch and before the notifications block (order doesn't matter, but keep it before `runApp`):

```dart
  final auth = AuthService();
  await auth.ensureSignedIn();
  final Repository repository = auth.uid != null
      ? FirestoreRepository(uid: auth.uid!)
      : LocalRepository();
```

Change the final line to `runApp(MyApp(repository: repository, auth: auth));`.

Add imports: `import 'data/firestore_repository.dart';` (`local_repository.dart`, `repository.dart`, `services/auth_service.dart` are already imported).

In `MyApp`:

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.repository, required this.auth});

  final Repository repository;
  final AuthService auth;
```

In the `MultiProvider` `providers:` list, replace the first two entries:

```dart
        Provider<Repository>.value(value: repository),
        ChangeNotifierProvider<AuthService>.value(value: auth),
```

Remove the old `Provider<Repository>(create: (_) => LocalRepository(), dispose: ...)` and `ChangeNotifierProvider(create: (_) => AuthService()..ensureSignedIn())`. The `dispose` for the repository now needs handling: add `dispose: (_) => repository.dispose()` is not available on `.value`; instead dispose in `main` is unnecessary for a process-lifetime object — drop it, or keep a top-level `@visibleForTesting` note. (Both `LocalRepository` and `FirestoreRepository` hold only stream controllers / nothing; leaking them for the app's lifetime is fine.)

- [ ] **Step 2: Verify**

```bash
flutter analyze --no-fatal-infos
flutter test
flutter build web --no-tree-shake-icons
```
All green. Without a Firebase project, `auth.uid` is `null` → `LocalRepository` → behaviour unchanged. Existing `test/widget_test.dart` does not build `MyApp` (it tests theme/motion widgets) so no test change is needed; if it does, pass `repository: LocalRepository()` and `auth: AuthService(auth: null, resolveDefault: false)`.

- [ ] **Step 3: Commit**

```bash
git add lib/main.dart
git commit -m "select FirestoreRepository when authenticated

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 4: Security rules and setup doc

**Files:**
- Create: `firestore.rules`, `firebase.json`, `docs/cloud-sync-firebase-setup.md`

**Interfaces:** none (config + docs).

- [ ] **Step 1: Write `firestore.rules`**

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // A signed-in user owns everything under their uid, and nothing else.
    match /users/{uid}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

- [ ] **Step 2: Write `firebase.json`**

```json
{
  "firestore": {
    "rules": "firestore.rules"
  }
}
```

- [ ] **Step 3: Write `docs/cloud-sync-firebase-setup.md`**

```markdown
# Cloud sync — Firebase setup (one-time, maintainer)

Until this is done, `AuthService.uid` is null at startup and the app runs
entirely on `LocalRepository` — every cloud-sync PR is inert.

1. **Create the project** — console.firebase.google.com → *Add project* "gaman"
   (skip Google Analytics).
2. **Auth providers** — Build → Authentication → Get started → enable
   **Anonymous** and **Google**.
3. **Firestore** — Build → Firestore Database → *Create database* → production
   mode → pick a region.
4. **Generate config** —
   ```
   dart pub global activate flutterfire_cli
   cd gaman && flutterfire configure
   ```
   Select the `gaman` project and the **android** + **web** platforms. This
   writes `lib/firebase_options.dart` and `android/app/google-services.json`.
5. **Use the config** — in `lib/main.dart`, change
   `Firebase.initializeApp()` → `Firebase.initializeApp(options:
   DefaultFirebaseOptions.currentPlatform)` (the `TODO(cloud-sync)` marker).
6. **Authorised domains** — Authentication → Settings → Authorized domains →
   add `egecanozcakar.github.io` (the GitHub Pages deploy).
7. **Deploy the rules** —
   ```
   npm i -g firebase-tools
   firebase login
   firebase deploy --only firestore:rules --project gaman
   ```
   Re-run step 7 whenever `firestore.rules` changes.
```

- [ ] **Step 4: Commit**

```bash
git add firestore.rules firebase.json docs/cloud-sync-firebase-setup.md
git commit -m "add Firestore security rules and setup doc

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 5: Verify and open the PR (controller)

- [ ] **Step 1:** `flutter analyze --no-fatal-infos` → 0 errors/warnings. `flutter test` → all green (expect ~50). `flutter build web --no-tree-shake-icons` → succeeds.
- [ ] **Step 2:** Confirm no `firebase_options.dart` / `google-services.json` / `DefaultFirebaseOptions` code snuck in.
- [ ] **Step 3:** `git push -u origin feat/firestore-repository`; PR against `feat/firebase-bootstrap`. Body: FirestoreRepository implemented + tested via `fake_cloud_firestore`, selected at startup when `uid` is available (still `LocalRepository` with no project), rules committed. **Note: migration of existing local data is PR 4 — a freshly-authenticated user gets an empty Firestore until then.**

## Self-Review

**Spec coverage** (rollout PR 3: "Implement against the data model; make it the runtime repository when Firebase is up; commit firestore.rules and the deploy step for them."):
- Implement against the model → Tasks 1–2, all four domains, `toJson` shapes verbatim ✓
- Runtime repository when Firebase is up → Task 3 (`auth.uid != null` gate) ✓
- `firestore.rules` + deploy step → Task 4 (rules file + `firebase.json` + documented `firebase deploy` command) ✓
- Data model matches spec's `users/{uid}/journal|tasks|activity|profile/settings` → Tasks 1–2 paths ✓

**Placeholder scan:** Task 1 Step 4 deliberately stubs 4 methods with `UnimplementedError`, all replaced in Task 2 Step 3 — the plan makes that explicit and testable (Task 2 Step 2 asserts the stubs throw first). Not a lingering placeholder.

**Type consistency:** `FirestoreRepository({required String uid, FirebaseFirestore? firestore})` used identically in Tasks 1 (tests), 3 (`main.dart`). `_dayKey` here matches `LocalRepository._dayKey` from PR 1 (same padding logic). `MyApp({required Repository repository, required AuthService auth})` — Task 3 defines it and updates the only construction site (`main()`); `test/widget_test.dart` doesn't construct `MyApp` (verified against PR 1).
