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
