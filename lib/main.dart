import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/onboarding_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nav Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A1F25), // Fallback dark color
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF2979FF),
          error: Color(0xFFE53935),
          surface: Color(0xFF2C313A),
        ),
      ),
      home: const OnboardingScreen(),
    );
  }
}
