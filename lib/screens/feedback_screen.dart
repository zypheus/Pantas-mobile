import 'package:flutter/material.dart';
import '../core/network/api_exception.dart';
import '../services/user_service.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _userService = UserService();
  final _messageController = TextEditingController();
  String? _selectedCategory;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_selectedCategory == null || _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _userService.submitFeedback(
        _selectedCategory!,
        _messageController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _selectedCategory = null;
      });
      _messageController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feedback submitted successfully'),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.validationSummary)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to submit feedback. Please try again.'),
        ),
      );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback & Support'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Selection
            Text(
              'Category',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            DropdownButton<String>(
              isExpanded: true,
              hint: const Text('Select a category'),
              value: _selectedCategory,
              items: [
                'App Issue',
                'Library Service',
                'Book Concern',
                'Room Reservation Concern',
                'Other',
              ]
                  .map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      ))
                  .toList(),
              onChanged: _isSubmitting
                  ? null
                  : (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
            ),
            const SizedBox(height: 24),

            // Message Field
            Text(
              'Message',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: 'Describe your feedback or issue...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              enabled: !_isSubmitting,
            ),
            const SizedBox(height: 24),

            // Contact Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact Information',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.email,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'library@university.edu',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.phone,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '+1 (555) 123-4567',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitFeedback,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Submit Feedback'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
