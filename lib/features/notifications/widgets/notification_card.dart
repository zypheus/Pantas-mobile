import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class NotificationCard extends StatelessWidget {
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final String? time;
  final VoidCallback? onMarkAsRead;

  const NotificationCard({
    super.key,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.time,
    this.onMarkAsRead,
  });

  _NotificationStyle get _style {
    switch (type) {
      case 'borrow_overdue':
        return const _NotificationStyle(
          icon: Icons.warning_amber_rounded,
          color: AppColors.danger,
          bgColor: AppColors.dangerLight,
        );
      case 'borrow_due_soon':
        return const _NotificationStyle(
          icon: Icons.schedule_rounded,
          color: AppColors.warning,
          bgColor: AppColors.warningLight,
        );
      case 'room_reservation_approved':
        return const _NotificationStyle(
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
          bgColor: AppColors.successLight,
        );
      case 'room_reservation_rejected':
      case 'room_reservation_cancelled':
        return const _NotificationStyle(
          icon: Icons.cancel_rounded,
          color: AppColors.danger,
          bgColor: AppColors.dangerLight,
        );
      case 'room_reservation_pending':
        return const _NotificationStyle(
          icon: Icons.meeting_room_rounded,
          color: Color(0xFF0EA5E9),
          bgColor: Color(0xFFE0F2FE),
        );
      case 'book_reservation_pending':
        return const _NotificationStyle(
          icon: Icons.queue_rounded,
          color: Color(0xFF0EA5E9),
          bgColor: Color(0xFFE0F2FE),
        );
      case 'book_reservation_fulfilled':
        return const _NotificationStyle(
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
          bgColor: AppColors.successLight,
        );
      case 'borrow_request_submitted':
      case 'borrow_request_approved':
        return const _NotificationStyle(
          icon: Icons.library_books_rounded,
          color: AppColors.success,
          bgColor: AppColors.successLight,
        );
      case 'borrow_request_rejected':
        return const _NotificationStyle(
          icon: Icons.library_books_outlined,
          color: AppColors.danger,
          bgColor: AppColors.dangerLight,
        );
      case 'book_reservation_ready':
        return const _NotificationStyle(
          icon: Icons.notifications_active_rounded,
          color: AppColors.success,
          bgColor: AppColors.successLight,
        );
      case 'book_reservation_expired':
        return const _NotificationStyle(
          icon: Icons.schedule_outlined,
          color: AppColors.warning,
          bgColor: AppColors.warningLight,
        );
      case 'book_reservation_cancelled':
        return const _NotificationStyle(
          icon: Icons.cancel_rounded,
          color: AppColors.danger,
          bgColor: AppColors.dangerLight,
        );
      default:
        return const _NotificationStyle(
          icon: Icons.campaign_rounded,
          color: AppColors.primaryLight,
          bgColor: AppColors.surface,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isRead ? AppColors.border : s.color.withValues(alpha: 0.25),
          width: isRead ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: s.bgColor,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(s.icon, color: s.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: isRead
                              ? FontWeight.w500
                              : FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (!isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: s.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
                if (time != null && time!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    time!,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (!isRead && onMarkAsRead != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: onMarkAsRead,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: s.bgColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.done_rounded,
                              size: 14,
                              color: s.color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Mark as read',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: s.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationStyle {
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _NotificationStyle({
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}
