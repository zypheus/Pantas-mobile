import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/skeleton_loading.dart';
import '../../../models/attendance_visit.dart';
import '../../../models/borrowed_book.dart';
import '../../../models/user.dart';
import '../../../services/attendance_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/borrow_service.dart';
import '../../../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Design tokens
  static const Color _ink = Color(0xFF0C1130);
  static const Color _inkDeep = Color(0xFF070A1F);
  static const Color _inkSoft = Color(0xFF1B2354);
  static const Color _gold = Color(0xFFE8AC3E);
  static const Color _goldSoft = Color(0xFFF6D290);
  static const Color _parchment = Color(0xFFFBF8F1);
  static const Color _paper = Color(0xFFF4F1E8);
  static const Color _cardLine = Color(0xFFE7E1D0);
  static const Color _slate = Color(0xFF3E4260);
  static const Color _slateSoft = Color(0xFF8A8CA3);
  static const Color _activeGreen = Color(0xFF2FBF83);
  static const Color _activeGreenBg = Color(0xFFE1F6EC);
  static const Color _danger = Color(0xFFD9534F);

  final _userService = UserService();
  final _authService = AuthService();
  final _borrowService = BorrowService();
  final _attendanceService = AttendanceService();
  bool _isLoading = true;
  User? _user;
  List<BorrowedBook> _currentBooks = const [];
  double _outstandingFinesTotal = 0;
  AttendancePreview? _attendancePreview;
  bool _isLoadingAttendance = true;

  @override
  void initState() {
    super.initState();
    final cachedUser = _userService.currentUser;
    if (cachedUser != null) {
      _user = cachedUser;
      _isLoading = false;
    }
    // Cache-first: reuse profile/borrow/attendance memory cache when available.
    _loadAll(refresh: false);
  }

  Future<void> _loadAll({bool refresh = false}) async {
    final hasCachedProfile = !refresh && _user != null;

    if (!hasCachedProfile) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final user = await _userService.getCurrentUser(refresh: refresh);
      final borrowOverview = await _borrowService.getBorrowOverview(
        refresh: refresh,
      );

      if (!mounted) return;

      setState(() {
        _user = user;
        _currentBooks = borrowOverview.activeLoans;
        _outstandingFinesTotal = borrowOverview.outstandingFinesTotal;
        _isLoading = false;
      });
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (exception.isUnauthenticated) {
        context.go('/login');
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(exception.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to load profile.')));
    }

    await _loadAttendance(refresh: refresh);
  }

  Future<void> _loadAttendance({bool refresh = false}) async {
    final hasCachedAttendance = !refresh && _attendancePreview != null;

    if (!hasCachedAttendance) {
      setState(() {
        _isLoadingAttendance = true;
      });
    }

    try {
      final preview = await _attendanceService.getAttendancePreview(
        refresh: refresh,
      );

      if (!mounted) return;

      setState(() {
        _attendancePreview = preview;
        _isLoadingAttendance = false;
      });
    } on ApiException catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingAttendance = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingAttendance = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.logout();
      if (!mounted) return;
      context.go('/login');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to logout')));
      }
    }
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _parchment,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Settings',
                      style: GoogleFonts.fraunces(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _ink,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: _slate),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSettingsTile(
                  icon: Icons.edit_rounded,
                  title: 'Edit profile',
                  subtitle: 'Update your personal details',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/profile/edit');
                  },
                ),
                const SizedBox(height: 8),
                _buildSettingsTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notification settings',
                  subtitle: 'Manage your notification channels',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/settings');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardLine, width: 1),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _paper,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: _ink),
        ),
        title: Text(
          title,
          style: GoogleFonts.publicSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _slate,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.publicSans(
            fontSize: 12,
            color: _slateSoft,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: _slateSoft,
          size: 22,
        ),
      ),
    );
  }

  void _showVisitsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _parchment,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final visits = _attendancePreview?.recentVisits ?? const [];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent visits',
                      style: GoogleFonts.fraunces(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _ink,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: _slate),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (visits.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.meeting_room_outlined,
                            size: 48,
                            color: _slateSoft,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No visits recorded yet. Your library check-ins will appear here once you scan your card at the desk.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.publicSans(
                              color: _slateSoft,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: visits.length,
                      separatorBuilder: (context, index) => const Divider(
                        color: _cardLine,
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final visit = visits[index];
                        final timeFormat = DateFormat('h:mm a');
                        final dateFormat = DateFormat('MMM d, yyyy');
                        final timeInStr = timeFormat.format(visit.timeIn);
                        final dateStr = dateFormat.format(visit.timeIn);

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: visit.isActive ? _activeGreenBg : _paper,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              visit.isActive
                                  ? Icons.access_time_rounded
                                  : Icons.check_circle_outline_rounded,
                              size: 18,
                              color: visit.isActive ? _activeGreen : _slate,
                            ),
                          ),
                          title: Text(
                            visit.isActive ? 'Currently in library' : dateStr,
                            style: GoogleFonts.publicSans(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: _ink,
                            ),
                          ),
                          subtitle: Text(
                            visit.isActive
                                ? 'Since $timeInStr'
                                : '$timeInStr – ${visit.timeOut != null ? timeFormat.format(visit.timeOut!) : ''}',
                            style: GoogleFonts.publicSans(
                              color: _slateSoft,
                              fontSize: 12,
                            ),
                          ),
                          trailing: !visit.isActive
                              ? Text(
                                  visit.durationText,
                                  style: GoogleFonts.publicSans(
                                    color: _slateSoft,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : null,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBooksBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _parchment,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final dateFormat = DateFormat('MMM d, yyyy');
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My books',
                      style: GoogleFonts.fraunces(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _ink,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: _slate),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                if (_outstandingFinesTotal > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Total dues: ${NumberFormat.currency(locale: 'en_PH', symbol: '₱').format(_outstandingFinesTotal)}',
                    style: GoogleFonts.publicSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _danger,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (_currentBooks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.library_books_outlined,
                            size: 48,
                            color: _slateSoft,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No active loans. Books you borrow from the library will appear here.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.publicSans(
                              color: _slateSoft,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _currentBooks.length,
                      separatorBuilder: (context, index) => const Divider(
                        color: _cardLine,
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final book = _currentBooks[index];
                        final isOverdue = book.isOverdue;
                        final isReturned = book.isReturned;
                        final currency = NumberFormat.currency(
                          locale: 'en_PH',
                          symbol: '₱',
                        );

                        final Color statusColor;
                        final IconData statusIcon;

                        if (isReturned) {
                          statusColor = _activeGreen;
                          statusIcon = Icons.check_circle_rounded;
                        } else if (isOverdue) {
                          statusColor = _danger;
                          statusIcon = Icons.warning_rounded;
                        } else {
                          statusColor = _gold;
                          statusIcon = Icons.schedule_rounded;
                        }

                        final dateLabel = isReturned && book.returnedDate != null
                            ? 'Returned ${dateFormat.format(book.returnedDate!)}'
                            : 'Due ${dateFormat.format(book.dueDate)}';

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          leading: Container(
                            width: 36,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _paper,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              color: _ink,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            book.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.publicSans(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: _ink,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                book.author,
                                style: GoogleFonts.publicSans(
                                  color: _slateSoft,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dateLabel,
                                style: GoogleFonts.publicSans(
                                  color: isOverdue ? _danger : _slateSoft,
                                  fontSize: 11,
                                  fontWeight: isOverdue
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                              if (book.fine > 0) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Due ${currency.format(book.fine)}',
                                  style: GoogleFonts.publicSans(
                                    color: _danger,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: Icon(statusIcon, size: 18, color: statusColor),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: SkeletonPage(
          children: [
            SkeletonCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(
                    height: 24,
                    width: 150,
                    margin: EdgeInsets.only(bottom: 16),
                  ),
                  SkeletonBox(
                    height: 80,
                    width: 80,
                    borderRadius: BorderRadius.all(Radius.circular(40)),
                    margin: EdgeInsets.only(bottom: 16),
                  ),
                  SkeletonLine(width: 200),
                  SizedBox(height: 24),
                  SkeletonCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonLine(width: double.infinity),
                        SizedBox(height: 12),
                        SkeletonLine(width: double.infinity),
                        SizedBox(height: 12),
                        SkeletonLine(width: 120),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final userName = _user?.name.isNotEmpty == true ? _user!.name : 'User';
    final initials = userName
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => _loadAll(refresh: true),
        color: _gold,
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(initials),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats cards
                    _buildLoanStatsRow(),
                    const SizedBox(height: 20),
                    // Quick shortcut cards
                    _buildQuickShortcutsRow(),
                    const SizedBox(height: 20),
                    // Eyebrow section header
                    _buildSectionHeader('LIBRARY'),
                    const SizedBox(height: 10),

                    // Library ID tile
                    PantasProfileTile(
                      icon: Icons.badge_rounded,
                      title: 'Library ID',
                      subtitle: _user?.studentNumber != null
                          ? _user!.studentNumber
                          : _user?.studentId ?? 'Not linked',
                      onTap: () => context.push('/profile/digital-id'),
                    ),

                    // Recent Visits tile
                    PantasProfileTile(
                      icon: Icons.history_rounded,
                      title: 'Recent visits',
                      subtitle: _isLoadingAttendance
                          ? 'Loading visits...'
                          : (_attendancePreview?.recentVisits.isEmpty == true
                              ? 'No visits recorded yet'
                              : 'View library visit logs'),
                      countBadge: _attendancePreview != null && _attendancePreview!.monthlyVisitCount > 0
                          ? '${_attendancePreview!.monthlyVisitCount}'
                          : null,
                      onTap: _showVisitsBottomSheet,
                    ),

                    // My Books tile
                    PantasProfileTile(
                      icon: Icons.menu_book_rounded,
                      title: 'My books',
                      subtitle: _myBooksSubtitle(),
                      countBadge: _currentBooks.isNotEmpty
                          ? '${_currentBooks.length}'
                          : null,
                      onTap: _showBooksBottomSheet,
                    ),

                    // My Reservations tile
                    PantasProfileTile(
                      icon: Icons.bookmark_border_rounded,
                      title: 'My reservations',
                      subtitle: 'View and manage book holds',
                      onTap: () => context.push('/book_reservations'),
                    ),

                    PantasProfileTile(
                      icon: Icons.assignment_outlined,
                      title: 'Assignments',
                      subtitle: 'Classroom activities and due work',
                      onTap: () => context.push('/assignments'),
                    ),

                    PantasProfileTile(
                      icon: Icons.class_rounded,
                      title: 'My classrooms',
                      subtitle: 'View joined faculty classrooms',
                      onTap: () => context.push('/classrooms'),
                    ),

                    PantasProfileTile(
                      icon: Icons.vpn_key_rounded,
                      title: 'Join classroom',
                      subtitle: 'Enter a faculty join code',
                      onTap: () => context.push('/classrooms/join'),
                    ),

                    const SizedBox(height: 36),
                    _buildSignOutButton(),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String initials) {
    final userName = _user?.name.isNotEmpty == true ? _user!.name : 'User';
    final email = _user?.email ?? '';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_inkSoft, _inkDeep],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Profile',
                    style: GoogleFonts.fraunces(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: _showSettingsSheet,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.settings_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_goldSoft, _gold],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 66,
                          height: 66,
                          decoration: const BoxDecoration(
                            color: _inkDeep,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: GoogleFonts.fraunces(
                                color: _gold,
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      userName,
                      style: GoogleFonts.fraunces(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: GoogleFonts.publicSans(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<BorrowedBook> get _dueSoonLoans {
    final today = _dateOnly(DateTime.now());

    return _currentBooks
        .where((loan) {
          if (loan.isOverdue || loan.isReturned) return false;
          final dueDate = _dateOnly(loan.dueDate);
          final daysUntilDue = dueDate.difference(today).inDays;
          return daysUntilDue >= 0 && daysUntilDue <= 3;
        })
        .toList(growable: false);
  }

  List<BorrowedBook> get _overdueLoans {
    return _currentBooks
        .where((loan) => loan.isOverdue && !loan.isReturned)
        .toList(growable: false);
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Widget _buildLoanStatsRow() {
    final dueSoonCount = _dueSoonLoans.length;
    final overdueCount = _overdueLoans.length;
    final isLoading = _isLoading;

    String statValue(int value) {
      if (isLoading) return '--';
      return value.toString();
    }

    return Row(
      children: [
        Expanded(
          child: _ProfileStatCard(
            value: statValue(_currentBooks.length),
            label: 'Active Loans',
            icon: Icons.library_books_rounded,
            color: _ink,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ProfileStatCard(
            value: statValue(dueSoonCount),
            label: 'Due Soon',
            icon: Icons.schedule_rounded,
            color: _gold,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ProfileStatCard(
            value: statValue(overdueCount),
            label: 'Overdue',
            icon: Icons.warning_amber_rounded,
            color: _danger,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickShortcutsRow() {
    return Row(
      children: [
        Expanded(
          child: _ProfileShortcutCard(
            icon: Icons.bookmark_border_rounded,
            label: 'My Reservations',
            subtitle: 'View book holds',
            color: _ink,
            onTap: () => context.push('/book_reservations'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ProfileShortcutCard(
            icon: Icons.assignment_turned_in_outlined,
            label: 'Borrow Requests',
            subtitle: 'Track approvals',
            color: _gold,
            onTap: () => context.push('/borrow_requests'),
          ),
        ),
      ],
    );
  }

  String _myBooksSubtitle() {
    if (_currentBooks.isEmpty) return 'No active loans';

    final loanLabel =
        '${_currentBooks.length} active ${_currentBooks.length == 1 ? 'loan' : 'loans'}';
    if (_outstandingFinesTotal <= 0) return loanLabel;

    final currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
    return '$loanLabel · ${currency.format(_outstandingFinesTotal)} due';
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.publicSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
        color: _slateSoft,
      ),
    );
  }

  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: Text(
          'Sign out',
          style: GoogleFonts.publicSans(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _danger,
          side: const BorderSide(color: _danger, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

// Stat card widget for loan stats
class _ProfileStatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _ProfileStatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF8A8CA3),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Shortcut card widget for quick actions
class _ProfileShortcutCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ProfileShortcutCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE7E1D0), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 1.5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF8A8CA3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Reusable list tile pattern
class PantasProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? countBadge;
  final VoidCallback onTap;

  const PantasProfileTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.countBadge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18), // 18px radius
        border: Border.all(color: const Color(0xFFE7E1D0), width: 1), // Hairline border
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F1E8), // Paper bg
            borderRadius: BorderRadius.circular(10), // 10px radius
          ),
          child: Icon(
            icon,
            size: 20,
            color: const Color(0xFF0C1130), // Ink color
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.publicSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3E4260), // Slate
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: GoogleFonts.publicSans(
                  fontSize: 12,
                  color: const Color(0xFF8A8CA3), // Slate soft
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (countBadge != null)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE1F6EC), // Active green bg
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  countBadge!,
                  style: GoogleFonts.publicSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2FBF83), // Active green
                  ),
                ),
              ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF8A8CA3), // Slate soft
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}