import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaman/services/auth_service.dart';

void main() {
  test('unavailable when Firebase is not initialised', () {
    final svc = AuthService(auth: null, resolveDefault: false);
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

  test('signOut drops the account and starts a fresh anonymous session',
      () async {
    final mock = MockFirebaseAuth(signedIn: true);
    final svc = AuthService(auth: mock);
    final seen = <String?>[];
    final sub = mock.authStateChanges().listen((u) => seen.add(u?.uid));
    await svc.signOut();
    await Future<void>.delayed(Duration.zero);
    expect(seen, contains(null)); // the old session really ended
    expect(svc.isSignedIn, isTrue); // and a new one started
    await sub.cancel();
  });

  test('signOut and dispose are safe no-ops when unavailable', () async {
    final svc = AuthService(auth: null, resolveDefault: false);
    await svc.signOut();      // must not throw
    svc.dispose();            // must not throw
    expect(svc.available, isFalse);
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
