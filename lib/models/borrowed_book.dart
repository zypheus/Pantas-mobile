class BorrowedBook {
  final String id;
  final String bookId;
  final String title;
  final String author;
  final String callNumber;
  final String accessionNo;
  final String barcode;
  final DateTime dueDate;
  final DateTime borrowDate;
  final DateTime? returnedDate;
  final bool isOverdue;
  final int daysOverdue;
  final double fine;
  final String status; // e.g., Active, Reserved, Returned

  BorrowedBook({
    required this.id,
    required this.bookId,
    required this.title,
    required this.author,
    required this.callNumber,
    required this.accessionNo,
    required this.barcode,
    required this.dueDate,
    required this.borrowDate,
    this.returnedDate,
    required this.isOverdue,
    required this.daysOverdue,
    required this.fine,
    required this.status,
  });

  factory BorrowedBook.fromJson(Map<String, dynamic> json) {
    return BorrowedBook(
      id: _stringValue(json['id']),
      bookId: _stringValue(json['book_id']),
      title: _stringValue(json['title'], fallback: 'Untitled'),
      author: _stringValue(json['author'], fallback: 'Unknown author'),
      callNumber: _stringValue(json['call_number']),
      accessionNo: _stringValue(json['accession_no']),
      barcode: _stringValue(json['barcode']),
      borrowDate: _dateValue(json['borrowed_at']),
      dueDate: _dateValue(json['due_at']),
      returnedDate: _nullableDateValue(json['returned_at']),
      status: _stringValue(json['status'], fallback: 'Checked Out'),
      isOverdue: _boolValue(json['is_overdue']),
      daysOverdue: _intValue(json['days_overdue']),
      fine: _doubleValue(json['fine']),
    );
  }

  bool get isReturned {
    final normalized = status.toLowerCase();
    return normalized == 'checked in' || normalized == 'returned';
  }

  String get displayStatus {
    if (isReturned) return 'Returned';
    if (isOverdue) return 'Overdue';
    return status.isEmpty ? 'Checked Out' : status;
  }
}

String _stringValue(Object? value, {String fallback = ''}) {
  final stringValue = value?.toString();
  return stringValue == null || stringValue.isEmpty ? fallback : stringValue;
}

bool _boolValue(Object? value) {
  if (value is bool) return value;
  final stringValue = value?.toString().toLowerCase();
  return stringValue == 'true' || stringValue == '1';
}

int _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _doubleValue(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime _dateValue(Object? value) {
  return _nullableDateValue(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? _nullableDateValue(Object? value) {
  final stringValue = value?.toString();
  if (stringValue == null || stringValue.isEmpty) return null;
  return DateTime.tryParse(stringValue);
}
