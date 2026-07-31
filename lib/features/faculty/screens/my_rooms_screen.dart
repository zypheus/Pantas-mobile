import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Lists active rooms created by the teacher with quick access to details.
class MyRoomsScreen extends StatelessWidget {
  const MyRoomsScreen({super.key});

  static const _rooms = [
    {'name': 'BSN 1A - Fundamentals', 'subject': 'Fundamentals of Nursing', 'students': 26, 'status': 'Active'},
    {'name': 'Pharmacology Group', 'subject': 'Pharmacology', 'students': 18, 'status': 'Active'},
    {'name': 'NCO Review Session', 'subject': 'Nursing Care Plan', 'students': 15, 'status': 'Active'},
  ];

  /// Builds the rooms list UI and floating action to create new rooms.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navyBrand,
        title: const Text('My Rooms'),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/faculty/create-room'),
        icon: const Icon(Icons.group_add_rounded),
        label: const Text('Create Room'),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.navyBrand,
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(20),
          itemBuilder: (context, index) {
            final room = _rooms[index];
            return GestureDetector(
              onTap: () => context.go('/faculty/rooms/details?id=room-$index'),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(room['name'] as String, style: AppTextStyles.headingMedium.copyWith(fontSize: 16)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.successLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(room['status'] as String, style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(room['subject'] as String, style: AppTextStyles.bodySmall),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.person_rounded, size: 18, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text('${room['students']} students', style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemCount: _rooms.length,
        ),
      ),
    );
  }
}
