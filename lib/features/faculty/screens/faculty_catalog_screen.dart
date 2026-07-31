import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/book.dart';
import '../../../services/catalog_service.dart';
import '../../catalog/widgets/book_result_card.dart';

/// Catalog browsing screen for faculty — supports search and listing.
class FacultyCatalogScreen extends StatefulWidget {
  const FacultyCatalogScreen({super.key, this.folderId});

  /// When set, book details open with this folder preselected for Add to Folder.
  final String? folderId;

  @override
  State<FacultyCatalogScreen> createState() => _FacultyCatalogScreenState();
}

class _FacultyCatalogScreenState extends State<FacultyCatalogScreen> {
  final _catalogService = CatalogService();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;
  List<Book> _results = const [];
  bool _isLoading = true;
  String? _error;

  /// Initialize the catalog screen and load initial results.
  @override
  void initState() {
    super.initState();
    _loadInitialResults();
  }

  /// Dispose controllers and timers used for searching and scrolling.
  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Loads initial catalog results (new arrivals). Use [refresh] to force reload.
  Future<void> _loadInitialResults({bool refresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final books = await _catalogService.getNewArrivals(refresh: refresh);
      if (!mounted) return;
      setState(() {
        _results = books;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load catalog.';
        _isLoading = false;
      });
    }
  }

  /// Debounces user input and schedules a search for [query].
  void _scheduleSearch(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(query));
  }

  /// Performs a catalog search for the provided [query]. Falls back to initial results when query is empty.
  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      return _loadInitialResults();
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final books = await _catalogService.searchBooks(query.trim(), perPage: 20);
      if (!mounted) return;
      setState(() {
        _results = books;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Search failed.';
        _isLoading = false;
      });
    }
  }

  /// Builds the faculty catalog UI with search and grid results.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navyBrand,
        title: const Text('Browse Catalog'),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: TextField(
                controller: _searchController,
                onChanged: _scheduleSearch,
                decoration: InputDecoration(
                  hintText: 'Search books, authors, subjects',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _results.isEmpty
                          ? const Center(child: Text('No books found.'))
                          : Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: GridView.builder(
                                controller: _scrollController,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 14,
                                  childAspectRatio: 0.7,
                                ),
                                itemCount: _results.length,
                                itemBuilder: (context, index) {
                                  final book = _results[index];
                                  return BookResultCard(
                                    book: book,
                                    onTap: () {
                                      final folderId = widget.folderId;
                                      final query = StringBuffer(
                                        '/faculty/book_details?id=${Uri.encodeComponent(book.id)}',
                                      );
                                      if (folderId != null &&
                                          folderId.isNotEmpty) {
                                        query.write(
                                          '&folderId=${Uri.encodeComponent(folderId)}',
                                        );
                                      }
                                      context.push(query.toString());
                                    },
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
