import 'dart:ui';
import 'package:flutter/material.dart';

class ReportHazardSheet extends StatelessWidget {
  const ReportHazardSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E232C).withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Report Hazard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Grid Items
              Row(
                children: [
                   Expanded(child: _HazardItem(label: 'SPEED CAMERA', icon: Icons.camera_alt, color: const Color(0xFF2979FF))), // Blue
                   const SizedBox(width: 16),
                   Expanded(child: _HazardItem(label: 'ACCIDENT', icon: Icons.warning_rounded, color: const Color(0xFFE53935))), // Red
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                   Expanded(child: _HazardItem(label: 'POLICE CHECK', icon: Icons.local_police, color: const Color(0xFFFFCC00))), // Yellowish
                   const SizedBox(width: 16),
                   Expanded(child: _HazardItem(label: 'ROAD BLOCK', icon: Icons.construction, color: const Color(0xFFFF6D00))), // Orange
                ],
              ),
              const SizedBox(height: 16),
              
              // Wide Item
              _HazardItem(
                label: 'DANGEROUS CURVE',
                subLabel: 'Report sharp turns or blind spots',
                icon: Icons.alt_route, // Fallback for curve
                color: const Color(0xFF00C853), // Green
                isWide: true,
              ),
              
              const SizedBox(height: 24),
              
              // Cancel Button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.white.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HazardItem extends StatelessWidget {
  final String label;
  final String? subLabel;
  final IconData icon;
  final Color color;
  final bool isWide;

  const _HazardItem({
    required this.label,
    required this.icon,
    required this.color,
    this.subLabel,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: isWide ? 80 : 120),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C313A).withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: isWide 
        ? Row(
            children: [
              _buildIconBox(),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (subLabel != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subLabel!,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          )
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildIconBox(),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildIconBox() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          icon,
          color: color,
          size: 24,
        ),
      ),
    );
  }
}
