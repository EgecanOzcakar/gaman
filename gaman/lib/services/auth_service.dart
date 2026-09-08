import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Providers a user can link/sign in with. `apple` is deliberately not here
/// yet — it needs a paid Apple Developer account (see the spec).
enum AuthProviderKind { google, email }

enum LinkResult { linked, conflict, cancelled, unavailable, failed }

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
    } catch (e) {
      debugPrint('Anonymous sign-in failed: $e');
    }
    notifyListeners();
  }

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
    final user = a.currentUser;
    if (user == null) return LinkResult.failed;
    try {
      await user.linkWithCredential(cred);
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
