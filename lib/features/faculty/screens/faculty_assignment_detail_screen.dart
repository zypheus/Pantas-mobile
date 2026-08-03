import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/assignment.dart';
import '../../../services/assignment_service.dart';

class FacultyAssignmentDetailScreen extends StatefulWidget {
  final String assignmentId;
  const FacultyAssignmentDetailScreen({super.key, required this.assignmentId});

  @override
  State<FacultyAssignmentDetailScreen> createState() =>
      _FacultyAssignmentDetailScreenState();
}

class _FacultyAssignmentDetailScreenState
    extends State<FacultyAssignmentDetailScreen> {
  final _service = AssignmentService();
  AssignmentSummary? _assignment;
  List<AssignmentSubmissionSummary> _submissions = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final assignment =
          await _service.getFacultyAssignment(widget.assignmentId);
      final submissions = await _service.getSubmissions(widget.assignmentId);
      if (!mounted) return;
      setState(() {
        _assignment = assignment;
        _submissions = submissions;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _complete(AssignmentSubmissionSummary row) async {
    final studentId = row.studentId;
    if (studentId == null) return;
    try {
      await _service.markSubmissionComplete(widget.assignmentId, studentId);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _reopen(AssignmentSubmissionSummary row) async {
    final studentId = row.studentId;
    if (studentId == null) return;
    try {
      await _service.reopenSubmission(widget.assignmentId, studentId);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignment = _assignment;
    return Scaffold(
      appBar: AppBar(
        title: Text(assignment?.title ?? 'Assignment'),
        backgroundColor: AppColors.navyBrand,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : assignment == null
              ? const Center(child: Text('Assignment not found'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      if (assignment.dueAt != null)
                        Text(
                          'Due ${_formatDate(assignment.dueAt!)}',
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      if (assignment.instructions != null) ...[
                        const SizedBox(height: 12),
                        Text(assignment.instructions!),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        'Books (${assignment.books.length})',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (assignment.books.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No books attached.',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        )
                      else
                        ...assignment.books.map(
                          (book) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.menu_book_rounded),
                            title: Text(book.title),
                            subtitle: Text(book.author),
                            onTap: () => context.push(
                              '/faculty/book_details?id=${Uri.encodeComponent(book.id)}',
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        'Submissions (${_submissions.length})',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      if (_submissions.isEmpty)
                        const Text(
                          'No students yet.',
                          style: TextStyle(color: AppColors.textMuted),
                        )
                      else
                        ..._submissions.map((row) {
                          return Card(
                            child: ListTile(
                              title: Text(row.studentName ?? 'Student'),
                              subtitle: Text(
                                [
                                  row.status,
                                  if (row.responseText != null &&
                                      row.responseText!.isNotEmpty)
                                    row.responseText!,
                                ].join(' · '),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: row.status == 'completed'
                                  ? TextButton(
                                      onPressed: () => _reopen(row),
                                      child: const Text('Reopen'),
                                    )
                                  : TextButton(
                                      onPressed: () => _complete(row),
                                      child: const Text('Complete'),
                                    ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
