class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final DateTime createdAt;
  final bool isRead;
  final String? relatedId;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.isRead,
    this.relatedId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final source = _asMap(json['source']);

    return NotificationModel(
      id: _stringValue(json['id']),
      title: _stringValue(json['title'], fallback: 'Notification'),
      message: _stringValue(json['message']),
      type: _stringValue(json['type'], fallback: 'announcement'),
      createdAt: _dateValue(json['created_at'] ?? json['date']),
      // Generated backend notifications do not persist read/unread state yet.
      isRead: _boolValue(json['is_read'] ?? json['isRead']),
      relatedId: _stringValue(source['id']).isNotEmpty
          ? _stringValue(source['id'])
          : null,
    );
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

String _stringValue(Object? value, {String fallback = ''}) {
  final stringValue = value?.toString();
  return stringValue == null || stringValue.isEmpty ? fallback : stringValue;
}

DateTime _dateValue(Object? value) {
  final stringValue = value?.toString();
  if (stringValue == null || stringValue.isEmpty) {
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  return DateTime.tryParse(stringValue) ??
      DateTime.fromMillisecondsSinceEpoch(0);
}

bool _boolValue(Object? value) {
  if (value is bool) return value;
  final stringValue = value?.toString().toLowerCase();
  return stringValue == 'true' || stringValue == '1';
}
