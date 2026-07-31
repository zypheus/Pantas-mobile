import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/faculty_classroom_service.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _service = FacultyClassroomService();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _subjectController = TextEditingController();
  bool _isPrivate = true;
  bool _requiresApproval = false;
  bool _saving = false;
  // Mode selector: when true we're creating a room, when false we're creating a folder
  bool _isCreatingRoom = true;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isCreatingRoom ? 'Room name is required.' : 'Folder name is required.')),
      );
      return;
    }

    // If the user is creating a folder, simulate creation and navigate back to folders.
    if (!_isCreatingRoom) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Folder created.')));
      // In a real implementation, call folder service to create then navigate.
      if (!mounted) return;
      context.go('/faculty/folders');
      return;
    }

    setState(() => _saving = true);
    try {
      final room = await _service.createClassroom(
        name: name,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        subject: _subjectController.text.trim().isEmpty
            ? null
            : _subjectController.text.trim(),
        isPrivate: _isPrivate,
        requiresApproval: _requiresApproval,
      );
      if (!mounted) return;
      context.go('/faculty/rooms/details?id=${room.id}');
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.validationSummary)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to create room.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isCreatingRoom ? 'Create Room' : 'Create Folder'),
        backgroundColor: AppColors.navyBrand,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Mode selector
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isCreatingRoom = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isCreatingRoom ? AppColors.card : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(child: Text('Room', style: TextStyle(fontWeight: FontWeight.w700, color: _isCreatingRoom ? AppColors.textPrimary : AppColors.textMuted))),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isCreatingRoom = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isCreatingRoom ? AppColors.card : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(child: Text('Folder', style: TextStyle(fontWeight: FontWeight.w700, color: !_isCreatingRoom ? AppColors.textPrimary : AppColors.textMuted))),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Common fields
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: _isCreatingRoom ? 'Room Name' : 'Folder Name', hintText: _isCreatingRoom ? 'e.g. BSN 1A - Fundamentals' : 'e.g. Pharmacology Books'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(labelText: 'Subject (optional)'),
            ),
            const SizedBox(height: 16),
            if (_isCreatingRoom) ...[
              SwitchListTile(
                title: const Text('Private room'),
                value: _isPrivate,
                onChanged: (v) => setState(() => _isPrivate = v),
              ),
              SwitchListTile(
                title: const Text('Require approval to join'),
                subtitle: const Text('Off = students join automatically'),
                value: _requiresApproval,
                onChanged: (v) => setState(() => _requiresApproval = v),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Creating...' : (_isCreatingRoom ? 'Create Room' : 'Create Folder')),
            ),
          ],
        ),
      ),
    );
  }
}
