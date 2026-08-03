import 'book.dart';

class AssignmentSubmissionSummary {
  final String id;
  final String status;
  final String? responseText;
  final DateTime? submittedAt;
  final DateTime? completedAt;
  final String? studentId;
  final String? studentNumber;
  final String? studentName;

  const AssignmentSubmissionSummary({
    required this.id,
    required this.status,
    this.responseText,
    this.submittedAt,
    this.completedAt,
    this.studentId,
    this.studentNumber,
    this.studentName,
  });

  factory AssignmentSubmissionSummary.fromJson(Map<String, dynamic> json) {
    final student = _asMap(json['student']);
    return AssignmentSubmissionSummary(
      id: _string(json['id']),
      status: _string(json['status'], fallback: 'assigned'),
      responseText: _nullable(json['response_text']),
      submittedAt: _date(json['submitted_at']),
      completedAt: _date(json['completed_at']),
      studentId: _nullable(student['id']),
      studentNumber: _nullable(student['id_number']),
      studentName: _nullable(student['name']),
    );
  }
}

class AssignmentSummary {
  final String id;
  final String title;
  final String? instructions;
  final DateTime? dueAt;
  final String status;
  final String? classroomId;
  final String? classroomName;
  final String? facultyName;
  final int bookCount;
  final List<Book> books;
  final AssignmentSubmissionSummary? mySubmission;
  final int assignedCount;
  final int submittedCount;
  final int completedCount;
  final int totalSubmissions;

  const AssignmentSummary({
    required this.id,
    required this.title,
    this.instructions,
    this.dueAt,
    this.status = 'published',
    this.classroomId,
    this.classroomName,
    this.facultyName,
    this.bookCount = 0,
    this.books = const [],
    this.mySubmission,
    this.assignedCount = 0,
    this.submittedCount = 0,
    this.completedCount = 0,
    this.totalSubmissions = 0,
  });

  bool get isOpenForStudent {
    final mine = mySubmission?.status;
    return mine == null || mine == 'assigned' || mine == 'submitted';
  }

  factory AssignmentSummary.fromJson(Map<String, dynamic> json) {
    final classroom = _asMap(json['classroom']);
    final faculty = _asMap(json['faculty']);
    final counts = _asMap(json['submission_counts']);
    final booksRaw = json['books'];
    final mySub = json['my_submission'];

    return AssignmentSummary(
      id: _string(json['id']),
      title: _string(json['title'], fallback: 'Untitled assignment'),
      instructions: _nullable(json['instructions']),
      dueAt: _date(json['due_at']),
      status: _string(json['status'], fallback: 'published'),
      classroomId: _nullable(classroom['id']),
      classroomName: _nullable(classroom['name']),
      facultyName: _nullable(faculty['name']),
      bookCount: _int(json['book_count']),
      books: booksRaw is List
          ? booksRaw.map((e) => Book.fromJson(_asMap(e))).toList(growable: false)
          : const [],
      mySubmission: mySub is Map
          ? AssignmentSubmissionSummary.fromJson(_asMap(mySub))
          : null,
      assignedCount: _int(counts['assigned']),
      submittedCount: _int(counts['submitted']),
      completedCount: _int(counts['completed']),
      totalSubmissions: _int(counts['total']),
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

String _string(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

String? _nullable(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int _int(Object? value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _date(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
