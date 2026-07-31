import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

/// Form to create a new folder for organizing teaching resources.
class CreateFolderScreen extends StatefulWidget {
  const CreateFolderScreen({super.key});

  @override
  State<CreateFolderScreen> createState() => _CreateFolderScreenState();
}

class _CreateFolderScreenState extends State<CreateFolderScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedSubject;

  final _subjects = [
    'Fundamentals of Nursing',
    'Pharmacology',
    'Pathophysiology',
    'Health Assessment',
    'Maternal-Newborn Nursing',
  ];

  /// Dispose controllers when the widget is removed from the tree.
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Builds the create-folder form UI.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navyBrand,
        title: const Text('Create Folder'),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildField(label: 'Folder Name', child: TextField(controller: _nameController, decoration: const InputDecoration(hintText: 'e.g. Pharmacology Books'))),
              const SizedBox(height: 16),
              _buildField(label: 'Description (optional)', child: TextField(controller: _descriptionController, decoration: const InputDecoration(hintText: 'Add a short description...'), maxLines: 3)),
              const SizedBox(height: 16),
              _buildField(
                label: 'Select Subject',
                child: DropdownButtonFormField<String>(
                  value: _selectedSubject,
                  decoration: const InputDecoration(hintText: 'Choose subject'),
                  items: _subjects.map((subject) => DropdownMenuItem(value: subject, child: Text(subject))).toList(),
                  onChanged: (value) => setState(() => _selectedSubject = value),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.navyBrand),
                  onPressed: () {
                    context.pop();
                  },
                  child: const Text('Create Folder'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: child,
        ),
      ],
    );
  }
}
