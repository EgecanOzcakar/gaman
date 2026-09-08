# Account Linking Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development or superpowers:executing-plans. Steps use `- [ ]`.

**Goal:** A "Back up your progress" section in Settings: shows whether the account is anonymous or linked, links it to Google, signs out, handles the `credential-already-in-use` conflict, and states plainly what is stored where.

**Architecture:** `AuthService` gains a Google link/sign-in path and an `accountLabel`. The Settings section is `Consumer<AuthService>` — anonymous → "on this device only" + link button; linked → "backed up as <label>" + sign out. Email-link and true bidirectional merge are follow-ups (issues filed), not this PR.

**Tech Stack:** `firebase_auth`, `google_sign_in`; `firebase_auth_mocks` + a hand fake for widget tests.

**Spec:** `docs/superpowers/specs/2026-09-07-cloud-sync-and-auth-design.md` (rollout PR 5). Branches off `feat/local-to-firestore-migration` (PR #40).

## Global Constraints

- Still no Firebase project → `AuthService.available` is `false` → the Settings section renders a disabled "cloud backup unavailable" state and every action is a no-op. **No behaviour change without a project.**
- Google only in this PR. Email-link needs deep-link plumbing (Android intent filters + web URL handling) — file a follow-up issue, do not build it here.
- `credential-already-in-use` conflict handling in this PR: a two-button dialog — **"Use my account's data"** (sign out the anon user, sign in with the pending Google credential) and **"Not now"** (stay anonymous, abandon the link). Full merge-this-device-into-the-account is a follow-up issue.
- No `firebase_options.dart` / `DefaultFirebaseOptions`. No `google-services.json`. Do not add the `com.google.gms.google-services` Gradle plugin (comes with `flutterfire configure`).
- Copy: sentence case, no "click", active voice. "Back up your progress", "Sign in with Google", "Sign out", "Use my account's data", "Not now".
- `flutter analyze --no-fatal-infos` (0 errors/warnings), `flutter test`, `flutter build web --no-tree-shake-icons` pass.
- Commit style: imperative lower-case first word, no period, blank line, `Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>`.

---

## File Structure

**Create**
- `test/services/auth_service_link_test.dart`
- `test/screens/settings_account_test.dart`

**Modify**
- `pubspec.yaml` — add `google_sign_in`.
- `lib/services/auth_service.dart` — `accountLabel`, `linkGoogle()`, `signInGoogle()`, `useAccountAfterConflict()`, `enum LinkResult`.
- `lib/screens/settings_screen.dart` — new "Back up your progress" `_Section` (first in the list) + a "What's stored" note in the existing "Your data" section; a `_BackupSection` widget + `_ConflictDialog`.

---

## Task 1: AuthService Google link path

**Files:**
- Modify: `pubspec.yaml`, `lib/services/auth_service.dart`
- Test: `test/services/auth_service_link_test.dart`

**Interfaces:**
- Produces on `AuthService`:
  - `String? get accountLabel` — `_auth?.currentUser?.email ?? _auth?.currentUser?.displayName` when signed in and not anonymous; else `null`.
  - `enum LinkResult { linked, conflict, cancelled, unavailable, failed }`
  - `Future<LinkResult> linkGoogle()` — `unavailable` if `!available`; obtain a Google credential via `google_sign_in` (`GoogleSignIn().signIn()` → `null` → `cancelled`); `currentUser!.linkWithCredential(credential)`; on `FirebaseAuthException` with `code == 'credential-already-in-use'` stash the credential in `_pendingCredential` and return `conflict`; other exception → `failed`; success → `linked` + `notifyListeners()`.
  - `Future<LinkResult> signInGoogle()` — for a signed-out state: same credential dance, `signInWithCredential`. `unavailable`/`cancelled`/`failed`/`linked`.
  - `Future<void> useAccountAfterConflict()` — if `_pendingCredential != null`: `await _auth!.signOut(); await _auth!.signInWithCredential(_pendingCredential!); _pendingCredential = null; notifyListeners();`
  - `void cancelConflict()` — `_pendingCredential = null; notifyListeners();`

- [ ] **Step 1: Add the package**

```bash
flutter pub add google_sign_in
```
If resolution conflicts with the pinned SDK or `firebase_auth`, STOP and report.

- [ ] **Step 2: Write the failing test**

Create `test/services/auth_service_link_test.dart`:

```dart
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaman/services/auth_service.dart';

void main() {
  test('accountLabel is null for an anonymous user', () async {
    final svc = AuthService(auth: MockFirebaseAuth());
    await svc.ensureSignedIn();
    expect(svc.isAnonymous, isTrue);
    expect(svc.accountLabel, isNull);
  });

  test('accountLabel is the email for a linked user', () {
    final auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(isAnonymous: false, email: 'x@y.com', uid: 'u'),
    );
    final svc = AuthService(auth: auth);
    expect(svc.accountLabel, 'x@y.com');
  });

  test('link/sign-in are unavailable no-ops when Firebase is absent', () async {
    final svc = AuthService(auth: null, resolveDefault: false);
    expect(await svc.linkGoogle(), LinkResult.unavailable);
    expect(await svc.signInGoogle(), LinkResult.unavailable);
    svc.cancelConflict(); // must not throw
  });
}
```

- [ ] **Step 3: Run to verify it fails**

Run: `flutter test test/services/auth_service_link_test.dart` → FAIL (members missing).

- [ ] **Step 4: Extend `lib/services/auth_service.dart`**

Add `import 'package:google_sign_in/google_sign_in.dart';`. Add:

```dart
enum LinkResult { linked, conflict, cancelled, unavailable, failed }
```

Inside `AuthService`:

```dart
  AuthCredential? _pendingCredential;

  String? get accountLabel {
    final u = _auth?.currentUser;
    if (u == null || u.isAnonymous) return null;
    return u.email ?? u.displayName;
  }

  Future<AuthCredential?> _googleCredential() async {
    final account = await GoogleSignIn().signIn();
    if (account == null) return null;
    final gAuth = await account.authentication;
    return GoogleAuthProvider.credential(
      idToken: gAuth.idToken,
      accessToken: gAuth.accessToken,
    );
  }

  Future<LinkResult> linkGoogle() async {
    final a = _auth;
    if (a == null) return LinkResult.unavailable;
    final AuthCredential? cred;
    try {
      cred = await _googleCredential();
    } catch (e) {
      debugPrint('Google sign-in failed: $e');
      return LinkResult.failed;
    }
    if (cred == null) return LinkResult.cancelled;
    try {
      await a.currentUser!.linkWithCredential(cred);
      notifyListeners();
      return LinkResult.linked;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        _pendingCredential = e.credential ?? cred;
        return LinkResult.conflict;
      }
      debugPrint('link failed: ${e.code}');
      return LinkResult.failed;
    }
  }

  Future<LinkResult> signInGoogle() async {
    final a = _auth;
    if (a == null) return LinkResult.unavailable;
    final AuthCredential? cred;
    try {
      cred = await _googleCredential();
    } catch (e) {
      debugPrint('Google sign-in failed: $e');
      return LinkResult.failed;
    }
    if (cred == null) return LinkResult.cancelled;
    try {
      await a.signInWithCredential(cred);
      notifyListeners();
      return LinkResult.linked;
    } on FirebaseAuthException catch (e) {
      debugPrint('sign-in failed: ${e.code}');
      return LinkResult.failed;
    }
  }

  Future<void> useAccountAfterConflict() async {
    final a = _auth;
    final cred = _pendingCredential;
    if (a == null || cred == null) return;
    await a.signOut();
    await a.signInWithCredential(cred);
    _pendingCredential = null;
    notifyListeners();
  }

  void cancelConflict() {
    _pendingCredential = null;
    notifyListeners();
  }
```

- [ ] **Step 5: Run to verify it passes**

Run: `flutter test test/services/auth_service_link_test.dart` → PASS (3 tests). Full suite: `flutter test` still green.

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/services/auth_service.dart test/services/auth_service_link_test.dart
git commit -m "add Google link and sign-in to AuthService

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 2: Settings "Back up your progress" section

**Files:**
- Modify: `lib/screens/settings_screen.dart`
- Test: `test/screens/settings_account_test.dart`

**Interfaces:**
- Consumes: `AuthService` (Task 1).
- Produces: a `_BackupSection` `StatelessWidget` and a private `_showConflictDialog(BuildContext, AuthService)`; both live in `settings_screen.dart`.

- [ ] **Step 1: Write the failing widget test**

Create `test/screens/settings_account_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gaman/screens/settings_screen.dart';
import 'package:gaman/services/auth_service.dart';

class _FakeAuth extends AuthService {
  _FakeAuth({required this.avail, this.label})
      : super(auth: null, resolveDefault: false);
  final bool avail;
  final String? label;
  @override
  bool get available => avail;
  @override
  bool get isAnonymous => label == null;
  @override
  bool get isSignedIn => true;
  @override
  String? get accountLabel => label;
}

Widget _host(AuthService auth) => MaterialApp(
      home: ChangeNotifierProvider<AuthService>.value(
        value: auth,
        child: const Scaffold(body: BackupSectionForTest()),
      ),
    );

void main() {
  testWidgets('unavailable → shows the unavailable line, no buttons', (t) async {
    await t.pumpWidget(_host(_FakeAuth(avail: false)));
    expect(find.textContaining('unavailable'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsNothing);
  });

  testWidgets('anonymous → offers to back up', (t) async {
    await t.pumpWidget(_host(_FakeAuth(avail: true)));
    expect(find.textContaining('on this device only'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
  });

  testWidgets('linked → shows the label and a sign-out button', (t) async {
    await t.pumpWidget(_host(_FakeAuth(avail: true, label: 'me@x.com')));
    expect(find.textContaining('me@x.com'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });
}
```

Note: the test references `BackupSectionForTest` — expose the widget for testing. In `settings_screen.dart` add at the bottom: `@visibleForTesting typedef BackupSectionForTest = _BackupSection;` — actually a typedef of a private type is awkward; instead make the class `BackupSection` (public, underscore-free) OR add `@visibleForTesting class BackupSectionForTest extends StatelessWidget { const BackupSectionForTest({super.key}); @override Widget build(c) => const _BackupSection(); }`. Use the wrapper approach.

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/screens/settings_account_test.dart` → FAIL.

- [ ] **Step 3: Add the section to `lib/screens/settings_screen.dart`**

In `build()`, make the FIRST child of the `ListView` (before "Appearance"):

```dart
          const _BackupSection(),
          const SizedBox(height: Insets.lg),
```

Add these classes at the bottom of the file:

```dart
class _BackupSection extends StatelessWidget {
  const _BackupSection();

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Back up your progress',
      child: Consumer<AuthService>(
        builder: (context, auth, _) {
          if (!auth.available) {
            return const ListTile(
              leading: Icon(Icons.cloud_off_outlined),
              title: Text('Cloud backup is unavailable on this build'),
              subtitle: Text('Your progress is saved on this device.'),
            );
          }
          if (auth.isAnonymous) {
            return Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.cloud_upload_outlined),
                  title: Text('Your progress is on this device only'),
                  subtitle: Text(
                      'Sign in to keep it safe and use it on another phone.'),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      Insets.md, 0, Insets.md, Insets.md),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _link(context, auth),
                      icon: const Icon(Icons.login),
                      label: const Text('Sign in with Google'),
                    ),
                  ),
                ),
              ],
            );
          }
          return Column(
            children: [
              ListTile(
                leading: const Icon(Icons.cloud_done_outlined),
                title: Text('Backed up as ${auth.accountLabel ?? 'your account'}'),
                subtitle: const Text('Your progress syncs across your devices.'),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    Insets.md, 0, Insets.md, Insets.md),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: auth.signOut,
                    child: const Text('Sign out'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _link(BuildContext context, AuthService auth) async {
    final result = await auth.linkGoogle();
    if (!context.mounted) return;
    switch (result) {
      case LinkResult.linked:
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Your progress is backed up')));
      case LinkResult.conflict:
        await _showConflictDialog(context, auth);
      case LinkResult.failed:
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not sign in — try again')));
      case LinkResult.cancelled:
      case LinkResult.unavailable:
        break;
    }
  }
}

Future<void> _showConflictDialog(BuildContext context, AuthService auth) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('That account already has progress'),
      content: const Text(
        'This Google account was used on another device. You can switch to '
        "that account's progress now — this device's local progress stays "
        'on this device.',
      ),
      actions: [
        TextButton(
          onPressed: () {
            auth.cancelConflict();
            Navigator.pop(context);
          },
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () async {
            await auth.useAccountAfterConflict();
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text("Use my account's data"),
        ),
      ],
    ),
  );
}

