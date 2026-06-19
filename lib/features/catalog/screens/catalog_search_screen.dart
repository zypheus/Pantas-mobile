import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/skeleton_loading.dart';
import '../../../models/book.dart';
import '../../../services/catalog_service.dart';
import '../widgets/book_result_card.dart';
import '../../catalog/widgets/catalog_filter_sheet.dart';

class CatalogSearchScreen extends StatefulWidget {
  const CatalogSearchScreen({super.key});

  @override
  State<CatalogSearchScreen> createState() => _CatalogSearchScreenState();
}

class _CatalogSearchScreenState extends State<CatalogSearchScreen> {
  final _catalogService = CatalogService();
  final TextEditingController _searchController = TextEditingController();
  int _selectedSegment = 0;
  List<Book> _results = const [];
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _searchDebounce;
  int _searchRequestId = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialResults();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialResults({bool refresh = false}) async {
    final requestId = ++_searchRequestId;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await _catalogService.getNewArrivals(
        limit: 20,
        refresh: refresh,
      );
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _errorMessage = 'Unable to load catalog.';
        _isLoading = false;
      });
    }
  }

  Future<void> _searchCatalog({bool refresh = false}) async {
    if (_searchController.text.trim().isEmpty && _selectedSegment == 0) {
      await _loadInitialResults(refresh: refresh);
      return;
    }

    final requestId = ++_searchRequestId;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await _catalogService.searchBooks(
        _searchController.text,
        format: _selectedSegment == 1 ? 'ebooks' : null,
        perPage: 20,
        refresh: refresh,
      );

      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _errorMessage = 'Unable to search catalog.';
        _isLoading = false;
      });
    }
  }

  void _scheduleSearch() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), _searchCatalog);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildResultsList()),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Catalog',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _HeaderIconButton(
                    icon: Icons.shopping_cart_outlined,
                    tooltip: 'Borrow cart',
                    onTap: () => context.go('/borrow_cart'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Search books, authors, subjects',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        onChanged: (_) => _scheduleSearch(),
                        decoration: InputDecoration(
                          hintText: 'Search…',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: Colors.white.withValues(alpha: 0.55),
                            size: 20,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    _loadInitialResults();
                                  },
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: Colors.white.withValues(alpha: 0.55),
                                    size: 18,
                                  ),
                                )
                              : null,
                          filled: false,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const CatalogFilterSheet(),
                    ),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        color: Colors.white.withValues(alpha: 0.85),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _SegmentChip(
                    label: 'Books',
                    isSelected: _selectedSegment == 0,
                    onTap: () {
                      setState(() => _selectedSegment = 0);
                      _searchCatalog();
                    },
                  ),
                  const SizedBox(width: 8),
                  _SegmentChip(
                    label: 'E-Books',
                    isSelected: _selectedSegment == 1,
                    onTap: () {
                      setState(() => _selectedSegment = 1);
                      _searchCatalog();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    if (_isLoading) {
      return const SkeletonList(
        itemCount: 5,
        padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: TextButton.icon(
          onPressed: () =>
              _searchController.text.trim().isEmpty && _selectedSegment == 0
              ? _loadInitialResults(refresh: true)
              : _searchCatalog(refresh: true),
          icon: const Icon(Icons.refresh_rounded),
          label: Text(_errorMessage!),
        ),
      );
    }

    if (_results.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      itemCount: _results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final book = _results[index];
        return BookResultCard(
          book: book,
          onTap: () => context.push('/book_details?id=${book.id}'),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 36,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No results found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try a different search term.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.85),
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _SegmentChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegmentChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: isSelected
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}
