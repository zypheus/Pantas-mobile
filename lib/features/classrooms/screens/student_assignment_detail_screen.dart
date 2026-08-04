import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/assignment.dart';
import '../../../services/assignment_service.dart';
import '../../../shared/widgets/app_notify.dart';

class StudentAssignmentDetailScreen extends StatefulWidget {
  final String assignmentId;
  const StudentAssignmentDetailScreen({super.key, required this.assignmentId});

  @override
  State<StudentAssignmentDetailScreen> createState() =>
      _StudentAssignmentDetailScreenState();
}

class _StudentAssignmentDetailScreenState
    extends State<StudentAssignmentDetailScreen> {
  final _service = AssignmentService();
  final _responseCtrl = TextEditingController();
  AssignmentSummary? _assignment;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _responseCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final assignment = await _service.getAssignment(widget.assignmentId);
      if (!mounted) return;
      setState(() {
        _assignment = assignment;
        _responseCtrl.text = assignment.mySubmission?.responseText ?? '';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      final text = _responseCtrl.text.trim();
      final updated = await _service.submitAssignment(
        widget.assignmentId,
        responseText: text.isEmpty ? null : text,
      );
      if (!mounted) return;
      setState(() => _assignment = updated);
      AppNotify.success(
        context,
        text.isEmpty ? 'Marked as done.' : 'Response submitted.',
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      AppNotify.error(context, e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _markDone() async {
    setState(() => _saving = true);
    try {
      final updated = await _service.completeAssignment(widget.assignmentId);
      if (!mounted) return;
      setState(() => _assignment = updated);
      AppNotify.success(context, 'Assignment marked done.');
    } on ApiException catch (e) {
      if (!mounted) return;
      AppNotify.error(context, e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignment = _assignment;
    final status = assignment?.mySubmission?.status ?? 'assigned';

    return Scaffold(
      appBar: AppBar(title: Text(assignment?.title ?? 'Assignment')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : assignment == null
              ? const Center(child: Text('Assignment not found'))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (assignment.classroomName != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.school_rounded,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              assignment.classroomName!,
                              style: const TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                        ],
                      ),
                    if (assignment.dueAt != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.event_rounded,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Due ${_formatDate(assignment.dueAt!)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.flag_rounded,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Status: $status',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    if (assignment.instructions != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.notes_rounded,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(assignment.instructions!)),
                        ],
                      ),
                    ],
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
                          'Books',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
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
                            '/book_details?id=${Uri.encodeComponent(book.id)}',
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.edit_note_rounded,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Your response (optional)',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _responseCtrl,
                      maxLines: 5,
                      enabled: status != 'completed',
                      decoration: const InputDecoration(
                        hintText: 'Write a short response…',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (status != 'completed') ...[
                      SizedBox(
                        height: 48,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _submit,
                          child: Text(
                            _responseCtrl.text.trim().isEmpty
                                ? 'Submit / Mark done'
                                : 'Submit response',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 48,
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _saving ? null : _markDone,
                          child: const Text('Mark done'),
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
