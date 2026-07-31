import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/classroom.dart';
import '../../../services/faculty_classroom_service.dart';

class ShareRoomScreen extends StatefulWidget {
  final String classroomId;
  const ShareRoomScreen({super.key, required this.classroomId});

  @override
  State<ShareRoomScreen> createState() => _ShareRoomScreenState();
}

class _ShareRoomScreenState extends State<ShareRoomScreen> {
  final _service = FacultyClassroomService();
  ClassroomSummary? _room;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final room = await _service.getClassroom(widget.classroomId);
      if (!mounted) return;
      setState(() {
        _room = room;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _regenerate() async {
    try {
      final room = await _service.regenerateCode(widget.classroomId);
      if (!mounted) return;
      setState(() => _room = room);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Join code regenerated.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.validationSummary)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = _room?.joinCode ?? '—';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Room'),
        backgroundColor: AppColors.navyBrand,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    _room?.name ?? 'Room',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        const Text('Join code'),
                        const SizedBox(height: 8),
                        Text(
                          code,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: code));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Join code copied.')),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copy code'),
                  ),
                  TextButton(
                    onPressed: _regenerate,
                    child: const Text('Regenerate code'),
                  ),
                ],
              ),
            ),
    );
  }
}
