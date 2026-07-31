import 'book.dart';

class ClassroomSummary {
  final String id;
  final String name;
  final String? description;
  final String? subject;
  final String? joinCode;
  final bool isPrivate;
  final bool requiresApproval;
  final int memberCount;
  final int pendingCount;
  final int folderCount;
  final String? facultyName;
  final String? membershipStatus;
  final List<Book> books;
  final List<FacultyFolderSummary> folders;

  const ClassroomSummary({
    required this.id,
    required this.name,
    this.description,
    this.subject,
    this.joinCode,
    this.isPrivate = true,
    this.requiresApproval = false,
    this.memberCount = 0,
    this.pendingCount = 0,
    this.folderCount = 0,
    this.facultyName,
    this.membershipStatus,
    this.books = const [],
    this.folders = const [],
  });

  factory ClassroomSummary.fromJson(Map<String, dynamic> json) {
    final faculty = _asMap(json['faculty']);
    final booksRaw = json['books'];
    final foldersRaw = json['folders'];

    return ClassroomSummary(
      id: _string(json['id']),
      name: _string(json['name'], fallback: 'Untitled classroom'),
      description: _nullable(json['description']),
      subject: _nullable(json['subject']),
      joinCode: _nullable(json['join_code']),
      isPrivate: json['is_private'] != false,
      requiresApproval: json['requires_approval'] == true,
      memberCount: _int(json['member_count']),
      pendingCount: _int(json['pending_count']),
      folderCount: _int(json['folder_count']),
      facultyName: _nullable(faculty['name']),
      membershipStatus: _nullable(json['membership_status']),
      books: booksRaw is List
          ? booksRaw.map((e) => Book.fromJson(_asMap(e))).toList(growable: false)
          : const [],
      folders: foldersRaw is List
          ? foldersRaw
              .map((e) => FacultyFolderSummary.fromJson(_asMap(e)))
              .toList(growable: false)
          : const [],
    );
  }
}

class ClassroomMemberSummary {
  final String id;
  final String status;
  final String? studentId;
  final String? studentNumber;
  final String name;
  final String? course;
  final String? year;

  const ClassroomMemberSummary({
    required this.id,
    required this.status,
    this.studentId,
    this.studentNumber,
    required this.name,
    this.course,
    this.year,
  });

  factory ClassroomMemberSummary.fromJson(Map<String, dynamic> json) {
    final student = _asMap(json['student']);
    return ClassroomMemberSummary(
      id: _string(json['id']),
      status: _string(json['status'], fallback: 'pending'),
      studentId: _nullable(student['id']),
      studentNumber: _nullable(student['id_number']),
      name: _nullable(student['name']) ??
          '${_nullable(student['firstname']) ?? ''} ${_nullable(student['lastname']) ?? ''}'
              .trim(),
      course: _nullable(student['course']),
      year: _nullable(student['year']),
    );
  }
}

class FacultyFolderSummary {
  final String id;
  final String name;
  final String? description;
  final int bookCount;
  final int classroomCount;
  final List<Book> books;

  const FacultyFolderSummary({
    required this.id,
    required this.name,
    this.description,
    this.bookCount = 0,
    this.classroomCount = 0,
    this.books = const [],
  });

  factory FacultyFolderSummary.fromJson(Map<String, dynamic> json) {
    final booksRaw = json['books'];
    return FacultyFolderSummary(
      id: _string(json['id']),
      name: _string(json['name'], fallback: 'Untitled folder'),
      description: _nullable(json['description']),
      bookCount: _int(json['book_count']),
      classroomCount: _int(json['classroom_count']),
      books: booksRaw is List
          ? booksRaw.map((e) => Book.fromJson(_asMap(e))).toList(growable: false)
          : const [],
    );
  }
}

class FacultyRecommendationGroup {
  final ClassroomSummary classroom;
  final List<Book> books;

  const FacultyRecommendationGroup({
    required this.classroom,
    required this.books,
  });

  factory FacultyRecommendationGroup.fromJson(Map<String, dynamic> json) {
    final booksRaw = json['books'];
    return FacultyRecommendationGroup(
      classroom: ClassroomSummary.fromJson(_asMap(json['classroom'])),
      books: booksRaw is List
          ? booksRaw.map((e) => Book.fromJson(_asMap(e))).toList(growable: false)
          : const [],
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
  final s = value?.toString();
  return s == null || s.isEmpty ? fallback : s;
}

String? _nullable(Object? value) {
  final s = value?.toString();
  return s == null || s.isEmpty ? null : s;
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
