import 'dart:convert';

import 'package:share_plus/share_plus.dart';

import '../data/repository.dart';

/// The export payload: whatever the active [Repository] holds for this user
/// (Firestore when signed in, the device otherwise). Built from typed user
/// data only, so device-level prefs and any credentials never leak in.
Future<String> buildExport(Repository repo, {DateTime? now}) async {
  final payload = <String, Object?>{
    'app': 'gaman',
    'schema': 2,
    'exportedAt': (now ?? DateTime.now()).toIso8601String(),
    'data': await repo.exportData(),
  };
  return const JsonEncoder.withIndent('  ').convert(payload);
}

/// Hands the export to the OS share sheet — save it to Files, mail it to
/// yourself, drop it in a note.
///
// ponytail: shared as text, not a .json file. Fine for a few hundred KB;
// switch to shareXFiles if journals get large enough that the share sheet
// chokes.
Future<void> exportAllData(Repository repo) async {
  await Share.share(
    await buildExport(repo),
    subject: 'Gaman backup ${DateTime.now().toIso8601String().split('T').first}',
  );
}
