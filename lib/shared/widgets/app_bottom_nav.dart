import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    int currentIndex = 0;

    if (location.startsWith('/search')) {
      currentIndex = 1;
    } else if (location.startsWith('/borrowed')) {
      currentIndex = 2;
    } else if (location.startsWith('/notifications')) {
      currentIndex = 3;
    } else if (location.startsWith('/profile')) {
      currentIndex = 4;
    }

    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.fromLTRB(20, 8, 20, bottomPad + 14),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.45),
              blurRadius: 28,
              offset: const Offset(0, 10),
              spreadRadius: -4,
            ),
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.18),
              blurRadius: 56,
              offset: const Offset(0, 16),
              spreadRadius: -8,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _FloatingNavItem(
              icon: Icons.home_rounded,
              label: 'Home',
              isSelected: currentIndex == 0,
              onTap: () => context.go('/home'),
            ),
            _FloatingNavItem(
              icon: Icons.search_rounded,
              label: 'Search',
              isSelected: currentIndex == 1,
              onTap: () => context.go('/search'),
            ),
            _FloatingNavItem(
              icon: Icons.library_books_rounded,
              label: 'Borrowed',
              isSelected: currentIndex == 2,
              onTap: () => context.go('/borrowed'),
            ),
            _FloatingNavItem(
              icon: Icons.notifications_rounded,
              label: 'Alerts',
              isSelected: currentIndex == 3,
              onTap: () => context.go('/notifications'),
            ),
            _FloatingNavItem(
              icon: Icons.person_rounded,
              label: 'Profile',
              isSelected: currentIndex == 4,
              onTap: () => context.go('/profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FloatingNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent.withValues(alpha: 0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                icon,
                size: 23,
                color: isSelected
                    ? AppColors.accent
                    : Colors.white.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              width: isSelected ? 5 : 0,
              height: isSelected ? 5 : 0,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

typedef AppBottomNav = FloatingNavBar;
