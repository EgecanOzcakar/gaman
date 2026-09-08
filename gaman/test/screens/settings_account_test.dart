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
