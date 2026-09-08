# Sync Status Indicator Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development or superpowers:executing-plans. Steps use `- [ ]`.

**Goal:** A small line in the Settings "Back up your progress" section that says whether the account is synced, syncing, or offline.

**Architecture:** `Repository` gains `Stream<SyncStatus> watchSyncStatus()`. `LocalRepository` emits a constant `SyncStatus.localOnly`. `FirestoreRepository` derives it from the `SnapshotMetadata` of a listener on the always-present `profile/settings` doc (`includeMetadataChanges: true`), via a pure `statusFromMetadata()` helper. The Settings section shows the line only when the account is linked.

**Tech Stack:** `cloud_firestore` (`SnapshotMetadata`), `fake_cloud_firestore` (dev).

**Spec:** `docs/superpowers/specs/2026-09-07-cloud-sync-and-auth-design.md` (rollout PR 6, "optional"). Branches off `feat/account-linking` (PR #43).

## Global Constraints

- No Firebase project → `LocalRepository` is the runtime repo → `watchSyncStatus()` emits `localOnly` → the Settings section is already in its "unavailable" state and the line is not shown → **no behaviour change**.
- No `firebase_options.dart` / `DefaultFirebaseOptions` / `google-services.json` / Gradle plugin.
- `flutter analyze --no-fatal-infos` (0 errors/warnings), `flutter test`, `flutter build web --no-tree-shake-icons` pass.
- Copy: sentence case, active voice. Exactly: "Synced", "Syncing…", "Offline — changes are saved on this device".
- Commit style: imperative lower-case first word, no period, blank line, `Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>`.

---

## File Structure

**Create**
- `lib/data/sync_status.dart` — `enum SyncStatus`, `SyncStatus statusFromMetadata(SnapshotMetadata)`.
- `test/data/sync_status_test.dart`

**Modify**
- `lib/data/repository.dart` — add `Stream<SyncStatus> watchSyncStatus();`
- `lib/data/local_repository.dart` — implement it (`Stream.value(SyncStatus.localOnly)`).
- `lib/data/firestore_repository.dart` — implement it from `_settingsDoc.snapshots(includeMetadataChanges: true)`.
- `test/data/firestore_repository_test.dart` — one test for the Firestore path.
- `lib/screens/settings_screen.dart` — show the line in `_BackupSection`'s linked state.

---

## Task 1: SyncStatus type + Repository method

**Files:**
- Create: `lib/data/sync_status.dart`, `test/data/sync_status_test.dart`
- Modify: `lib/data/repository.dart`, `lib/data/local_repository.dart`, `lib/data/firestore_repository.dart`, `test/data/firestore_repository_test.dart`

**Interfaces:**
- Produces:
  - `enum SyncStatus { localOnly, synced, syncing, offline }`
  - `SyncStatus statusFromMetadata(SnapshotMetadata m)` — `m.hasPendingWrites` → `syncing`; else `m.isFromCache` → `offline`; else `synced`.
  - `Repository.watchSyncStatus() -> Stream<SyncStatus>`
  - `LocalRepository.watchSyncStatus()` → `Stream.value(SyncStatus.localOnly)`.
  - `FirestoreRepository.watchSyncStatus()` → `_settingsDoc.snapshots(includeMetadataChanges: true).map((s) => statusFromMetadata(s.metadata)).asBroadcastStream()`.

- [ ] **Step 1: Write the failing test**

Create `test/data/sync_status_test.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaman/data/sync_status.dart';

class _Meta implements SnapshotMetadata {
  _Meta({required this.hasPendingWrites, required this.isFromCache});
  @override
  final bool hasPendingWrites;
  @override
  final bool isFromCache;
}

void main() {
  test('pending writes → syncing', () {
    expect(
      statusFromMetadata(_Meta(hasPendingWrites: true, isFromCache: true)),
      SyncStatus.syncing,
    );
  });

  test('from cache, no pending writes → offline', () {
    expect(
      statusFromMetadata(_Meta(hasPendingWrites: false, isFromCache: true)),
      SyncStatus.offline,
    );
  });

  test('server snapshot → synced', () {
    expect(
      statusFromMetadata(_Meta(hasPendingWrites: false, isFromCache: false)),
      SyncStatus.synced,
    );
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/data/sync_status_test.dart` → FAIL (file missing). If `SnapshotMetadata` can't be `implements`ed (it's a concrete class), switch `_Meta` to a small record/param object and make `statusFromMetadata` take `({bool hasPendingWrites, bool isFromCache})` instead — adjust the call site in `firestore_repository.dart` to `statusFromMetadata((hasPendingWrites: s.metadata.hasPendingWrites, isFromCache: s.metadata.isFromCache))`.

