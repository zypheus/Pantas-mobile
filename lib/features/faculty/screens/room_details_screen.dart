import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/assignment.dart';
import '../../../models/classroom.dart';
import '../../../services/assignment_service.dart';
import '../../../services/faculty_classroom_service.dart';

class RoomDetailsScreen extends StatefulWidget {
  final String classroomId;
  const RoomDetailsScreen({super.key, required this.classroomId});

  @override
  State<RoomDetailsScreen> createState() => _RoomDetailsScreenState();
}

class _RoomDetailsScreenState extends State<RoomDetailsScreen> {
  final _service = FacultyClassroomService();
  ClassroomSummary? _room;
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
      final room = await _service.getClassroom(widget.classroomId);
      if (!mounted) return;
      setState(() {
        _room = room;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.validationSummary;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load room.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final room = _room;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(room?.name ?? 'Room'),
        backgroundColor: AppColors.navyBrand,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : room == null
                  ? const Center(child: Text('Room not found'))
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        if (room.subject != null)
                          Text(room.subject!,
                              style: const TextStyle(color: AppColors.textMuted)),
                        if (room.description != null) ...[
                          const SizedBox(height: 8),
                          Text(room.description!),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          '${room.memberCount} students · ${room.pendingCount} pending · ${room.folderCount} folders',
                        ),
                        const SizedBox(height: 24),
                        _ActionTile(
                          icon: Icons.share_rounded,
                          title: 'Share join code',
                          onTap: () => context.push(
                            '/faculty/rooms/share?id=${room.id}',
                          ),
                        ),
                        _ActionTile(
                          icon: Icons.people_alt_rounded,
                          title: 'Manage students',
                          onTap: () => context.push(
                            '/faculty/rooms/manage?id=${room.id}',
                          ),
                        ),
                        _ActionTile(
                          icon: Icons.folder_shared_rounded,
                          title: 'Share a folder',
                          onTap: () => context.push(
                            '/faculty/rooms/add-books?id=${room.id}',
                          ),
                        ),
                        _ActionTile(
                          icon: Icons.assignment_rounded,
                          title: 'Create assignment',
                          onTap: () => context.push(
                            '/faculty/assignments/create?classroomId=${Uri.encodeComponent(room.id)}',
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Assignments',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        _AssignmentsPreview(classroomId: room.id),
                        const SizedBox(height: 16),
                        const Text(
                          'Shared folders',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        if (room.folders.isEmpty)
                          const Text(
                            'No folders shared yet.',
                            style: TextStyle(color: AppColors.textMuted),
                          )
                        else
                          ...room.folders.map(
                            (f) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.folder_rounded),
                              title: Text(f.name),
                              subtitle: Text('${f.bookCount} books'),
                              onTap: () => context.push(
                                '/faculty/folders/details?id=${f.id}',
                              ),
                            ),
                          ),
                      ],
                    ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _AssignmentsPreview extends StatefulWidget {
  final String classroomId;
  const _AssignmentsPreview({required this.classroomId});

  @override
  State<_AssignmentsPreview> createState() => _AssignmentsPreviewState();
}

class _AssignmentsPreviewState extends State<_AssignmentsPreview> {
  final _service = AssignmentService();
  List<AssignmentSummary> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items =
          await _service.listFacultyAssignments(widget.classroomId);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_items.isEmpty) {
      return const Text(
        'No assignments yet.',
        style: TextStyle(color: AppColors.textMuted),
      );
    }
    return Column(
      children: _items
          .take(5)
          .map(
            (a) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.assignment_outlined),
              title: Text(a.title),
              subtitle: Text(
                a.dueAt == null
                    ? '${a.completedCount}/${a.totalSubmissions} completed'
                    : 'Due ${a.dueAt!.month}/${a.dueAt!.day} · ${a.completedCount}/${a.totalSubmissions} done',
              ),
              onTap: () => context.push(
                '/faculty/assignments/details?id=${Uri.encodeComponent(a.id)}',
              ),
            ),
          )
          .toList(),
    );
  }
}
