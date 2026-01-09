import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../game/typing_game_screen.dart';
import '../game/widgets/neon_orb.dart';
import '../game/widgets/falling_word_chip.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.forward();

    // Navigate to the game after a short delay.
    _timer = Timer(const Duration(milliseconds: 1700), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, animation, secondaryAnimation) {
            return FadeTransition(opacity: animation, child: const TypingGameScreen());
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF020617), Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -100,
              left: -60,
              child: NeonOrb(size: 260, color: Color(0xFF22D3EE)),
            ),
            const Positioned(
              bottom: -140,
              right: -100,
              child: NeonOrb(size: 340, color: Color(0xFF7C3AED)),
            ),
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.04),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: const Icon(Icons.bolt_rounded, size: 40, color: Color(0xFFFB7185)),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'TypeRush',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Typing speed challenge',
                        style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13),
                      ),
                      const SizedBox(height: 26),
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FallingWordChip(text: 'Love'),
                          SizedBox(width: 10),
                          FallingWordChip(text: 'Laugh'),
                          SizedBox(width: 10),
                          FallingWordChip(text: 'Live'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  'by stormbit labs',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
