import '../core/cache/memory_cache_store.dart';
import '../core/network/api_client.dart';
import '../models/notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final ApiClient _apiClient = ApiClient();
  final MemoryCacheStore _cache = MemoryCacheStore.instance;

  static const _notificationsTtl = Duration(minutes: 1);

  Future<List<NotificationModel>> getNotifications({
    bool refresh = false,
  }) async {
    return _cache.getOrFetch<List<NotificationModel>>(
      'notifications:list',
      ttl: _notificationsTtl,
      refresh: refresh,
      fetch: () async {
        final response = await _apiClient.get('/notifications');
        final data = response['data'];
        if (data is! List) return const [];

        return data
            .map((item) => NotificationModel.fromJson(_asMap(item)))
            .toList(growable: false);
      },
    );
  }

  Future<bool> markAsRead(String notificationId) async {
    // The mobile API intentionally has no persistent read/unread endpoint yet.
    return false;
  }

  Future<int> getUnreadCount({bool refresh = false}) async {
    final notifications = await getNotifications(refresh: refresh);
    return notifications.where((notification) => !notification.isRead).length;
  }

  void invalidateNotificationCaches() {
    _cache.invalidateByPrefix('notifications:');
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}
