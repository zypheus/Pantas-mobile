import 'package:flutter/material.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/classroom.dart';
import '../../../services/faculty_classroom_service.dart';
import '../../../shared/widgets/app_notify.dart';

/// Share an existing folder into a classroom (recommended books for students).
class AddBooksToRoomScreen extends StatefulWidget {
  final String classroomId;
  const AddBooksToRoomScreen({super.key, required this.classroomId});

  @override
  State<AddBooksToRoomScreen> createState() => _AddBooksToRoomScreenState();
}

class _AddBooksToRoomScreenState extends State<AddBooksToRoomScreen> {
  final _service = FacultyClassroomService();
  List<FacultyFolderSummary> _folders = const [];
  bool _loading = true;
  String? _sharingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final folders = await _service.getFolders();
      if (!mounted) return;
      setState(() {
        _folders = folders;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _share(FacultyFolderSummary folder) async {
    setState(() => _sharingId = folder.id);
    try {
      await _service.shareFolder(widget.classroomId, folder.id);
      if (!mounted) return;
      AppNotify.success(context, 'Shared "${folder.name}" to this room.');
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      AppNotify.error(context, e.validationSummary);
    } finally {
      if (mounted) setState(() => _sharingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Folder to Room'),
        backgroundColor: AppColors.navyBrand,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _folders.isEmpty
              ? const Center(
                  child: Text('Create a folder with books first.'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _folders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final folder = _folders[index];
                    final sharing = _sharingId == folder.id;
                    return ListTile(
                      tileColor: AppColors.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      leading: const Icon(
                        Icons.folder_rounded,
                        color: AppColors.navyBrand,
                      ),
                      title: Text(folder.name),
                      subtitle: Text('${folder.bookCount} books'),
                      trailing: sharing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : TextButton.icon(
                              onPressed: () => _share(folder),
                              icon: const Icon(Icons.share_rounded, size: 18),
                              label: const Text('Share'),
                            ),
                    );
                  },
                ),
    );
  }
}
