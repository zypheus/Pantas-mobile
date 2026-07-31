import 'package:flutter/material.dart';
import '../services/borrow_service.dart';

class BorrowCartScreen extends StatefulWidget {
  const BorrowCartScreen({super.key});

  @override
  State<BorrowCartScreen> createState() => _BorrowCartScreenState();
}

class _BorrowCartScreenState extends State<BorrowCartScreen> {
  final _borrowService = BorrowService();
  bool _isSubmitting = false;

  void _removeItem(String bookId) {
    setState(() {
      _borrowService.removeFromBorrowCart(bookId);
    });
  }

  Future<void> _submitCheckout() async {
    final cartItems = _borrowService.getBorrowCart();
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cart is empty')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await _borrowService.submitCheckoutRequest(cartItems);
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Checkout request submitted successfully'),
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit checkout request')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('An error occurred')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = _borrowService.getBorrowCart();

    return Scaffold(
      appBar: AppBar(title: const Text('Borrow Cart')),
      body: cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your cart is empty',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final bookId = cartItems[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Container(
                            width: 50,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.book),
                          ),
                          title: Text('Book $bookId'),
                          subtitle: const Text('Available'),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => _removeItem(bookId),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Items in cart:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${cartItems.length}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitCheckout,
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Submit Checkout'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
