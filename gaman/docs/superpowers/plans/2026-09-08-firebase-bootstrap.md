# Firebase Bootstrap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Add `firebase_core` + `firebase_auth`, initialise Firebase guarded so a missing/invalid config is a no-op, and add an anonymous-first `AuthService` — the app behaves exactly as today until someone runs `flutterfire configure`.

**Architecture:** `main()` calls `Firebase.initializeApp()` inside try/catch; on success it becomes possible to sign in. `AuthService` wraps `firebase_auth`: `available` is false when Firebase never initialised, in which case every method is a safe no-op. `LocalRepository` stays the runtime repository — `FirestoreRepository` is a later PR.

**Tech Stack:** Flutter, `firebase_core`, `firebase_auth`, `provider`; `firebase_auth_mocks` + `firebase_core_platform_interface` for tests.

**Spec:** `docs/superpowers/specs/2026-09-07-cloud-sync-and-auth-design.md` (rollout PR 2). Branches off `feat/repository-layer` (PR #37).

## Global Constraints

- No `flutterfire configure` in this PR (no Firebase project exists yet). Do NOT add `lib/firebase_options.dart`, `google-services.json`, the `com.google.gms.google-services` Gradle plugin, or any `GoogleService-Info.plist`. `Firebase.initializeApp()` is called with **no `options:` argument** — a `// TODO(cloud-sync): switch to DefaultFirebaseOptions after flutterfire configure` comment marks the spot.
- **Zero behaviour change without a Firebase project:** in dev / CI / the current web deploy, `Firebase.initializeApp()` throws (no native config) → caught → `AuthService.available == false` → app runs exactly as on `feat/repository-layer`.
- `flutter analyze --no-fatal-infos` passes (0 errors/warnings). `flutter test` passes. `flutter build web --no-tree-shake-icons` succeeds.
- Dependency versions: let `flutter pub add` pick versions compatible with the pinned SDK (`>=3.2.3 <4.0.0`). If `flutter pub add firebase_core` fails to resolve, STOP and report — do not hand-edit `pubspec.lock`.
- Platforms in scope: **Android + web only** (per spec — iOS deferred). Do not touch `ios/` or `macos/` config.
- Commit style: imperative lower-case first word, no trailing period, blank line, `Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>`.

---

## File Structure

**Create**
- `lib/services/auth_service.dart` — `AuthService` (ChangeNotifier).
- `test/services/auth_service_test.dart`

**Modify**
- `pubspec.yaml` — add `firebase_core`, `firebase_auth`; dev-add `firebase_auth_mocks`.
- `lib/main.dart` — `WidgetsFlutterBinding.ensureInitialized()` (already present), guarded `Firebase.initializeApp()`, create + provide `AuthService`, call `ensureSignedIn()` after `runApp` via a post-frame callback or directly in `main`.

---

## Task 1: Add Firebase packages and guarded init

**Files:**
- Modify: `pubspec.yaml`, `lib/main.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `bool firebaseReady` — a top-level `late final bool` in `main.dart`... no. Produces: after `main()` runs, `Firebase.apps.isNotEmpty` is true iff init succeeded. Task 2's `AuthService` reads that.

- [ ] **Step 1: Add the packages**

Run:
```bash
flutter pub add firebase_core firebase_auth
flutter pub add dev:firebase_auth_mocks
```
Expected: resolves, `pubspec.yaml` gains the three entries, `pubspec.lock` updates. If resolution fails, STOP and report the version conflict.

- [ ] **Step 2: Guarded init in `lib/main.dart`**

At the top of `main()`, after `WidgetsFlutterBinding.ensureInitialized();` and before the notifications block, add:

```dart
  // TODO(cloud-sync): switch to DefaultFirebaseOptions after `flutterfire configure`.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase not configured; running local-only: $e');
  }
