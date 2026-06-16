import 'package:flutter/material.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/borrow_service.dart';
import '../../../shared/widgets/primary_button.dart';

class BorrowCartScreen extends StatefulWidget {
  const BorrowCartScreen({super.key});

  @override
  State<BorrowCartScreen> createState() => _BorrowCartScreenState();
}

class _BorrowCartScreenState extends State<BorrowCartScreen> {
  final _borrowService = BorrowService();
  BorrowLimits? _limits;
  bool _isLoadingLimits = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadBorrowLimits();
  }

  Future<void> _loadBorrowLimits() async {
    try {
      final limits = await _borrowService.getBorrowLimits();
      if (!mounted) return;
      setState(() {
        _limits = limits;
        _isLoadingLimits = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingLimits = false;
      });
    }
  }

  Future<void> _submitRequest() async {
    final bookIds = _borrowService.getBorrowCart();
    if (bookIds.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _borrowService.submitCheckoutRequest(bookIds);
      if (!mounted) return;

      final rejected = _borrowService.lastRejectedReasons;
      final message = [
        _borrowService.lastCheckoutMessage ?? 'Borrow request submitted.',
        if (rejected.isNotEmpty) rejected.join('\n'),
      ].join('\n');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      setState(() {});
      await _loadBorrowLimits();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.validationSummary)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to submit borrow request.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _removeItem(String bookId) {
    setState(() {
      _borrowService.removeFromBorrowCart(bookId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = _borrowService.getBorrowCartItems();
    final maxLoans = _limits?.maxActiveLoans ?? 5;
    final remainingLoans = _limits?.remainingLoans ?? maxLoans;

    return Scaffold(
      appBar: AppBar(title: const Text('Borrow Cart')),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: cartItems.isEmpty
              ? const Center(
                  child: Text(
                    'Your borrow cart is empty.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                )
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        _isLoadingLimits
                            ? 'Checking your borrowing limit...'
                            : 'You may borrow up to $maxLoans items. $remainingLoans loan${remainingLoans == 1 ? '' : 's'} remaining.',
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView.separated(
                        itemCount: cartItems.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final book = cartItems[index];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 58,
                                  height: 82,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.book,
                                    color: AppColors.primary,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        book.displayTitle,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        book.displayAuthor,
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        book.displayCallNumber,
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: _isSubmitting
                                      ? null
                                      : () => _removeItem(book.bookId),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: AppColors.danger,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '${cartItems.length} of $maxLoans items selected',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: _isSubmitting ? 'Submitting...' : 'Submit Request',
                      enabled: !_isSubmitting && cartItems.isNotEmpty,
                      onPressed: _submitRequest,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
