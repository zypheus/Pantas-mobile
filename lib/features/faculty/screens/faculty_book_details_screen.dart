import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/book.dart';
import '../../../shared/widgets/skeleton_loading.dart';
import '../../../services/catalog_service.dart';
import '../widgets/folder_room_pickers.dart';

/// Detailed book view for faculty with tabs for details, summary and notes.
class FacultyBookDetailsScreen extends StatefulWidget {
  const FacultyBookDetailsScreen({
    super.key,
    required this.bookId,
    this.folderId,
  });

  final String bookId;
  final String? folderId;

  @override
  State<FacultyBookDetailsScreen> createState() =>
      _FacultyBookDetailsScreenState();
}

class _FacultyBookDetailsScreenState extends State<FacultyBookDetailsScreen>
    with SingleTickerProviderStateMixin {
  final _catalogService = CatalogService();
  late final TabController _tabController;
  BookDetails? _details;
  bool _isLoading = true;
  bool _isAdding = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookDetails({bool refresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final details =
          await _catalogService.getBookDetail(widget.bookId, refresh: refresh);
      if (!mounted) return;
      setState(() {
        _details = details;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load book details.';
        _isLoading = false;
      });
    }
  }

  Future<void> _onAddToFolder() async {
    if (_isAdding || _details == null) return;
    setState(() => _isAdding = true);
    try {
      await addBookToFolderFlow(
        context,
        bookId: _details!.book.id,
        preselectedFolderId: widget.folderId,
      );
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _onAddToRoom() async {
    if (_isAdding || _details == null) return;
    setState(() => _isAdding = true);
    try {
      await addBookToRoomFlow(context, bookId: _details!.book.id);
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const SkeletonPage(children: [
              SkeletonBox(
                height: 220,
                width: double.infinity,
                borderRadius: BorderRadius.all(Radius.circular(20)),
                margin: EdgeInsets.only(bottom: 20),
              ),
              SkeletonLine(width: double.infinity),
              SizedBox(height: 12),
              SkeletonLine(width: 220),
              SizedBox(height: 20),
              SkeletonBox(height: 44, width: double.infinity),
              SizedBox(height: 12),
              SkeletonBox(height: 44, width: double.infinity),
              SizedBox(height: 12),
              SkeletonBox(height: 44, width: double.infinity),
            ])
          : _errorMessage != null
              ? Center(
                  child: TextButton.icon(
                    onPressed: () => _loadBookDetails(refresh: true),
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(_errorMessage!),
                  ),
                )
              : Column(
                  children: [
                    _buildHeader(context),
                    _buildTabBar(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildHoldingsTab(),
                          _buildDescriptionTab(),
                          _buildMarcViewTab(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final details = _details!;
    final book = details.book;
    final description = details.description;

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      book.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withAlpha(220),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 110,
                    height: 150,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(76),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: _BookCover(coverUrl: book.coverImage),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          book.author,
                          style: TextStyle(
                            color: Colors.white.withAlpha(180),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildMetaRow('Main author', book.author),
                        const SizedBox(height: 8),
                        _buildMetaRow('Format', description.format),
                        const SizedBox(height: 8),
                        _buildMetaRow(
                          'Published',
                          description.published.isNotEmpty
                              ? description.published
                              : '${book.year}',
                        ),
                      ],
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

  Widget _buildMetaRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      indicatorColor: AppColors.accent,
      tabs: const [
        Tab(text: 'Details'),
        Tab(text: 'Summary'),
        Tab(text: 'Notes'),
      ],
    );
  }

  Widget _buildHoldingsTab() {
    final details = _details!;
    final hasPreselectedFolder =
        widget.folderId != null && widget.folderId!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Availability'),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoTile('Status', details.book.availability),
              _buildInfoTile(
                'Copies',
                '${details.book.availableCopies}/${details.book.totalCopies}',
              ),
            ],
          ),
          if (hasPreselectedFolder) ...[
            const SizedBox(height: 12),
            Text(
              'Adding from a folder — tap Add to Folder to place this book there.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.navyBrand,
              ),
              onPressed: _isAdding ? null : _onAddToFolder,
              child: _isAdding
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      hasPreselectedFolder
                          ? 'Add to this Folder'
                          : 'Add to Folder',
                    ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.navyBrand,
              ),
              onPressed: _isAdding ? null : _onAddToRoom,
              child: const Text('Add to Room'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionTab() {
    final description = _details!.description;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Description'),
          const SizedBox(height: 12),
          Text(
            description.generalNote,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildMarcViewTab() {
    return const Center(child: Text('Additional information available here.'));
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _BookCover extends StatelessWidget {
  final String? coverUrl;
  const _BookCover({required this.coverUrl});

  @override
  Widget build(BuildContext context) {
    if (coverUrl != null && coverUrl!.isNotEmpty) {
      return Image.network(
        coverUrl!,
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallbackCover(),
      );
    }
    return _fallbackCover();
  }

  Widget _fallbackCover() {
    return Container(
      color: AppColors.surface,
      child: const Icon(
        Icons.menu_book_rounded,
        size: 40,
        color: AppColors.primary,
      ),
    );
  }
}
