import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Screen that allows teachers to search and add books into a room.
class AddBooksToRoomScreen extends StatefulWidget {
  const AddBooksToRoomScreen({super.key});

  @override
  State<AddBooksToRoomScreen> createState() => _AddBooksToRoomScreenState();
}

class _AddBooksToRoomScreenState extends State<AddBooksToRoomScreen> {
  final _books = [
    {'title': 'Fundamentals of Nursing', 'author': 'Keizer, Barbara', 'selected': false},
    {'title': 'Nursing Care Plans', 'author': 'Nettina, Marion', 'selected': false},
    {'title': 'Dosage Calculations', 'author': 'Dimond, Linda', 'selected': false},
    {'title': 'Pharmacology for Nurses', 'author': 'Lehne, Richard', 'selected': false},
    {'title': 'Clinical Pharmacology', 'author': 'Lilley, Linda', 'selected': false},
  ];

  /// Builds the selectable list of books and the action button to add them.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Books to Room'),
        backgroundColor: AppColors.navyBrand,
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: TextField(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.card,
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: 'Search books...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemBuilder: (context, index) {
                  final book = _books[index];
                  return CheckboxListTile(
                    value: book['selected'] as bool,
                    onChanged: (checked) {
                      setState(() {
                        _books[index]['selected'] = checked ?? false;
                      });
                    },
                    title: Text(book['title'] as String, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                    subtitle: Text(book['author'] as String, style: AppTextStyles.bodySmall),
                    secondary: const Icon(Icons.menu_book_rounded, color: AppColors.primary),
                  );
                },
                separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                itemCount: _books.length,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.navyBrand),
                  onPressed: () {
                    context.pop();
                  },
                  child: const Text('Add Selected (2)'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
