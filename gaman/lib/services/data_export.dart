import 'dart:convert';

import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dump everything the app has stored (journal, tasks, activity log,
/// settings) as JSON and hand it to the OS share sheet — save it to Files,
/// mail it to yourself, drop it in a note.
///
// ponytail: shared as text, not a .json file. Fine for a few hundred KB;
// switch to shareXFiles + path_provider if journals get large enough that
// the share sheet chokes.
Future<void> exportAllData() async {
  final prefs = await SharedPreferences.getInstance();
  final payload = <String, Object?>{
    'app': 'gaman',
    'schema': 1,
    'exportedAt': DateTime.now().toIso8601String(),
    'data': {for (final key in prefs.getKeys()) key: prefs.get(key)},
  };
  await Share.share(
    const JsonEncoder.withIndent('  ').convert(payload),
    subject: 'Gaman backup ${DateTime.now().toIso8601String().split('T').first}',
  );
}
