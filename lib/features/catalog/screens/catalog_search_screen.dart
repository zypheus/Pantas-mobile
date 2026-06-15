import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/mock_book.dart';
import '../widgets/book_result_card.dart';
import '../../catalog/widgets/catalog_filter_sheet.dart';

class CatalogSearchScreen extends StatefulWidget {
  const CatalogSearchScreen({super.key});

  @override
  State<CatalogSearchScreen> createState() => _CatalogSearchScreenState();
}

class _CatalogSearchScreenState extends State<CatalogSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedSegment = 0;

  static const List<MockBook> _mockBooks = [
    MockBook(
      id: '1',
      title: 'Library Science Essentials',
      author: 'Anna Reyes',
      callNumber: 'Z 675 .R49',
      availability: 'Available',
      coverUrl: '',
      year: '2023',
      description: 'Foundations and practice for modern libraries.',
      copies: 4,
      isAvailable: true,
    ),
    MockBook(
      id: '2',
      title: 'Philippine History for Students',
      author: 'Jose Rizal Jr.',
      callNumber: 'DS 653 .H58',
      availability: 'Checked Out',
      coverUrl: '',
      year: '2021',
      description: 'A user-friendly guide to local history.',
      copies: 0,
      isAvailable: false,
    ),
    MockBook(
      id: '3',
      title: 'Introduction to Filipino Studies',
      author: 'Maria Dela Cruz',
      callNumber: 'QA 650 .D45',
      availability: 'Available',
      coverUrl: '',
      year: '2022',
      description: 'A modern guide to Philippine culture and literature.',
      copies: 5,
      isAvailable: true,
    ),
  ];

  List<MockBook> get _filtered => _mockBooks
      .where(
        (b) =>
            b.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            b.author.toLowerCase().contains(_searchController.text.toLowerCase()),
      )
      .toList();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: results.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    itemCount: results.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final book = results[index];
                      return BookResultCard(
                        book: book,
                        onTap: () => context.go('/book_details?id=${book.id}'),
                      );
                    },
                  ),
          ),
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
              const Text(
                'Catalog',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
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
                        onChanged: (_) => setState(() {}),
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
                                    setState(() {});
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
                    onTap: () => setState(() => _selectedSegment = 0),
                  ),
                  const SizedBox(width: 8),
                  _SegmentChip(
                    label: 'E-Books',
                    isSelected: _selectedSegment == 1,
                    onTap: () => setState(() => _selectedSegment = 1),
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
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.12),
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
