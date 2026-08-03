import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class FacultyCreateScreen extends StatelessWidget {
  const FacultyCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create'),
        backgroundColor: AppColors.navyBrand,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Create', style: AppTextStyles.headingLarge.copyWith(fontSize: 26)),
          const SizedBox(height: 8),
          Text(
            'Choose how you want to start.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Row(
              children: [
                Expanded(
                  child: _CreateOptionCard(
                    title: 'Create Room',
                    subtitle: 'Manage classrooms and students',
                    icon: Icons.group_add_rounded,
                    onTap: () => context.push('/faculty/create-room'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CreateOptionCard(
                    title: 'Create Folder',
                    subtitle: 'Book lists and recommendations',
                    icon: Icons.create_new_folder_rounded,
                    onTap: () => context.push('/faculty/create-folder'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _CreateOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: AppTextStyles.headingMedium.copyWith(fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
