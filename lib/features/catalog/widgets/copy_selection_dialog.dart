import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/book.dart';

/// A bottom-sheet dialog that lets a student choose which specific copy of a
/// book to add to their borrow cart.
///
/// Shown when a book has **multiple** available copies. Each available copy
/// is listed with its accession number, call number, volume, collection,
/// shelving location, and circulation status so the student can pick the
/// exact physical copy they want to borrow.
class CopySelectionDialog extends StatelessWidget {
  final String bookTitle;
  final List<BookCopy> copies;

  const CopySelectionDialog({
    super.key,
    required this.bookTitle,
    required this.copies,
  });

  /// Convenience method to show the dialog as a modal bottom sheet.
  /// Returns the selected [BookCopy], or `null` if the user dismissed the
  /// sheet without choosing.
  static Future<BookCopy?> show(
    BuildContext context, {
    required String bookTitle,
    required List<BookCopy> copies,
  }) {
    return showModalBottomSheet<BookCopy>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CopySelectionDialog(
        bookTitle: bookTitle,
        copies: copies,
      ),
    );
  }

  List<BookCopy> get _availableCopies =>
      copies.where((copy) => copy.isAvailable).toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final available = _availableCopies;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.library_books_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select a copy',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            bookTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${available.length} available cop${available.length == 1 ? 'y' : 'ies'} — choose the one you want to borrow.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          // Copy list
          Flexible(
            child: available.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Text(
                      'No available copies.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shrinkWrap: true,
                    itemCount: available.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final copy = available[index];
                      return _CopyTile(
                        copy: copy,
                        copyNumber: index + 1,
                        onTap: () => Navigator.of(context).pop(copy),
                      );
                    },
                  ),
          ),
          // Cancel button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single copy row inside the selection dialog.
class _CopyTile extends StatelessWidget {
  final BookCopy copy;
  final int copyNumber;
  final VoidCallback onTap;

  const _CopyTile({
    required this.copy,
    required this.copyNumber,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Copy number badge + status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Copy #$copyNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      copy.circulationStatus.isNotEmpty
                          ? copy.circulationStatus
                          : 'Available',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Copy details grid
              _DetailChip(
                icon: Icons.numbers_rounded,
                label: 'Accession #',
                value: copy.accessionNo,
              ),
              const SizedBox(height: 10),
              _DetailChip(
                icon: Icons.menu_book_rounded,
                label: 'Call #',
                value: copy.callNumber,
                mono: true,
              ),
              if (copy.volume.isNotEmpty) ...[
                const SizedBox(height: 10),
                _DetailChip(
                  icon: Icons.inventory_2_rounded,
                  label: 'Volume',
                  value: copy.volume,
                ),
              ],
              if (copy.shelvingLocation.isNotEmpty) ...[
                const SizedBox(height: 10),
                _DetailChip(
                  icon: Icons.place_outlined,
                  label: 'Shelf location',
                  value: copy.shelvingLocation,
                ),
              ],
              if (copy.collection.isNotEmpty) ...[
                const SizedBox(height: 10),
                _DetailChip(
                  icon: Icons.folder_outlined,
                  label: 'Collection',
                  value: copy.collection,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool mono;

  const _DetailChip({
    required this.icon,
    required this.label,
    required this.value,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : '—',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
              fontFamily: mono ? 'monospace' : null,
            ),
          ),
        ),
      ],
    );
  }
}