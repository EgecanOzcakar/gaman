import 'package:flutter/material.dart';
import 'dart:async';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  String _displayText = '';
  final String _fullText = 'Enduring the seemingly unbearable with patience and dignity';
  int _charIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    _startTypingAnimation();
    _controller.forward();

    // Navigate to home screen after animation completes
    Future.delayed(const Duration(seconds: 5), () {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    });
  }

  void _startTypingAnimation() {
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_charIndex < _fullText.length) {
        setState(() {
          _displayText += _fullText[_charIndex];
          _charIndex++;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Define darker duck egg blue color
    const duckEggBlue = Color(0xFF8FB3B3); // A darker, muted blue-green
    const darkTextColor = Color(0xFF1A2C2C); // A darker blue-gray for text

    return Scaffold(
      backgroundColor: duckEggBlue,
      body: Stack(
        fit: StackFit.expand, // This ensures the stack fills the screen
        children: [
          // Background Image with Opacity
          Positioned.fill(
            child: Opacity(
              opacity: 0.12,
              child: Transform.scale(
                scale: 1.1, // Slightly scale up the image to avoid white edges
                child: Image.asset(
                  'assets/images/ulysses-147003_1280.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.high,
                  color: Colors.black.withOpacity(0.4),
                  colorBlendMode: BlendMode.darken,
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  // App Name with Animation
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: Opacity(
                          opacity: _fadeAnimation.value,
                          child: Text(
                            'Gaman',
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              color: darkTextColor,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 8,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  // Quote with Animation
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: Opacity(
                          opacity: _fadeAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: darkTextColor.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: Text(
                                _displayText,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: darkTextColor.withOpacity(0.9),
                                  height: 1.5,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 