import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Lists teacher-created folders for organizing shared resources.
class MyFoldersScreen extends StatelessWidget {
  const MyFoldersScreen({super.key});

  static const _folders = [
    {'name': 'Pharmacology', 'count': 8},
    {'name': 'Pathophysiology', 'count': 7},
    {'name': 'Health Assessment', 'count': 6},
    {'name': 'Lecture Materials', 'count': 5},
  ];

  /// Builds the folders list screen UI.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navyBrand,
        title: const Text('My Folders'),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/faculty/create-folder'),
        icon: const Icon(Icons.create_new_folder_rounded),
        label: const Text('New Folder'),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.navyBrand,
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(20),
          itemBuilder: (context, index) {
            final folder = _folders[index];
            return GestureDetector(
              onTap: () => context.go('/faculty/folders/details?name=${Uri.encodeComponent(folder['name'] as String)}'),
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
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.folder_rounded, color: AppColors.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(folder['name'] as String, style: AppTextStyles.headingMedium.copyWith(fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('${folder['count']} books', style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                  ],
                ),
              ),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemCount: _folders.length,
        ),
      ),
    );
  }
}
