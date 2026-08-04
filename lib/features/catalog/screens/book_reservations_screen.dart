import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/book_reservation.dart';
import '../../../services/reservation_service.dart';
import '../../../shared/widgets/app_notify.dart';
import '../../../shared/widgets/skeleton_loading.dart';

/// Screen that lists the current student's book reservations.
///
/// Active reservations (pending / ready) are shown first, followed by past
/// reservations (fulfilled / expired / cancelled). Each active reservation
/// can be cancelled (leaving the queue).
class BookReservationsScreen extends StatefulWidget {
  const BookReservationsScreen({super.key});

  @override
  State<BookReservationsScreen> createState() =>
      _BookReservationsScreenState();
}

class _BookReservationsScreenState extends State<BookReservationsScreen> {
  final _reservationService = ReservationService();
  List<BookReservation> _reservations = const [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _cancellingId;

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations({bool refresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final reservations = await _reservationService.getMyReservations(
        refresh: refresh,
      );
      if (!mounted) return;
      setState(() {
        _reservations = reservations;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.validationSummary;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load reservations.';
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelReservation(BookReservation reservation) async {
    setState(() => _cancellingId = reservation.id);

    try {
      await _reservationService.cancelReservation(reservation.id);
      if (!mounted) return;

      AppNotify.success(
        context,
        _reservationService.lastMessage ?? 'Reservation cancelled.',
      );
      await _loadReservations(refresh: true);
    } on ApiException catch (error) {
      if (!mounted) return;
      AppNotify.error(context, error.validationSummary);
    } catch (_) {
      if (!mounted) return;
      AppNotify.error(context, 'Unable to cancel reservation.');
    } finally {
      if (mounted) setState(() => _cancellingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _reservations.where((r) => r.isActive).toList();
    final past = _reservations.where((r) => !r.isActive).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Reservations'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/search'),
        ),
      ),
      body: _isLoading
          ? const SkeletonList(
              itemCount: 3,
              padding: EdgeInsets.all(20),
            )
          : _errorMessage != null
              ? _buildError()
              : _reservations.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: () => _loadReservations(refresh: true),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                        children: [
                          if (active.isNotEmpty) ...[
                            _buildSectionHeader(
                              'Active',
                              '${active.length} waiting',
                            ),
                            const SizedBox(height: 12),
                            ...active.map((r) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _ReservationCard(
                                    reservation: r,
                                    isCancelling: _cancellingId == r.id,
                                    onCancel: () => _cancelReservation(r),
                                    onTap: () => context.go(
                                      '/book_details?id=${r.bookId}',
                                    ),
                                  ),
                                )),
                          ],
                          if (past.isNotEmpty) ...[
                            if (active.isNotEmpty)
                              const SizedBox(height: 24),
                            _buildSectionHeader('History', '${past.length} past'),
                            const SizedBox(height: 12),
                            ...past.map((r) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _ReservationCard(
                                    reservation: r,
                                    isCancelling: false,
                                    onCancel: null,
                                    onTap: () => context.go(
                                      '/book_details?id=${r.bookId}',
                                    ),
                                  ),
                                )),
                          ],
                        ],
                      ),
                    ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bookmark_border_rounded,
              size: 36,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No reservations',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Books you reserve will appear here.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: AppColors.textMuted,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: () => _loadReservations(refresh: true),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A live countdown until the hold expires.
class _HoldExpiryCountdown extends StatefulWidget {
  final DateTime expiresAt;

  const _HoldExpiryCountdown({required this.expiresAt});

  @override
  State<_HoldExpiryCountdown> createState() => _HoldExpiryCountdownState();
}

class _HoldExpiryCountdownState extends State<_HoldExpiryCountdown> {
  @override
  void initState() {
    super.initState();
    _scheduleTick();
  }

  void _scheduleTick() {
    Future<void>.delayed(const Duration(seconds: 30), () {
      if (!mounted) return;
      setState(() {});
      _scheduleTick();
    });
  }

  String _formatRemaining() {
    final remaining = widget.expiresAt.difference(DateTime.now());
    if (remaining.isNegative) return 'Hold expired';

    final days = remaining.inDays;
    final hours = remaining.inHours.remainder(24);
    final minutes = remaining.inMinutes.remainder(60);

    if (days > 0) return '$days d ${hours}h remaining';
    if (hours > 0) return '${hours}h ${minutes}m remaining';
    return '${minutes}m remaining';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatRemaining(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.success,
      ),
    );
  }
}

/// A single reservation card showing book info, queue position, status,
/// and a cancel button (for active reservations).
class _ReservationCard extends StatelessWidget {
  final BookReservation reservation;
  final bool isCancelling;
  final VoidCallback? onCancel;
  final VoidCallback onTap;

  const _ReservationCard({
    required this.reservation,
    required this.isCancelling,
    required this.onCancel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isReady = reservation.isReady;
    final isPending = reservation.isPending;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isReady
                  ? AppColors.success.withValues(alpha: 0.3)
                  : AppColors.border,
              width: isReady ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reservation.bookTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reservation.bookAuthor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (reservation.callNumber.isNotEmpty)
                          Text(
                            reservation.callNumber,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              fontFamily: 'monospace',
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _StatusBadge(reservation: reservation),
                  const Spacer(),
                  if (isPending)
                    Text(
                      'Position #${reservation.queuePosition}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
              if (isReady) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reservation.expiresAt != null
                                  ? 'Visit the library desk to claim${reservation.heldCallNumber != null && reservation.heldCallNumber!.isNotEmpty ? ' copy ${reservation.heldCallNumber}' : ''} before ${DateFormat('MMM d, h:mm a').format(reservation.expiresAt!)}.'
                                  : 'Visit the library desk to claim your held copy.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (reservation.expiresAt != null) ...[
                              const SizedBox(height: 4),
                              _HoldExpiryCountdown(
                                expiresAt: reservation.expiresAt!,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (onCancel != null) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: OutlinedButton.icon(
                    onPressed: isCancelling ? null : onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: BorderSide(
                        color: AppColors.danger.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: isCancelling
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.danger,
                            ),
                          )
                        : const Icon(Icons.cancel_outlined, size: 18),
                    label: Text(
                      isCancelling ? 'Cancelling...' : 'Cancel reservation',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                'Reserved on ${DateFormat('MMM d, yyyy').format(reservation.reservedAt)}',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final BookReservation reservation;

  const _StatusBadge({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor;
    final bgColor = _statusBgColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            reservation.statusLabel,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  IconData get _statusIcon {
    if (reservation.isReady) return Icons.check_circle_rounded;
    if (reservation.isPending) return Icons.hourglass_top_rounded;
    if (reservation.isFulfilled) return Icons.done_all_rounded;
    if (reservation.isExpired) return Icons.schedule_outlined;
    if (reservation.isCancelled) return Icons.cancel_rounded;
    return Icons.info_outline_rounded;
  }

  Color get _statusColor {
    if (reservation.isReady) return AppColors.success;
    if (reservation.isPending) return AppColors.warning;
    if (reservation.isFulfilled) return AppColors.primary;
    if (reservation.isExpired) return AppColors.warning;
    if (reservation.isCancelled) return AppColors.danger;
    return AppColors.textMuted;
  }

  Color get _statusBgColor {
    if (reservation.isReady) return AppColors.successLight;
    if (reservation.isPending) return AppColors.warningLight;
    if (reservation.isFulfilled) return AppColors.primary.withValues(alpha: 0.1);
    if (reservation.isExpired) return AppColors.warningLight;
    if (reservation.isCancelled) return AppColors.dangerLight;
    return AppColors.surface;
  }
}