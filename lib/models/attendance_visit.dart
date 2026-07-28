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
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      timeIn: DateTime.parse(json['time_in'] as String),
      timeOut: json['time_out'] != null
          ? DateTime.parse(json['time_out'] as String)
          : null,
      durationMinutes: json['duration_minutes'] != null
          ? json['duration_minutes'] is int
              ? json['duration_minutes']
              : int.tryParse(json['duration_minutes'].toString())
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
    final visitsJson = json['recent_visits'] as List<dynamic>? ?? [];
    final visits = visitsJson
        .map((v) => AttendanceVisit.fromJson(v as Map<String, dynamic>))
        .toList();

    return AttendancePreview(
      recentVisits: visits,
      monthlyVisitCount:
          json['monthly_visit_count'] is int
              ? json['monthly_visit_count']
              : int.tryParse(json['monthly_visit_count']?.toString() ?? '0') ?? 0,
    );
  }
}