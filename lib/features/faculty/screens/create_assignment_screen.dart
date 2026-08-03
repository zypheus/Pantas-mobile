import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/book.dart';
import '../../../services/assignment_service.dart';
import '../../../services/catalog_service.dart';
import '../../../services/faculty_classroom_service.dart';

class CreateAssignmentScreen extends StatefulWidget {
  final String classroomId;
  const CreateAssignmentScreen({super.key, required this.classroomId});

  @override
  State<CreateAssignmentScreen> createState() => _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState extends State<CreateAssignmentScreen> {
  final _assignmentService = AssignmentService();
  final _classroomService = FacultyClassroomService();
  final _catalogService = CatalogService();
  final _titleCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  DateTime? _dueAt;
  final Set<String> _selectedBookIds = {};
  List<Book> _candidateBooks = const [];
  bool _loadingBooks = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    setState(() => _loadingBooks = true);
    try {
      final room = await _classroomService.getClassroom(widget.classroomId);
      final books = <String, Book>{};
      for (final folder in room.folders) {
        final detail = await _classroomService.getFolder(folder.id);
        for (final book in detail.books) {
          books[book.id] = book;
        }
      }
      if (books.isEmpty) {
        final arrivals = await _catalogService.getNewArrivals();
        for (final book in arrivals) {
          books[book.id] = book;
        }
      }
      if (!mounted) return;
      setState(() {
        _candidateBooks = books.values.toList(growable: false);
        _loadingBooks = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingBooks = false);
    }
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _dueAt ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueAt ?? date.add(const Duration(hours: 23))),
    );
    if (!mounted) return;
    setState(() {
      _dueAt = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 23,
        time?.minute ?? 59,
      );
    });
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final created = await _assignmentService.createAssignment(
        classroomId: widget.classroomId,
        title: title,
        instructions: _instructionsCtrl.text.trim().isEmpty
            ? null
            : _instructionsCtrl.text.trim(),
        dueAt: _dueAt,
        bookIds: _selectedBookIds.toList(),
      );
      if (!mounted) return;
      context.pushReplacement(
        '/faculty/assignments/details?id=${Uri.encodeComponent(created.id)}',
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to create assignment.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create assignment'),
        backgroundColor: AppColors.navyBrand,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _instructionsCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Instructions (optional)',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Due date'),
            subtitle: Text(
              _dueAt == null
                  ? 'No due date'
                  : '${_dueAt!.year}-${_dueAt!.month.toString().padLeft(2, '0')}-${_dueAt!.day.toString().padLeft(2, '0')} '
                      '${_dueAt!.hour.toString().padLeft(2, '0')}:${_dueAt!.minute.toString().padLeft(2, '0')}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_dueAt != null)
                  IconButton(
                    onPressed: () => setState(() => _dueAt = null),
                    icon: const Icon(Icons.clear),
                  ),
                IconButton(
                  onPressed: _pickDueDate,
                  icon: const Icon(Icons.event),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Attach books (optional)',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (_loadingBooks)
            const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ))
          else if (_candidateBooks.isEmpty)
            const Text(
              'No books available. Share a folder to this room or browse the catalog later.',
              style: TextStyle(color: AppColors.textMuted),
            )
          else
            ..._candidateBooks.map((book) {
              final selected = _selectedBookIds.contains(book.id);
              return CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: selected,
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _selectedBookIds.add(book.id);
                    } else {
                      _selectedBookIds.remove(book.id);
                    }
                  });
                },
                title: Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text(book.author),
              );
            }),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.navyBrand,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create assignment'),
            ),
          ),
        ],
      ),
    );
  }
}
