import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/classroom.dart';
import '../../../services/faculty_classroom_service.dart';

class MyRoomsScreen extends StatefulWidget {
  const MyRoomsScreen({super.key});

  @override
  State<MyRoomsScreen> createState() => _MyRoomsScreenState();
}

class _MyRoomsScreenState extends State<MyRoomsScreen> {
  final _service = FacultyClassroomService();
  List<ClassroomSummary> _rooms = const [];
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
      final rooms = await _service.getClassrooms();
      if (!mounted) return;
      setState(() {
        _rooms = rooms;
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
        _error = 'Unable to load rooms.';
        _loading = false;
      });
    }
  }

  Future<void> _createRoom() async {
    await context.push('/faculty/create-room');
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.navyBrand,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: FloatingActionButton.extended(
          onPressed: _createRoom,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text(
            'Create Room',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 6,
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: topInset + 8),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 18),
            child: Row(
              children: [
                _HeaderIcon(),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Rooms',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.02,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Manage and access your classrooms',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              clipBehavior: Clip.antiAlias,
              child: RefreshIndicator(
                onRefresh: _load,
                child: _buildBody(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Center(child: Text(_error!)),
          TextButton(onPressed: _load, child: const Text('Retry')),
        ],
      );
    }

    if (_rooms.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 120),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              children: [
                Icon(Icons.meeting_room_outlined,
                    size: 48, color: AppColors.primary),
                SizedBox(height: 12),
                Text(
                  'No rooms yet',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Create a room to invite students and share materials.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 140),
      itemCount: _rooms.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final room = _rooms[index];
        final theme = _RoomTheme.forIndex(index, room);
        return _RoomCard(
          room: room,
          theme: theme,
          onTap: () => context.push('/faculty/rooms/details?id=${room.id}'),
        );
      },
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.account_balance_rounded,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}

class _RoomTheme {
  final Color accent;
  final Color soft;
  final IconData icon;
  final IconData decoIcon;

  const _RoomTheme({
    required this.accent,
    required this.soft,
    required this.icon,
    required this.decoIcon,
  });

  static const _palette = <(Color, Color, IconData, IconData)>[
    (Color(0xFF7C3AED), Color(0xFFF3E8FF), Icons.meeting_room_rounded, Icons.desk_rounded),
    (Color(0xFF059669), Color(0xFFD1FAE5), Icons.laptop_mac_rounded, Icons.code_rounded),
    (Color(0xFFD97706), Color(0xFFFEF3C7), Icons.public_rounded, Icons.language_rounded),
    (Color(0xFF2563EB), Color(0xFFDBEAFE), Icons.web_rounded, Icons.monitor_rounded),
  ];

  factory _RoomTheme.forIndex(int index, ClassroomSummary room) {
    final subject = (room.subject ?? room.name).toLowerCase();
    var paletteIndex = index % _palette.length;

    if (subject.contains('web') || subject.contains('html')) {
      paletteIndex = 3;
    } else if (subject.contains('program') ||
        subject.contains('code') ||
        subject.contains('fund')) {
      paletteIndex = 1;
    } else if (subject.contains('geo') || subject.contains('world')) {
      paletteIndex = 2;
    }

    final entry = _palette[paletteIndex];
    return _RoomTheme(
      accent: entry.$1,
      soft: entry.$2,
      icon: entry.$3,
      decoIcon: entry.$4,
    );
  }
}

class _RoomCard extends StatelessWidget {
  final ClassroomSummary room;
  final _RoomTheme theme;
  final VoidCallback onTap;

  const _RoomCard({
    required this.room,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = room.subject?.trim().isNotEmpty == true
        ? room.subject!
        : (room.description?.trim().isNotEmpty == true
            ? room.description!
            : 'Classroom');
    final studentLabel =
        '${room.memberCount} ${room.memberCount == 1 ? 'student' : 'students'}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 108,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 5, color: theme.accent),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: theme.soft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(theme.icon, color: theme.accent, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              room.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.soft,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.person_outline_rounded,
                                    size: 14,
                                    color: theme.accent,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    studentLabel,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: theme.accent,
                                    ),
                                  ),
                                  if (room.pendingCount > 0) ...[
                                    Text(
                                      ' · ${room.pendingCount} pending',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: theme.accent.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.accent.withValues(alpha: 0.18),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: theme.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