@visibleForTesting
class BackupSectionForTest extends StatelessWidget {
  const BackupSectionForTest({super.key});
  @override
  Widget build(BuildContext context) => const _BackupSection();
}
```

Add imports to `settings_screen.dart` if missing: `import 'package:flutter/foundation.dart' show visibleForTesting;` and `import '../services/auth_service.dart';`.

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/screens/settings_account_test.dart` → PASS (3). Full suite green.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/settings_screen.dart test/screens/settings_account_test.dart
git commit -m "add a back-up-your-progress section to Settings

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 3: Privacy note; wire AuthService into the Settings screen's provider scope; verify; PR (controller does verify + PR)

**Files:**
- Modify: `lib/screens/settings_screen.dart`

**Interfaces:** none new.

- [ ] **Step 1: Add a "What's stored" note to the existing "Your data" `_Section`**

In the "Your data" section's `Column`, before the export button, add:

```dart
                  const Text(
                    "What's stored: your journal, tasks, activity history and "
                    'app settings. When you sign in, a copy is kept in your '
                    "Google-linked account so it survives reinstalling the app. "
                    "It is not shared with anyone.",
                    style: TextStyle(height: 1.4),
                  ),
                  const SizedBox(height: Insets.md),
```

(Match the surrounding style — if the section uses `Theme.of(context).textTheme.bodyMedium`, use that instead of an inline `TextStyle`.)

