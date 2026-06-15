import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/mock_book.dart';

class BookDetailsScreen extends StatefulWidget {
  final String bookId;
  const BookDetailsScreen({super.key, required this.bookId});

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  MockBook get mockBook => const MockBook(
        id: '1',
        title: 'Research Methods in Education',
        author: 'Cohen, Louis',
        callNumber: 'LB1028 .C577 2018',
        availability: 'On-Shelf',
        coverUrl: '',
        year: '2018',
        description:
            'Research Methods in Education is an essential guide for students and researchers in education. This comprehensive text covers a wide range of both qualitative and quantitative research methods including surveys, case studies, experiments, and action research. The book provides practical guidance on designing studies, collecting data, and interpreting results in educational contexts.',
        copies: 3,
        isAvailable: true,
      );

  static const List<Map<String, String>> _holdings = [
    {
      'accession': 'GG-2024-0016',
      'callNumber': 'LB1028\n.C577 2018',
      'volume': '—',
      'copy': '—',
      'collection': 'Research in\nEducation',
      'shelving': 'Academic Library\n— Main stacks',
      'circType': 'Regular\ncirculation',
      'circStatus': 'On-Shelf',
      'barcode': 'BC-GG-00016',
      'rfid': 'RFID-GG-00016',
    },
    {
      'accession': 'GG-2024-0017',
      'callNumber': 'LB1028\n.C577 2018',
      'volume': '—',
      'copy': '2',
      'collection': 'Research in\nEducation',
      'shelving': 'Academic Library\n— Main stacks',
      'circType': 'Regular\ncirculation',
      'circStatus': 'On-Shelf',
      'barcode': 'BC-GG-00017',
      'rfid': 'RFID-GG-00017',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
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
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top bar with back button
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
                      mockBook.title,
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
            // Book info card
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Book cover
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/defaultBook.png',
                          width: 90,
                          height: 110,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.menu_book_rounded,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  // Book meta
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mockBook.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          mockBook.author,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildMetaRow('Main author', mockBook.author),
                        const SizedBox(height: 8),
                        _buildMetaRow('Format', 'Printed'),
                        const SizedBox(height: 8),
                        _buildMetaRow(
                            'Published', 'Routledge ${mockBook.year}'),
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
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
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
                'Academic Library — Main stacks',
                style: TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Holdings table
          Container(
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
                  rows: _holdings.map((h) {
                    final isAvailable = h['circStatus'] == 'On-Shelf';
                    return DataRow(
                      cells: [
                        DataCell(Text(h['accession'] ?? '')),
                        DataCell(Text(
                          h['callNumber'] ?? '',
                          style: const TextStyle(fontFamily: 'monospace'),
                        )),
                        DataCell(Text(h['volume'] ?? '')),
                        DataCell(Text(h['copy'] ?? '')),
                        DataCell(Text(h['collection'] ?? '')),
                        DataCell(Text(h['shelving'] ?? '')),
                        DataCell(Text(h['circType'] ?? '')),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isAvailable
                                  ? AppColors.successLight
                                  : AppColors.dangerLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              h['circStatus'] ?? '',
                              style: TextStyle(
                                color: isAvailable
                                    ? AppColors.success
                                    : AppColors.danger,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                        DataCell(Text(h['barcode'] ?? '')),
                        DataCell(Text(h['rfid'] ?? '')),
                        DataCell(
                          SizedBox(
                            height: 34,
                            child: ElevatedButton(
                              onPressed: isAvailable ? () {} : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                disabledBackgroundColor:
                                    AppColors.textMuted.withValues(alpha: 0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
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
          ),
          const SizedBox(height: 24),
          // Bottom action bar
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
                    onPressed: () {},
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

  Widget _buildDescriptionTab() {
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
            mockBook.description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 24),
          _buildDescRow('Title', mockBook.title),
          _buildDescRow('Author', mockBook.author),
          _buildDescRow('Publisher', 'Routledge'),
          _buildDescRow('Year', mockBook.year),
          _buildDescRow('Format', 'Printed'),
          _buildDescRow('Call Number', mockBook.callNumber),
          _buildDescRow('Copies', '${mockBook.copies}'),
        ],
      ),
    );
  }

  Widget _buildDescRow(String label, String value) {
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
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
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
    final marcFields = [
      ('020', 'ISBN', '9781138209886'),
      ('100', 'Main Entry - Personal Name', 'Cohen, Louis, author.'),
      ('245', 'Title Statement',
          'Research methods in education / Louis Cohen, Lawrence Manion, Keith Morrison.'),
      ('250', 'Edition Statement', 'Eighth edition.'),
      ('264', 'Production/Publication',
          'London ; New York : Routledge, 2018.'),
      ('300', 'Physical Description', 'xxxi, 758 pages ; 25 cm'),
      ('504', 'Bibliography Note',
          'Includes bibliographical references and index.'),
      ('650', 'Subject', 'Education — Research — Methodology.'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
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
}
