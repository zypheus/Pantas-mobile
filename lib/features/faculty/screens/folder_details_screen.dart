import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/book.dart';
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

  static const _accents = <Color>[
    Color(0xFF7C3AED),
    Color(0xFF2563EB),
    Color(0xFF059669),
    Color(0xFFD97706),
  ];

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

  Future<void> _openCatalog() async {
    await context.push(
      '/faculty/catalog?folderId=${Uri.encodeComponent(widget.folderId)}',
    );
    if (mounted) await _load();
  }

  Future<void> _confirmRemove(Book book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove book'),
        content: Text('Remove "${book.title}" from this folder?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _service.removeBookFromFolder(widget.folderId, book.id);
      await _load();
      if (!mounted) return;
      AppNotify.success(context, 'Book removed from folder.');
    } on ApiException catch (e) {
      if (!mounted) return;
      AppNotify.error(context, e.validationSummary);
    }
  }

  @override
  Widget build(BuildContext context) {
    final folder = _folder;
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.navyBrand,
      body: Column(
        children: [
          SizedBox(height: topInset + 4),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 16, 16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    folder?.name ?? 'Folder',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.02,
                    ),
                  ),
                ),
                const Icon(
                  Icons.auto_stories_outlined,
                  color: Colors.white24,
                  size: 40,
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              clipBehavior: Clip.antiAlias,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : folder == null
                      ? const Center(child: Text('Folder not found'))
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 22, 16, 28),
                            children: [
                              _FolderIntro(
                                description: folder.description,
                                bookCount: folder.books.length,
                                onAddBooks: _openCatalog,
                              ),
                              const SizedBox(height: 18),
                              if (folder.books.isEmpty)
                                _EmptyBooks(onAddBooks: _openCatalog)
                              else
                                ...folder.books.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final book = entry.value;
                                  final accent =
                                      _accents[index % _accents.length];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _BookCard(
                                      book: book,
                                      accent: accent,
                                      onTap: () => context.push(
                                        '/faculty/book_details?id=${book.id}',
                                      ),
                                      onRemove: () => _confirmRemove(book),
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FolderIntro extends StatelessWidget {
  final String? description;
  final int bookCount;
  final VoidCallback onAddBooks;

  const _FolderIntro({
    required this.description,
    required this.bookCount,
    required this.onAddBooks,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = (description != null && description!.trim().isNotEmpty)
        ? description!.trim()
        : 'These resources will help you get started.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.bookmark_rounded,
                color: Color(0xFF6D28D9),
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Shared folder books',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.menu_book_rounded,
                    size: 14,
                    color: Color(0xFF6D28D9),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$bookCount ${bookCount == 1 ? 'book' : 'books'}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6D28D9),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onAddBooks,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add books'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyBooks extends StatelessWidget {
  final VoidCallback onAddBooks;
  const _EmptyBooks({required this.onAddBooks});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.library_books_outlined,
            size: 44,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          const Text(
            'No books yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add books from the catalog to share with this room.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onAddBooks,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add books'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final Book book;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _BookCard({
    required this.book,
    required this.accent,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final soft = Color.lerp(accent, Colors.white, 0.88) ?? accent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Container(width: 5, color: accent),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: soft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.menu_book_rounded,
                              color: accent,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  book.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.person_outline_rounded,
                                      size: 14,
                                      color: AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        book.author,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Material(
                            color: const Color(0xFFF3E8FF),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: onRemove,
                              child: const SizedBox(
                                width: 36,
                                height: 36,
                                child: Icon(
                                  Icons.remove_rounded,
                                  color: Color(0xFF6D28D9),
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
