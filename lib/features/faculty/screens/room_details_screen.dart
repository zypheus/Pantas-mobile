import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/status_badge.dart';

/// Detailed view for a single room, shows shared books and management actions.
class RoomDetailsScreen extends StatelessWidget {
  const RoomDetailsScreen({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navyBrand,
        title: const Text('Room Details'),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(),
              const SizedBox(height: 16),
              _buildSharedBooksCard(),
              const SizedBox(height: 16),
              Expanded(child: _buildActionRow(context)),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the card showing room metadata (name, description, student count, status).
  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.meeting_room_rounded, size: 24, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text('BSN 1A - Fundamentals', style: AppTextStyles.headingMedium.copyWith(fontSize: 18)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text('Active', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text('Description', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          const Text('This room is for sharing books and materials for BSN 1A.', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          Row(
            children: const [
              Icon(Icons.person_rounded, color: AppColors.textMuted, size: 18),
              SizedBox(width: 6),
              Text('25 students', style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the list of books currently shared in this room.
  Widget _buildSharedBooksCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Shared Books', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 14),
          _buildBookRow('Fundamentals of Nursing', 'Keizer, Barbara'),
          const SizedBox(height: 12),
          _buildBookRow('Nursing Care Plans', 'Nettina, Marion'),
          const SizedBox(height: 12),
          _buildBookRow('Dosage Calculations', 'Dimond, Linda'),
        ],
      ),
    );
  }

  /// Row widget for an individual shared book with status badge.
  Widget _buildBookRow(String title, String author) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.menu_book_rounded, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(author, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
        const StatusBadge(label: 'Available', color: AppColors.success),
      ],
    );
  }

  /// Action buttons for room management (share, add books, manage students).
  Widget _buildActionRow(BuildContext context) {
    return Column(
      children: [
        _ActionButton(
          label: 'Share Room',
          icon: Icons.share_rounded,
          onTap: () => context.go('/faculty/rooms/share?id=$roomId'),
        ),
        const SizedBox(height: 12),
        _ActionButton(
          label: 'Add Books',
          icon: Icons.library_add_rounded,
          onTap: () => context.go('/faculty/rooms/add-books'),
        ),
        const SizedBox(height: 12),
        _ActionButton(
          label: 'Manage Students',
          icon: Icons.groups_rounded,
          onTap: () => context.go('/faculty/rooms/manage?id=$roomId'),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.card,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          side: const BorderSide(color: AppColors.border),
        ),
        onPressed: onTap,
        icon: Icon(icon, color: AppColors.primary),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
