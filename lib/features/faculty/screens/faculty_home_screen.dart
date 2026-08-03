import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/book.dart';
import '../../../services/catalog_service.dart';
import '../../../services/faculty_classroom_service.dart';
import '../../../services/user_service.dart';
import '../../../shared/widgets/section_title.dart';
import '../../catalog/widgets/book_result_card.dart';

/// Faculty dashboard for teachers — shows quick actions, stats and recommendations.
class FacultyHomeScreen extends StatefulWidget {
  const FacultyHomeScreen({super.key});

  @override
  State<FacultyHomeScreen> createState() => _FacultyHomeScreenState();
}

class _FacultyHomeScreenState extends State<FacultyHomeScreen> {
  final _catalogService = CatalogService();
  final _classroomService = FacultyClassroomService();
  bool _isLoading = true;
  String? _errorMessage;
  List<Book> _recommendedBooks = const [];
  // Dynamic stats
  bool _isStatsLoading = true;
  int _subjectsCount = 0;
  int _foldersCount = 0;
  int _roomsCount = 0;
  int _sharedBooksCount = 0;

  /// Initialize state and load initial recommendations.
  @override
  void initState() {
    super.initState();
    _loadRecommendations();
    _loadStats();
  }

  /// Loads dynamic counts for subjects, folders, rooms and shared books.
  Future<void> _loadStats() async {
    setState(() {
      _isStatsLoading = true;
    });

    try {
      final rooms = await _classroomService.getClassrooms();
      final folders = await _classroomService.getFolders();

      // Subjects: unique non-null subject values across classrooms
      final subjects = <String>{};
      for (final r in rooms) {
        if (r.subject != null && r.subject!.isNotEmpty) subjects.add(r.subject!);
      }

      // Shared books: sum of folder book counts
      var sharedBooks = 0;
      for (final f in folders) {
        sharedBooks += f.bookCount;
      }

      if (!mounted) return;
      setState(() {
        _roomsCount = rooms.length;
        _foldersCount = folders.length;
        _subjectsCount = subjects.length;
        _sharedBooksCount = sharedBooks;
        _isStatsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isStatsLoading = false;
      });
    }
  }

  /// Loads recommended books for the dashboard. If [refresh] is true, forces reload.
  Future<void> _loadRecommendations({bool refresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final books = await _catalogService.getNewArrivals(refresh: refresh);
      if (!mounted) return;
      setState(() {
        _recommendedBooks = books;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load recommendations.';
        _isLoading = false;
      });
    }
  }

  /// Returns a greeting string based on the current hour.
  String _greetingText() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  /// Builds the main dashboard UI for faculty users.
  @override
  Widget build(BuildContext context) {
    final user = UserService().currentUser;
    final name = user?.name.isNotEmpty == true ? user!.name : 'Faculty';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(name),
              const SizedBox(height: 16),
              _buildStatsSection(),
              const SizedBox(height: 16),
              _buildQuickActions(context),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SectionTitle(
                  title: 'Recommended Books',
                  actionLabel: 'View all',
                  onAction: () => context.go('/faculty/catalog'),
                ),
              ),
              const SizedBox(height: 12),
              _buildRecommendations(context),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SectionTitle(
                  title: 'Teaching shortcuts',
                ),
              ),
              const SizedBox(height: 12),
              _buildShortcutCards(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String name) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.dashboard_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Teacher Dashboard',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '${_greetingText()}, $name',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
        children: [
          _SummaryCard(label: 'My Subjects', value: _isStatsLoading ? '—' : '$_subjectsCount', icon: Icons.book_rounded),
          _SummaryCard(label: 'My Folders', value: _isStatsLoading ? '—' : '$_foldersCount', icon: Icons.folder_rounded),
          _SummaryCard(label: 'Active Rooms', value: _isStatsLoading ? '—' : '$_roomsCount', icon: Icons.groups_rounded),
          _SummaryCard(label: 'Shared Books', value: _isStatsLoading ? '—' : '$_sharedBooksCount', icon: Icons.menu_book_rounded),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = (constraints.maxWidth - 24) / 3;

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: itemWidth,
                child: _ActionTile(
                  label: 'Browse Catalog',
                  icon: Icons.menu_book_rounded,
                  onTap: () => context.go('/faculty/catalog'),
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _ActionTile(
                  label: 'Create Folder',
                  icon: Icons.create_new_folder_rounded,
                  onTap: () => context.go('/faculty/create-folder'),
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _ActionTile(
                  label: 'Create Room',
                  icon: Icons.group_add_rounded,
                  onTap: () => context.go('/faculty/create-room'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRecommendations(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Center(
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: AppColors.danger),
          ),
        ),
      );
    }

    if (_recommendedBooks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Text('No recommendations are available right now.'),
      );
    }

    return SizedBox(
      height: 240,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final book = _recommendedBooks[index];
          return SizedBox(
            width: 160,
            child: BookResultCard(
              book: book,
              onTap: () => context.go('/faculty/book_details?id=${Uri.encodeComponent(book.id)}'),
            ),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemCount: _recommendedBooks.length,
      ),
    );
  }

  Widget _buildShortcutCards(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: Row(
        children: [
          Expanded(
            child: _ShortcutCard(
              title: 'My Folders',
              subtitle: 'Organize books by subject or lesson',
              icon: Icons.folder_rounded,
              onTap: () => context.go('/faculty/folders'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ShortcutCard(
              title: 'My Rooms',
              subtitle: 'Manage classrooms and share resources',
              icon: Icons.groups_rounded,
              onTap: () => context.go('/faculty/rooms'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(4),
            blurRadius: 6,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: AppTextStyles.headingMedium.copyWith(fontSize: 18),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(32),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.accent, size: 20),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ShortcutCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: AppTextStyles.headingMedium.copyWith(fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
