import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class TimeSlotChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const TimeSlotChip({
    super.key,
    required this.label,
    required this.selected,
    this.enabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: enabled ? onTap : null,
      backgroundColor: selected
          ? AppColors.primary
          : enabled
          ? AppColors.card
          : AppColors.surface,
      labelStyle: TextStyle(
        color: selected
            ? Colors.white
            : enabled
            ? AppColors.textPrimary
            : AppColors.textMuted,
      ),
      elevation: 0,
    );
  }
}
