import 'dart:async';

import 'package:flutter/material.dart';

/// Shared motion vocabulary. Calm by default: slow-ish durations, soft curves.
class Motion {
  static const quick = Duration(milliseconds: 200);
  static const base = Duration(milliseconds: 350);
  static const slow = Duration(milliseconds: 600);
  static const curve = Curves.easeOutCubic;

  /// True when the platform / user asked for reduced motion.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;
}

/// One-shot "settle into place" entrance: fade + small upward rise.
/// Used for the single orchestrated home-screen reveal (staggered via [delay]).
/// Respects reduced-motion by rendering the child immediately.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 12,
  });

  final Widget child;
  final Duration delay;
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> {
  bool _shown = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced(context)) return widget.child;
    return AnimatedSlide(
      offset: _shown ? Offset.zero : Offset(0, widget.offset / 100),
      duration: Motion.slow,
      curve: Motion.curve,
      child: AnimatedOpacity(
        opacity: _shown ? 1 : 0,
        duration: Motion.slow,
        curve: Motion.curve,
        child: widget.child,
      ),
    );
  }
}

/// Scales its child down briefly while pressed. For cards / tappable tiles.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool v) => setState(() => _down = v);

  @override
  Widget build(BuildContext context) {
    final scale = (_down && !Motion.reduced(context)) ? 0.96 : 1.0;
    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: scale,
        duration: Motion.quick,
        curve: Motion.curve,
        child: widget.child,
      ),
    );
  }
}
