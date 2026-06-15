import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/section_title.dart';
import '../../../shared/models/mock_book.dart';
import '../../../features/catalog/widgets/book_result_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  List<MockBook> get _newArrivals => const [
        MockBook(
          id: '1',
          title: 'Introduction to Filipino Studies',
          author: 'Maria Dela Cruz',
          callNumber: 'QA 650 .D45',
          availability: 'Available',
          coverUrl: '',
          year: '2022',
          description: 'A modern guide to Philippine culture and literature.',
          copies: 5,
          isAvailable: true,
        ),
        MockBook(
          id: '2',
          title: 'Digital Libraries in Education',
          author: 'Juan Santos',
          callNumber: 'Z 678 .S26',
          availability: 'Available',
          coverUrl: '',
          year: '2023',
          description: 'Strategies for managing digital collections in schools.',
          copies: 3,
          isAvailable: true,
        ),
        MockBook(
          id: '3',
          title: 'Research Methods in Social Sciences',
          author: 'Elena Reyes',
          callNumber: 'H 62 .R49',
          availability: 'Available',
          coverUrl: '',
          year: '2023',
          description: 'Comprehensive guide to qualitative and quantitative methods.',
          copies: 2,
          isAvailable: true,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _GradientHeader(onSearchTap: () => context.go('/search')),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsRow(),
                  const SizedBox(height: 24),
                  _buildQuickActions(context),
                  const SizedBox(height: 24),
                  _buildReminderCard(),
                  const SizedBox(height: 24),
                  SectionTitle(
                    title: 'New Arrivals',
                    actionLabel: 'View all',
                    onAction: () => context.go('/search'),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 218,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _newArrivals.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        final book = _newArrivals[index];
                        return BookResultCard(
                          book: book,
                          onTap: () => context.go(
                            '/book_details?id=${book.id}',
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: '2',
            label: 'Active Loans',
            icon: Icons.library_books_rounded,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            value: '1',
            label: 'Due Soon',
            icon: Icons.schedule_rounded,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            value: '0',
            label: 'Overdue',
            icon: Icons.warning_amber_rounded,
            color: AppColors.danger,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickActionData(Icons.search_rounded, 'Catalog', '/search',
          const Color(0xFF4F46E5)),
      _QuickActionData(Icons.library_books_rounded, 'Borrowed', '/borrowed',
          const Color(0xFF059669)),
      _QuickActionData(Icons.meeting_room_rounded, 'Rooms',
          '/room_reservation', const Color(0xFF0EA5E9)),
      _QuickActionData(Icons.notifications_rounded, 'Alerts', '/notifications',
          const Color(0xFFF59E0B)),
      _QuickActionData(
          Icons.person_rounded, 'Profile', '/profile', AppColors.primary),
      _QuickActionData(
          Icons.feedback_rounded, 'Feedback', '/feedback', const Color(0xFFEC4899)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Access',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.0,
          children: actions
              .map((a) => _QuickActionCard(
                    icon: a.icon,
                    label: a.label,
                    color: a.color,
                    onTap: () => context.go(a.route),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildReminderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: AppColors.warning,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Due in 2 days',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF92400E),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  '"Research Methods" is due on June 17.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }
}

class _GradientHeader extends StatelessWidget {
  final VoidCallback onSearchTap;
  const _GradientHeader({required this.onSearchTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good afternoon 👋',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Ana Cruz',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: AppColors.accentGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'A',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: onSearchTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: Colors.white.withValues(alpha: 0.55),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Search books, authors, subjects…',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 14,
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
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionData {
  final IconData icon;
  final String label;
  final String route;
  final Color color;
  const _QuickActionData(this.icon, this.label, this.route, this.color);
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
