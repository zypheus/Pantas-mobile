import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/classroom.dart';
import '../../../services/faculty_classroom_service.dart';
import '../../../shared/widgets/app_notify.dart';

class FolderDetailsScreen extends StatefulWidget {
  final String folderId;
  const FolderDetailsScreen({super.key, required this.folderId});

  @override
  State<FolderDetailsScreen> createState() => _FolderDetailsScreenState();
}

class _FolderDetailsScreenState extends State<FolderDetailsScreen> {
  final _service = FacultyClassroomService();
  FacultyFolderSummary? _folder;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final folder = await _service.getFolder(widget.folderId);
      if (!mounted) return;
      setState(() {
        _folder = folder;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final folder = _folder;
    return Scaffold(
      appBar: AppBar(
        title: Text(folder?.name ?? 'Folder'),
        backgroundColor: AppColors.navyBrand,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Add books from catalog',
            onPressed: () => context.push(
              '/faculty/catalog?folderId=${Uri.encodeComponent(widget.folderId)}',
            ),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : folder == null
              ? const Center(child: Text('Folder not found'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (folder.description != null) Text(folder.description!),
                    const SizedBox(height: 12),
                    Text('${folder.bookCount} books'),
                    const SizedBox(height: 16),
                    if (folder.books.isEmpty)
                      const Text(
                        'No books yet. Open Catalog and add books to this folder.',
                        style: TextStyle(color: AppColors.textMuted),
                      )
                    else
                      ...folder.books.map(
                        (book) => ListTile(
                          title: Text(book.title),
                          subtitle: Text(book.author),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () async {
                              try {
                                await _service.removeBookFromFolder(
                                  widget.folderId,
                                  book.id,
                                );
                                await _load();
                              } on ApiException catch (e) {
                                if (!context.mounted) return;
                                AppNotify.error(context, e.validationSummary);
                              }
                            },
                          ),
                          onTap: () => context.push(
                            '/faculty/book_details?id=${book.id}',
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}