- [ ] **Step 3: Write `lib/data/sync_status.dart`**

```dart
/// Whether the signed-in account's data is up to date with the server.
enum SyncStatus {
  /// No cloud backup — data lives only on this device.
  localOnly,

  /// Everything is on the server.
  synced,

  /// Local changes are on their way to the server.
  syncing,

  /// No connection — changes are queued locally.
  offline,
}

/// Maps Firestore snapshot metadata to a [SyncStatus].
SyncStatus statusFromMetadata(
    ({bool hasPendingWrites, bool isFromCache}) m) {
  if (m.hasPendingWrites) return SyncStatus.syncing;
  if (m.isFromCache) return SyncStatus.offline;
  return SyncStatus.synced;
}
```

- [ ] **Step 4: Add to `lib/data/repository.dart`**

```dart
import 'sync_status.dart';
```
and in the abstract class:
```dart
  /// Whether writes have reached the server. `localOnly` when there is no
  /// cloud backend.
  Stream<SyncStatus> watchSyncStatus();
```

- [ ] **Step 5: Implement in `lib/data/local_repository.dart`**

```dart
import 'sync_status.dart';
```
```dart
  @override
  Stream<SyncStatus> watchSyncStatus() =>
      Stream<SyncStatus>.value(SyncStatus.localOnly);
```

- [ ] **Step 6: Implement in `lib/data/firestore_repository.dart`**

```dart
import 'sync_status.dart';
```
```dart
  @override
  Stream<SyncStatus> watchSyncStatus() => _settingsDoc
      .snapshots(includeMetadataChanges: true)
      .map((s) => statusFromMetadata((
            hasPendingWrites: s.metadata.hasPendingWrites,
            isFromCache: s.metadata.isFromCache,
          )))
      .asBroadcastStream();
```

- [ ] **Step 7: Add a FirestoreRepository test**

Append to `test/data/firestore_repository_test.dart`:

```dart
  test('watchSyncStatus emits synced for a fake (server) snapshot', () async {
    await repo.saveSettings(const AppSettings());
    expect(await repo.watchSyncStatus().first, SyncStatus.synced);
  });
```

Add `import 'package:gaman/data/sync_status.dart';` to that test file.

- [ ] **Step 8: Run to verify it passes**

Run: `flutter test` → all green (66 → ~70).

- [ ] **Step 9: Commit**

```bash
git add lib/data/sync_status.dart lib/data/repository.dart lib/data/local_repository.dart lib/data/firestore_repository.dart test/data/sync_status_test.dart test/data/firestore_repository_test.dart
git commit -m "add watchSyncStatus to the repository

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 2: Show the status line in Settings

**Files:**
- Modify: `lib/screens/settings_screen.dart`
- Test: `test/screens/settings_account_test.dart`

**Interfaces:**
- Consumes: `Repository.watchSyncStatus()`, `SyncStatus`.
- Produces: nothing new — an extra `subtitle`/line in `_BackupSection`'s linked branch.

- [ ] **Step 1: Add a failing test**

Append to `test/screens/settings_account_test.dart` — the existing `_FakeAuth` fake doesn't cover the repo; add a `Provider<Repository>` to `_host` returning a fake that emits a fixed `SyncStatus`, and assert the linked state shows "Synced" / "Syncing…" / "Offline — changes are saved on this device". Use a minimal fake:

```dart
class _FakeRepo implements Repository {
  _FakeRepo(this._status);
  final SyncStatus _status;
  @override
  Stream<SyncStatus> watchSyncStatus() => Stream.value(_status);
  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}
