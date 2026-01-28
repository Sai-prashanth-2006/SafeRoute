import 'package:flutter/material.dart';
import '../widgets/nav_map.dart';
import '../widgets/speedometer.dart';
import '../widgets/speed_limit.dart';
import '../widgets/alert_banner.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/report_hazard_sheet.dart';
import 'dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Toggle for demo purposes
  bool _isHazardMode = false;
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: [
              _buildNavView(context),
              const DashboardScreen(),
            ],
          ),
          
          if (!_isHazardMode || _selectedIndex == 1)
             Positioned(
              left: 0,
              right: 0,
              bottom: 20,
              child: BottomNav(
                currentIndex: _selectedIndex,
                onTabChange: (index) => setState(() => _selectedIndex = index),
                onHazardTap: () {
                   showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (context) => const ReportHazardSheet(),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavView(BuildContext context) {
    return Stack(
        children: [
          // 1. Map Layer (Full Screen)
          const Positioned.fill(
            child: NavMap(),
          ),

          // 2. Main Content & Overlays
          // Using SafeArea manually for top/bottom where needed, but keeping map full bleed.
          SafeArea(
            child: Stack(
              children: [
                
                // --- Top Area ---
                if (!_isHazardMode) ...[
                  // Search Bar (Replaces static alert for Community view)
                   Positioned(
                    top: 16,
                    left: 20,
                    right: 20,
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E232C),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                           BoxShadow(
                             color: Colors.black.withOpacity(0.3),
                             blurRadius: 10,
                             offset: const Offset(0, 4),
                           ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: Colors.blue[400]),
                          const SizedBox(width: 12),
                          Text('Search destination', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // Hazard Mode Top Nav (Next Turn)
                   Positioned(
                    top: 16,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E232C),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2979FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.turn_right, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                           Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('NEXT TURN', style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold)),
                              const Text('450m', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Settings Interaction
                  Positioned(
                    top: 16,
                    right: 20,
                    child: GestureDetector(
                        onTap: () => setState(() => _isHazardMode = !_isHazardMode), // Toggle fake hazard
                        child: CircleAvatar(
                          backgroundColor:  const Color(0xFF1E232C),
                          radius: 24,
                          child: const Icon(Icons.settings, color: Colors.white),
                        ),
                    ),
                  ),

                  // Hazard Card Big
                  Positioned(
                    top: 90,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                           colors: [Color(0xFFFF5252), Color(0xFFFF9100)],
                           begin: Alignment.topLeft,
                           end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5252).withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.speed, color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 12),
                              const Text('URGENT HAZARD', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, height: 1.1),
                              children: [
                                TextSpan(text: 'Speed Camera '),
                                TextSpan(text: '250m\n', style: TextStyle(fontWeight: FontWeight.w800)),
                                TextSpan(text: 'Ahead'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(height: 1, color: Colors.white.withOpacity(0.2)),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('ZONE LIMIT', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                                  Text('100 km/h', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text('REDUCE SPEED', style: TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                   // Speed Control Overlay (Middle)
                   Positioned(
                     top: 380, // Approx
                     left: 20,
                     right: 20,
                     child: IntrinsicHeight(
                       child: Stack(
                         children: [
                           // Main Black Box
                           Container(
                              margin: const EdgeInsets.only(right: 20), // Space for +/- buttons
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16181D),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('CURRENT SPEED', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                                      RichText(
                                        text: const TextSpan(
                                          children: [
                                            TextSpan(text: '85 ', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                                            TextSpan(text: 'KM/H', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Progress Bar
                                  Stack(
                                    children: [
                                       Container(height: 8, decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(4))),
                                       Container(width: 200, height: 8, decoration: BoxDecoration(color: const Color(0xFF2979FF), borderRadius: BorderRadius.circular(4))),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('0', style: TextStyle(color: Colors.grey, fontSize: 10)),
                                      Text('LIMIT 100', style: TextStyle(color: Colors.grey, fontSize: 10)),
                                      Text('160', style: TextStyle(color: Colors.grey, fontSize: 10)),
                                    ],
                                  ),
                                ],
                              ),
                           ),
                           // Zoom Buttons attached
                           Align(
                             alignment: Alignment.centerRight,
                             child: Container(
                               width: 48,
                               height: 96,
                               decoration: BoxDecoration(
                                 color: const Color(0xFF1E232C),
                                 borderRadius: BorderRadius.circular(16),
                                 border: Border.all(color: Colors.white.withOpacity(0.1)),
                               ),
                               child: Column(
                                 children: [
                                   Expanded(child: Icon(Icons.add, color: Colors.white.withOpacity(0.8))),
                                   Expanded(child: Icon(Icons.remove, color: Colors.white.withOpacity(0.8))),
                                 ],
                               ),
                             ),
                           ),
                         ],
                       ),
                     ),
                   ),

                   // Feedback Bottom Sheet
                   Positioned(
                     bottom: 20,
                     left: 20,
                     right: 20,
                     child: Container(
                       padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16181D),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          children: [
                            const Text('Is the hazard still there?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2979FF),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.white, size: 20),
                                        SizedBox(height: 4),
                                        Text('STILL THERE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _isHazardMode = false),
                                    child: Container(
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2C313A),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.cancel, color: Colors.white, size: 20),
                                          SizedBox(height: 4),
                                          Text('CLEARED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text('REPORTED BY 12 DRIVERS RECENTLY', style: TextStyle(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                          ],
                        ),
                     ),
                   ),

                ],

                // --- Standard Mode UI Group ---
                // We use Positioned widgets for exact coordinates observed in image 1.
                 if (!_isHazardMode) ...[
                     // Speedometer Group (Top Right relative to center)
                     // In Image 1, it's roughly 1/3 down, right aligned.
                     // --- Right Side Controls Column ---
                     Positioned(
                       right: 16,
                       top: 140, 
                       bottom: 120, // Above Bottom Nav
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.center,
                         children: [
                           // Speedometer
                           const Speedometer(speed: 75),
                           
                           const SizedBox(height: 24),
                           
                           // Speed Limit
                           const SpeedLimit(limit: 80),
                           
                           const SizedBox(height: 16),
                           
                           // Hazard (Construction) Icon
                           Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6D00), // Orange
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.build, color: Colors.white, size: 20),
                            ),
                            
                            const Spacer(),
                            
                            // Map Controls (Simulate Hazard & Layers)
                            Column(
                              children: [
                                 GestureDetector(
                                    onTap: () => setState(() => _isHazardMode = true),
                                    child: const _MapButton(icon: Icons.warning_amber_rounded)
                                 ),
                                 const SizedBox(height: 12),
                                const _MapButton(icon: Icons.layers_outlined),
                              ],
                            ),
                         ],
                       ),
                     ),

                     // Nav Arrow (Blue Box) - Vertically Centered Left
                     Positioned(
                        left: 20,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2979FF), Color(0xFF2962FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                 BoxShadow(
                                  color: const Color(0xFF2979FF).withOpacity(0.5),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.navigation, 
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ),

                 ],
                 
              ],
            ),
          ),
        ],
      );
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;

  const _MapButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF1E232C).withOpacity(0.9),
        borderRadius: BorderRadius.circular(14), // Slightly more rounded
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}
