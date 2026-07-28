import '../core/network/api_client.dart';
import '../models/attendance_visit.dart';

class AttendanceService {
  static final AttendanceService _instance = AttendanceService._internal();

  factory AttendanceService() => _instance;

  AttendanceService._internal();

  final ApiClient _apiClient = ApiClient();

  Future<AttendancePreview> getAttendancePreview() async {
    final response = await _apiClient.get('/attendance/preview');

    final data = response['data'] as Map<String, dynamic>? ?? {};

    return AttendancePreview.fromJson(data);
  }
}