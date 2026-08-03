import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/assignment.dart';
import '../../../models/book.dart';
import '../../../models/classroom.dart';
import '../../../services/assignment_service.dart';
import '../../../services/catalog_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/user_service.dart';
import '../../../shared/widgets/section_title.dart';
import '../../../features/catalog/widgets/book_result_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _catalogService = CatalogService();
  final _userService = UserService();
  final _notificationService = NotificationService();
  final _assignmentService = AssignmentService();
  List<Book> _newArrivals = const [];
  List<Book> _recommendations = const [];
  List<FacultyRecommendationGroup> _facultyRecommendations = const [];
  List<AssignmentSummary> _openAssignments = const [];
  String? _recommendationLabel;
  bool _isLoadingNewArrivals = true;
  bool _isLoadingRecommendations = true;
  String? _newArrivalsError;
  String? _recommendationsError;
  int _unreadNotificationCount = 0;
  final _recommendationScrollController = ScrollController();
  int _recommendationCurrentPage = 0;
  final _newArrivalsScrollController = ScrollController();
  int _newArrivalsCurrentPage = 0;

  @override
  void initState() {
    super.initState();
    _recommendationScrollController.addListener(_onRecommendationScroll);
    _newArrivalsScrollController.addListener(_onNewArrivalsScroll);
    _loadHomeOverview();
  }

  @override
  void dispose() {
    _recommendationScrollController.removeListener(_onRecommendationScroll);
    _recommendationScrollController.dispose();
    _newArrivalsScrollController.removeListener(_onNewArrivalsScroll);
    _newArrivalsScrollController.dispose();
    super.dispose();
  }

  void _onRecommendationScroll() {
    if (_recommendations.isEmpty) return;
    final position = _recommendationScrollController.position;
    const cardStep = 174.0;
    final viewportCenter = position.pixels + position.viewportDimension / 2;
    final index = (viewportCenter / cardStep).round();
    final clamped = index.clamp(0, _recommendations.length - 1);
    if (clamped != _recommendationCurrentPage) {
      setState(() {
        _recommendationCurrentPage = clamped;
      });
    }
  }

  void _onNewArrivalsScroll() {
    if (_newArrivals.isEmpty) return;
    final position = _newArrivalsScrollController.position;
    const cardStep = 174.0;
    final viewportCenter = position.pixels + position.viewportDimension / 2;
    final index = (viewportCenter / cardStep).round();
    final clamped = index.clamp(0, _newArrivals.length - 1);
    if (clamped != _newArrivalsCurrentPage) {
      setState(() {
        _newArrivalsCurrentPage = clamped;
      });
    }
  }

  Future<void> _loadHomeOverview({bool refresh = false}) async {
    setState(() {
      _isLoadingNewArrivals = true;
      _isLoadingRecommendations = true;
      _newArrivalsError = null;
      _recommendationsError = null;
      _recommendationLabel = null;
    });

    // Load unread notification count in parallel — non-blocking.
    _notificationService
        .getUnreadCount(refresh: refresh)
        .then((count) {
          if (!mounted) return;
          setState(() => _unreadNotificationCount = count);
        })
        .catchError((_) {
          // Silently ignore; badge simply won't update.
        });

    try {
      final overview = await _catalogService.getHomeOverview(refresh: refresh);
      if (!mounted) return;
      setState(() {
        _newArrivals = overview.newArrivals;
        _recommendations = overview.recommendedBooks;
        _facultyRecommendations = overview.facultyRecommendations;
        _recommendationLabel = overview.recommendationContext.displayLabel;
        _isLoadingNewArrivals = false;
        _isLoadingRecommendations = false;
      });

      _loadOpenAssignments();

      if (_recommendationLabel == null) {
        await _loadRecommendationLabelFallback();
      }

      if (_recommendations.isEmpty && refresh == false) {
        _loadRecommendationsFallback();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _newArrivalsError = 'Unable to load home data.';
        _isLoadingNewArrivals = false;
        _isLoadingRecommendations = false;
      });
    }
  }

  Future<void> _loadOpenAssignments() async {
    try {
      final items = await _assignmentService.listMyAssignments();
      if (!mounted) return;
      setState(() {
        _openAssignments = items
            .where((a) => a.mySubmission?.status != 'completed')
            .toList(growable: false);
      });
    } catch (_) {
      // Assignments section stays hidden on failure.
    }
  }

  Future<void> _loadRecommendationLabelFallback() async {
    try {
      final user = await _userService.getCurrentUser();
      if (!mounted) return;

      final course = user?.course;
      if (course == null || course.isEmpty) return;

      setState(() {
        _recommendationLabel ??= course;
      });
    } catch (_) {
      // Keep the generic title when profile is unavailable.
    }
  }

  Future<void> _loadRecommendationsFallback({bool refresh = false}) async {
    if (!mounted) return;

    setState(() {
      _isLoadingRecommendations = true;
      _recommendationsError = null;
    });

    try {
      final recommendations = await _catalogService.getRecommendations(
        refresh: refresh,
      );
      if (!mounted) return;
      setState(() {
        _recommendations = recommendations;
        _isLoadingRecommendations = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _recommendationsError = 'Unable to load recommendations.';
        _isLoadingRecommendations = false;
      });
    }
  }

  String get _recommendationsTitle {
    final label = _recommendationLabel;
    if (label == null || label.isEmpty) {
      return 'Recommended for You';
    }
    return 'Recommended for $label';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeHeader(context),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_openAssignments.isNotEmpty) ...[
                      SectionTitle(
                        title: 'Assignments',
                        actionLabel: 'View all',
                        onAction: () => context.push('/assignments'),
                      ),
                      const SizedBox(height: 10),
                      ..._openAssignments.take(3).map(
                        (a) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.assignment_outlined),
                            title: Text(a.title),
                            subtitle: Text(
                              [
                                if (a.classroomName != null) a.classroomName!,
                                if (a.dueAt != null)
                                  'Due ${a.dueAt!.month}/${a.dueAt!.day}',
                                a.mySubmission?.status ?? 'assigned',
                              ].join(' · '),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push(
                              '/assignments/details?id=${Uri.encodeComponent(a.id)}',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_facultyRecommendations.isNotEmpty) ...[
                      SectionTitle(
                        title: 'Recommended books by Faculty',
                        actionLabel: 'View all',
                        onAction: () => context.push('/faculty_recommendations'),
                      ),
                      const SizedBox(height: 14),
                      _buildFacultyRecommendationsPreview(context),
                      const SizedBox(height: 20),
                    ],
                    if (_recommendations.isNotEmpty ||
                        _isLoadingRecommendations ||
                        _recommendationsError != null) ...[
                      SectionTitle(
                        title: _recommendationsTitle,
                        actionLabel: 'View all',
                        onAction: () => context.go('/search'),
                      ),
                      const SizedBox(height: 14),
                      _buildRecommendationsList(context),
                      const SizedBox(height: 20),
                    ],
                    SectionTitle(
                      title: 'New Arrivals',
                      actionLabel: 'View all',
                      onAction: () => context.go('/search'),
                    ),
                    const SizedBox(height: 14),
                    _buildNewArrivalsList(context),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewArrivalsList(BuildContext context) {
    if (_isLoadingNewArrivals) {
      return _buildNewArrivalsSkeleton();
    }

    if (_newArrivalsError != null) {
      return SizedBox(
        height: 230,
        child: Center(
          child: TextButton.icon(
            onPressed: () => _loadHomeOverview(refresh: true),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(_newArrivalsError!),
          ),
        ),
      );
    }

    if (_newArrivals.isEmpty) {
      return const SizedBox(
        height: 230,
        child: Center(
          child: Text(
            'No new arrivals yet.',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 230,
          child: ListView.separated(
            controller: _newArrivalsScrollController,
            scrollDirection: Axis.horizontal,
            itemCount: _newArrivals.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final book = _newArrivals[index];
              return BookResultCard(
                book: book,
                onTap: () => context.push('/book_details?id=${book.id}'),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _buildNewArrivalsDots(),
      ],
    );
  }

  Widget _buildRecommendationsList(BuildContext context) {
    if (_isLoadingRecommendations) {
      return _buildRecommendationsSkeleton();
    }

    if (_recommendationsError != null) {
      return SizedBox(
        height: 230,
        child: Center(
          child: TextButton.icon(
            onPressed: () => _loadRecommendationsFallback(refresh: true),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(_recommendationsError!),
          ),
        ),
      );
    }

    if (_recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: 230,
          child: ListView.separated(
            controller: _recommendationScrollController,
            scrollDirection: Axis.horizontal,
            itemCount: _recommendations.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final book = _recommendations[index];
              return BookResultCard(
                book: book,
                onTap: () => context.push('/book_details?id=${book.id}'),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _buildRecommendationDots(),
      ],
    );
  }

  Widget _buildRecommendationDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_recommendations.length, (index) {
        final isActive = index == _recommendationCurrentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFFFCC00)
                : const Color(0xFF0B1740).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildFacultyRecommendationsPreview(BuildContext context) {
    final first = _facultyRecommendations.first;
    final books = first.books.take(8).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          first.classroom.name,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        if (_facultyRecommendations.length > 1)
          Text(
            '+ ${_facultyRecommendations.length - 1} more classroom${_facultyRecommendations.length > 2 ? 's' : ''}',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        const SizedBox(height: 10),
        SizedBox(
          height: 230,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: books.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final book = books[index];
              return BookResultCard(
                book: book,
                onTap: () => context.push('/book_details?id=${book.id}'),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNewArrivalsDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_newArrivals.length, (index) {
        final isActive = index == _newArrivalsCurrentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFFFCC00)
                : const Color(0xFF0B1740).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildRecommendationsSkeleton() {
    return SizedBox(
      height: 230,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        padding: EdgeInsets.zero,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          return Container(
            width: 160,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 100,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Container(
                      height: 24,
                      width: 70,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      height: 16,
                      width: 16,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNewArrivalsSkeleton() {
    return SizedBox(
      height: 230,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        padding: EdgeInsets.zero,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          return Container(
            width: 160,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 100,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Container(
                      height: 24,
                      width: 70,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      height: 16,
                      width: 16,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    final user = _userService.currentUser;
    final displayName = user?.firstName ?? user?.name ?? 'User';
    final greeting = _greeting();
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFFFCC00),
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyBrand,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              _buildNotificationBell(context),
            ],
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => context.go('/search'),
            child: Container(
              width: double.infinity,
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Search books, authors...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _buildNotificationBell(BuildContext context) {
    final hasUnread = _unreadNotificationCount > 0;
    final badgeLabel = _unreadNotificationCount > 9
        ? '9+'
        : '$_unreadNotificationCount';

    return GestureDetector(
      onTap: () => GoRouter.of(context).go('/notifications'),
      child: SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.notifications_rounded,
                color: AppColors.navyBrand,
                size: 18,
              ),
            ),
            if (hasUnread)
              Positioned(
                top: -2,
                right: 2,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.all(Radius.circular(9)),
                  ),
                  child: Center(
                    child: Text(
                      badgeLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}