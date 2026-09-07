import 'package:flutter/material.dart';
import '../theme/motion.dart';

/// A large progress ring with centred content. [progress] is 0..1 and animates
/// smoothly to each new value.
class TimerRing extends StatelessWidget {
  const TimerRing({
    super.key,
    required this.progress,
    required this.child,
    this.color,
    this.size = 260,
  });

  final double progress;
  final Widget child;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ringColor = color ?? scheme.primary;
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
        duration: Motion.reduced(context) ? Duration.zero : Motion.slow,
        curve: Motion.curve,
        builder: (context, value, _) => Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 6,
                strokeCap: StrokeCap.round,
                backgroundColor: ringColor.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation(ringColor),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}
