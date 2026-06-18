import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../core/cache/memory_cache_store.dart';
import '../core/storage/token_storage.dart';
import '../models/user.dart';
import 'user_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() => _instance;

  AuthService._internal();

  final ApiClient _apiClient = ApiClient();
  final MemoryCacheStore _cache = MemoryCacheStore.instance;
  final TokenStorage _tokenStorage = TokenStorage();
  final UserService _userService = UserService();

  Future<bool> login(String studentId, [String? unusedPassword]) async {
    final response = await _apiClient.post(
      '/login',
      authenticated: false,
      body: {'student_id': studentId.trim()},
    );

    final data = _asMap(response['data']);
    final token = data['token']?.toString();

    if (token == null || token.isEmpty) {
      throw const ApiException(
        message: 'Login response did not include a token.',
      );
    }

    await _tokenStorage.saveToken(token);
    _cache.clear();
    _userService.setCurrentUser(User.fromApiJson(data));
    return true;
  }

  Future<bool> logout() async {
    try {
      await _apiClient.post('/logout');
    } on ApiException catch (exception) {
      if (!exception.isUnauthenticated) {
        rethrow;
      }
    } finally {
      await _tokenStorage.clearToken();
      _userService.clearCurrentUser();
      _cache.clear();
    }

    return true;
  }

  Future<bool> isAuthenticated() async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      return false;
    }

    try {
      await _userService.getCurrentUser(refresh: true);
      return true;
    } on ApiException {
      await _tokenStorage.clearToken();
      _userService.clearCurrentUser();
      _cache.clear();
      return false;
    }
  }

  Future<String?> getToken() async {
    return _tokenStorage.readToken();
  }

  Future<bool> resetPassword(String email) async {
    // Student ID mobile login does not use passwords.
    return true;
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }
}
