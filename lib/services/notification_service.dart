import '../core/network/api_client.dart';
import '../models/notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final ApiClient _apiClient = ApiClient();

  Future<List<NotificationModel>> getNotifications() async {
    final response = await _apiClient.get('/notifications');
    final data = response['data'];
    if (data is! List) return const [];

    return data
        .map((item) => NotificationModel.fromJson(_asMap(item)))
        .toList(growable: false);
  }

  Future<bool> markAsRead(String notificationId) async {
    // The mobile API intentionally has no persistent read/unread endpoint yet.
    return false;
  }

  Future<int> getUnreadCount() async {
    final notifications = await getNotifications();
    return notifications.where((notification) => !notification.isRead).length;
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}
