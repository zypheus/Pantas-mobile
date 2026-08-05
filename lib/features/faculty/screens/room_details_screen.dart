import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/assignment.dart';
import '../../../models/classroom.dart';
import '../../../services/assignment_service.dart';
import '../../../services/faculty_classroom_service.dart';

class RoomDetailsScreen extends StatefulWidget {
  final String classroomId;
  const RoomDetailsScreen({super.key, required this.classroomId});

  @override
  State<RoomDetailsScreen> createState() => _RoomDetailsScreenState();
}

class _RoomDetailsScreenState extends State<RoomDetailsScreen> {
  final _service = FacultyClassroomService();
  ClassroomSummary? _room;
  bool _loading = true;
  String? _error;
  int _assignmentsRefreshToken = 0;

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
      final room = await _service.getClassroom(widget.classroomId);
      if (!mounted) return;
      setState(() {
        _room = room;
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
        _error = 'Unable to load room.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final room = _room;
    return Scaffold(
      backgroundColor: AppColors.navyBrand,
      appBar: AppBar(
        title: Text(room?.name ?? 'Room'),
        backgroundColor: AppColors.navyBrand,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const ColoredBox(
              color: AppColors.background,
              child: Center(child: CircularProgressIndicator()),
            )
          : _error != null
              ? ColoredBox(
                  color: AppColors.background,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!),
                        TextButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : room == null
                  ? const ColoredBox(
                      color: AppColors.background,
                      child: Center(child: Text('Room not found')),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                          children: [
                            _RoomHeroCard(room: room),
                            const SizedBox(height: 14),
                            _ActionTile(
                              icon: Icons.share_rounded,
                              iconColor: const Color(0xFF6D28D9),
                              iconBg: const Color(0xFFF3E8FF),
                              title: 'Share join code',
                              subtitle: 'Invite students to join your class',
                              onTap: () => context.push(
                                '/faculty/rooms/share?id=${room.id}',
                              ),
                            ),
                            const SizedBox(height: 10),
                            _ActionTile(
                              icon: Icons.people_alt_rounded,
                              iconColor: const Color(0xFF059669),
                              iconBg: const Color(0xFFD1FAE5),
                              title: 'Manage students',
                              subtitle: 'View and manage class members',
                              onTap: () => context.push(
                                '/faculty/rooms/manage?id=${room.id}',
                              ),
                            ),
                            const SizedBox(height: 10),
                            _ActionTile(
                              icon: Icons.folder_shared_rounded,
                              iconColor: const Color(0xFFD97706),
                              iconBg: const Color(0xFFFEF3C7),
                              title: 'Share a folder',
                              subtitle: 'Share resources and materials',
                              tinted: true,
                              onTap: () => context.push(
                                '/faculty/rooms/add-books?id=${room.id}',
                              ),
                            ),
                            const SizedBox(height: 10),
                            _ActionTile(
                              icon: Icons.assignment_rounded,
                              iconColor: const Color(0xFF2563EB),
                              iconBg: const Color(0xFFDBEAFE),
                              title: 'Create assignment',
                              subtitle: 'Create new assignments for students',
                              onTap: () async {
                                await context.push(
                                  '/faculty/assignments/create?classroomId=${Uri.encodeComponent(room.id)}',
                                );
                                if (!mounted) return;
                                setState(() => _assignmentsRefreshToken++);
                              },
                            ),
                            const SizedBox(height: 22),
                            _AssignmentsPreview(
                              key: ValueKey(_assignmentsRefreshToken),
                              classroomId: room.id,
                            ),
                            const SizedBox(height: 22),
                            _SharedFoldersSection(room: room),
                          ],
                        ),
                      ),
                    ),
    );
  }
}

