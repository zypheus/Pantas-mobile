import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const List<Map<String, dynamic>> _notifications = [
    {
      'title': 'Due date reminder',
      'message': 'Your reserved book is due tomorrow.',
      'type': 'due',
      'isRead': false,
      'time': '2 hrs ago',
    },
    {
      'title': 'Overdue notice',
      'message': 'Return "Research Methods" to avoid fine.',
      'type': 'overdue',
      'isRead': false,
      'time': '5 hrs ago',
    },
    {
      'title': 'Room reservation update',
      'message': 'Your room reservation is pending approval.',
      'type': 'room',
      'isRead': true,
      'time': 'Yesterday',
    },
    {
      'title': 'Library announcement',
      'message': 'New hours available this weekend.',
      'type': 'announcement',
      'isRead': true,
      'time': '2 days ago',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((n) => !(n['isRead'] as bool)).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(context, unread),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              itemCount: _notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final note = _notifications[index];
                return _NotificationCard(
                  title: note['title'] as String,
                  message: note['message'] as String,
                  type: note['type'] as String,
                  isRead: note['isRead'] as bool,
                  time: note['time'] as String,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int unreadCount) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notifications',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$unreadCount new',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
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

class _NotificationCard extends StatelessWidget {
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final String time;

  const _NotificationCard({
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.time,
  });

  _NotificationStyle get _style {
    switch (type) {
      case 'overdue':
        return _NotificationStyle(
          icon: Icons.warning_amber_rounded,
          color: AppColors.danger,
          bgColor: AppColors.dangerLight,
        );
      case 'due':
        return _NotificationStyle(
          icon: Icons.schedule_rounded,
          color: AppColors.warning,
          bgColor: AppColors.warningLight,
        );
      case 'room':
        return _NotificationStyle(
          icon: Icons.meeting_room_rounded,
          color: const Color(0xFF0EA5E9),
          bgColor: const Color(0xFFE0F2FE),
        );
      default:
        return _NotificationStyle(
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
        color: isRead ? AppColors.card : AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isRead
              ? AppColors.border
              : s.color.withValues(alpha: 0.25),
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
                const SizedBox(height: 8),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
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
