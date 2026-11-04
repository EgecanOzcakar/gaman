import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaman/data/firestore_repository.dart';
import 'package:gaman/data/models.dart';
import 'package:gaman/services/auth_service.dart';

/// Throws requires-recent-login on the first delete, like a stale session.
// ignore: must_be_immutable
class _StaleUser extends MockUser {
  _StaleUser() : super(uid: 'u1', isAnonymous: false, email: 'a@b.c');
  int deletes = 0;
  int reauths = 0;
  @override
  Future<void> delete() async {
    if (deletes++ == 0) {
      throw FirebaseAuthException(code: 'requires-recent-login');
    }
  }

  @override
  Future<UserCredential> reauthenticateWithCredential(AuthCredential? c) {
    reauths++;
    return super.reauthenticateWithCredential(c);
  }
}

void main() {
  late FakeFirebaseFirestore db;

  Future<void> seed(String uid) async {
    final repo = FirestoreRepository(uid: uid, firestore: db);
    await repo.upsertJournalEntry(JournalEntry(
        id: 'j', content: 'x', date: DateTime(2026), mood: '😊'));
    await repo.saveTasks(DateTime(2026), [
      TodoTask(id: 't', title: 't', isMainTask: true, createdAt: DateTime(2026)),
    ]);
    await repo.addActivity(ActivityEvent(type: ActivityType.focus, at: DateTime(2026)));
    await repo.saveSettings(const AppSettings());
    await repo.markMigrated();
  }

  Future<int> docCount(String uid) async {
    var n = 0;
    for (final c in ['journal', 'tasks', 'activity', 'profile']) {
      n += (await db.collection('users/$uid/$c').get()).docs.length;
    }
    return n;
  }

  setUp(() => db = FakeFirebaseFirestore());

  test('deletes all Firestore data under the uid, then the user', () async {
    await seed('u1');
    await seed('someone-else');
    final svc = AuthService(
        auth: MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'u1')));

    final r = await svc.deleteAccount(
        (uid) => FirestoreRepository(uid: uid, firestore: db).deleteAllUserData());

    expect(r, DeleteResult.deleted);
    expect(await docCount('u1'), 0);
    expect(await docCount('someone-else'), greaterThan(0));
    expect(svc.uid, isNot('u1')); // back to a fresh anonymous user
  });

  test('requires-recent-login → re-authenticates and retries', () async {
    await seed('u1');
    final user = _StaleUser();
    final svc = AuthService(
      auth: MockFirebaseAuth(signedIn: true, mockUser: user),
      credentialFor: (_) async =>
          GoogleAuthProvider.credential(idToken: 'id', accessToken: 'at'),
    );

    final r = await svc.deleteAccount(
        (uid) => FirestoreRepository(uid: uid, firestore: db).deleteAllUserData());

    expect(r, DeleteResult.deleted);
    expect(user.reauths, 1);
    expect(user.deletes, 2);
    expect(await docCount('u1'), 0);
  });

  test('re-auth cancelled → reports cancelled, keeps the user', () async {
    final user = _StaleUser();
    final svc = AuthService(
      auth: MockFirebaseAuth(signedIn: true, mockUser: user),
      credentialFor: (_) async => null,
    );
    final r = await svc.deleteAccount((_) async {});
    expect(r, DeleteResult.cancelled);
    expect(svc.uid, 'u1');
  });

  test('unavailable without Firebase', () async {
    final svc = AuthService(auth: null, resolveDefault: false);
    expect(await svc.deleteAccount((_) async {}), DeleteResult.unavailable);
  });
}
