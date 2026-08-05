import 'package:flutter/material.dart';
import '../../../core/network/api_exception.dart';
import '../../../services/user_service.dart';
import '../../../shared/widgets/app_notify.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _userService = UserService();
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  String? _selectedCategory;
  bool _isSubmitting = false;

  static const _categories = [
    'App Issue',
    'Library Service',
    'Book Concern',
    'Room Reservation Concern',
    'Other',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) {
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

      FocusScope.of(context).unfocus();
      _formKey.currentState!.reset();
      setState(() {
        _selectedCategory = null;
      });
      _messageController.clear();

      AppNotify.success(context, 'Feedback submitted successfully');
    } on ApiException catch (e) {
      if (!mounted) return;
      AppNotify.error(context, e.validationSummary);
    } catch (_) {
      if (!mounted) return;
      AppNotify.error(context, 'Unable to submit feedback. Please try again.');
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
        title: const Text(
          'Feedback & Support',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Category',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey(_selectedCategory),
                isExpanded: true,
                decoration: InputDecoration(
                  hintText: 'Select a category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                initialValue: _selectedCategory,
                items: _categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: _isSubmitting
                    ? null
                    : (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Message',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _messageController,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: 'Describe your feedback or issue...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                enabled: !_isSubmitting,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your feedback message';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
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
      ),
    );
  }
}
