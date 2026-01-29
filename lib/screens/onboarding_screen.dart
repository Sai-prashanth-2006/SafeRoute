import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1216), // Deep dark background
      body: Stack(
        fit: StackFit.expand,
        children: [
          
          Column(
            children: [
               // Skip Button
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                      );
                    },
                    child: Text(
                      'Skip',
                      style: GoogleFonts.inter(
                        color: Colors.grey[500],
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Hero Image area
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: Image.asset(
                    'assets/images/car_hero.png',
                    fit: BoxFit.contain, // Maintain aspect ratio
                  ),
                ),
              ),

              // Content Area
              Expanded(
                flex: 4,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: GoogleFonts.inter(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                              color: Colors.white,
                            ),
                            children: [
                              const TextSpan(text: 'Your Intelligent '),
                              TextSpan(
                                text: 'Co-\nDriver',
                                style: TextStyle(
                                  color: const Color(0xFF2979FF),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Subtitle
                        Text(
                          'Experience safer journeys with real-time hazard alerts, speed camera detection, and insights powered by a global community of drivers.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: Colors.grey[400],
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                         
                        const SizedBox(height: 24),
                         
                         // Pagination Dots
                         Row(
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: [
                             _buildDot(true),
                             const SizedBox(width: 8),
                             _buildDot(false),
                             const SizedBox(width: 8),
                             _buildDot(false),
                           ],
                         ),
                         
                        const SizedBox(height: 24),
  
                        // Get Started Button
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2979FF), Color(0xFF2962FF)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2979FF).withOpacity(0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                 Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Get Started',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward, color: Colors.white),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Footer
                        Text(
                          'SMART NAVIGATION & SAFETY',
                          style: GoogleFonts.inter(
                            color: Colors.grey[700],
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDot(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 6,
      width: isActive ? 24 : 6,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF2979FF) : Colors.grey[700],
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
