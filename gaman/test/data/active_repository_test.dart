import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaman/data/active_repository.dart';
import 'package:gaman/data/firestore_repository.dart';
import 'package:gaman/data/local_repository.dart';
import 'package:gaman/data/models.dart';
import 'package:gaman/data/repository.dart';
import 'package:gaman/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore db;
  late MockFirebaseAuth mock;
  late AuthService auth;
  late List<String> signedIn;

  ActiveRepository build() => ActiveRepository.followAuth(
        auth,
        build: (uid) => uid == null
            ? LocalRepository()
            : FirestoreRepository(uid: uid, firestore: db),
        onSignedIn: (r) => signedIn.add('signed-in'),
      );

  JournalEntry entry(String id) =>
      JournalEntry(id: id, content: id, date: DateTime(2026, 1, 1), mood: '😊');

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = FakeFirebaseFirestore();
    mock = MockFirebaseAuth();
    auth = AuthService(auth: mock);
    signedIn = [];
  });

  test('starts local, switches to the uid once background sign-in lands',
      () async {
    final repo = build();
    expect(repo.current, isA<LocalRepository>());

    await auth.ensureSignedIn();
    await pumpEventQueue();

    expect(repo.current, isA<FirestoreRepository>());
    expect(signedIn, hasLength(1));
    await repo.upsertJournalEntry(entry('a'));
    final docs = await db.collection('users/${auth.uid}/journal').get();
    expect(docs.docs.single.id, 'a');
  });

  test('writes follow the new uid after an account switch', () async {
    await auth.ensureSignedIn();
    final first = auth.uid!;
    final repo = build();

    await mock.signOut();
    await mock.signInAnonymously();
    await pumpEventQueue();
    final second = auth.uid!;
    expect(second, isNot(first));

    await repo.upsertJournalEntry(entry('b'));
    expect((await db.collection('users/$first/journal').get()).docs, isEmpty);
    expect((await db.collection('users/$second/journal').get()).docs.single.id,
        'b');
  });

  test('an open watch stream re-points to the new user', () async {
    await db.doc('users/other/journal/x').set(entry('x').toJson());
    await auth.ensureSignedIn();
    final repo = build();
    final seen = <List<String>>[];
    final sub = repo.watchJournal().listen((l) => seen.add(l.map((e) => e.id).toList()));
    await pumpEventQueue();
    expect(seen.last, isEmpty);

    repo.switchTo(FirestoreRepository(uid: 'other', firestore: db));
    await pumpEventQueue();
    expect(seen.last, ['x']);
    await sub.cancel();
  });

  test('signing out falls back to a local repository', () async {
    await auth.ensureSignedIn();
    final Repository repo = build();
    await mock.signOut();
    await pumpEventQueue();
    expect((repo as ActiveRepository).current, isA<LocalRepository>());
  });
}
