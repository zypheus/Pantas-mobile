import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/classroom.dart';
import '../../../services/student_classroom_service.dart';

class MyClassroomsScreen extends StatefulWidget {
  const MyClassroomsScreen({super.key});

  @override
  State<MyClassroomsScreen> createState() => _MyClassroomsScreenState();
}

class _MyClassroomsScreenState extends State<MyClassroomsScreen> {
  final _service = StudentClassroomService();
  List<ClassroomSummary> _classrooms = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final classrooms = await _service.getMyClassrooms();
      if (!mounted) return;
      setState(() {
        _classrooms = classrooms;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.validationSummary;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load classrooms.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Classrooms'),
        actions: [
          IconButton(
            onPressed: () async {
              await context.push('/classrooms/join');
              _load();
            },
            icon: const Icon(Icons.group_add_rounded),
            tooltip: 'Join classroom',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    children: [
                      const SizedBox(height: 80),
                      Center(child: Text(_error!)),
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  )
                : _classrooms.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 80),
                          const Center(child: Text('You have not joined any classrooms.')),
                          TextButton(
                            onPressed: () => context.push('/classrooms/join'),
                            child: const Text('Join with code'),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _classrooms.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final room = _classrooms[index];
                          return ListTile(
                            tileColor: AppColors.card,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            title: Text(room.name),
                            subtitle: Text(
                              [
                                room.facultyName,
                                room.subject,
                              ].whereType<String>().join(' · '),
                            ),
                            onTap: () => context.push('/classrooms/${room.id}'),
                          );
                        },
                      ),
      ),
    );
  }
}
