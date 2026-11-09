import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:flutter/widgets.dart';

import '../providers/feature_prefs.dart';

/// A soft bell when a timer ends (urge, focus, meditation), plus a haptic.
/// The sound is synthesised by `tool/make_chime.py`, so there is no licence
/// to track. Off via Settings → Sound (stored as the 'chime' feature pref).
class Chime {
  static const prefId = 'chime';

  static Future<void> play(BuildContext context) async {
    HapticFeedback.mediumImpact();
    if (!context.read<FeaturePrefs>().isEnabled(prefId)) return;
    final player = AudioPlayer();
    try {
      await player.setAsset('assets/audio/chime.mp3');
      await player.play();
    } catch (e) {
      debugPrint('Chime failed: $e');
    } finally {
      await player.dispose();
    }
  }
}
