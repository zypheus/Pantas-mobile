import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

/// Form to create a new teaching room and configure its settings.
class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedSubject;
  bool _isPrivate = true;
  bool _requiresApproval = true;

  final _subjects = [
    'Fundamentals of Nursing',
    'Pharmacology',
    'Pathophysiology',
    'Health Assessment',
  ];

  /// Dispose controllers when closing the screen to avoid memory leaks.
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Builds the create-room form and options UI.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Room'),
        backgroundColor: AppColors.navyBrand,
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildField(
                label: 'Room Name',
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(hintText: 'e.g. BSN 1A - Fundamentals'),
                ),
              ),
              const SizedBox(height: 16),
              _buildField(
                label: 'Description (optional)',
                child: TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(hintText: 'Add a short description...'),
                  maxLines: 3,
                ),
              ),
              const SizedBox(height: 16),
              _buildField(
                label: 'Select Subject',
                child: DropdownButtonFormField<String>(
                  value: _selectedSubject,
                  decoration: const InputDecoration(border: InputBorder.none, hintText: 'Choose a subject'),
                  items: _subjects
                      .map((subject) => DropdownMenuItem(value: subject, child: Text(subject)))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedSubject = value),
                ),
              ),
              const SizedBox(height: 16),
              _buildToggleOption(
                label: 'Privacy',
                child: Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('Public'),
                        value: false,
                        groupValue: _isPrivate,
                        onChanged: (value) => setState(() => _isPrivate = value ?? true),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('Private'),
                        value: true,
                        groupValue: _isPrivate,
                        onChanged: (value) => setState(() => _isPrivate = value ?? true),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildToggleOption(
                label: 'Join approval',
                child: SwitchListTile(
                  title: const Text('Require approval'),
                  value: _requiresApproval,
                  onChanged: (value) => setState(() => _requiresApproval = value),
                  activeColor: AppColors.navyBrand,
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
                  child: const Text('Create Room'),
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
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: child,
        ),
      ],
    );
  }

  Widget _buildToggleOption({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: child,
        ),
      ],
    );
  }
}
