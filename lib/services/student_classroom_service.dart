import '../core/network/api_client.dart';
import '../models/classroom.dart';

class StudentClassroomService {
  static final StudentClassroomService _instance =
      StudentClassroomService._internal();
  factory StudentClassroomService() => _instance;
  StudentClassroomService._internal();

  final ApiClient _api = ApiClient();

  Future<List<ClassroomSummary>> getMyClassrooms() async {
    final response = await _api.get('/classrooms');
    final data = response['data'];
    if (data is! List) return const [];
    return data
        .map((e) => ClassroomSummary.fromJson(_asMap(e)))
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> joinClassroom(String joinCode) async {
    final response = await _api.post(
      '/classrooms/join',
      body: {'join_code': joinCode.trim()},
    );
    return {
      'message': response['message']?.toString() ?? 'Joined.',
      'data': _asMap(response['data']),
    };
  }

  Future<ClassroomSummary> getClassroom(String id) async {
    final response = await _api.get('/classrooms/$id');
    return ClassroomSummary.fromJson(_asMap(response['data']));
  }

  Future<void> leaveClassroom(String id) async {
    await _api.delete('/classrooms/$id/leave');
  }

  Future<List<FacultyRecommendationGroup>> getFacultyRecommendations({
    bool refresh = false,
  }) async {
    final response = await _api.get('/home/faculty-recommendations');
    final data = response['data'];
    if (data is! List) return const [];
    return data
        .map((e) => FacultyRecommendationGroup.fromJson(_asMap(e)))
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
