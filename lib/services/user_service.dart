import '../models/user.dart';
import '../core/cache/memory_cache_store.dart';
import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';

class UserService {
  static final UserService _instance = UserService._internal();

  factory UserService() => _instance;

  UserService._internal();

  final ApiClient _apiClient = ApiClient();
  final MemoryCacheStore _cache = MemoryCacheStore.instance;
  final TokenStorage _tokenStorage = TokenStorage();
  User? _currentUser;

  User? get currentUser => _currentUser;

  Future<User?> getCurrentUser({bool refresh = false}) async {
    if (_currentUser != null && !refresh) return _currentUser;

    final user = await _cache.getOrFetch<User>(
      'user:profile',
      ttl: const Duration(minutes: 5),
      refresh: refresh,
      fetch: () async {
        final response = await _apiClient.get('/profile');
        return User.fromApiJson(_asMap(response['data']));
      },
    );

    _currentUser = user;

    return user;
  }

  Future<bool> updatePassword(String oldPassword, String newPassword) async {
    await _apiClient.post(
      '/change-password',
      body: {
        'current_password': oldPassword,
        'password': newPassword,
        'password_confirmation': newPassword,
      },
    );

    await _tokenStorage.clearToken();
    clearCurrentUser();
    ApiClient.clearResponseCache();

    return true;
  }

  Future<bool> submitFeedback(String category, String message) async {
    await _apiClient.post(
      '/feedback',
      body: {'comments': '[$category] $message'},
    );

    return true;
  }

  void setCurrentUser(User user) {
    _currentUser = user;
    _cache.set<User>('user:profile', user, const Duration(minutes: 5));
  }

  void clearCurrentUser() {
    _currentUser = null;
    _cache.remove('user:profile');
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }
}