```

Add the import: `import 'package:firebase_core/firebase_core.dart';` and (for `debugPrint`) `import 'package:flutter/foundation.dart';` if not already imported — check; `main.dart` already imports `package:flutter/foundation.dart show kIsWeb`, so widen it to `import 'package:flutter/foundation.dart';` or add `debugPrint` to the `show` list.

- [ ] **Step 3: Verify no behaviour change**

Run:
```bash
flutter analyze --no-fatal-infos
flutter test
flutter build web --no-tree-shake-icons
```
Expected: analyze 0 errors/warnings; all existing tests pass (35); web build succeeds. `flutter run` (if available) still shows the app working normally — Firebase init logs a caught error and nothing else changes.

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/main.dart
git commit -m "add firebase_core/firebase_auth with guarded init

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 2: AuthService (anonymous-first)

**Files:**
- Create: `lib/services/auth_service.dart`, `test/services/auth_service_test.dart`
- Modify: `lib/main.dart`

**Interfaces:**
- Consumes: `firebase_auth`, `firebase_core` (`Firebase.apps`).
- Produces:
  - `enum AuthProviderKind { google, email }` — `apple` intentionally absent; add later.
  - `class AuthService extends ChangeNotifier`
    - `AuthService({FirebaseAuth? auth})` — `auth` defaults to `FirebaseAuth.instance` but ONLY when `Firebase.apps.isNotEmpty`; otherwise `available` is false and `_auth` is null. Tests pass a `MockFirebaseAuth`.
    - `bool get available` — true iff a `FirebaseAuth` instance is present.
    - `String? get uid` — `_auth?.currentUser?.uid`.
    - `bool get isAnonymous` — `_auth?.currentUser?.isAnonymous ?? true`.
    - `bool get isSignedIn` — `uid != null`.
    - `Stream<User?> get userChanges` — `_auth?.userChanges() ?? const Stream.empty()`.
    - `Future<void> ensureSignedIn()` — if `available` and `currentUser == null`, `await _auth!.signInAnonymously()`. Swallows `FirebaseAuthException`, logs via `debugPrint`. `notifyListeners()` after.
    - `Future<void> signOut()` — `available` → `await _auth!.signOut()`, then `notifyListeners()`. (After sign-out, the app is left signed-out; `ensureSignedIn` is not auto-called — that is the account-UI PR's job.)
  - Constructor subscribes to `userChanges` and calls `notifyListeners()` on each event; cancels in `dispose()`.

- [ ] **Step 1: Write the failing test**

Create `test/services/auth_service_test.dart`:

```dart
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaman/services/auth_service.dart';

void main() {
  test('unavailable when Firebase is not initialised', () {
    final svc = AuthService(auth: null); // explicit: no backend
    expect(svc.available, isFalse);
    expect(svc.isSignedIn, isFalse);
    expect(svc.isAnonymous, isTrue);
  });

  test('ensureSignedIn creates an anonymous user', () async {
    final mock = MockFirebaseAuth();
    final svc = AuthService(auth: mock);
    expect(svc.isSignedIn, isFalse);

    await svc.ensureSignedIn();

    expect(svc.isSignedIn, isTrue);
    expect(svc.isAnonymous, isTrue);
    expect(svc.uid, isNotNull);
  });

  test('ensureSignedIn is a no-op when already signed in', () async {
    final mock = MockFirebaseAuth(signedIn: true);
    final svc = AuthService(auth: mock);
    final uidBefore = svc.uid;
    await svc.ensureSignedIn();
    expect(svc.uid, uidBefore);
  });

  test('signOut clears the user', () async {
    final mock = MockFirebaseAuth(signedIn: true);
    final svc = AuthService(auth: mock);
    expect(svc.isSignedIn, isTrue);
    await svc.signOut();
    expect(svc.isSignedIn, isFalse);
  });

  test('notifies listeners on auth state change', () async {
    final mock = MockFirebaseAuth();
    final svc = AuthService(auth: mock);
    var n = 0;
    svc.addListener(() => n++);
    await svc.ensureSignedIn();
    await Future<void>.delayed(Duration.zero);
    expect(n, greaterThan(0));
  });
}
```

Note: `AuthService(auth: null)` must be allowed — make the parameter `FirebaseAuth? auth` and when the caller passes nothing, the production path resolves `Firebase.apps.isNotEmpty ? FirebaseAuth.instance : null`. In tests we pass `null` or a `MockFirebaseAuth` explicitly.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/auth_service_test.dart`
Expected: FAIL — `auth_service.dart` doesn't exist.

- [ ] **Step 3: Write `lib/services/auth_service.dart`**

```dart
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Providers a user can link/sign in with. `apple` is deliberately not here
/// yet — it needs a paid Apple Developer account (see the spec).
enum AuthProviderKind { google, email }

/// Anonymous-first auth. When Firebase was never configured (`available` is
/// false) every method is a safe no-op and the app runs local-only.
class AuthService extends ChangeNotifier {
  AuthService({FirebaseAuth? auth, bool resolveDefault = true})
      : _auth = auth ??
            (resolveDefault && Firebase.apps.isNotEmpty
                ? FirebaseAuth.instance
                : null) {
    final a = _auth;
    if (a != null) {
      _sub = a.userChanges().listen((_) => notifyListeners());
    }
  }

  final FirebaseAuth? _auth;
  StreamSubscription<User?>? _sub;

  bool get available => _auth != null;
  String? get uid => _auth?.currentUser?.uid;
  bool get isSignedIn => uid != null;
  bool get isAnonymous => _auth?.currentUser?.isAnonymous ?? true;

  Stream<User?> get userChanges =>
      _auth?.userChanges() ?? const Stream<User?>.empty();

  Future<void> ensureSignedIn() async {
    final a = _auth;
    if (a == null || a.currentUser != null) return;
    try {
      await a.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      debugPrint('Anonymous sign-in failed: ${e.code}');
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    await _auth?.signOut();
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
```