class _RoomHeroCard extends StatelessWidget {
  final ClassroomSummary room;
  const _RoomHeroCard({required this.room});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.02,
                      ),
                    ),
                    if (room.subject != null && room.subject!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE9FE),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          room.subject!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF5B21B6),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const _RoomHeroIllustration(),
            ],
          ),
          if (room.description != null && room.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              room.description!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  icon: Icons.groups_rounded,
                  label: _plural(room.memberCount, 'Student', 'Students'),
                ),
              ),
              Expanded(
                child: _StatChip(
                  icon: Icons.schedule_rounded,
                  label: _plural(room.pendingCount, 'Pending', 'Pending'),
                ),
              ),
              Expanded(
                child: _StatChip(
                  icon: Icons.folder_rounded,
                  label: _plural(room.folderCount, 'Folder', 'Folders'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _plural(int count, String singular, String plural) {
    return '$count ${count == 1 ? singular : plural}';
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoomHeroIllustration extends StatelessWidget {
  const _RoomHeroIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      height: 68,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 58,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E7FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
              ),
              child: const Center(
                child: Icon(
                  Icons.school_rounded,
                  size: 22,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            bottom: 2,
            child: Column(
              children: [
                Container(
                  width: 18,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFF34D399),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Container(
                  width: 14,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFF92400E),
                    borderRadius: BorderRadius.circular(3),
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

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool tinted;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.tinted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: tinted ? const Color(0xFFFFFBEB) : AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SharedFoldersSection extends StatelessWidget {
  final ClassroomSummary room;
  const _SharedFoldersSection({required this.room});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.folder_rounded, size: 18, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'Shared folders',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (room.folders.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'No folders shared yet.',
              style: TextStyle(color: AppColors.textMuted),
            ),
          )
        else
          ...room.folders.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => context.push(
                    '/faculty/folders/details?id=${f.id}',
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.folder_rounded,
                            color: Color(0xFFD97706),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                f.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${f.bookCount} books',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AssignmentsPreview extends StatefulWidget {
  final String classroomId;
  const _AssignmentsPreview({super.key, required this.classroomId});

  @override
  State<_AssignmentsPreview> createState() => _AssignmentsPreviewState();
}

class _AssignmentsPreviewState extends State<_AssignmentsPreview> {
  final _service = AssignmentService();
  List<AssignmentSummary> _items = const [];
  bool _loading = true;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items =
          await _service.listFacultyAssignments(widget.classroomId);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _showAll ? _items : _items.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.assignment_outlined,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Assignments',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (_items.length > 5)
              TextButton(
                onPressed: () => setState(() => _showAll = !_showAll),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(_showAll ? 'Show less' : 'View all >'),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'No assignments yet.',
              style: TextStyle(color: AppColors.textMuted),
            ),
          )
        else
          ...visible.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AssignmentCard(assignment: a),
            ),
          ),
      ],
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final AssignmentSummary assignment;
  const _AssignmentCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final progress = _assignmentProgress(assignment);
    final dueLabel = assignment.dueAt == null
        ? 'No due date'
        : 'Due ${DateFormat('MMM d, y').format(assignment.dueAt!.toLocal())}';
    final countLabel =
        '${assignment.completedCount}/${assignment.totalSubmissions} done';

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(
          '/faculty/assignments/details?id=${Uri.encodeComponent(assignment.id)}',
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$dueLabel · $countLabel',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _ProgressBadge(progress: progress),
            ],
          ),
        ),
      ),
    );
  }
}

enum _AssignmentProgress { pending, inProgress, completed, noStudents }

_AssignmentProgress _assignmentProgress(AssignmentSummary a) {
  if (a.totalSubmissions <= 0) return _AssignmentProgress.noStudents;
  if (a.completedCount >= a.totalSubmissions) {
    return _AssignmentProgress.completed;
  }
  if (a.completedCount > 0 || a.submittedCount > 0) {
    return _AssignmentProgress.inProgress;
  }
  return _AssignmentProgress.pending;
}

class _ProgressBadge extends StatelessWidget {
  final _AssignmentProgress progress;
  const _ProgressBadge({required this.progress});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon, bg) = switch (progress) {
      _AssignmentProgress.completed => (
          'Completed',
          AppColors.success,
          Icons.check_circle_rounded,
          AppColors.successLight,
        ),
      _AssignmentProgress.inProgress => (
          'In progress',
          const Color(0xFF2563EB),
          Icons.timelapse_rounded,
          const Color(0xFFDBEAFE),
        ),
      _AssignmentProgress.noStudents => (
          'No students',
          AppColors.textMuted,
          Icons.person_off_outlined,
          AppColors.surface,
        ),
      _AssignmentProgress.pending => (
          'Pending',
          AppColors.warning,
          Icons.schedule_rounded,
          AppColors.warningLight,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
