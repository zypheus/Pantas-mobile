import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

class FacultyFloatingNavBar extends StatelessWidget {
  const FacultyFloatingNavBar({super.key});

  static const double _barHeight = 76;
  static const double _fabSize = 56;
  static const double _iconSize = 24;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _indexForLocation(location);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding + 14),
      child: SizedBox(
        height: _barHeight + _fabSize / 2,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: _barHeight,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(34),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildItem(context, 0, Icons.dashboard_rounded, '/faculty_home', 'Dashboard', currentIndex),
                    _buildItem(context, 1, Icons.menu_book_rounded, '/faculty/catalog', 'Catalog', currentIndex),
                    const Spacer(),
                    _buildItem(context, 3, Icons.meeting_room_rounded, '/faculty/rooms', 'Rooms', currentIndex),
                    _buildItem(context, 4, Icons.person_rounded, '/faculty/profile', 'Profile', currentIndex),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              child: _buildCenterButton(context),
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
    String label,
    int currentIndex,
  ) {
    final isActive = currentIndex == index;
    final color = isActive ? AppColors.navyBrand : AppColors.textMuted;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.go(route),
        child: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: _iconSize, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterButton(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/faculty/create-room'),
      child: Container(
        width: _fabSize + 16,
        height: _fabSize + 16,
        decoration: const BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: _fabSize,
            height: _fabSize,
            decoration: const BoxDecoration(
              color: AppColors.navyBrand,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
          ),
        ),
      ),
    );
  }

  int _indexForLocation(String location) {
    if (location.startsWith('/faculty_home')) return 0;
    if (location.startsWith('/faculty/catalog')) return 1;
    if (location.startsWith('/faculty/rooms')) return 3;
    if (location.startsWith('/faculty/profile')) return 4;
    return -1;
  }
}
