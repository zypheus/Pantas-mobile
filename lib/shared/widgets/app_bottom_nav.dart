import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

/// Floating bottom navigation bar with an elevated center home button.
///
/// Slot mapping:
///   0 – Search    (/search)
///   1 – Library   (/borrowed)
///   2 – Home      (/home)   — raised gold circle
///   3 – Feedback  (/feedback)
///   4 – Profile   (/profile)
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({super.key});

  // ───── dimensions ─────
  static const double _barHeight = 70;
  static const double _fabSize = 56;
  static const double _fabRingWidth = 4;
  static const double _fabOverlap = 16;
  static const double _iconSize = 22;

  // ───── colors ─────
  static const Color _barColor = AppColors.navyBrand;
  static const Color _inactiveIcon = Color(0xFF9CA3AF);

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _indexForLocation(location);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad + 14),
      child: SizedBox(
        height: _barHeight + _fabOverlap + 20,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // ── pill ──
            Container(
              height: _barHeight,
              decoration: BoxDecoration(
                color: _barColor,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Row(
                children: [
                  // Left pair
                  _buildItem(context, 0, Icons.search_rounded, '/search', currentIndex, 'Catalog'),
                  _buildItem(context, 1, Icons.library_books_rounded, '/borrowed', currentIndex, 'Room'),
                  // Center gap for the FAB
                  const SizedBox(width: 64),
                  // Right pair
                  _buildItem(context, 3, Icons.chat_bubble_outline_rounded, '/feedback', currentIndex, 'Feedback'),
                  _buildItem(context, 4, Icons.person_rounded, '/profile', currentIndex, 'Profile'),
                ],
              ),
            ),

            // ── elevated center home button with label ──
            Positioned(
              top: 0,
              child: _buildCenterButton(context, currentIndex == 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    int index,
    IconData icon,
    String route,
    int currentIndex,
    String label,
  ) {
    final isActive = currentIndex == index;
    final color = isActive ? AppColors.accent : _inactiveIcon;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.go(route),
        child: SizedBox(
          height: _barHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: _iconSize, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterButton(BuildContext context, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => context.go('/home'),
          child: Container(
            width: _fabSize + _fabRingWidth * 2,
            height: _fabSize + _fabRingWidth * 2,
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: _fabSize,
                height: _fabSize,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.home_rounded,
                  size: 28,
                  color: AppColors.navyBrand,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Home',
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? AppColors.accent : _inactiveIcon,
          ),
        ),
      ],
    );
  }

  int _indexForLocation(String location) {
    if (location.startsWith('/search')) return 0;
    if (location.startsWith('/borrowed')) return 1;
    if (location.startsWith('/feedback')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 2; // /home and anything else
  }
}

typedef AppBottomNav = FloatingNavBar;