import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/book.dart';
import '../../../models/book_reservation.dart';
import '../../../shared/widgets/skeleton_loading.dart';
import '../../../services/borrow_service.dart';
import '../../../services/catalog_service.dart';
import '../../../services/reservation_service.dart';
import '../widgets/copy_selection_dialog.dart';

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
  final _reservationService = ReservationService();
  late TabController _tabController;
  BookDetails? _details;
  BookReservation? _activeReservation;
  bool _isLoading = true;
  bool _isReserving = false;
  bool _isCancelling = false;
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

  Future<void> _loadBookDetails({bool refresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final details = await _catalogService.getBookDetail(
        widget.bookId,
        refresh: refresh,
      );
      if (!mounted) return;

      // Load active reservation so ready holds show desk-claim messaging.
      BookReservation? activeReservation;
      try {
        activeReservation =
            await _reservationService.getActiveReservationForBook(
          widget.bookId,
        );
      } catch (_) {
        // Ignore reservation lookup errors — the cart flow still works.
      }

      if (!mounted) return;
      setState(() {
        _details = details;
        _activeReservation = activeReservation;
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
          ? const SkeletonPage(
              children: [
                SkeletonBox(
                  height: 220,
                  width: double.infinity,
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  margin: EdgeInsets.only(bottom: 20),
                ),
                SkeletonLine(width: double.infinity),
                SizedBox(height: 12),
                SkeletonLine(width: 220),
                SizedBox(height: 20),
                SkeletonBox(height: 44, width: double.infinity),
                SizedBox(height: 12),
                SkeletonBox(height: 44, width: double.infinity),
                SizedBox(height: 12),
                SkeletonBox(height: 44, width: double.infinity),
              ],
            )
          : _errorMessage != null
          ? Center(
              child: TextButton.icon(
                onPressed: () => _loadBookDetails(refresh: true),
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
                    onPressed: () => context.pop(),
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
                  IconButton(
                    tooltip: 'Borrow cart',
                    onPressed: () => context.go('/borrow_cart'),
                    icon: const Icon(
                      Icons.shopping_cart_outlined,
                      color: Colors.white,
                      size: 22,
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
          _buildActionButtons(),
          if (_activeReservation != null) ...[
            const SizedBox(height: 16),
            _buildReservationStatusCard(),
          ],
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
              final canAddToCart = copy.canAddToCart;
              final isHeld = copy.isHeld;
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
                  DataCell(_statusCell(copy.circulationStatus, canAddToCart, isHeld)),
                  DataCell(Text(copy.barcode)),
                  DataCell(Text(copy.rfid)),
                  DataCell(
                    SizedBox(
                      height: 34,
                      child: ElevatedButton(
                        onPressed: canAddToCart
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

  Widget _statusCell(String label, bool canAddToCart, bool isHeld) {
    final Color backgroundColor;
    final Color textColor;

    if (canAddToCart) {
      backgroundColor = AppColors.successLight;
      textColor = AppColors.success;
    } else if (isHeld) {
      backgroundColor = AppColors.warningLight;
      textColor = AppColors.warning;
    } else {
      backgroundColor = AppColors.dangerLight;
      textColor = AppColors.danger;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
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

  /// Builds the primary action button(s) based on availability:
  /// - **Available copies > 0**: "Add to Borrow Cart" button
  /// - **No available copies**: "Reserve" button (or "Cancel reservation"
  ///   if the student already has an active reservation)
  Widget _buildActionButtons() {
    final book = _details!.book;
    final copies = _details!.copies;
    final availableCopies =
        copies.where((copy) => copy.isAvailable).toList(growable: false);

    return Row(
      children: [
        Expanded(
          child: _buildPrimaryActionButton(book, availableCopies),
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
            onPressed: () => context.go('/book_reservations'),
            tooltip: 'My reservations',
            icon: const Icon(
              Icons.bookmark_border_rounded,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  /// The primary action button — changes label/icon/onPressed based on the
  /// three-branch Add-to-Cart logic.
  Widget _buildPrimaryActionButton(
    Book book,
    List<BookCopy> availableCopies,
  ) {
    // Branch 3: No available copies → Reserve (or Cancel reservation)
    if (availableCopies.isEmpty) {
      if (_activeReservation != null) {
        if (_activeReservation!.isReady) {
          return _buildDeskClaimBanner();
        }
        return _buildCancelButton();
      }
      return _buildReserveButton();
    }

    // Branch 1 & 2: Available copies → Add to Borrow Cart
    return _buildAddToCartButton();
  }

  Widget _buildAddToCartButton() {
    return Container(
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
        onPressed: _handleAddToCart,
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
    );
  }

  Widget _buildReserveButton() {
    return Container(
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
        onPressed: _isReserving ? null : _reserveBook,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: _isReserving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(
                Icons.notification_add_rounded,
                size: 18,
                color: Colors.white,
              ),
        label: Text(
          _isReserving ? 'Reserving...' : 'Reserve',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.dangerLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: ElevatedButton.icon(
        onPressed: _isCancelling ? null : _cancelReservation,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: _isCancelling
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.danger,
                ),
              )
            : const Icon(
                Icons.cancel_outlined,
                size: 18,
                color: AppColors.danger,
              ),
        label: const Text(
          'Cancel reservation',
          style: TextStyle(
            color: AppColors.danger,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildDeskClaimBanner() {
    final reservation = _activeReservation!;
    final heldLabel = reservation.heldCallNumber != null &&
            reservation.heldCallNumber!.isNotEmpty
        ? ' copy ${reservation.heldCallNumber}'
        : '';

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.storefront_rounded, color: AppColors.success, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Visit the library desk to claim$heldLabel',
              style: const TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows the current reservation status (queue position or ready-to-claim).
  Widget _buildReservationStatusCard() {
    final reservation = _activeReservation!;
    final isReady = reservation.isReady;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isReady ? AppColors.successLight : AppColors.warningLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isReady
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isReady ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
            color: isReady ? AppColors.success : AppColors.warning,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isReady
                      ? 'Your reserved book is available!'
                      : 'You are in the reservation queue',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isReady ? AppColors.success : AppColors.warning,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isReady
                      ? 'Please visit the library desk to claim your held copy.'
                      : 'Position #${reservation.queuePosition} in queue. '
                          'You will be notified when a copy is returned.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isReady
                        ? AppColors.success.withValues(alpha: 0.8)
                        : AppColors.warning.withValues(alpha: 0.8),
                  ),
                ),
                if (isReady &&
                    reservation.heldCallNumber != null &&
                    reservation.heldCallNumber!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Held copy: ${reservation.heldCallNumber}',
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: AppColors.success.withValues(alpha: 0.8),
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

  /// Core Add-to-Cart logic with three branches:
  /// 1. Single available copy → add directly, no prompt.
  /// 2. Multiple available copies → show copy selection dialog.
  /// 3. No available copies → handled by the Reserve button, not here.
  Future<void> _handleAddToCart() async {
    final copies = _details!.copies;
    final availableCopies =
        copies.where((copy) => copy.isAvailable).toList(growable: false);

    if (availableCopies.isEmpty) return;

    if (availableCopies.length == 1) {
      // Branch 1: Only one available copy — add directly without a prompt.
      _addCopyToCart(availableCopies.first);
      return;
    }

    // Branch 2: Multiple available copies — show a confirmation alert first,
    // then let the student choose the exact copy to add.
    final shouldSelectCopy = await _confirmCopySelection();
    if (shouldSelectCopy != true) return;
    if (!mounted) return;

    final selected = await CopySelectionDialog.show(
      context,
      bookTitle: _details!.book.title,
      copies: copies,
    );

    if (selected == null) return;
    if (!mounted) return;

    _addCopyToCart(selected);
  }

  Future<bool?> _confirmCopySelection() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose a copy'),
          content: const Text(
            'There are multiple available copies for this book. '
            'Please select the specific copy you want to add to your borrow cart.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Select copy'),
            ),
          ],
        );
      },
    );
  }

  /// Reserves the book (joins the queue) when no copies are available.
  Future<void> _reserveBook() async {
    setState(() => _isReserving = true);

    try {
      final reservation = await _reservationService.reserveBook(
        _details!.book.id,
      );
      if (!mounted) return;

      setState(() {
        _activeReservation = reservation;
        _isReserving = false;
      });

      _reservationService.refreshNotifications();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _reservationService.lastMessage ??
                'Book reserved. You are #${reservation.queuePosition} in the queue.',
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _isReserving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.validationSummary)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isReserving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to reserve book.')),
      );
    }
  }

  /// Cancels an active reservation (leaves the queue).
  Future<void> _cancelReservation() async {
    final reservation = _activeReservation;
    if (reservation == null) return;

    setState(() => _isCancelling = true);

    try {
      await _reservationService.cancelReservation(reservation.id);
      if (!mounted) return;

      setState(() {
        _activeReservation = null;
        _isCancelling = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _reservationService.lastMessage ?? 'Reservation cancelled.',
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _isCancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.validationSummary)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isCancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to cancel reservation.')),
      );
    }
  }

  void _addCopyToCart(BookCopy copy) {
    _borrowService.addCopyToBorrowCart(copy, _details!.book);
    _showAddToCartMessage();
  }

  void _showAddToCartMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Added to borrow cart.'),
        action: SnackBarAction(
          label: 'View cart',
          onPressed: () => context.go('/borrow_cart'),
        ),
      ),
    );
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
