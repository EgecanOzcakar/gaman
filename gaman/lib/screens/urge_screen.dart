import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../endurance.dart';
import '../l10n/app_localizations.dart';
import '../providers/activity_log.dart';
import '../services/chime.dart';
import '../theme/app_theme.dart';
import '../widgets/urge_wave.dart';

/// "I have an urge": name it, ride it out for ten minutes, log the outcome.
class UrgeScreen extends StatefulWidget {
  const UrgeScreen({super.key});

  @override
  State<UrgeScreen> createState() => _UrgeScreenState();
}

class _UrgeScreenState extends State<UrgeScreen> {
  String? _tag;
  DateTime? _startedAt;
  Timer? _tick;

  static const _total = Duration(minutes: urgeMinutes);

  Duration get _elapsed =>
      _startedAt == null ? Duration.zero : DateTime.now().difference(_startedAt!);

  bool get _over => _elapsed >= _total;

  void _start(String tag) {
    HapticFeedback.selectionClick();
    setState(() {
      _tag = tag;
      _startedAt = DateTime.now();
    });
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      if (_over) {
        _tick?.cancel();
        Chime.play(context);
      }
    });
  }

  Future<void> _finish(bool held) async {
    _tick?.cancel();
    final secs = _elapsed.inSeconds.clamp(0, _total.inSeconds);
    await context.read<ActivityLog>().log(ActivityType.urge,
        durationSeconds: secs, meta: {'tag': _tag, 'held': held});
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(held ? l10n.urgeHeldSnack : l10n.urgeGaveInSnack)));
    Navigator.pop(context, held);
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navEndure)),
      body: _tag == null ? _pickTag(text, l10n) : _riding(text, l10n),
    );
  }

  Widget _pickTag(TextTheme text, AppLocalizations l10n) => ListView(
        padding: const EdgeInsets.all(Insets.lg),
        children: [
          Text(l10n.urgePickTitle, style: text.headlineSmall),
          const SizedBox(height: Insets.sm),
          Text(l10n.urgePickBody, style: text.bodyLarge),
          const SizedBox(height: Insets.lg),
          Wrap(
            spacing: Insets.sm,
            runSpacing: Insets.sm,
            children: [
              for (final t in urgeTags)
                ActionChip(label: Text(l10n.urgeTag(t)), onPressed: () => _start(t)),
            ],
          ),
        ],
      );

  Widget _riding(TextTheme text, AppLocalizations l10n) {
    final remaining = _total - _elapsed;
    final mm = remaining.isNegative ? 0 : remaining.inMinutes;
    final ss = remaining.isNegative ? 0 : remaining.inSeconds % 60;
    return ListView(
      padding: const EdgeInsets.all(Insets.lg),
      children: [
        Center(
          child: Column(
            children: [
              Text(_over ? l10n.urgePassed : '$mm:${ss.toString().padLeft(2, '0')}',
                  style: text.displayMedium),
              Text(l10n.urgeTag(_tag!), style: text.titleMedium),
            ],
          ),
        ),
        const SizedBox(height: Insets.md),
        Semantics(
          label: l10n.urgeWaveSemantics((remaining.inSeconds / 60).ceil().clamp(0, urgeMinutes)),
          child: UrgeWave(progress: _elapsed.inSeconds / _total.inSeconds),
        ),
        const SizedBox(height: Insets.xl),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Text(
            _over
                ? l10n.urgeAskHeld
                : l10n.urgeGuidance(guidanceIndexAt(_elapsed)),
            key: ValueKey(_over ? -1 : guidanceIndexAt(_elapsed)),
            textAlign: TextAlign.center,
            style: text.titleLarge?.copyWith(height: 1.4),
          ),
        ),
        const SizedBox(height: Insets.xl),
        FilledButton(
          onPressed: () => _finish(true),
          child: Text(_over ? l10n.urgeHeld : l10n.urgeHeldEarly),
        ),
        const SizedBox(height: Insets.sm),
        OutlinedButton(
          onPressed: () => _finish(false),
          child: Text(l10n.urgeGaveIn),
        ),
      ],
    );
  }
}
