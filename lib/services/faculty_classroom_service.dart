import '../core/network/api_client.dart';
import '../models/classroom.dart';

class FacultyClassroomService {
  static final FacultyClassroomService _instance =
      FacultyClassroomService._internal();
  factory FacultyClassroomService() => _instance;
  FacultyClassroomService._internal();

  final ApiClient _api = ApiClient();

  Future<List<ClassroomSummary>> getClassrooms() async {
    final response = await _api.get('/faculty/classrooms');
    final data = response['data'];
    if (data is! List) return const [];
    return data
        .map((e) => ClassroomSummary.fromJson(_asMap(e)))
        .toList(growable: false);
  }

  Future<ClassroomSummary> createClassroom({
    required String name,
    String? description,
    String? subject,
    bool isPrivate = true,
    bool requiresApproval = false,
  }) async {
    final response = await _api.post(
      '/faculty/classrooms',
      body: {
        'name': name,
        'description': description,
        'subject': subject,
        'is_private': isPrivate,
        'requires_approval': requiresApproval,
      },
    );
    return ClassroomSummary.fromJson(_asMap(response['data']));
  }

  Future<ClassroomSummary> getClassroom(String id) async {
    final response = await _api.get('/faculty/classrooms/$id');
    return ClassroomSummary.fromJson(_asMap(response['data']));
  }

  Future<List<ClassroomMemberSummary>> getMembers(String classroomId) async {
    final response = await _api.get('/faculty/classrooms/$classroomId/members');
    final data = response['data'];
    if (data is! List) return const [];
    return data
        .map((e) => ClassroomMemberSummary.fromJson(_asMap(e)))
        .toList(growable: false);
  }

  Future<void> approveMember(String classroomId, String memberId) async {
    await _api.post('/faculty/classrooms/$classroomId/members/$memberId/approve');
  }

  Future<void> rejectMember(String classroomId, String memberId) async {
    await _api.post('/faculty/classrooms/$classroomId/members/$memberId/reject');
  }

  Future<ClassroomSummary> regenerateCode(String classroomId) async {
    final response =
        await _api.post('/faculty/classrooms/$classroomId/regenerate-code');
    return ClassroomSummary.fromJson(_asMap(response['data']));
  }

  Future<void> shareFolder(String classroomId, String folderId) async {
    await _api.post(
      '/faculty/classrooms/$classroomId/folders',
      body: {'folder_id': int.tryParse(folderId) ?? folderId},
    );
  }

  Future<void> unshareFolder(String classroomId, String folderId) async {
    await _api.delete('/faculty/classrooms/$classroomId/folders/$folderId');
  }

  Future<List<FacultyFolderSummary>> getFolders() async {
    final response = await _api.get('/faculty/folders');
    final data = response['data'];
    if (data is! List) return const [];
    return data
        .map((e) => FacultyFolderSummary.fromJson(_asMap(e)))
        .toList(growable: false);
  }

  Future<FacultyFolderSummary> createFolder({
    required String name,
    String? description,
  }) async {
    final response = await _api.post(
      '/faculty/folders',
      body: {'name': name, 'description': description},
    );
    return FacultyFolderSummary.fromJson(_asMap(response['data']));
  }

  Future<FacultyFolderSummary> getFolder(String id) async {
    final response = await _api.get('/faculty/folders/$id');
    return FacultyFolderSummary.fromJson(_asMap(response['data']));
  }

  Future<void> addBooksToFolder(String folderId, List<String> bookIds) async {
    await _api.post(
      '/faculty/folders/$folderId/books',
      body: {
        'book_ids': bookIds.map((id) => int.tryParse(id) ?? id).toList(),
      },
    );
  }

  Future<void> removeBookFromFolder(String folderId, String bookId) async {
    await _api.delete('/faculty/folders/$folderId/books/$bookId');
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }
}
