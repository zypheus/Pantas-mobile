import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_exception.dart';
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
    _loadAll(refresh: true);
  }

  Future<void> _loadAll({bool refresh = false}) async {
    setState(() {
      _isLoading = true;
    });

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

    await _loadAttendance(refresh: true);
  }

  Future<void> _loadAttendance({bool refresh = true}) async {
    setState(() {
      _isLoadingAttendance = true;
    });

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
        _attendancePreview = null;
        _isLoadingAttendance = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _attendancePreview = null;
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
        backgroundColor: _paper,
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
      backgroundColor: _paper,
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
                    _buildLibraryIdCard(),
                    const SizedBox(height: 32),
                    
                    // Eyebrow section header
                    _buildSectionHeader('LIBRARY'),
                    const SizedBox(height: 10),
                    
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

                    const SizedBox(height: 20),
                    _buildSectionHeader('ACCOUNT'),
                    const SizedBox(height: 10),
                    PantasProfileTile(
                      icon: Icons.edit_rounded,
                      title: 'Edit profile',
                      subtitle: 'Update your personal details',
                      onTap: () {},
                    ),

                    const SizedBox(height: 20),
                    _buildSectionHeader('PREFERENCES'),
                    const SizedBox(height: 10),
                    PantasProfileTile(
                      icon: Icons.notifications_outlined,
                      title: 'Notification settings',
                      subtitle: 'Manage your notification channels',
                      onTap: () => context.go('/settings'),
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
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
          child: Column(
            children: [
              // Title and Active status badge row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Profile',
                    style: GoogleFonts.fraunces(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _activeGreenBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: _activeGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Active',
                          style: GoogleFonts.publicSans(
                            color: _activeGreen,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              
              // Avatar circle with gold gradient
              Container(
                width: 84,
                height: 84,
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
                    width: 78,
                    height: 78,
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
                          fontSize: 26,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Scholar register serif name
              Text(
                userName,
                style: GoogleFonts.fraunces(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: GoogleFonts.publicSans(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLibraryIdCard() {
    final studentNumber = _user?.studentNumber ?? _user?.studentId ?? 'Not linked';
    final courseYear = [
      _user?.course,
      _user?.year,
    ].where((value) => value != null && value.isNotEmpty).join(' - ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/profile/digital-id'),
        borderRadius: BorderRadius.circular(4),
        child: ClipPath(
      clipper: const DieCutCardClipper(cutSize: 24),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: _parchment,
        ),
        child: Stack(
          children: [
            // Hairline border
            Positioned.fill(
              child: CustomPaint(
                painter: DieCutBorderPainter(cutSize: 24, color: _cardLine),
              ),
            ),
            
            // 4px gold foil strip along the top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 4,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_goldSoft, _gold, _goldSoft],
                  ),
                ),
              ),
            ),

            // Card content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'LIBRARY ID',
                        style: GoogleFonts.publicSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 1.6,
                          color: _slateSoft,
                        ),
                      ),
                      Text(
                        'Tap to open',
                        style: GoogleFonts.fraunces(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: _slate,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Framed QR Code
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _cardLine, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: _slate.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Container(
                      width: 140,
                      height: 140,
                      color: Colors.white,
                      child: const Icon(
                        Icons.qr_code_2_rounded,
                        size: 110,
                        color: _ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  
                  // Monospaced ID Number
                  Text(
                    studentNumber,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 16,
                      color: _ink,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  if (courseYear.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      courseYear,
                      style: GoogleFonts.publicSans(
                        fontSize: 13,
                        color: _slate,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  
                  // Italic caption
                  Text(
                    'Tap to view & save digital ID',
                    style: GoogleFonts.publicSans(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: _slateSoft,
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

// Die cut clipper for student library ID
class DieCutCardClipper extends CustomClipper<Path> {
  final double cutSize;
  const DieCutCardClipper({this.cutSize = 24.0});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width - cutSize, 0);
    path.lineTo(size.width, cutSize);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant DieCutCardClipper oldClipper) => oldClipper.cutSize != cutSize;
}

// Custom painter for die cut hairline border
class DieCutBorderPainter extends CustomPainter {
  final double cutSize;
  final Color color;

  DieCutBorderPainter({required this.cutSize, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width - cutSize, 0);
    path.lineTo(size.width, cutSize);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant DieCutBorderPainter oldDelegate) =>
      oldDelegate.cutSize != cutSize || oldDelegate.color != color;
}