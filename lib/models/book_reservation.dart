/// Represents a book reservation placed by a student when no copies are
/// available. The student joins a queue and is notified when a copy becomes
/// available (i.e. returned by another borrower).
class BookReservation {
  final String id;
  final String bookId;
  final String bookTitle;
  final String bookAuthor;
  final String? coverUrl;
  final String callNumber;
  final String status;
  final int queuePosition;
  final DateTime reservedAt;
  final DateTime? availableAt;
  final DateTime? expiresAt;
  final DateTime? fulfilledAt;
  final DateTime? cancelledAt;
  final String? heldCallNumber;
  final String? heldAccessionNo;

  const BookReservation({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.bookAuthor,
    this.coverUrl,
    required this.callNumber,
    required this.status,
    required this.queuePosition,
    required this.reservedAt,
    this.availableAt,
    this.expiresAt,
    this.fulfilledAt,
    this.cancelledAt,
    this.heldCallNumber,
    this.heldAccessionNo,
  });

  /// Status values returned by the API.
  /// - `pending`     — waiting in the queue for a copy to become available
  /// - `ready`       — a copy is available and held for the student
  /// - `fulfilled`   — the student borrowed the reserved book
  /// - `expired`     — the hold expired before the student claimed the book
  /// - `cancelled`   — the student (or staff) cancelled the reservation
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isReady => status.toLowerCase() == 'ready';
  bool get isFulfilled => status.toLowerCase() == 'fulfilled';
  bool get isExpired => status.toLowerCase() == 'expired';
  bool get isCancelled => status.toLowerCase() == 'cancelled';
  bool get isActive => isPending || isReady;

  /// A human-readable label for the current status.
  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Waiting in queue';
      case 'ready':
        return 'Available — ready to claim';
      case 'fulfilled':
        return 'Fulfilled';
      case 'expired':
        return 'Expired';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.isNotEmpty
            ? status[0].toUpperCase() + status.substring(1)
            : 'Unknown';
    }
  }

  factory BookReservation.fromJson(Map<String, dynamic> json) {
    final book = _asMap(json['book']);
    final bookGroup = _asMap(book['group']);
    final bookDescription = _asMap(book['description']);

    final heldCopy = _asMap(json['held_copy']);

    return BookReservation(
      id: _stringValue(json['id']),
      bookId: _stringValue(book['id'], fallback: _stringValue(json['book_id'])),
      bookTitle: _stringValue(
        bookGroup['title'],
        fallback: _stringValue(
          bookDescription['title'],
          fallback: _stringValue(json['book_title'], fallback: 'Untitled'),
        ),
      ),
      bookAuthor: _stringValue(
        bookGroup['author'],
        fallback: _stringValue(
          bookDescription['author'],
          fallback: _stringValue(json['book_author'], fallback: 'Unknown author'),
        ),
      ),
      coverUrl: _nullableString(
        bookDescription['cover_url'] ?? bookGroup['cover_url'],
      ),
      callNumber: _stringValue(
        bookDescription['call_number'],
        fallback: _stringValue(bookGroup['call_number']),
      ),
      status: _stringValue(json['status'], fallback: 'pending'),
      queuePosition: _intValue(json['queue_position']),
      reservedAt: _dateValue(json['reserved_at'] ?? json['created_at']),
      availableAt: _nullableDate(json['available_at']),
      expiresAt: _nullableDate(json['expires_at'] ?? json['hold_expires_at']),
      fulfilledAt: _nullableDate(json['fulfilled_at']),
      cancelledAt: _nullableDate(json['cancelled_at']),
      heldCallNumber: _nullableString(heldCopy['call_number']),
      heldAccessionNo: _nullableString(heldCopy['accession_no']),
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

String? _nullableString(Object? value) {
  final stringValue = value?.toString();
  return stringValue == null || stringValue.isEmpty ? null : stringValue;
}

int _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime _dateValue(Object? value) {
  final stringValue = value?.toString();
  if (stringValue == null || stringValue.isEmpty) {
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
  return DateTime.tryParse(stringValue) ??
      DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? _nullableDate(Object? value) {
  final stringValue = value?.toString();
  if (stringValue == null || stringValue.isEmpty) return null;
  return DateTime.tryParse(stringValue);
}