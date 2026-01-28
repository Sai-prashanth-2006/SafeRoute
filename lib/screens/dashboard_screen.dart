import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1216),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundImage: AssetImage('assets/images/avatar_placeholder.png'), // Placeholder
                    backgroundColor: Color(0xFF2979FF),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  Column(
                    children: [
                      Text(
                        'Driver Safety',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00C853),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'LIVE STATUS',
                            style: GoogleFonts.inter(
                              color: Colors.grey[500],
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E232C),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.notifications_none, color: Colors.white, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Score Circle
              const Center(child: _SafetyScoreGauge(score: 92)),
              
              const SizedBox(height: 24),

              // Trip Summary Pill
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E232C),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Text(
                    'Last trip: 12 mins ago • 14.2 km',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ),
              ),
              
              const SizedBox(height: 30),

              // Stats Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.25,
                children: const [
                  _StatCard(
                    icon: Icons.speed,
                    iconColor: Color(0xFF2979FF),
                    label: 'AVG SPEED',
                    value: '64',
                    unit: 'km/h',
                    trend: '↗ 2% vs prev.',
                    trendColor: Color(0xFFFF5252), // Red for speed increase? Or generic.
                  ),
                  _StatCard(
                    icon: Icons.warning_amber_rounded,
                    iconColor: Color(0xFFFF9100),
                    label: 'OVERSPEED',
                    value: '2',
                    unit: 'Alerts',
                    trend: '↘ 1 less trip',
                    trendColor: Color(0xFF00C853), // Good
                  ),
                  _StatCard(
                    icon: Icons.shield,
                    iconColor: Color(0xFF00C853),
                    label: 'HAZARDS',
                    value: '14',
                    unit: 'Avoided',
                    trend: '+ 3 new detections',
                    trendColor: Color(0xFF00C853),
                  ),
                  _StatCard(
                    icon: Icons.group,
                    iconColor: Color(0xFF00E5FF),
                    label: 'COMMUNITY',
                    value: '28',
                    unit: 'Contribs',
                    trend: 'Top 5% Driver',
                    trendColor: Color(0xFF00E5FF),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),

              // Weekly Safety Trends Chart
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF16181D),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Weekly Safety Trends',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Daily average based on 24 trips',
                              style: TextStyle(color: Colors.grey[500], fontSize: 10),
                            ),
                          ],
                        ),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                             Text(
                              '88.5',
                              style: TextStyle(color: Color(0xFF2979FF), fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                             Text(
                              '+4.2% ↗',
                              style: TextStyle(color: Color(0xFF00C853), fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 100,
                      width: double.infinity,
                      child: CustomPaint(painter: _ChartPainter()),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']
                          .map((d) => Text(d, style: TextStyle(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.bold)))
                          .toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              
              // Recent Insights Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Insights', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('VIEW HISTORY', style: TextStyle(color: Colors.blue[400], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                ],
              ),
              const SizedBox(height: 16),
              
              // Insights List
              _InsightTile(
                icon: Icons.speed,
                iconColor: const Color(0xFFFF9100),
                title: 'Moderate Speeding on I-95',
                subtitle: '14.2km trip • Wed, 4:20 PM',
                points: '-5 pts',
                pointsColor: const Color(0xFFFF9100),
              ),
              const SizedBox(height: 12),
               _InsightTile(
                icon: Icons.navigation,
                iconColor: const Color(0xFF2979FF),
                title: 'Safe Route Completed',
                subtitle: '8.1km trip • Wed, 8:45 AM',
                points: '+12 pts',
                pointsColor: const Color(0xFF00C853),
              ),
              
              const SizedBox(height: 100), // Bottom padding for Nav Bar
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String unit;
  final String trend;
  final Color trendColor;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.unit,
    required this.trend,
    required this.trendColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16181D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.grey[500],
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                trend,
                style: TextStyle(color: trendColor, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String points;
  final Color pointsColor;

  const _InsightTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.points,
    required this.pointsColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E232C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
              ],
            ),
          ),
          Text(points, style: TextStyle(color: pointsColor, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}

class _SafetyScoreGauge extends StatelessWidget {
  final int score;

  const _SafetyScoreGauge({required this.score});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        fit: StackFit.expand,
        children: [
           CustomPaint(
            painter: _GaugePainter(),
           ),
           Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               Text(
                 'Safety Score',
                 style: TextStyle(
                   color: const Color(0xFF2979FF).withOpacity(0.5),
                   fontSize: 12,
                   fontWeight: FontWeight.bold,
                 ),
               ),
               Text(
                 '$score',
                 style: const TextStyle(
                   color: Colors.white, // In screenshot it's fading behind generic gradient? No, it's bold white.
                   fontSize: 64,
                   fontWeight: FontWeight.bold, // Custom font normally
                   height: 1.0,
                 ),
               ),
               const SizedBox(height: 8),
               Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Icon(Icons.trending_up, color: const Color(0xFF00E676), size: 16),
                   const SizedBox(width: 4),
                   const Text(
                     'EXCELLENT',
                     style: TextStyle(
                       color: Color(0xFF00E676),
                       fontSize: 12,
                       fontWeight: FontWeight.bold,
                       letterSpacing: 1.0,
                     ),
                   ),
                 ],
               ),
             ],
           ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Draw background circle (Dark)
    // Actually visual shows a large filled gradient circle background.
    
    final bgPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
         Color(0xFF1E232C),
         Color(0xFF0F1216),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
      
    canvas.drawCircle(center, radius, bgPaint);
    
    // Draw Gradient Arc Sweep
    // The visual has a cyan/blue sweep.
    final paint = Paint()
       ..style = PaintingStyle.stroke
       ..strokeWidth = 20
       ..strokeCap = StrokeCap.round;
      
   final rect = Rect.fromCircle(center: center, radius: radius - 20);
   
   // Background Track
   paint.color = const Color(0xFF1E232C);
   canvas.drawArc(rect, math.pi * 0.8, math.pi * 1.4, false, paint);
   
   // Active Arc
   const gradient = SweepGradient(
     startAngle: math.pi * 0.8,
     endAngle: math.pi * 2.2, // Full circle ish
     colors: [
       Color(0xFF00E5FF),
       Color(0xFF2979FF),
     ],
     transform: GradientRotation(math.pi / 2),
   );
   
   paint.shader = gradient.createShader(rect);
   // Draw 75% filled for "92"
   canvas.drawArc(rect, math.pi * 0.8, math.pi * 1.1, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2979FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // Simulate a smooth curve
    // Points: (0, 80%), (w/6, 40%), (2w/6, 70%), (3w/6, 90%), (4w/6, 60%), (5w/6, 20%), (w, 50%)
    // Y coordinates are inverted (0 is top)
    
    final h = size.height;
    final w = size.width;
    
    path.moveTo(0, h * 0.7);
    
    // Cubic bezier implementation for smoothness (approximate)
    path.cubicTo(w * 0.1, h * 0.2, w * 0.2, h * 0.2, w * 0.25, h * 0.6);
    path.cubicTo(w * 0.3, h * 0.8, w * 0.4, h * 0.5, w * 0.5, h * 0.5);
    path.cubicTo(w * 0.6, h * 0.5, w * 0.7, h * 0.9, w * 0.75, h * 0.9);
    path.cubicTo(w * 0.8, h * 0.9, w * 0.85, h * 0.1, w * 0.9, h * 0.4);
    path.quadraticBezierTo(w * 0.95, h * 0.6, w, h * 0.3);

    canvas.drawPath(path, paint);
    
    // Gradient fill below
    final fillPath = Path.from(path)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
      
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF2979FF).withOpacity(0.3),
          const Color(0xFF2979FF).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
      
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
