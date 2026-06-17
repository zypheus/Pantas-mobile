import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/borrowed_book.dart';
import '../../../models/user.dart';
import '../../../services/auth_service.dart';
import '../../../services/borrow_service.dart';
import '../../../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userService = UserService();
  final _authService = AuthService();
  final _borrowService = BorrowService();
  bool _isLoading = true;
  User? _user;
  List<BorrowedBook> _currentBooks = const [];
  List<BorrowedBook> _historyBooks = const [];
  int _borrowedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      final results = await Future.wait([
        _userService.getCurrentUser(),
        _borrowService.getCurrentBorrowedBooks(),
        _borrowService.getBorrowHistory(),
      ]);
      if (mounted) {
        setState(() {
          _user = results[0] as User;
          _currentBooks = results[1] as List<BorrowedBook>;
          _historyBooks = results[2] as List<BorrowedBook>;
          _isLoading = false;
        });
      }
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final userName = _user?.name.isNotEmpty == true ? _user!.name : 'User';
    final initials = userName
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(initials),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQrCard(),
                  const SizedBox(height: 24),
                  _buildBorrowedSection(),
                  const SizedBox(height: 24),
                  _buildSection('Account', [
                    _ProfileTile(
                      icon: Icons.edit_rounded,
                      label: 'Edit Profile',
                      onTap: () {},
                    ),
                    _ProfileTile(
                      icon: Icons.lock_outline_rounded,
                      label: 'Change Password',
                      onTap: _showChangePasswordDialog,
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _buildSection('Preferences', [
                    _ProfileTile(
                      icon: Icons.notifications_outlined,
                      label: 'Notification Settings',
                      onTap: () => context.go('/settings'),
                    ),
                  ]),
                  const SizedBox(height: 28),
                  _buildLogoutButton(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String initials) {
    final userName = _user?.name.isNotEmpty == true ? _user!.name : 'User';
    final email = _user?.email ?? '';
    final status = _user?.accountStatus ?? 'Active';

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    'Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 26,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: TextStyle(
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

  Widget _buildQrCard() {
    final studentNumber =
        _user?.studentNumber ?? _user?.studentId ?? 'Not linked';
    final courseYear = [
      _user?.course,
      _user?.year,
    ].where((value) => value != null && value.isNotEmpty).join(' - ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Library ID Card',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Tap to expand',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.qr_code_2_rounded,
              size: 100,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            studentNumber,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (courseYear.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              courseYear,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'Scan at the library desk',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildBorrowedSection() {
    final books = _borrowedTab == 0 ? _currentBooks : _historyBooks;
    final dateFormat = DateFormat('MMM d, yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'MY BOOKS',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(2),
              child: Row(
                children: [
                  _BorrowTabChip(
                    label: 'Current',
                    isSelected: _borrowedTab == 0,
                    onTap: () => setState(() => _borrowedTab = 0),
                  ),
                  _BorrowTabChip(
                    label: 'History',
                    isSelected: _borrowedTab == 1,
                    onTap: () => setState(() => _borrowedTab = 1),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (books.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.library_books_outlined,
                  size: 32,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 8),
                Text(
                  _borrowedTab == 0
                      ? 'No active loans'
                      : 'No borrowing history',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                for (int i = 0; i < books.length; i++) ...[
                  _buildBorrowedBookRow(books[i], dateFormat),
                  if (i < books.length - 1)
                    const Divider(
                      height: 1,
                      indent: 70,
                      color: AppColors.border,
                    ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBorrowedBookRow(BorrowedBook book, DateFormat dateFormat) {
    final isOverdue = book.isOverdue;
    final isReturned = book.isReturned;

    final Color statusColor;
    final IconData statusIcon;

    if (isReturned) {
      statusColor = AppColors.success;
      statusIcon = Icons.check_circle_rounded;
    } else if (isOverdue) {
      statusColor = AppColors.danger;
      statusIcon = Icons.warning_rounded;
    } else {
      statusColor = AppColors.warning;
      statusIcon = Icons.schedule_rounded;
    }

    final dateLabel = isReturned && book.returnedDate != null
        ? 'Returned ${dateFormat.format(book.returnedDate!)}'
        : 'Due ${dateFormat.format(book.dueDate)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  book.author,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateLabel,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(statusIcon, size: 18, color: statusColor),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              for (int i = 0; i < tiles.length; i++) ...[
                tiles[i],
                if (i < tiles.length - 1)
                  const Divider(height: 1, indent: 58, color: AppColors.border),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text(
          'Sign Out',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: BorderSide(color: AppColors.danger.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setDialogState) {
            Future<void> submit() async {
              final newPassword = newPasswordController.text;
              final confirmPassword = confirmPasswordController.text;

              if (currentPasswordController.text.isEmpty ||
                  newPassword.isEmpty ||
                  confirmPassword.isEmpty) {
                ScaffoldMessenger.of(builderContext).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all password fields.'),
                  ),
                );
                return;
              }

              if (newPassword != confirmPassword) {
                ScaffoldMessenger.of(builderContext).showSnackBar(
                  const SnackBar(content: Text('New passwords do not match.')),
                );
                return;
              }

              setDialogState(() => isSubmitting = true);

              try {
                await _userService.updatePassword(
                  currentPasswordController.text,
                  newPassword,
                );

                if (!mounted || !dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password changed. Please log in again.'),
                  ),
                );
                context.go('/login');
              } on ApiException catch (exception) {
                if (!mounted || !dialogContext.mounted) return;
                setDialogState(() => isSubmitting = false);
                ScaffoldMessenger.of(builderContext).showSnackBar(
                  SnackBar(content: Text(exception.validationSummary)),
                );
              } catch (_) {
                if (!mounted || !dialogContext.mounted) return;
                setDialogState(() => isSubmitting = false);
                ScaffoldMessenger.of(builderContext).showSnackBar(
                  const SnackBar(content: Text('Unable to change password.')),
                );
              }
            }

            return AlertDialog(
              backgroundColor: AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                'Change Password',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PasswordField(
                    controller: currentPasswordController,
                    label: 'Current password',
                    obscureText: obscureCurrent,
                    onToggle: () =>
                        setDialogState(() => obscureCurrent = !obscureCurrent),
                  ),
                  const SizedBox(height: 12),
                  _PasswordField(
                    controller: newPasswordController,
                    label: 'New password',
                    obscureText: obscureNew,
                    onToggle: () =>
                        setDialogState(() => obscureNew = !obscureNew),
                  ),
                  const SizedBox(height: 12),
                  _PasswordField(
                    controller: confirmPasswordController,
                    label: 'Confirm new password',
                    obscureText: obscureConfirm,
                    onToggle: () =>
                        setDialogState(() => obscureConfirm = !obscureConfirm),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isSubmitting ? null : submit,
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscureText,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _BorrowTabChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _BorrowTabChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textMuted,
        size: 20,
      ),
    );
  }
}
