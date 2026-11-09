import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../endurance.dart';
import '../providers/activity_log.dart';
import '../theme/app_theme.dart';
import '../widgets/timer_ring.dart';

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
        HapticFeedback.mediumImpact();
      }
    });
  }

  Future<void> _finish(bool held) async {
    _tick?.cancel();
    final secs = _elapsed.inSeconds.clamp(0, _total.inSeconds);
    await context.read<ActivityLog>().log(ActivityType.urge,
        durationSeconds: secs, meta: {'tag': _tag, 'held': held});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(held
            ? 'Gaman. That one is yours.'
            : 'Noted, not judged. Next time, ride it a little longer.')));
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
    return Scaffold(
      appBar: AppBar(title: const Text('Endure')),
      body: _tag == null ? _pickTag(text) : _riding(text),
    );
  }

  Widget _pickTag(TextTheme text) => ListView(
        padding: const EdgeInsets.all(Insets.lg),
        children: [
          Text('What is pulling at you?', style: text.headlineSmall),
          const SizedBox(height: Insets.sm),
          Text(
              'Name it, then give it ten minutes before you decide. '
              'Most urges pass on their own.',
              style: text.bodyLarge),
          const SizedBox(height: Insets.lg),
          Wrap(
            spacing: Insets.sm,
            runSpacing: Insets.sm,
            children: [
              for (final t in urgeTags)
                ActionChip(label: Text(t), onPressed: () => _start(t)),
            ],
          ),
        ],
      );

  Widget _riding(TextTheme text) {
    final remaining = _total - _elapsed;
    final mm = remaining.isNegative ? 0 : remaining.inMinutes;
    final ss = remaining.isNegative ? 0 : remaining.inSeconds % 60;
    return ListView(
      padding: const EdgeInsets.all(Insets.lg),
      children: [
        Center(
          child: TimerRing(
            progress: _elapsed.inSeconds / _total.inSeconds,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_over ? 'Passed' : '$mm:${ss.toString().padLeft(2, '0')}',
                    style: text.displayMedium),
                Text(_tag!, style: text.titleMedium),
              ],
            ),
          ),
        ),
        const SizedBox(height: Insets.xl),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Text(
            _over
                ? 'The wave has passed. Did you hold?'
                : guidanceAt(_elapsed),
            key: ValueKey(_over ? 'over' : guidanceAt(_elapsed)),
            textAlign: TextAlign.center,
            style: text.titleLarge?.copyWith(height: 1.4),
          ),
        ),
        const SizedBox(height: Insets.xl),
        FilledButton(
          onPressed: () => _finish(true),
          child: Text(_over ? 'I held' : 'It passed. I held'),
        ),
        const SizedBox(height: Insets.sm),
        OutlinedButton(
          onPressed: () => _finish(false),
          child: const Text('I gave in'),
        ),
      ],
    );
  }
}
