import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/book.dart';
import '../../../models/borrowed_book.dart';
import '../../../services/borrow_service.dart';
import '../../../services/catalog_service.dart';
import '../../../shared/widgets/section_title.dart';
import '../../../features/catalog/widgets/book_result_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _catalogService = CatalogService();
  final _borrowService = BorrowService();
  List<Book> _newArrivals = const [];
  List<BorrowedBook> _currentLoans = const [];
  bool _isLoadingNewArrivals = true;
  bool _isLoadingLoans = true;
  bool _loanStatsFailed = false;
  String? _newArrivalsError;

  @override
  void initState() {
    super.initState();
    _loadNewArrivals();
    _loadLoanStats();
  }

  Future<void> _loadNewArrivals() async {
    setState(() {
      _isLoadingNewArrivals = true;
      _newArrivalsError = null;
    });

    try {
      final books = await _catalogService.getNewArrivals(limit: 10);
      if (!mounted) return;
      setState(() {
        _newArrivals = books;
        _isLoadingNewArrivals = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _newArrivalsError = 'Unable to load new arrivals.';
        _isLoadingNewArrivals = false;
      });
    }
  }

  Future<void> _loadLoanStats() async {
    setState(() {
      _isLoadingLoans = true;
      _loanStatsFailed = false;
    });

    try {
      final loans = await _borrowService.getCurrentBorrowedBooks();
      if (!mounted) return;
      setState(() {
        _currentLoans = loans;
        _isLoadingLoans = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _currentLoans = const [];
        _loanStatsFailed = true;
        _isLoadingLoans = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final reminder = _loanStatsFailed ? null : _buildLoanReminder();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const _BannerHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsRow(),
                  if (reminder != null) ...[
                    const SizedBox(height: 24),
                    _buildReminderCard(reminder),
                  ],
                  const SizedBox(height: 24),
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
          ),
        ],
      ),
    );
  }

  Widget _buildNewArrivalsList(BuildContext context) {
    if (_isLoadingNewArrivals) {
      return _buildNewArrivalsSkeleton();
    }

    if (_newArrivalsError != null) {
      return SizedBox(
        height: 218,
        child: Center(
          child: TextButton.icon(
            onPressed: _loadNewArrivals,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(_newArrivalsError!),
          ),
        ),
      );
    }

    if (_newArrivals.isEmpty) {
      return const SizedBox(
        height: 218,
        child: Center(
          child: Text(
            'No new arrivals yet.',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    return SizedBox(
      height: 218,
      child: ListView.separated(
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
    );
  }

  Widget _buildNewArrivalsSkeleton() {
    return SizedBox(
      height: 218,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        padding: EdgeInsets.zero,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
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

  Widget _buildStatsRow() {
    final dueSoonCount = _dueSoonLoans.length;
    final overdueCount = _overdueLoans.length;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: _statValue(_currentLoans.length),
            label: 'Active Loans',
            icon: Icons.library_books_rounded,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            value: _statValue(dueSoonCount),
            label: 'Due Soon',
            icon: Icons.schedule_rounded,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            value: _statValue(overdueCount),
            label: 'Overdue',
            icon: Icons.warning_amber_rounded,
            color: AppColors.danger,
          ),
        ),
      ],
    );
  }

  String _statValue(int value) {
    if (_isLoadingLoans) return '--';
    if (_loanStatsFailed) return '0';
    return value.toString();
  }

  List<BorrowedBook> get _dueSoonLoans {
    final today = _dateOnly(DateTime.now());

    return _currentLoans
        .where((loan) {
          if (loan.isOverdue || loan.isReturned) return false;
          final dueDate = _dateOnly(loan.dueDate);
          final daysUntilDue = dueDate.difference(today).inDays;
          return daysUntilDue >= 0 && daysUntilDue <= 3;
        })
        .toList(growable: false);
  }

  List<BorrowedBook> get _overdueLoans {
    return _currentLoans
        .where((loan) => loan.isOverdue && !loan.isReturned)
        .toList(growable: false);
  }

  _LoanReminder? _buildLoanReminder() {
    if (_isLoadingLoans) return null;

    final overdue = [..._overdueLoans]
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    if (overdue.isNotEmpty) {
      final loan = overdue.first;
      final days = loan.daysOverdue;
      return _LoanReminder(
        title: days <= 1 ? 'Overdue by 1 day' : 'Overdue by $days days',
        message:
            '"${loan.title}" was due on ${_formatShortDate(loan.dueDate)}.',
        icon: Icons.warning_amber_rounded,
        color: AppColors.danger,
        iconBackground: AppColors.danger.withValues(alpha: 0.15),
        gradientColors: const [Color(0xFFFEF2F2), Color(0xFFFEE2E2)],
        textColor: const Color(0xFF991B1B),
        messageColor: const Color(0xFFB91C1C),
      );
    }

    final dueSoon = [..._dueSoonLoans]
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    if (dueSoon.isEmpty) return null;

    final loan = dueSoon.first;
    return _LoanReminder(
      title: _dueSoonTitle(loan.dueDate),
      message: '"${loan.title}" is due on ${_formatShortDate(loan.dueDate)}.',
      icon: Icons.schedule_rounded,
      color: AppColors.warning,
      iconBackground: AppColors.warning.withValues(alpha: 0.15),
      gradientColors: const [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
      textColor: const Color(0xFF92400E),
      messageColor: const Color(0xFFB45309),
    );
  }

  String _dueSoonTitle(DateTime dueDate) {
    final daysUntilDue = _dateOnly(
      dueDate,
    ).difference(_dateOnly(DateTime.now())).inDays;

    return switch (daysUntilDue) {
      0 => 'Due today',
      1 => 'Due tomorrow',
      _ => 'Due in $daysUntilDue days',
    };
  }

  String _formatShortDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Widget _buildReminderCard(_LoanReminder reminder) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: reminder.gradientColors,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: reminder.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: reminder.iconBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(reminder.icon, color: reminder.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: reminder.textColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  reminder.message,
                  style: TextStyle(fontSize: 13, color: reminder.messageColor),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: reminder.color),
        ],
      ),
    );
  }
}

class _LoanReminder {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final Color iconBackground;
  final List<Color> gradientColors;
  final Color textColor;
  final Color messageColor;

  const _LoanReminder({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.iconBackground,
    required this.gradientColors,
    required this.textColor,
    required this.messageColor,
  });
}

class _BannerHeader extends StatelessWidget {
  const _BannerHeader();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SizedBox(
        width: double.infinity,
        height: 180,
        child: Image.asset(
          'assets/Bannernew.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            decoration: const BoxDecoration(gradient: AppColors.heroGradient),
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
