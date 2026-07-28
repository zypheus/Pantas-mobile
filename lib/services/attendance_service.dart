import '../models/attendance_log.dart';
import '../core/cache/memory_cache_store.dart';
import '../core/network/api_client.dart';

class AttendanceService {
  static final AttendanceService _instance = AttendanceService._internal();

  factory AttendanceService() => _instance;

  AttendanceService._internal();

  final ApiClient _apiClient = ApiClient();
  final MemoryCacheStore _cache = MemoryCacheStore.instance;

  Future<AttendancePreview> getAttendancePreview({bool refresh = false}) async {
    return _cache.getOrFetch<AttendancePreview>(
      'mobile:attendance:preview',
      ttl: const Duration(minutes: 10),
      refresh: refresh,
      fetch: () async {
        final response = await _apiClient.get('/attendance/preview');
        final data = _asMap(response['data']);
        return AttendancePreview.fromJson(data);
      },
    );
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }
}