import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/classroom.dart';
import '../../../services/faculty_classroom_service.dart';

class MyFoldersScreen extends StatefulWidget {
  const MyFoldersScreen({super.key});

  @override
  State<MyFoldersScreen> createState() => _MyFoldersScreenState();
}

class _MyFoldersScreenState extends State<MyFoldersScreen> {
  final _service = FacultyClassroomService();
  List<FacultyFolderSummary> _folders = const [];
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
      final folders = await _service.getFolders();
      if (!mounted) return;
      setState(() {
        _folders = folders;
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
        _error = 'Unable to load folders.';
        _loading = false;
      });
    }
  }

  Future<void> _createFolder() async {
    await context.push('/faculty/create-folder');
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.navyBrand,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: FloatingActionButton.extended(
          onPressed: _createFolder,
          icon: const Icon(Icons.create_new_folder_rounded),
          label: const Text(
            'Create Folder',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 6,
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: topInset + 8),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 18),
            child: Row(
              children: [
                _HeaderIcon(),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Folders',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.02,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Organize books to share with your rooms',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
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
              child: RefreshIndicator(
                onRefresh: _load,
                child: _buildBody(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Center(child: Text(_error!)),
          TextButton(onPressed: _load, child: const Text('Retry')),
        ],
      );
    }

    if (_folders.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 120),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.folder_open_rounded,
                  size: 48,
                  color: AppColors.primary,
                ),
                SizedBox(height: 12),
                Text(
                  'No folders yet',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Create a folder, add books, then share it to your rooms.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 140),
      itemCount: _folders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final folder = _folders[index];
        final theme = _FolderTheme.forIndex(index);
        return _FolderCard(
          folder: folder,
          theme: theme,
          onTap: () => context.push(
            '/faculty/folders/details?id=${folder.id}',
          ),
        );
      },
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.folder_rounded,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}

class _FolderTheme {
  final Color accent;
  final Color soft;

  const _FolderTheme({required this.accent, required this.soft});

  static const _palette = <(Color, Color)>[
    (Color(0xFFD97706), Color(0xFFFEF3C7)),
    (Color(0xFF7C3AED), Color(0xFFF3E8FF)),
    (Color(0xFF2563EB), Color(0xFFDBEAFE)),
    (Color(0xFF059669), Color(0xFFD1FAE5)),
  ];

  factory _FolderTheme.forIndex(int index) {
    final entry = _palette[index % _palette.length];
    return _FolderTheme(accent: entry.$1, soft: entry.$2);
  }
}

class _FolderCard extends StatelessWidget {
  final FacultyFolderSummary folder;
  final _FolderTheme theme;
  final VoidCallback onTap;

  const _FolderCard({
    required this.folder,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = (folder.description != null &&
            folder.description!.trim().isNotEmpty)
        ? folder.description!.trim()
        : 'Reading list';
    final bookLabel =
        '${folder.bookCount} ${folder.bookCount == 1 ? 'book' : 'books'}';
    final roomLabel =
        '${folder.classroomCount} ${folder.classroomCount == 1 ? 'room' : 'rooms'}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 112,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 5, color: theme.accent),
                ),
                Positioned(
                  right: -6,
                  top: 10,
                  bottom: 10,
                  child: Icon(
                    Icons.auto_stories_outlined,
                    size: 88,
                    color: theme.accent.withValues(alpha: 0.08),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: theme.soft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.folder_rounded,
                          color: theme.accent,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              folder.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _MetaPill(
                                  icon: Icons.menu_book_rounded,
                                  label: bookLabel,
                                  accent: theme.accent,
                                  soft: theme.soft,
                                ),
                                _MetaPill(
                                  icon: Icons.meeting_room_outlined,
                                  label: roomLabel,
                                  accent: theme.accent,
                                  soft: theme.soft,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.accent.withValues(alpha: 0.18),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: theme.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final Color soft;

  const _MetaPill({
    required this.icon,
    required this.label,
    required this.accent,
    required this.soft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: accent),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}
