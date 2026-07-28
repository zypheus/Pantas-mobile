import 'package:flutter/material.dart';

class FloatingBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FloatingBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<FloatingBottomNavBar> createState() => _FloatingBottomNavBarState();
}

class _FloatingBottomNavBarState extends State<FloatingBottomNavBar> {
  static const double _barHeight = 64;
  static const double _dotSize = 6;

  static const Color _barColor = Color(0xFF0B0B3B);
  static const Color _dotColor = Color(0xFFFBBF24);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final segmentWidth = screenWidth / 5;

    return Container(
      height: _barHeight + _dotSize + 8,
      margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: _barHeight,
            decoration: BoxDecoration(
              color: _barColor,
              borderRadius: BorderRadius.circular(40),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Row(
              children: List.generate(5, (index) {
                return Expanded(
                  child: _NavItem(
                    index: index,
                    segmentWidth: segmentWidth,
                    icon: _iconForIndex(index),
                    isActive: widget.currentIndex == index,
                    onTap: () => widget.onTap(index),
                  ),
                );
              }),
            ),
          ),
          if (widget.currentIndex >= 0 && widget.currentIndex < 5)
            Positioned(
              top: _barHeight + 2,
              left: segmentWidth * widget.currentIndex +
                  segmentWidth / 2 -
                  _dotSize / 2,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                width: _dotSize,
                height: _dotSize,
                decoration: const BoxDecoration(
                  color: _dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _iconForIndex(int index) {
    switch (index) {
      case 0:
        return Icons.home_rounded;
      case 1:
        return Icons.bar_chart_rounded;
      case 2:
        return Icons.door_front_door_rounded;
      case 3:
        return Icons.notifications_rounded;
      case 4:
        return Icons.person_rounded;
      default:
        return Icons.circle;
    }
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final double segmentWidth;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.index,
    required this.segmentWidth,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  static const double _badgeSize = 48;
  static const Color _badgeColor = Color(0xFF1A1A4A);
  static const double _iconSize = 24;

  @override
  Widget build(BuildContext context) {
    final iconColor =
        isActive ? const Color(0xFFFBBF24) : const Color(0xFFE5E7EB);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: segmentWidth,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              width: isActive ? _badgeSize : 0,
              height: isActive ? _badgeSize : 0,
              decoration: const BoxDecoration(
                color: _badgeColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: _iconSize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
