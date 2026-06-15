import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/borrow_service.dart';
import '../services/catalog_service.dart';

class BookDetailsScreen extends StatefulWidget {
  final String bookId;

  const BookDetailsScreen({super.key, required this.bookId});

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  final _catalogService = CatalogService();
  final _borrowService = BorrowService();
  Book? _book;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookDetails();
  }

  Future<void> _loadBookDetails() async {
    try {
      final book = await _catalogService.getBookDetails(widget.bookId);
      if (mounted) {
        setState(() {
          _book = book;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load book details.')),
        );
      }
    }
  }

  void _addToBorrowCart() {
    _borrowService.addToBorrowCart(_book!.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added to borrow cart')),
    );
  }

  void _saveToFavorites() {
    // TODO: Implement save to favorites
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved to favorites')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _book == null
              ? const Center(child: Text('Book not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cover Image
                      Center(
                        child: Container(
                          width: 150,
                          height: 220,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: _book!.coverImage != null
                                ? Image.network(
                                    _book!.coverImage!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Image.asset(
                                      'assets/defaultBook.png',
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Image.asset(
                                    'assets/defaultBook.png',
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Title and Author
                      Text(
                        _book!.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'by ${_book!.author}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Availability Status
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _book!.isAvailable
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          border: Border.all(
                            color: _book!.isAvailable
                                ? Colors.green.shade200
                                : Colors.red.shade200,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _book!.isAvailable
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: _book!.isAvailable
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _book!.isAvailable
                                        ? 'Available'
                                        : 'Not Available',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _book!.isAvailable
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                    ),
                                  ),
                                  Text(
                                    '${_book!.availableCopies} of ${_book!.totalCopies} copies',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Details Section
                      Text(
                        'Details',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow('Content Type:', _book!.contentType),
                      _buildDetailRow('Year:', _book!.year.toString()),
                      _buildDetailRow('Call Number:', _book!.callNumber),
                      _buildDetailRow('Section:', _book!.section),
                      const SizedBox(height: 20),

                      // Action Buttons
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _book!.isAvailable
                              ? _addToBorrowCart
                              : null,
                          child: const Text('Add to Borrow Cart'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _saveToFavorites,
                          child: const Text('Save to Favorites'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
