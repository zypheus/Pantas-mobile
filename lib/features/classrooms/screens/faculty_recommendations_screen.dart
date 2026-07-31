import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/classroom.dart';
import '../../../services/student_classroom_service.dart';
import '../../catalog/widgets/book_result_card.dart';

class FacultyRecommendationsScreen extends StatefulWidget {
  const FacultyRecommendationsScreen({super.key});

  @override
  State<FacultyRecommendationsScreen> createState() =>
      _FacultyRecommendationsScreenState();
}

class _FacultyRecommendationsScreenState
    extends State<FacultyRecommendationsScreen> {
  final _service = StudentClassroomService();
  List<FacultyRecommendationGroup> _groups = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final groups = await _service.getFacultyRecommendations(refresh: true);
      if (!mounted) return;
      setState(() {
        _groups = groups;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('From your classrooms')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _groups.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 80),
                        Center(
                          child: Text(
                            'No faculty recommendations yet.\nJoin a classroom to see books here.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _groups.length,
                      itemBuilder: (context, index) {
                        final group = _groups[index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.classroom.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (group.classroom.facultyName != null)
                              Text(
                                group.classroom.facultyName!,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 240,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: group.books.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 12),
                                itemBuilder: (context, bookIndex) {
                                  final book = group.books[bookIndex];
                                  return SizedBox(
                                    width: 140,
                                    child: BookResultCard(
                                      book: book,
                                      onTap: () => context.push(
                                        '/book_details?id=${book.id}',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        );
                      },
                    ),
            ),
    );
  }
}
