import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_exception.dart';
import '../../../models/user.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';
import '../../../shared/widgets/skeleton_loading.dart';
import '../../../shared/widgets/app_notify.dart';

/// Faculty-only profile — no student borrow/attendance/classroom tiles.
class FacultyProfileScreen extends StatefulWidget {
  const FacultyProfileScreen({super.key});

  @override
  State<FacultyProfileScreen> createState() => _FacultyProfileScreenState();
}

class _FacultyProfileScreenState extends State<FacultyProfileScreen> {
  static const Color _ink = Color(0xFF0C1130);
  static const Color _inkDeep = Color(0xFF070A1F);
  static const Color _inkSoft = Color(0xFF1B2354);
  static const Color _gold = Color(0xFFE8AC3E);
  static const Color _goldSoft = Color(0xFFF6D290);
  static const Color _paper = Color(0xFFF4F1E8);
  static const Color _cardLine = Color(0xFFE7E1D0);
  static const Color _slateSoft = Color(0xFF8A8CA3);
  static const Color _danger = Color(0xFFD9534F);

  final _userService = UserService();
  final _authService = AuthService();
  bool _isLoading = true;
  User? _user;

  @override
  void initState() {
    super.initState();
    final cached = _userService.currentUser;
    if (cached != null) {
      _user = cached;
      _isLoading = false;
    }
    _load(refresh: false);
  }

  Future<void> _load({bool refresh = false}) async {
    final hasCached = !refresh && _user != null;
    if (!hasCached) {
      setState(() => _isLoading = true);
    }

    try {
      final user = await _userService.getCurrentUser(refresh: refresh);
      if (!mounted) return;
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (exception.isUnauthenticated) {
        context.go('/login');
        return;
      }
      AppNotify.error(context, exception.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppNotify.error(context, 'Unable to load profile.');
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.logout();
      if (!mounted) return;
      context.go('/login');
    } catch (_) {
      if (!mounted) return;
      AppNotify.error(context, 'Failed to logout');
    }
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
                ],
              ),
            ),
          ],
        ),
      );
    }

    final userName = _user?.name.isNotEmpty == true ? _user!.name : 'Faculty';
    final initials = userName
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Scaffold(
      backgroundColor: _paper,
      body: RefreshIndicator(
        onRefresh: () => _load(refresh: true),
        color: _gold,
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(initials, userName),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader('ACCOUNT'),
                    const SizedBox(height: 10),
                    _infoCard([
                      _infoRow(
                        'Employee ID',
                        _user?.employeeId?.isNotEmpty == true
                            ? _user!.employeeId!
                            : '—',
                      ),
                      _infoRow(
                        'Department',
                        _user?.department?.isNotEmpty == true
                            ? _user!.department!
                            : '—',
                      ),
                      _infoRow(
                        'Designation',
                        _user?.designation?.isNotEmpty == true
                            ? _user!.designation!
                            : '—',
                      ),
                    ]),
                    const SizedBox(height: 28),
                    _sectionHeader('TEACHING'),
                    const SizedBox(height: 10),
                    _tile(
                      icon: Icons.class_rounded,
                      title: 'My Rooms',
                      subtitle: 'Manage classrooms and students',
                      onTap: () => context.go('/faculty/rooms'),
                    ),
                    _tile(
                      icon: Icons.folder_outlined,
                      title: 'My Folders',
                      subtitle: 'Book lists and recommendations',
                      onTap: () => context.go('/faculty/folders'),
                    ),
                    const SizedBox(height: 36),
                    SizedBox(
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
                    ),
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

  Widget _buildHeader(String initials, String userName) {
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
                  GestureDetector(
                    onTap: _showSettingsSheet,
                    child: Container(
                      width: 36,
                      height: 36,
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
      ),
    );
  }

  Widget _sectionHeader(String title) {
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

  Widget _infoCard(List<Widget> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardLine),
      ),
      child: Column(children: rows),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.publicSans(
                color: _slateSoft,
                fontSize: 13,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.publicSans(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: _ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardLine),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F1E8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _ink, size: 22),
        ),
        title: Text(
          title,
          style: GoogleFonts.publicSans(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: _ink,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.publicSans(
            color: _slateSoft,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: _slateSoft),
      ),
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
            color: _ink,
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
          color: Color(0xFF8A8CA3),
          size: 22,
        ),
      ),
    );
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _paper,
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
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF8A8CA3)),
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
                    context.push('/settings');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
