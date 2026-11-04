import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../config.dart';

/// Providers a user can link/sign in with. Apple is behind
/// [AppConfig.appleSignIn] until the Apple Developer setup is done.
enum AuthProviderKind { google, apple }

enum LinkResult { linked, conflict, cancelled, unavailable, failed }

enum DeleteResult { deleted, cancelled, unavailable, failed }

/// Anonymous-first auth. When Firebase was never configured (`available` is
/// false) every method is a safe no-op and the app runs local-only.
class AuthService extends ChangeNotifier {
  AuthService({
    FirebaseAuth? auth,
    bool resolveDefault = true,
    Future<AuthCredential?> Function(AuthProviderKind kind)? credentialFor,
  })  : _credentialOverride = credentialFor,
        _auth = auth ??
            (resolveDefault && Firebase.apps.isNotEmpty
                ? FirebaseAuth.instance
                : null) {
    final a = _auth;
    if (a != null) {
      _sub = a.userChanges().listen((_) => notifyListeners());
    }
  }

  final FirebaseAuth? _auth;
  final Future<AuthCredential?> Function(AuthProviderKind)? _credentialOverride;
  StreamSubscription<User?>? _sub;

  /// Whether to offer Sign in with Apple on this device.
  static bool get appleSignInEnabled =>
      AppConfig.appleSignIn &&
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

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

  Future<AuthCredential?> _appleCredential() async {
    // Firebase checks the SHA-256 of the raw nonce Apple signs into the token.
    final rnd = Random.secure();
    final rawNonce =
        base64Url.encode(List.generate(32, (_) => rnd.nextInt(256)));
    try {
      final apple = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email],
        nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
      );
      return OAuthProvider('apple.com').credential(
        idToken: apple.identityToken,
        rawNonce: rawNonce,
        accessToken: apple.authorizationCode,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      rethrow;
    }
  }

  Future<AuthCredential?> _credential(AuthProviderKind kind) =>
      _credentialOverride?.call(kind) ??
      switch (kind) {
        AuthProviderKind.google => _googleCredential(),
        AuthProviderKind.apple => _appleCredential(),
      };

  Future<LinkResult> linkGoogle() => link(AuthProviderKind.google);
  Future<LinkResult> signInGoogle() => signIn(AuthProviderKind.google);

  Future<LinkResult> link(AuthProviderKind kind) async {
    final a = _auth;
    if (a == null) return LinkResult.unavailable;
    final AuthCredential? cred;
    try {
      cred = await _credential(kind);
    } catch (e) {
      debugPrint('${kind.name} sign-in failed: $e');
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

  Future<LinkResult> signIn(AuthProviderKind kind) async {
    final a = _auth;
    if (a == null) return LinkResult.unavailable;
    final AuthCredential? cred;
    try {
      cred = await _credential(kind);
    } catch (e) {
      debugPrint('${kind.name} sign-in failed: $e');
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

  /// Signs out, then straight back in as a fresh anonymous user
  /// (anonymous-first: there is always a uid to store data under).
  Future<void> signOut() async {
    final a = _auth;
    if (a == null) return;
    await a.signOut();
    try {
      await GoogleSignIn().signOut(); // so the next sign-in offers the picker
    } catch (_) {}
    notifyListeners();
    await ensureSignedIn();
  }

  /// Deletes the user's cloud data via [deleteData], then the auth user.
  /// If Firebase wants a recent login, re-authenticates with the provider the
  /// account is linked to and retries. Ends signed in as a new anonymous user.
  Future<DeleteResult> deleteAccount(
      Future<void> Function(String uid) deleteData) async {
    final a = _auth;
    final user = a?.currentUser;
    if (a == null || user == null) return DeleteResult.unavailable;
    try {
      await deleteData(user.uid);
      try {
        await user.delete();
      } on FirebaseAuthException catch (e) {
        if (e.code != 'requires-recent-login') rethrow;
        final ids = user.providerData.map((p) => p.providerId);
        final kind = ids.contains('apple.com')
            ? AuthProviderKind.apple
            : AuthProviderKind.google;
        final cred = await _credential(kind);
        if (cred == null) return DeleteResult.cancelled;
        await user.reauthenticateWithCredential(cred);
        await user.delete();
      }
    } catch (e) {
      debugPrint('Account deletion failed: $e');
      return DeleteResult.failed;
    }
    await signOut();
    return DeleteResult.deleted;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