The test passes `auth: null` — with `resolveDefault` still true that yields `_auth == null` because the ternary's `auth ?? ...` sees a non-null... wait. `auth ?? (...)` — if `auth` is `null`, it evaluates the right side. So `AuthService(auth: null)` resolves the default. To get a guaranteed-unavailable instance in the test, pass `resolveDefault: false`. **Fix the test:** in the first test use `AuthService(auth: null, resolveDefault: false)`.

- [ ] **Step 4: Fix the first test**

In `test/services/auth_service_test.dart`, first test:
```dart
    final svc = AuthService(auth: null, resolveDefault: false);
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/services/auth_service_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 6: Wire into `lib/main.dart`**

Add `import 'services/auth_service.dart';`. In the `MultiProvider` `providers:` list, after `Provider<Repository>`:

```dart
        ChangeNotifierProvider(create: (_) => AuthService()..ensureSignedIn()),
```

(When Firebase isn't configured, `AuthService()` is unavailable and `ensureSignedIn()` returns immediately — no behaviour change.)

- [ ] **Step 7: Full verification**

```bash
flutter analyze --no-fatal-infos
flutter test
flutter build web --no-tree-shake-icons
```
All green (40 test now).

- [ ] **Step 8: Commit**

```bash
git add lib/services/auth_service.dart test/services/auth_service_test.dart lib/main.dart
git commit -m "add anonymous-first AuthService

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 3: Verify and open the PR

**Files:** none (verification only).

- [ ] **Step 1: Grep for accidental config**

```bash
git diff --stat feat/repository-layer..HEAD
ls lib/firebase_options.dart android/app/google-services.json 2>&1   # expect: not found
grep -rn "DefaultFirebaseOptions\|google-services" android/ lib/ 2>/dev/null   # expect: no matches
```

- [ ] **Step 2: Confirm the app still runs local-only**

`flutter run -d chrome` (if available): app loads, all tabs work, hot-restart persists — identical to `feat/repository-layer`. The console shows one "Firebase not configured; running local-only" line.

- [ ] **Step 3: Push and PR** (controller does this)

```bash
git push -u origin feat/firebase-bootstrap
gh pr create --base feat/repository-layer --head feat/firebase-bootstrap \
  --title "Firebase bootstrap (cloud-sync PR 2 of 6)" --body "<see below>"
```

PR body: explains this is inert scaffolding — `firebase_core` + `firebase_auth` added, `Firebase.initializeApp()` guarded, `AuthService` anonymous-first with an `available` flag that is false until someone runs `flutterfire configure` against a real project. No `firebase_options.dart` / `google-services.json` / Gradle plugin yet (those come with the project). App behaviour is byte-identical to PR 1 until config lands. Lists the 5 Firebase-console setup steps the maintainer must do to activate it.

## Self-Review

**Spec coverage** (spec rollout PR 2: "firebase_core + firebase_auth; flutterfire configure (Android + web); Firebase.initializeApp guarded so a failure falls back to LocalRepository; AuthService with anonymous-first sign-in. No data goes to the cloud yet."):
- firebase_core + firebase_auth → Task 1 ✓
- `flutterfire configure` → deferred with a Global Constraint + TODO marker (no project exists; documented) ✓ (partial-by-necessity, flagged)
- guarded init, local fallback → Task 1 Step 2 ✓
- AuthService anonymous-first → Task 2 ✓
- no cloud data → nothing writes to Firestore here ✓

**Placeholder scan:** the one `TODO(cloud-sync)` is a deliberate, documented marker for the `flutterfire configure` follow-up, not an incomplete step.

**Type consistency:** `AuthService({FirebaseAuth? auth, bool resolveDefault})` used consistently in Task 2 tests (Steps 1, 4) and `main.dart` wiring (Step 6, uses the zero-arg form). `AuthProviderKind` defined but not yet consumed — it's the seam for PR 5; acceptable to define the enum now so PR 5's `link(kind)` signature is stable.
