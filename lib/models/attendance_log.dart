class AttendanceLog {
  final String id;
  final String status;
  final DateTime scannedAt;

  const AttendanceLog({
    required this.id,
    required this.status,
    required this.scannedAt,
  });

  factory AttendanceLog.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final rawStatus = json['status'];
    final rawScannedAt = json['scanned_at'];

    return AttendanceLog(
      id: rawId?.toString() ?? '',
      status: rawStatus?.toString() ?? 'IN',
      scannedAt: DateTime.tryParse(rawScannedAt?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class AttendancePreview {
  final List<AttendanceLog> recentVisits;
  final int monthlyVisitCount;

  const AttendancePreview({
    this.recentVisits = const [],
    this.monthlyVisitCount = 0,
  });

  factory AttendancePreview.fromJson(Map<String, dynamic> json) {
    final recentRaw = json['recent_visits'];
    final monthlyCount = json['monthly_visit_count'] ?? json['monthly_visits'] ?? 0;

    List<AttendanceLog> recent = const [];
    if (recentRaw is List) {
      recent = recentRaw
          .map((item) => AttendanceLog.fromJson(_asMap(item)))
          .toList(growable: false);
    }

    return AttendancePreview(
      recentVisits: recent,
      monthlyVisitCount: _intValue(monthlyCount),
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

int _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}