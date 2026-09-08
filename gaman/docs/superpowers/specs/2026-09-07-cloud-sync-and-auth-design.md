# Cloud sync & authentication — design

Status: draft for review
Date: 2026-09-07
Tracking issue: #29. Builds on #16 (activity log), #24 (export).

## Problem

Everything the app stores — journal entries, daily task lists, the activity
log, preferences — lives in `SharedPreferences` on one device. Deleting the
app or switching phones loses it all. Users of a long-running practice app
expect their history to survive both.

## Goal

- Progress survives app deletion and reinstall.
- Progress syncs across a user's own devices and platforms (iOS, Android, web).
- The app stays **fully usable offline**; sync happens opportunistically.
- Signing up is not a wall in front of the first session.

## Non-goals

- Sharing or collaboration between users.
- Server-side computation, analytics, or an admin surface.
- Provider portability — Firebase lock-in is accepted.
- Cross-device push notifications.

## Decisions (settled)

| Question | Decision |
|---|---|
| Backend | **Firebase** — Auth + Cloud Firestore |
| Auth model | **Anonymous-first**; link to **Google** or **email-link** (passwordless) |
| Platforms | **Android + web now.** iOS deferred — auth layer built so Sign in with Apple slots in without rework |
| Sign in with Apple | Not in this work (no paid Apple Developer account yet) |
| Sync granularity | **Per-record**, behind a repository layer |
| Privacy | Short plain-language note in Settings — what is stored and where. Not a legal document |
| Manual export (#24) | Kept as the provider-independent backstop |
| Timing | Implement after the current PR stack lands on `main` (Phase 0 / #35) |

App context: personal / small-circle tool, not an App Store launch. That
lowers the bar on store listings and Apple-review pressure but not on the
sync itself — the user's own phone + tablet + a few friends still need it.

Firestore is chosen over Supabase/PocketBase for one reason: its offline
persistence is transparent and battle-tested. The SDK writes to a local cache
synchronously and reconciles with the server when a connection is available.
For an app used on planes and in meditation sessions, that removes the single
hardest part of "offline-first" — we do not build a sync engine.

## Architecture

### Repository layer (new)

Screens and providers never touch storage directly after this change.

```
lib/data/
  models.dart              plain data classes: JournalEntry, TodoTask, ActivityEvent, AppSettings
                           (moved out of the screen files that define them today)
  repository.dart          abstract Repository: streams to read, methods to write, per domain
  firestore_repository.dart Firestore-backed implementation (runtime default once Firebase is up)
  local_repository.dart    SharedPreferences-backed implementation
```

`Repository` surface (illustrative):

```dart
abstract class Repository {
  Stream<List<JournalEntry>> journal();
  Future<void> upsertJournalEntry(JournalEntry e);
  Future<void> deleteJournalEntry(String id);

  Stream<List<TodoTask>> tasksForDay(DateTime day);
  Future<void> setTasksForDay(DateTime day, List<TodoTask> tasks);

  Stream<List<ActivityEvent>> activity();          // append-only
  Future<void> logActivity(ActivityEvent e);

  Stream<AppSettings> settings();
  Future<void> saveSettings(AppSettings s);
}
```

- `firestore_repository` works offline too (cache), so it is the runtime
  implementation whenever `Firebase.initializeApp` succeeds.
- `local_repository` is kept for two jobs: the **migration source** (reads the
  old `SharedPreferences` keys once) and the **test double** (all existing
  provider/widget tests keep running with no network).
- If Firebase init fails (missing config on a dev build, hard offline on a
  brand-new install with no cached auth), the app falls back to
  `local_repository` and Settings shows "Cloud backup unavailable". It stays
  fully functional; it promotes to Firestore once auth succeeds.

### Providers become thin

`ActivityLog`, `SettingsProvider`, `FeaturePrefs`, `ThemeProvider`, and the
`NotificationProvider` persisted fields all route through `Repository`. Their
public getters are unchanged, so screens are barely touched. Each provider
subscribes to its repository stream and calls `notifyListeners()` on new
snapshots.

### Auth

`AuthService` (thin wrapper over `firebase_auth`):

- On launch: if `FirebaseAuth.currentUser == null`, call `signInAnonymously()`.
  That uid owns all data from the first session — backup is silent and
  immediate, before the user ever "signs up".
- Settings shows account state:
  - anonymous → "Your progress is on this device only. [Back up to an account]"
  - linked → "Backed up as <email/name>. [Sign out]"
- **Link** (`currentUser.linkWithCredential`): keeps the same uid, so all data
  stays put and becomes recoverable elsewhere. Providers offered: Google
  (`google_sign_in`) and email-link (Firebase passwordless — user enters an
  email, taps a link, no password to manage).
- **Sign in on a second device**: same uid → Firestore streams the existing
  data down into the local cache.
- **Sign in with Apple** is not built now. `AuthService` exposes
  `link(provider)` / `signIn(provider)` over an enum so an `apple` case can be
  added later without touching call sites or the UI structure.

## Data model (Firestore)

```
users/{uid}
  profile/settings        { themeMode, meditationMinutes, breathSeconds, focusMinutes,
                            longBreakEvery, reminderEnabled, reminderHour, reminderMinute,
                            disabledFeatures: string[], migrated: bool, updatedAt }
  journal/{entryId}       { content, date, mood, type, sections: map, updatedAt }
  tasks/{yyyy-MM-dd}      { tasks: [{id, title, isCompleted, isMainTask, createdAt}], updatedAt }
  activity/{eventId}      { type, at, durationSeconds, meta: map }
```

- **tasks** are keyed by date — one small document per day, always edited
  together on one screen, so an array inside the day document is fine.
- **activity** is append-only and never edited, so it cannot conflict. Each
  event carries a client-generated id (`<millisSinceEpoch>-<random>`).
- **journal** deletes are real `delete()` calls. Risk: a device offline for
  longer than the cache retains tombstones could resurrect an entry. Accepted
  for v1; revisit with soft-delete (`deleted: true`) if it happens.
- `updatedAt` uses `FieldValue.serverTimestamp()`. Conflict resolution is
  Firestore's default last-write-wins **per document**. With per-record
  granularity, a real conflict needs the *same* entry edited on two devices
  while both are offline — rare for a personal journal, and the loss is one
  edit, not the dataset.

## Migration (one-time)

On startup, after auth resolves:

1. Read `users/{uid}/profile/settings.migrated`. If true, skip.
2. If `SharedPreferences` holds legacy keys (`journal_entries`, `todo_tasks_*`,
   `activity_log`, `theme_mode`, `settings_*`, `disabled_features`, …):
   parse them all.
3. Batch-write every record to Firestore under the uid.
4. Set `migrated: true`.
5. Clear the legacy `SharedPreferences` keys so there is a single source of
   truth. (The manual JSON export from #24 stays as a separate escape hatch.)

Idempotent: re-running finds `migrated: true` and does nothing.

## Account-linking edge case

Device B has been used anonymously (has local data under an anon uid), then
the user signs in there with an account that already exists (has its own uid
and data). `linkWithCredential` throws `credential-already-in-use`.

Handling (v1): show a chooser —

- **Merge** (default): upload B's local records whose ids don't exist under
  the account uid, then `signInWithCredential` to the account.
- **Keep account data**: discard B's local anon data, sign in.

## Data flow

- **Read**: repository exposes `Stream`s backed by Firestore snapshot
  listeners. Offline → served from cache immediately. Providers hold the latest
  snapshot.
- **Write**: `repository.upsertX()` → `doc(id).set(...)`. Firestore updates the
  cache synchronously (UI echoes at once) and queues the network write.
- **Sync status** (optional, later): `SnapshotMetadata.hasPendingWrites` and
  `isFromCache` drive a small "syncing… / offline" line in Settings.

## Error handling

| Failure | Behaviour |
|---|---|
| `Firebase.initializeApp` fails | Log, run on `local_repository`, Settings shows "Cloud backup unavailable", retry init on next launch |
| Anonymous sign-in fails (offline first launch) | Run on `local_repository`; retry auth with backoff; migrate once it succeeds |
| Write fails / stays pending | Firestore SDK retries automatically; surface only if pending a long time |
| `credential-already-in-use` on link | Merge / keep-account chooser (above) |
| Permission denied (rules) | "Backup paused" in Settings; keep writing to cache |

## Security rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{db}/documents {
    match /users/{uid}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

Add shape checks (field types, a cap on `content` length) in a later pass to
limit damage from a compromised client. App Check attestation: deferred.

## Cost

Firebase Spark (free) tier: 1 GiB stored, 50k reads / 20k writes / 20k deletes
per day, 10 GiB/month egress. One active user generates a few hundred
reads/writes a day; thousands of users fit inside the free tier. Blaze
(pay-as-you-go) is only needed at real scale and costs cents there.

Document-size note: an activity event is ~50 bytes; 20k events ≈ 1 MB. Because
activity is per-record, not one blob, there is no per-document ceiling to hit.

## Platform configuration

`flutterfire configure` generates `lib/firebase_options.dart` and most native
wiring. Manual pieces:

- **Android**: `google-services.json`; SHA-1 / SHA-256 signing fingerprints
  registered for Google sign-in; min SDK 23.
- **Web**: config in `firebase_options.dart`; add the GitHub Pages origin
  (`egecanozcakar.github.io`) to Firebase Auth authorised domains. Deploy
  target confirmed from `.github/workflows/deploy.yml` (gh-pages).
- **iOS**: deferred. When it happens: `GoogleService-Info.plist`, min iOS 13,
  add the Apple provider and the "Sign in with Apple" capability (Apple
  requires it once Google sign-in ships on iOS).

## Testing

- `local_repository` + a fake `AuthService` → all current provider/widget
  tests keep running offline.
- `fake_cloud_firestore` + `firebase_auth_mocks` → repository contract tests:
  write-then-read, stream emission on change, delete propagation, migration
  idempotency, the link merge path.
- Manual matrix: two-device sync; reinstall-and-restore; anonymous → linked;
  offline edit then reconnect; `credential-already-in-use` merge.

## Rollout

Branch off `main` **after** Phase 0 (#35) lands — this rewrites the data layer
touched by everything merged so far.

Sequenced PRs:

1. **Repository layer, no backend.** `lib/data/`: `models.dart` (move
   `JournalEntry` / `TodoTask` / `ActivityEvent` out of the screen files),
   `Repository` interface, `LocalRepository` (SharedPreferences, wrapping
   today's logic). Refactor `ActivityLog` / `SettingsProvider` / `FeaturePrefs`
   / `ThemeProvider` / notification fields onto it. Still offline-only, no
   user-visible change — the biggest diff, lowest risk, ships on its own.
2. **Firebase bootstrap.** `firebase_core` + `firebase_auth`;
   `flutterfire configure` (Android + web); `Firebase.initializeApp` guarded
   so a failure falls back to `LocalRepository`; `AuthService` with
   anonymous-first sign-in. No data goes to the cloud yet.
3. **`FirestoreRepository`.** Implement against the data model; make it the
   runtime repository when Firebase is up; commit `firestore.rules` and the
   deploy step for them.
4. **Migration.** One-time copy of legacy SharedPreferences data to Firestore
   under the uid; set `migrated`; clear legacy keys.
5. **Account UI.** Settings "Back up your progress": Google + email-link,
   sign-out, the `credential-already-in-use` merge chooser, and the
   plain-language privacy note.
6. **Sync-status indicator** (optional): "syncing / offline / backed up" line
   from `SnapshotMetadata`.

## Resolved (was: open questions)

1. **Apple Developer account** — none yet. Android + web only. `AuthService`
   is written so `apple` is an added enum case later, not a refactor.
2. **Email method** — email-link (passwordless).
3. **#24 export** — kept.
