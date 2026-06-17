import 'package:flutter/material.dart';
import '../models/borrowed_book.dart';
import '../services/borrow_service.dart';
import '../shared/widgets/skeleton_loading.dart';

class BorrowedBooksScreen extends StatefulWidget {
  const BorrowedBooksScreen({super.key});

  @override
  State<BorrowedBooksScreen> createState() => _BorrowedBooksScreenState();
}

class _BorrowedBooksScreenState extends State<BorrowedBooksScreen> {
  final _borrowService = BorrowService();
  List<BorrowedBook> _borrowedBooks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBorrowedBooks();
  }

  Future<void> _loadBorrowedBooks() async {
    try {
      final books = await _borrowService.getCurrentBorrowedBooks();
      if (mounted) {
        setState(() {
          _borrowedBooks = books;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load borrowed books')),
        );
      }
    }
  }

  Future<void> _renewBook(String bookId) async {
    try {
      final success = await _borrowService.renewBook(bookId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book renewed successfully')),
        );
        _loadBorrowedBooks();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to renew book')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Borrowed Books'),
      ),
      body: _isLoading
          ? const SkeletonList(itemCount: 4, padding: EdgeInsets.all(16))
          : _borrowedBooks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.library_books,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No borrowed books',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _borrowedBooks.length,
                  itemBuilder: (context, index) {
                    final book = _borrowedBooks[index];
                    final daysUntilDue = book.dueDate.difference(DateTime.now()).inDays;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'by ${book.author}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: book.isOverdue
                                    ? Colors.red.shade50
                                    : daysUntilDue <= 3
                                        ? Colors.orange.shade50
                                        : Colors.green.shade50,
                                border: Border.all(
                                  color: book.isOverdue
                                      ? Colors.red.shade200
                                      : daysUntilDue <= 3
                                          ? Colors.orange.shade200
                                          : Colors.green.shade200,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Due Date:',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        book.dueDate.toString().split(' ')[0],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: book.isOverdue
                                              ? Colors.red.shade700
                                              : daysUntilDue <= 3
                                                  ? Colors.orange.shade700
                                                  : Colors.green.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (!book.isOverdue)
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.refresh, size: 16),
                                      label: const Text('Renew'),
                                      onPressed: () => _renewBook(book.id),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
