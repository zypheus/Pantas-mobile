import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../services/faculty_classroom_service.dart';
import '../../../shared/widgets/app_notify.dart';

enum CreateMode { room, folder }

class CreateRoomScreen extends StatefulWidget {
  final CreateMode initialMode;

  const CreateRoomScreen({super.key, this.initialMode = CreateMode.room});

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
  late bool _isCreatingRoom;

  @override
  void initState() {
    super.initState();
    _isCreatingRoom = widget.initialMode == CreateMode.room;
  }

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
      AppNotify.info(
        context,
        _isCreatingRoom ? 'Room name is required.' : 'Folder name is required.',
      );
      return;
    }

    // If the user is creating a folder, call the folder creation service.
    if (!_isCreatingRoom) {
      setState(() => _saving = true);
      try {
        final folder = await _service.createFolder(
          name: name,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );
        if (!mounted) return;
        AppNotify.success(context, 'Folder created.');
        // Navigate to the new folder details using its id.
        context.go('/faculty/folders/details?id=${Uri.encodeComponent(folder.id)}');
        return;
      } on ApiException catch (e) {
        if (!mounted) return;
        AppNotify.error(context, e.validationSummary);
        return;
      } catch (_) {
        if (!mounted) return;
        AppNotify.error(context, 'Unable to create folder.');
        return;
      } finally {
        if (mounted) setState(() => _saving = false);
      }
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
      AppNotify.error(context, e.validationSummary);
    } catch (_) {
      if (!mounted) return;
      AppNotify.error(context, 'Unable to create room.');
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isCreatingRoom ? 'Create Room' : 'Create Folder',
                    style: AppTextStyles.headingLarge.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isCreatingRoom
                        ? 'Build a classroom and invite students to join.'
                        : 'Organize learning resources with a new book folder.',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isCreatingRoom = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: _isCreatingRoom ? const Color.fromARGB(31, 91, 117, 255) : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _isCreatingRoom ? AppColors.primary : AppColors.border,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Room',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: _isCreatingRoom ? AppColors.primary : AppColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isCreatingRoom = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: !_isCreatingRoom ? const Color.fromARGB(31, 91, 117, 255) : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: !_isCreatingRoom ? AppColors.primary : AppColors.border,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Folder',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: !_isCreatingRoom ? AppColors.primary : AppColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: _isCreatingRoom ? 'Room Name' : 'Folder Name',
                      hintText: _isCreatingRoom ? 'e.g. BSN 1A - Fundamentals' : 'e.g. Pharmacology Books',
                    ),
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
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'Creating...' : (_isCreatingRoom ? 'Create Room' : 'Create Folder')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
