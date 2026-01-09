import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'splash_screen.dart';

class TypeRushApp extends StatelessWidget {
  const TypeRushApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData.dark(useMaterial3: true);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TypeRush',
      theme: baseTheme.copyWith(
        textTheme: GoogleFonts.spaceGroteskTextTheme(baseTheme.textTheme),
        colorScheme: baseTheme.colorScheme.copyWith(
          primary: const Color(0xFF7C3AED),
          secondary: const Color(0xFF22D3EE),
        ),
        scaffoldBackgroundColor: const Color(0xFF020617),
      ),
      home: const SplashScreen(),
    );
  }
}