```

Update `_host` to wrap the child in `MultiProvider` with both the `AuthService` and `Provider<Repository>.value`. Add one test:

```dart
  testWidgets('linked + syncing → shows "Syncing…"', (t) async {
    await t.pumpWidget(_host(
      _FakeAuth(avail: true, label: 'me@x.com'),
      repo: _FakeRepo(SyncStatus.syncing),
    ));
    await t.pump();
    expect(find.text('Syncing…'), findsOneWidget);
  });
```

(Also update the three existing tests' `_host` calls to pass `repo: _FakeRepo(SyncStatus.synced)`.)

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/screens/settings_account_test.dart` → the new test FAILs.

- [ ] **Step 3: Edit `_BackupSection`'s linked branch in `lib/screens/settings_screen.dart`**

In the linked-state `Column`, change the `ListTile`'s `subtitle` to a `StreamBuilder<SyncStatus>`:

```dart
              ListTile(
                leading: const Icon(Icons.cloud_done_outlined),
                title: Text('Backed up as ${auth.accountLabel ?? 'your account'}'),
                subtitle: StreamBuilder<SyncStatus>(
                  stream: context.read<Repository>().watchSyncStatus(),
                  builder: (context, snap) => Text(switch (snap.data) {
                    SyncStatus.syncing => 'Syncing…',
                    SyncStatus.offline =>
                      'Offline — changes are saved on this device',
                    _ => 'Synced',
                  }),
                ),
              ),
```

Add imports if missing: `import '../data/repository.dart';`, `import '../data/sync_status.dart';`.

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/screens/settings_account_test.dart` → all PASS. Full suite green.

- [ ] **Step 5: Verify**

```bash
flutter analyze --no-fatal-infos
flutter test
flutter build web --no-tree-shake-icons
```
All green. Without a project the linked branch is never reached (`isAnonymous` / `!available`), so the `StreamBuilder` never runs.

- [ ] **Step 6: Commit**

```bash
git add lib/screens/settings_screen.dart test/screens/settings_account_test.dart
git commit -m "show sync status in the backup section

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 3: Verify and open the PR (controller)

- [ ] `flutter analyze --no-fatal-infos` (0/0), `flutter test` (all green), `flutter build web` succeeds.
- [ ] No `firebase_options.dart` / `DefaultFirebaseOptions` snuck in.
- [ ] `git push -u origin feat/sync-indicator`; PR against `feat/account-linking`. Body: `watchSyncStatus()` on the repository (`localOnly` for local, `SnapshotMetadata`-derived for Firestore), shown as a one-line status under "Backed up as …". Completes the 6-PR cloud-sync rollout. Still inert without a project.

## Self-Review

**Spec coverage** (rollout PR 6: "Sync-status indicator (optional): 'syncing / offline / backed up' line from `SnapshotMetadata`."):
- from `SnapshotMetadata` → `statusFromMetadata` maps `hasPendingWrites` / `isFromCache` ✓
- syncing / offline / backed-up line → Task 2 `StreamBuilder` in the linked state ("Synced" = backed up) ✓
- Settings line → Task 2 ✓

**Placeholder scan:** none.

**Type consistency:** `SyncStatus` enum + `statusFromMetadata(({bool hasPendingWrites, bool isFromCache}))` defined Task 1, used in `firestore_repository.dart` (Task 1 Step 6) and the tests. `Repository.watchSyncStatus()` added Task 1 Step 4, implemented in both repos (Steps 5–6), consumed in Task 2 Step 3. The Task 1 Step 2 fallback (record param instead of `implements SnapshotMetadata`) is already baked into Step 3's signature, so no divergence.
