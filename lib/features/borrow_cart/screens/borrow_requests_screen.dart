import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/borrow_service.dart';
import '../../../shared/widgets/primary_button.dart';

class BorrowRequestsScreen extends StatefulWidget {
  const BorrowRequestsScreen({super.key});

  @override
  State<BorrowRequestsScreen> createState() => _BorrowRequestsScreenState();
}

class _BorrowRequestsScreenState extends State<BorrowRequestsScreen> {
  final _borrowService = BorrowService();
  List<BorrowRequestSummary> _requests = const [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _cancellingId;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests({bool refresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final requests = await _borrowService.getBorrowRequests(refresh: refresh);
      if (!mounted) return;
      setState(() {
        _requests = requests;
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
        _errorMessage = 'Unable to load borrow requests.';
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelRequest(BorrowRequestSummary request) async {
    setState(() => _cancellingId = request.id);
    try {
      await _borrowService.cancelBorrowRequest(request.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Borrow request cancelled.')),
      );
      await _loadRequests(refresh: true);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _cancellingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Borrow Requests'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/profile'),
        ),
      ),
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => _loadRequests(refresh: true),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Text(_errorMessage!),
                            const SizedBox(height: 12),
                            PrimaryButton(
                              label: 'Retry',
                              onPressed: () => _loadRequests(refresh: true),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : _requests.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 120),
                          Center(
                            child: Text(
                              'No borrow requests yet.',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: _requests.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final request = _requests[index];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        request.status.toUpperCase(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      DateFormat('MMM d, h:mm a')
                                          .format(request.requestedAt),
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                if (request.staffNote != null &&
                                    request.staffNote!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    request.staffNote!,
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                ...request.items.map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '${item.author} · ${item.callNumber}',
                                          style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          item.status,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        if (item.rejectionReason != null &&
                                            item.rejectionReason!.isNotEmpty)
                                          Text(
                                            item.rejectionReason!,
                                            style: const TextStyle(
                                              color: AppColors.danger,
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (request.isPending) ...[
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _cancellingId == request.id
                                          ? null
                                          : () => _cancelRequest(request),
                                      child: Text(
                                        _cancellingId == request.id
                                            ? 'Cancelling...'
                                            : 'Cancel request',
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
