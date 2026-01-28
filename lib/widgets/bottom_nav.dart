import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  final VoidCallback? onHazardTap;
  final int currentIndex;
  final Function(int) onTabChange;

  const BottomNav({
    super.key,
    this.onHazardTap,
    required this.currentIndex,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Background Bar
          Container(
            height: 80,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(
                0xFF1E232C,
              ).withOpacity(0.95), // Dark background
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => onTabChange(0),
                  behavior: HitTestBehavior.opaque,
                  child: _NavItem(
                    icon: Icons.explore,
                    label: 'NAV',
                    selected: currentIndex == 0,
                  ),
                ),
                GestureDetector(
                  onTap: () => onTabChange(1),
                  behavior: HitTestBehavior.opaque,
                  child: _NavItem(
                    icon: Icons.grid_view,
                    label: 'DASH',
                    selected: currentIndex == 1,
                  ),
                ),
                const SizedBox(width: 60), // Space for center FAB
                GestureDetector(
                  onTap: onHazardTap,
                  behavior: HitTestBehavior.opaque,
                  child: _NavItem(
                    icon: Icons.warning_amber_rounded,
                    label: 'HAZARDS',
                    selected: false, // Always false for action button
                  ),
                ),
                _NavItem(
                  icon: Icons.settings,
                  label: 'SETTINGS',
                  selected: false,
                ),
              ],
            ),
          ),
          // Center FAB
          Positioned(
            top: 0,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2979FF), Color(0xFF2962FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2979FF).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: const Color(0xFF1E232C), width: 4),
              ),
              child: const Center(
                child: Icon(Icons.navigation, color: Colors.white, size: 32),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;

  const _NavItem({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: selected ? const Color(0xFF2979FF) : Colors.grey[600],
          size: 28,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF2979FF) : Colors.grey[600],
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
