import 'dart:io';

import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../core/cache/memory_cache_store.dart';
import '../core/storage/token_storage.dart';
import '../models/user.dart';
import 'user_service.dart';

class LoginResult {
  final String token;
  final bool mustChangePassword;

  const LoginResult({
    required this.token,
    required this.mustChangePassword,
  });
}

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() => _instance;

  AuthService._internal();

  final ApiClient _apiClient = ApiClient();
  final MemoryCacheStore _cache = MemoryCacheStore.instance;
  final TokenStorage _tokenStorage = TokenStorage();
  final UserService _userService = UserService();

  /// Logs in with ID Number (student or faculty) and password.
  /// Returns a [LoginResult] indicating where to route the user next.
  Future<LoginResult> login(String loginId, String password) async {
    final response = await _apiClient.post(
      '/login',
      authenticated: false,
      body: {
        'login_id': loginId.trim(),
        'student_id': loginId.trim(), // backward compatible with older API clients
        'password': password,
      },
    );

    final mustChangePassword = response['must_change_password'] == true;

    final data = _asMap(response['data']);
    final token = data['token']?.toString();

    if (token == null || token.isEmpty) {
      throw const ApiException(
        message: 'Login response did not include a token.',
      );
    }

    await _tokenStorage.saveToken(token);
    _cache.clear();
    ApiClient.clearResponseCache();
    _userService.setCurrentUser(User.fromApiJson(data));

    return LoginResult(
      token: token,
      mustChangePassword: mustChangePassword,
    );
  }

  /// Submits a teaching-faculty registration for library staff approval.
  Future<String> registerFaculty({
    required String firstname,
    required String lastname,
    String? middleInitial,
    required String employeeId,
    required String designation,
    required String department,
    required DateTime birthday,
    required String mobileNumber,
    String? address,
    String? emergencyContactName,
    String? emergencyContactRelationship,
    String? emergencyContactNumber,
    String? emergencyAddress,
    File? profilePicture,
  }) async {
    final fields = {
      'firstname': firstname.trim(),
      'lastname': lastname.trim(),
      'middle_initial': middleInitial?.trim(),
      'employee_id': employeeId.trim(),
      'designation': designation.trim(),
      'department': department.trim(),
      'program': department.trim(),
      'birthday':
          '${birthday.year.toString().padLeft(4, '0')}-'
          '${birthday.month.toString().padLeft(2, '0')}-'
          '${birthday.day.toString().padLeft(2, '0')}',
      'mobile_number': mobileNumber.trim(),
      'address': address?.trim(),
      'emergency_contact_name': emergencyContactName?.trim(),
      'emergency_contact_relationship': emergencyContactRelationship?.trim(),
      'emergency_contact_number': emergencyContactNumber?.trim(),
      'emergency_address': emergencyAddress?.trim(),
    }..removeWhere((_, value) => value == null || value == '');

    final response = profilePicture != null
        ? await _apiClient.postMultipart(
            '/register/faculty',
            authenticated: false,
            fields: fields.cast<String, String>(),
            files: [
              FileUpload(
                field: 'profile_picture',
                path: profilePicture.path,
                filename: profilePicture.path.split(Platform.pathSeparator).last,
              ),
            ],
          )
        : await _apiClient.post(
            '/register/faculty',
            authenticated: false,
            body: fields,
          );

    return response['message']?.toString() ??
        'Faculty registration submitted. Please wait for library approval.';
  }

  Future<String> registerStudent({
    required String firstname,
    required String lastname,
    String? middleInitial,
    required String studentId,
    required String course,
    required String year,
    required DateTime birthday,
    required String mobileNumber,
    String? address,
    String? emergencyContactName,
    String? emergencyContactRelationship,
    String? emergencyContactNumber,
    String? emergencyAddress,
    File? profilePicture,
  }) async {
    final fields = {
      'firstname': firstname.trim(),
      'lastname': lastname.trim(),
      'middle_initial': middleInitial?.trim(),
      'student_id': studentId.trim(),
      'course': course.trim(),
      'year': year.trim(),
      'birthday':
          '${birthday.year.toString().padLeft(4, '0')}-'
          '${birthday.month.toString().padLeft(2, '0')}-'
          '${birthday.day.toString().padLeft(2, '0')}',
      'mobile_number': mobileNumber.trim(),
      'address': address?.trim(),
      'emergency_contact_name': emergencyContactName?.trim(),
      'emergency_contact_relationship': emergencyContactRelationship?.trim(),
      'emergency_contact_number': emergencyContactNumber?.trim(),
      'emergency_address': emergencyAddress?.trim(),
    }..removeWhere((_, value) => value == null || value == '');

    final response = profilePicture != null
        ? await _apiClient.postMultipart(
            '/register/student',
            authenticated: false,
            fields: fields.cast<String, String>(),
            files: [
              FileUpload(
                field: 'profile_picture',
                path: profilePicture.path,
                filename: profilePicture.path.split(Platform.pathSeparator).last,
              ),
            ],
          )
        : await _apiClient.post(
            '/register/student',
            authenticated: false,
            body: fields,
          );

    return response['message']?.toString() ??
        'Student registration submitted. Please wait for library approval.';
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    final response = await _apiClient.post(
      '/student/change-password',
      body: {
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': newPasswordConfirmation,
      },
    );

    final data = _asMap(response['data']);
    final token = data['token']?.toString();

    if (token != null && token.isNotEmpty) {
      await _tokenStorage.saveToken(token);
      _cache.clear();
      ApiClient.clearResponseCache();
    }

    // Refresh user data
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
      ApiClient.clearResponseCache();
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
      ApiClient.clearResponseCache();
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