- [ ] **Step 2: Confirm `AuthService` is in scope**

`AuthService` is provided at the app root (PR 3 wired `ChangeNotifierProvider<AuthService>.value` into `MyApp`'s `MultiProvider`). The Settings screen is a descendant, so `Consumer<AuthService>` resolves. No change needed — but verify by running the app: Settings shows the new section without a provider error.

- [ ] **Step 3: Verify**

```bash
flutter analyze --no-fatal-infos
flutter test
flutter build web --no-tree-shake-icons
```
All green. Without a project: `AuthService.available` is false → the section shows "Cloud backup is unavailable on this build" → no behaviour change to anything else.

- [ ] **Step 4: Commit**

```bash
git add lib/screens/settings_screen.dart
git commit -m "state plainly what is stored and where

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

- [ ] **Step 5 (controller): file follow-up issues + PR**

Issues to file:
- "Email-link sign-in" — needs deep-link plumbing (Android intent filters, web URL handling, `app_links`); the `AuthProviderKind.email` case is a stub.
- "Bidirectional account merge" — on `credential-already-in-use`, offer to merge this device's records into the account (upload records absent remotely), not only "use account data".

PR against `feat/local-to-firestore-migration`. Body: Settings "Back up your progress" (Google link / sign-out / conflict chooser) + a plain-language storage note; inert (`available == false`) without a project; email-link and true merge are filed follow-ups.

## Self-Review

**Spec coverage** (rollout PR 5: "Settings 'Back up your progress': Google + email-link, sign-out, the `credential-already-in-use` merge chooser, and the plain-language privacy note."):
- Settings "Back up your progress" → Task 2 ✓
- Google → Tasks 1–2 ✓
- email-link → **deferred** to a filed follow-up issue (needs deep links; disproportionate to build inert) — flagged
- sign-out → Task 2 (linked state) ✓
- `credential-already-in-use` chooser → Task 1 (`conflict` result, `useAccountAfterConflict`, `cancelConflict`) + Task 2 (`_showConflictDialog`) ✓ (v1 = "use account" / "not now"; full merge is a filed follow-up — flagged)
- plain-language privacy note → Task 3 ✓

**Placeholder scan:** `AuthProviderKind.email` remains unhandled by the new methods — it's the seam for the filed email-link follow-up, documented, not a silent gap.

**Type consistency:** `LinkResult` enum defined in Task 1, consumed in Task 2's `_link` switch (all 5 cases). `AuthService.linkGoogle()` / `signInGoogle()` / `useAccountAfterConflict()` / `cancelConflict()` / `accountLabel` defined Task 1, used Task 2. `BackupSectionForTest` wrapper defined Task 2, used by Task 2's test.
