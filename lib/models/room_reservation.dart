class RoomReservation {
  final String id;
  final String roomId;
  final String roomName;
  final int roomCapacity;
  final DateTime reservationDate;
  final String startTime;
  final String endTime;
  final String status; // e.g., pending, approved, rejected
  final String patronEmail;
  final int numberOfStudents;
  final List<String> studentNames;
  final String notes;
  final DateTime? approvedAt;
  final DateTime createdAt;

  RoomReservation({
    required this.id,
    required this.roomId,
    required this.roomName,
    required this.roomCapacity,
    required this.reservationDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.patronEmail,
    required this.numberOfStudents,
    required this.studentNames,
    required this.notes,
    this.approvedAt,
    required this.createdAt,
  });

  factory RoomReservation.fromJson(Map<String, dynamic> json) {
    final room = _asMap(json['room']);
    final studentNames = json['student_names'];

    return RoomReservation(
      id: _stringValue(json['id']),
      roomId: _stringValue(room['id']),
      roomName: _stringValue(room['name'], fallback: 'Room'),
      roomCapacity: _intValue(room['capacity']),
      reservationDate: _dateValue(json['date']),
      startTime: _stringValue(json['start_time']),
      endTime: _stringValue(json['end_time']),
      status: _stringValue(json['status'], fallback: 'pending'),
      patronEmail: _stringValue(json['patron_email']),
      numberOfStudents: _intValue(json['number_of_students']),
      studentNames: studentNames is List
          ? studentNames.map((name) => name.toString()).toList(growable: false)
          : const [],
      notes: _stringValue(json['notes']),
      approvedAt: _nullableDateValue(json['approved_at']),
      createdAt: _dateValue(json['created_at']),
    );
  }

  bool get canCancel => status.toLowerCase() == 'pending';

  String get displayStatus {
    final value = status.replaceAll('_', ' ');
    if (value.isEmpty) return 'Pending';
    return value[0].toUpperCase() + value.substring(1);
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

int _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime _dateValue(Object? value) {
  return _nullableDateValue(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? _nullableDateValue(Object? value) {
  final stringValue = value?.toString();
  if (stringValue == null || stringValue.isEmpty) return null;
  return DateTime.tryParse(stringValue);
}
