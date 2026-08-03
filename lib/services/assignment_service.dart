import '../core/network/api_client.dart';
import '../models/assignment.dart';

class AssignmentService {
  static final AssignmentService _instance = AssignmentService._internal();
  factory AssignmentService() => _instance;
  AssignmentService._internal();

  final ApiClient _api = ApiClient();

  // ── Faculty ─────────────────────────────────────────────────────

  Future<List<AssignmentSummary>> listFacultyAssignments(
    String classroomId,
  ) async {
    final response =
        await _api.get('/faculty/classrooms/$classroomId/assignments');
    return _list(response);
  }

  Future<AssignmentSummary> createAssignment({
    required String classroomId,
    required String title,
    String? instructions,
    DateTime? dueAt,
    List<String> bookIds = const [],
  }) async {
    final response = await _api.post(
      '/faculty/classrooms/$classroomId/assignments',
      body: {
        'title': title,
        'instructions': instructions,
        'due_at': dueAt?.toIso8601String(),
        'book_ids': bookIds.map((id) => int.tryParse(id) ?? id).toList(),
      }..removeWhere((_, value) => value == null || value == ''),
    );
    return AssignmentSummary.fromJson(_asMap(response['data']));
  }

  Future<AssignmentSummary> getFacultyAssignment(String id) async {
    final response = await _api.get('/faculty/assignments/$id');
    return AssignmentSummary.fromJson(_asMap(response['data']));
  }

  Future<List<AssignmentSubmissionSummary>> getSubmissions(
    String assignmentId,
  ) async {
    final response =
        await _api.get('/faculty/assignments/$assignmentId/submissions');
    final data = response['data'];
    if (data is! List) return const [];
    return data
        .map((e) => AssignmentSubmissionSummary.fromJson(_asMap(e)))
        .toList(growable: false);
  }

  Future<void> markSubmissionComplete(
    String assignmentId,
    String studentId,
  ) async {
    await _api.post(
      '/faculty/assignments/$assignmentId/submissions/$studentId/complete',
    );
  }

  Future<void> reopenSubmission(String assignmentId, String studentId) async {
    await _api.post(
      '/faculty/assignments/$assignmentId/submissions/$studentId/reopen',
    );
  }

  Future<void> archiveAssignment(String assignmentId) async {
    await _api.delete('/faculty/assignments/$assignmentId');
  }

  // ── Student ─────────────────────────────────────────────────────

  Future<List<AssignmentSummary>> listMyAssignments() async {
    final response = await _api.get('/assignments');
    return _list(response);
  }

  Future<List<AssignmentSummary>> listClassroomAssignments(
    String classroomId,
  ) async {
    final response = await _api.get('/classrooms/$classroomId/assignments');
    return _list(response);
  }

  Future<AssignmentSummary> getAssignment(String id) async {
    final response = await _api.get('/assignments/$id');
    return AssignmentSummary.fromJson(_asMap(response['data']));
  }

  Future<AssignmentSummary> submitAssignment(
    String id, {
    String? responseText,
  }) async {
    final response = await _api.post(
      '/assignments/$id/submit',
      body: {
        'response_text': responseText,
      }..removeWhere((_, value) => value == null),
    );
    return AssignmentSummary.fromJson(_asMap(response['data']));
  }

  Future<AssignmentSummary> completeAssignment(String id) async {
    final response = await _api.post('/assignments/$id/complete');
    return AssignmentSummary.fromJson(_asMap(response['data']));
  }

  List<AssignmentSummary> _list(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is! List) return const [];
    return data
        .map((e) => AssignmentSummary.fromJson(_asMap(e)))
        .toList(growable: false);
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }
}
