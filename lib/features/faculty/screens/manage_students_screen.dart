import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Screen for approving and managing students in a room.
class ManageStudentsScreen extends StatelessWidget {
  const ManageStudentsScreen({super.key});

  static const _students = [
    {'name': 'Jane Doe', 'status': 'Approved'},
    {'name': 'Mark Rivera', 'status': 'Pending'},
    {'name': 'Emilia Cruz', 'status': 'Approved'},
    {'name': 'Ken Adams', 'status': 'Approved'},
  ];

  /// Builds the student management list UI.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Students'),
        backgroundColor: AppColors.navyBrand,
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: _students.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final student = _students[index];
            final isPending = student['status'] == 'Pending';
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.surface,
                    child: const Icon(Icons.person_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(student['name'] as String, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isPending ? const Color(0xFFFFF4E5) : AppColors.successLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            student['status'] as String,
                            style: TextStyle(
                              color: isPending ? const Color(0xFFB45309) : AppColors.success,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isPending)
                    TextButton(
                      onPressed: () {},
                      child: const Text('Approve'),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
