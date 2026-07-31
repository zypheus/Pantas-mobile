import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/classroom.dart';
import '../../../services/faculty_classroom_service.dart';

class ManageStudentsScreen extends StatefulWidget {
  final String classroomId;
  const ManageStudentsScreen({super.key, required this.classroomId});

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  final _service = FacultyClassroomService();
  List<ClassroomMemberSummary> _members = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final members = await _service.getMembers(widget.classroomId);
      if (!mounted) return;
      setState(() {
        _members = members;
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
      appBar: AppBar(
        title: const Text('Manage Students'),
        backgroundColor: AppColors.navyBrand,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _members.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 80),
                        Center(child: Text('No students yet.')),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _members.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final member = _members[index];
                        return ListTile(
                          title: Text(member.name),
                          subtitle: Text(
                            [
                              member.studentNumber,
                              member.course,
                              member.status,
                            ]
                                .whereType<String>()
                                .where((s) => s.isNotEmpty)
                                .join(' · '),
                          ),
                          trailing: member.status == 'pending'
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.check,
                                        color: AppColors.success,
                                      ),
                                      onPressed: () async {
                                        await _service.approveMember(
                                          widget.classroomId,
                                          member.id,
                                        );
                                        await _load();
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: AppColors.danger,
                                      ),
                                      onPressed: () async {
                                        await _service.rejectMember(
                                          widget.classroomId,
                                          member.id,
                                        );
                                        await _load();
                                      },
                                    ),
                                  ],
                                )
                              : null,
                        );
                      },
                    ),
            ),
    );
  }
}
