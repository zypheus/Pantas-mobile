import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/assignment.dart';
import '../../../models/classroom.dart';
import '../../../services/assignment_service.dart';
import '../../../services/student_classroom_service.dart';

class ClassroomDetailScreen extends StatefulWidget {
  final String classroomId;
  const ClassroomDetailScreen({super.key, required this.classroomId});

  @override
  State<ClassroomDetailScreen> createState() => _ClassroomDetailScreenState();
}

class _ClassroomDetailScreenState extends State<ClassroomDetailScreen> {
  final _service = StudentClassroomService();
  final _assignmentService = AssignmentService();
  ClassroomSummary? _classroom;
  List<AssignmentSummary> _assignments = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final classroom = await _service.getClassroom(widget.classroomId);
      final assignments =
          await _assignmentService.listClassroomAssignments(widget.classroomId);
      if (!mounted) return;
      setState(() {
        _classroom = classroom;
        _assignments = assignments;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final classroom = _classroom;
    return Scaffold(
      appBar: AppBar(
        title: Text(classroom?.name ?? 'Classroom'),
        actions: [
          if (classroom != null)
            IconButton(
              tooltip: 'Leave classroom',
              onPressed: () async {
                await _service.leaveClassroom(classroom.id);
                if (!context.mounted) return;
                context.pop();
              },
              icon: const Icon(Icons.exit_to_app_rounded),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : classroom == null
              ? const Center(child: Text('Classroom not found'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (classroom.facultyName != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.person_pin_circle_rounded,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Faculty: ${classroom.facultyName}',
                                style: const TextStyle(color: AppColors.textMuted),
                              ),
                            ),
                          ],
                        ),
                      if (classroom.description != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.notes_rounded,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(classroom.description!)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(
                            Icons.assignment_rounded,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Assignments',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_assignments.isEmpty)
                        const Text(
                          'No assignments yet.',
                          style: TextStyle(color: AppColors.textMuted),
                        )
                      else
                        ..._assignments.map(
                          (a) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.assignment_rounded,
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ),
                            title: Text(
                              a.title,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              [
                                if (a.dueAt != null)
                                  'Due ${a.dueAt!.month}/${a.dueAt!.day}',
                                a.mySubmission?.status ?? 'assigned',
                              ].join(' · '),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textMuted,
                            ),
                            onTap: () => context.push(
                              '/assignments/details?id=${Uri.encodeComponent(a.id)}',
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(
                            Icons.menu_book_rounded,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Recommended books',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (classroom.books.isEmpty)
                        const Text(
                          'No books shared yet.',
                          style: TextStyle(color: AppColors.textMuted),
                        )
                      else
                        ...classroom.books.map(
                          (book) => ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.menu_book_rounded,
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ),
                            title: Text(
                              book.title,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(book.author),
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textMuted,
                            ),
                            onTap: () => context.push(
                              '/book_details?id=${book.id}',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
