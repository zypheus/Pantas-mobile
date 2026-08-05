import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_exception.dart';
import '../../../services/student_classroom_service.dart';
import '../../../shared/widgets/app_notify.dart';

class JoinClassroomScreen extends StatefulWidget {
  const JoinClassroomScreen({super.key});

  @override
  State<JoinClassroomScreen> createState() => _JoinClassroomScreenState();
}

class _JoinClassroomScreenState extends State<JoinClassroomScreen> {
  final _service = StudentClassroomService();
  final _codeController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      AppNotify.info(context, 'Enter a join code.');
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await _service.joinClassroom(code);
      if (!mounted) return;
      AppNotify.success(
        context,
        result['message']?.toString() ?? 'Joined.',
      );
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      AppNotify.error(context, e.validationSummary);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Classroom')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Join code',
                hintText: 'e.g. JOINDEMO',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _join,
              child: Text(_loading ? 'Joining...' : 'Join'),
            ),
          ],
        ),
      ),
    );
  }
}
