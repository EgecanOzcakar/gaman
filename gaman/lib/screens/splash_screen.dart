import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _quote =
      'Enduring the seemingly unbearable with patience and dignity';

  late final AnimationController _controller;
  late final Animation<double> _wordmark;
  late final Animation<int> _typed;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3400),
      vsync: this,
    );
    _wordmark = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.22, curve: Curves.easeOutCubic),
    );
    _typed = StepTween(begin: 0, end: _quote.length).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
      ),
    );
    _controller
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _goHome();
      })
      ..forward();
  }

  void _goHome() {
    if (_navigated) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 700),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A fixed, deliberately calm identity screen — one look, both themes.
    const bg = AppColors.water;
    const fg = AppColors.ink;

    if (Motion.reduced(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _goHome());
    }

    return Scaffold(
      backgroundColor: bg,
      body: GestureDetector(
        onTap: _goHome,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.10,
                child: Image.asset(
                  'assets/images/ulysses-147003_1280.png',
                  fit: BoxFit.cover,
                  color: Colors.black.withOpacity(0.4),
                  colorBlendMode: BlendMode.darken,
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Insets.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) => Opacity(
                        opacity: _wordmark.value,
                        child: Transform.translate(
                          offset: Offset(0, (1 - _wordmark.value) * 16),
                          child: Text(
                            'Gaman',
                            style: Theme.of(context)
                                .textTheme
                                .displayLarge
                                ?.copyWith(
                                  color: fg,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 6,
                                ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: Insets.lg),
                    Container(
                      padding: const EdgeInsets.only(left: Insets.md),
                      decoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(color: Color(0x4D1C2B2B), width: 2),
                        ),
                      ),
                      child: AnimatedBuilder(
                        animation: _typed,
                        builder: (context, _) => Text(
                          _quote.substring(0, _typed.value),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: fg.withOpacity(0.9),
                                height: 1.5,
                                fontWeight: FontWeight.w400,
                              ),
                        ),
                      ),
                    ),
                    const Spacer(flex: 2),
                    Text(
                      'Tap to begin',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: fg.withOpacity(0.5),
                          ),
                    ),
                    const SizedBox(height: Insets.md),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
