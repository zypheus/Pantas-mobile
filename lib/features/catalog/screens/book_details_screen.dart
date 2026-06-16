import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/book.dart';
import '../../../services/borrow_service.dart';
import '../../../services/catalog_service.dart';

class BookDetailsScreen extends StatefulWidget {
  final String bookId;
  const BookDetailsScreen({super.key, required this.bookId});

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen>
    with SingleTickerProviderStateMixin {
  final _catalogService = CatalogService();
  final _borrowService = BorrowService();
  late TabController _tabController;
  BookDetails? _details;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final details = await _catalogService.getBookDetail(widget.bookId);
      if (!mounted) return;
      setState(() {
        _details = details;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load book details.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: TextButton.icon(
                onPressed: _loadBookDetails,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(_errorMessage!),
              ),
            )
          : Column(
              children: [
                _buildHeader(context),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildHoldingsTab(),
                      _buildDescriptionTab(),
                      _buildMarcViewTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final details = _details!;
    final book = details.book;
    final description = details.description;

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      book.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 110,
                    height: 150,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: _BookCover(coverUrl: book.coverImage),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          book.author,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildMetaRow('Main author', book.author),
                        const SizedBox(height: 8),
                        _buildMetaRow('Format', description.format),
                        const SizedBox(height: 8),
                        _buildMetaRow(
                          'Published',
                          description.published.isNotEmpty
                              ? description.published
                              : '${book.year}',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.card,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        indicatorColor: AppColors.primary,
        indicatorWeight: 2.5,
        tabs: const [
          Tab(text: 'Holdings'),
          Tab(text: 'Description'),
          Tab(text: 'MARC View'),
        ],
      ),
    );
  }

  Widget _buildHoldingsTab() {
    final copies = _details!.copies;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              const Text(
                'Academic Library - Main stacks',
                style: TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (copies.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  'No holdings found.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            )
          else
            _buildHoldingsTable(copies),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _details!.book.isAvailable
                        ? _addBookToCart
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(
                      Icons.shopping_cart_outlined,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Add to Borrow Cart',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.bookmark_border_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHoldingsTable(List<BookCopy> copies) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppColors.surface),
            headingTextStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
            dataTextStyle: const TextStyle(
              fontSize: 11,
              color: AppColors.textPrimary,
            ),
            columnSpacing: 16,
            horizontalMargin: 14,
            dataRowMinHeight: 56,
            dataRowMaxHeight: 72,
            columns: const [
              DataColumn(label: Text('Accession #')),
              DataColumn(label: Text('Call #')),
              DataColumn(label: Text('Vol / Part #')),
              DataColumn(label: Text('Copy #')),
              DataColumn(label: Text('Collection')),
              DataColumn(label: Text('Shelving location')),
              DataColumn(label: Text('Circulation type')),
              DataColumn(label: Text('Circ. status')),
              DataColumn(label: Text('Barcode')),
              DataColumn(label: Text('RFID')),
              DataColumn(label: Text('Add to cart')),
            ],
            rows: copies.map((copy) {
              final isAvailable = copy.isAvailable;
              return DataRow(
                cells: [
                  DataCell(Text(copy.accessionNo)),
                  DataCell(
                    Text(
                      copy.callNumber,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                  DataCell(Text(copy.volume)),
                  const DataCell(Text('')),
                  DataCell(Text(copy.collection)),
                  DataCell(Text(copy.shelvingLocation)),
                  DataCell(Text(copy.circulationType)),
                  DataCell(_statusCell(copy.circulationStatus, isAvailable)),
                  DataCell(Text(copy.barcode)),
                  DataCell(Text(copy.rfid)),
                  DataCell(
                    SizedBox(
                      height: 34,
                      child: ElevatedButton(
                        onPressed: isAvailable
                            ? () => _addCopyToCart(copy)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.textMuted
                              .withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Add to cart',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _statusCell(String label, bool isAvailable) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAvailable ? AppColors.successLight : AppColors.dangerLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isAvailable ? AppColors.success : AppColors.danger,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildDescriptionTab() {
    final details = _details!;
    final book = details.book;
    final description = details.description;
    final about = description.generalNote.isNotEmpty
        ? description.generalNote
        : 'No description available.';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About this book',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            about,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 24),
          _buildDescRow('Title', book.title),
          _buildDescRow('Author', book.author),
          _buildDescRow('Published', description.published),
          _buildDescRow('Year', book.year == 0 ? '' : '${book.year}'),
          _buildDescRow('Format', description.format),
          _buildDescRow('Edition', description.edition),
          _buildDescRow('ISBN', description.isbn),
          _buildDescRow('Call Number', book.callNumber),
          _buildDescRow('Physical', description.physicalDescription),
          _buildDescRow('Bibliography', description.bibliography),
          _buildDescRow('Subject', description.subjectTopic),
          _buildDescRow('Genre', description.genre),
          _buildDescRow('Copies', '${book.totalCopies}'),
        ],
      ),
    );
  }

  Widget _buildDescRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarcViewTab() {
    final description = _details!.description;
    final marcFields = [
      ('020', 'ISBN', description.isbn),
      ('100', 'Main Entry - Personal Name', description.author),
      ('245', 'Title Statement', description.title),
      ('250', 'Edition Statement', description.edition),
      ('264', 'Production/Publication', description.published),
      ('300', 'Physical Description', description.physicalDescription),
      ('504', 'Bibliography Note', description.bibliography),
      ('650', 'Subject', description.subjectTopic),
      ('655', 'Genre/Form', description.genre),
    ].where((field) => field.$3.isNotEmpty).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: marcFields.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No MARC details available.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              )
            : Column(
                children: marcFields.indexed
                    .map(
                      (entry) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: entry.$1.isEven
                              ? Colors.transparent
                              : AppColors.surface.withValues(alpha: 0.5),
                          border: entry.$1 < marcFields.length - 1
                              ? const Border(
                                  bottom: BorderSide(color: AppColors.border),
                                )
                              : null,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                entry.$2.$1,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  fontFamily: 'monospace',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.$2.$2,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    entry.$2.$3,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
      ),
    );
  }

  void _addBookToCart() {
    _borrowService.addBookToBorrowCart(_details!.book);
    _showAddToCartMessage();
  }

  void _addCopyToCart(BookCopy copy) {
    _borrowService.addCopyToBorrowCart(copy, _details!.book);
    _showAddToCartMessage();
  }

  void _showAddToCartMessage() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Added to borrow cart.')));
  }
}

class _BookCover extends StatelessWidget {
  final String? coverUrl;

  const _BookCover({required this.coverUrl});

  @override
  Widget build(BuildContext context) {
    if (coverUrl != null && coverUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          coverUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallbackCover(),
        ),
      );
    }

    return Image.asset(
      'assets/defaultBook.png',
      width: 90,
      height: 110,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => _fallbackCover(),
    );
  }

  Widget _fallbackCover() {
    return const Icon(Icons.menu_book_rounded, size: 48, color: Colors.white);
  }
}
