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
