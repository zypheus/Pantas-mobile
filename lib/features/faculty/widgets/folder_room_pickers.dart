import 'package:flutter/material.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/classroom.dart';
import '../../../services/faculty_classroom_service.dart';
import '../../../shared/widgets/app_notify.dart';

/// Picks a folder (or creates one), then adds [bookId] to it.
Future<bool> addBookToFolderFlow(
  BuildContext context, {
  required String bookId,
  String? preselectedFolderId,
  FacultyClassroomService? service,
}) async {
  final svc = service ?? FacultyClassroomService();

  try {
    if (preselectedFolderId != null && preselectedFolderId.isNotEmpty) {
      await svc.addBooksToFolder(preselectedFolderId, [bookId]);
      if (context.mounted) {
        AppNotify.success(context, 'Book added to folder.');
      }
      return true;
    }

    final folder = await showFolderPickerSheet(context, service: svc);
    if (folder == null) return false;

    await svc.addBooksToFolder(folder.id, [bookId]);
    if (context.mounted) {
      AppNotify.success(context, 'Added to "${folder.name}".');
    }
    return true;
  } on ApiException catch (e) {
    if (context.mounted) {
      AppNotify.error(context, e.message);
    }
    return false;
  } catch (_) {
    if (context.mounted) {
      AppNotify.error(context, 'Unable to add book to folder.');
    }
    return false;
  }
}

/// Picks a room, then a folder; adds [bookId] and shares the folder to the room.
Future<bool> addBookToRoomFlow(
  BuildContext context, {
  required String bookId,
  FacultyClassroomService? service,
}) async {
  final svc = service ?? FacultyClassroomService();

  try {
    final classroom = await showClassroomPickerSheet(context, service: svc);
    if (classroom == null || !context.mounted) return false;

    final folder = await showFolderPickerSheet(
      context,
      service: svc,
      title: 'Choose folder for ${classroom.name}',
    );
    if (folder == null || !context.mounted) return false;

    await svc.addBooksToFolder(folder.id, [bookId]);
    await svc.shareFolder(classroom.id, folder.id);

    if (context.mounted) {
      AppNotify.success(
        context,
        'Added to "${folder.name}" and shared with "${classroom.name}".',
      );
    }
    return true;
  } on ApiException catch (e) {
    if (context.mounted) {
      AppNotify.error(context, e.message);
    }
    return false;
  } catch (_) {
    if (context.mounted) {
      AppNotify.error(context, 'Unable to add book to room.');
    }
    return false;
  }
}

Future<FacultyFolderSummary?> showFolderPickerSheet(
  BuildContext context, {
  FacultyClassroomService? service,
  String title = 'Add to folder',
}) async {
  final svc = service ?? FacultyClassroomService();

  return showModalBottomSheet<FacultyFolderSummary>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return _FolderPickerSheet(
        service: svc,
        title: title,
      );
    },
  );
}

Future<ClassroomSummary?> showClassroomPickerSheet(
  BuildContext context, {
  FacultyClassroomService? service,
  String title = 'Add to room',
}) async {
  final svc = service ?? FacultyClassroomService();

  return showModalBottomSheet<ClassroomSummary>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return _ClassroomPickerSheet(service: svc, title: title);
    },
  );
}

class _FolderPickerSheet extends StatefulWidget {
  const _FolderPickerSheet({
    required this.service,
    required this.title,
  });

  final FacultyClassroomService service;
  final String title;

  @override
  State<_FolderPickerSheet> createState() => _FolderPickerSheetState();
}

class _FolderPickerSheetState extends State<_FolderPickerSheet> {
  List<FacultyFolderSummary> _folders = const [];
  bool _loading = true;
  bool _creating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final folders = await widget.service.getFolders();
      if (!mounted) return;
      setState(() {
        _folders = folders;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load folders.';
        _loading = false;
      });
    }
  }

  Future<void> _createFolder() async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('New folder'),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Folder name',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) => Navigator.pop(dialogContext, value.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, nameController.text.trim()),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (name == null || name.isEmpty || !mounted) return;

    setState(() => _creating = true);
    try {
      final folder = await widget.service.createFolder(name: name);
      if (!mounted) return;
      Navigator.pop(context, folder);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _creating = false);
      AppNotify.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _creating = false);
      AppNotify.error(context, 'Unable to create folder.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.55,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _creating ? null : _createFolder,
                      tooltip: 'Create folder',
                      icon: _creating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.create_new_folder_outlined),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(
                            child: TextButton(
                              onPressed: _load,
                              child: Text(_error!),
                            ),
                          )
                        : _folders.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'No folders yet.',
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextButton.icon(
                                        onPressed: _creating
                                            ? null
                                            : _createFolder,
                                        icon: const Icon(Icons.add),
                                        label: const Text('Create folder'),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.separated(
                                itemCount: _folders.length,
                                separatorBuilder: (_, _) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final folder = _folders[index];
                                  return ListTile(
                                    leading: const Icon(
                                      Icons.folder_outlined,
                                      color: AppColors.navyBrand,
                                    ),
                                    title: Text(folder.name),
                                    subtitle: Text(
                                      '${folder.bookCount} book${folder.bookCount == 1 ? '' : 's'}',
                                    ),
                                    onTap: () =>
                                        Navigator.pop(context, folder),
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassroomPickerSheet extends StatefulWidget {
  const _ClassroomPickerSheet({
    required this.service,
    required this.title,
  });

  final FacultyClassroomService service;
  final String title;

  @override
  State<_ClassroomPickerSheet> createState() => _ClassroomPickerSheetState();
}

class _ClassroomPickerSheetState extends State<_ClassroomPickerSheet> {
  List<ClassroomSummary> _rooms = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rooms = await widget.service.getClassrooms();
      if (!mounted) return;
      setState(() {
        _rooms = rooms;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load rooms.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.5,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: TextButton(
                            onPressed: _load,
                            child: Text(_error!),
                          ),
                        )
                      : _rooms.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'No rooms yet. Create a room first.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppColors.textMuted),
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: _rooms.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final room = _rooms[index];
                                return ListTile(
                                  leading: const Icon(
                                    Icons.class_outlined,
                                    color: AppColors.navyBrand,
                                  ),
                                  title: Text(room.name),
                                  subtitle: Text(
                                    room.subject?.isNotEmpty == true
                                        ? room.subject!
                                        : '${room.memberCount} students',
                                  ),
                                  onTap: () => Navigator.pop(context, room),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
