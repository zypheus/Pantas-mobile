import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Shows details for a specific folder and the list of contained books.
class FolderDetailsScreen extends StatelessWidget {
  const FolderDetailsScreen({super.key, required this.folderName});

  final String folderName;

  static const _books = [
    {'title': 'Pharmacology for Nurses', 'author': 'Lehne, Richard'},
    {'title': 'Drug Guide for Nurses', 'author': 'Adams, Howard'},
    {'title': 'Clinical Pharmacology', 'author': 'Lilley, Linda'},
    {'title': 'Principles of Pharmacology', 'author': 'Lowdermilk, Terry'},
  ];

  /// Builds the folder detail view showing description and books.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navyBrand,
        title: Text(folderName),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Description', style: AppTextStyles.headingMedium.copyWith(fontSize: 16)),
              const SizedBox(height: 8),
              Text('Books and resources for $folderName lectures and student assignments.', style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemBuilder: (context, index) {
                    final book = _books[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(book['title'] as String, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                Text(book['author'] as String, style: AppTextStyles.bodySmall),
                              ],
                            ),
                          ),
                          const StatusBadge(label: 'Available', color: AppColors.success),
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: _books.length,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.navyBrand),
                  onPressed: () {
                    context.go('/faculty/rooms/add-books');
                  },
                  child: const Text('Add Books'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const StatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha((0.16 * 255).round()),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
