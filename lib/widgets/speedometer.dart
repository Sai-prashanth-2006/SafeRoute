import 'package:flutter/material.dart';
import 'dart:math' as math;

class Speedometer extends StatelessWidget {
  final int speed;
  final String unit;

  const Speedometer({super.key, required this.speed, this.unit = 'km/h'});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: const Color(0xFF1E232C).withOpacity(0.95),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF2979FF).withOpacity(0.2),
            blurRadius: 30,
            spreadRadius: -10,
          ),
        ],
        border: Border.all(color: const Color(0xFF2C313A), width: 1),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Progress Arc
          CustomPaint(
            painter: _SpeedometerPainter(
              percentage: speed / 120,
            ), // Assumed max speed 120
          ),
          // Text Content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'CURRENT',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$speed',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40, // Reduced from 48
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
              Text(
                unit,
                style: const TextStyle(
                  color: Color(0xFF2979FF),
                  fontSize: 12, // Reduced from 14
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpeedometerPainter extends CustomPainter {
  final double percentage;

  _SpeedometerPainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4; // Padding

    // Draw Background Track (partial if needed, here full circle thin)
    // Actually the image shows a blue highlight arc on the right.
    // I'll draw a progress arc from -90 degrees (top) or standard speedometer angle.
    // Image shows it highlighting the right side mostly. Let's make it a standard clockwise progress.

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    // Background track
    paint.color = const Color(0xFF2C313A);
    // canvas.drawCircle(center, radius, paint);

    // Gradient Arc
    // We need a sweep gradient
    final Rect rect = Rect.fromCircle(center: center, radius: radius);
    const Gradient gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: 3 * math.pi / 2,
      tileMode: TileMode.repeated,
      colors: [Color(0xFF2979FF), Color(0xFF29B6FF)],
    );

    paint.shader = gradient.createShader(rect);

    // Draw arc starting from top (-pi/2)
    // For 75km/h out of 100 or 120.
    // The image shows a sector highlighted.

    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * percentage, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
