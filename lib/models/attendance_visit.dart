class AttendanceVisit {
  final int id;
  final DateTime timeIn;
  final DateTime? timeOut;
  final int? durationMinutes;

  const AttendanceVisit({
    required this.id,
    required this.timeIn,
    this.timeOut,
    this.durationMinutes,
  });

  factory AttendanceVisit.fromJson(Map<String, dynamic> json) {
    return AttendanceVisit(
      id: _intValue(json['id']),
      timeIn: DateTime.parse(json['time_in'].toString()),
      timeOut: json['time_out'] != null
          ? DateTime.parse(json['time_out'].toString())
          : null,
      durationMinutes: json['duration_minutes'] != null
          ? _intValue(json['duration_minutes'])
          : null,
    );
  }

  /// Whether the student is currently inside the library (no time_out).
  bool get isActive => timeOut == null;

  /// Human-readable duration string.
  String get durationText {
    if (durationMinutes == null) return '—';

    final hours = durationMinutes! ~/ 60;
    final mins = durationMinutes! % 60;

    if (hours > 0 && mins > 0) {
      return '${hours}h ${mins}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${mins}m';
    }
  }
}

class AttendancePreview {
  final List<AttendanceVisit> recentVisits;
  final int monthlyVisitCount;

  const AttendancePreview({
    required this.recentVisits,
    required this.monthlyVisitCount,
  });

  factory AttendancePreview.fromJson(Map<String, dynamic> json) {
    final visitsJson = json['recent_visits'];
    final visits = <AttendanceVisit>[];

    if (visitsJson is List) {
      for (final item in visitsJson) {
        if (item is! Map) continue;

        try {
          visits.add(
            AttendanceVisit.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          );
        } catch (_) {
          // Skip malformed rows instead of failing the whole preview.
        }
      }
    }

    return AttendancePreview(
      recentVisits: List<AttendanceVisit>.unmodifiable(visits),
      monthlyVisitCount: _intValue(json['monthly_visit_count']),
    );
  }
}

int _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
