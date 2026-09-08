import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gaman/data/repository.dart';
import 'package:gaman/data/sync_status.dart';
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

class _FakeRepo implements Repository {
  _FakeRepo(this._status);
  final SyncStatus _status;
  @override
  Stream<SyncStatus> watchSyncStatus() => Stream.value(_status);
  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

Widget _host(AuthService auth, {_FakeRepo? repo}) => MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: auth),
          Provider<Repository>.value(
              value: repo ?? _FakeRepo(SyncStatus.synced)),
        ],
        child: const Scaffold(body: BackupSectionForTest()),
      ),
    );

void main() {
  testWidgets('unavailable → shows the unavailable line, no buttons', (t) async {
    await t.pumpWidget(_host(_FakeAuth(avail: false),
        repo: _FakeRepo(SyncStatus.synced)));
    expect(find.textContaining('unavailable'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsNothing);
  });

  testWidgets('anonymous → offers to back up', (t) async {
    await t.pumpWidget(_host(_FakeAuth(avail: true),
        repo: _FakeRepo(SyncStatus.synced)));
    expect(find.textContaining('on this device only'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
  });

  testWidgets('linked → shows the label and a sign-out button', (t) async {
    await t.pumpWidget(_host(_FakeAuth(avail: true, label: 'me@x.com'),
        repo: _FakeRepo(SyncStatus.synced)));
    expect(find.textContaining('me@x.com'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('linked + syncing → shows "Syncing…"', (t) async {
    await t.pumpWidget(_host(
      _FakeAuth(avail: true, label: 'me@x.com'),
      repo: _FakeRepo(SyncStatus.syncing),
    ));
    await t.pump();
    expect(find.text('Syncing…'), findsOneWidget);
  });
}
