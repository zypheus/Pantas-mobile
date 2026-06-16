import '../models/borrowed_book.dart';
import '../models/book.dart';
import '../core/network/api_client.dart';

class BorrowService {
  static final BorrowService _instance = BorrowService._internal();

  factory BorrowService() => _instance;

  BorrowService._internal();

  final ApiClient _apiClient = ApiClient();
  final List<BorrowCartItem> _borrowCart = [];
  String? lastCheckoutMessage;
  List<String> lastRejectedReasons = const [];

  List<String> getBorrowCart() {
    return _borrowCart.map((item) => item.bookId).toList(growable: false);
  }

  List<BorrowCartItem> getBorrowCartItems() {
    return List.unmodifiable(_borrowCart);
  }

  void addToBorrowCart(String bookId) {
    addToBorrowCartItem(BorrowCartItem(bookId: bookId));
  }

  void addBookToBorrowCart(Book book) {
    addToBorrowCartItem(
      BorrowCartItem(
        bookId: book.id,
        title: book.title,
        author: book.author,
        callNumber: book.callNumber,
        coverUrl: book.coverImage,
      ),
    );
  }

  void addCopyToBorrowCart(BookCopy copy, Book book) {
    addToBorrowCartItem(
      BorrowCartItem(
        bookId: copy.id,
        title: book.title,
        author: book.author,
        callNumber: copy.callNumber.isNotEmpty
            ? copy.callNumber
            : book.callNumber,
        accessionNo: copy.accessionNo,
        barcode: copy.barcode,
        coverUrl: book.coverImage,
      ),
    );
  }

  void addToBorrowCartItem(BorrowCartItem item) {
    if (!_borrowCart.any((cartItem) => cartItem.bookId == item.bookId)) {
      _borrowCart.add(item);
    }
  }

  void removeFromBorrowCart(String bookId) {
    _borrowCart.removeWhere((item) => item.bookId == bookId);
  }

  void clearBorrowCart() {
    _borrowCart.clear();
  }

  Future<List<BorrowedBook>> getCurrentBorrowedBooks() async {
    final response = await _apiClient.get('/borrowed-books');
    return _borrowedBooksFromResponse(response);
  }

  Future<List<BorrowedBook>> getBorrowHistory() async {
    final response = await _apiClient.get('/borrow-history');
    return _borrowedBooksFromResponse(response);
  }

  Future<BorrowLimits> getBorrowLimits() async {
    final response = await _apiClient.get('/borrow-limits');
    return BorrowLimits.fromJson(_asMap(response['data']));
  }

  Future<bool> submitCheckoutRequest(List<String> bookIds) async {
    final response = await _apiClient.post(
      '/borrow-cart/submit',
      body: {
        'book_ids': bookIds
            .map((id) => int.tryParse(id))
            .whereType<int>()
            .toList(growable: false),
      },
    );

    lastCheckoutMessage = response['message']?.toString();
    lastRejectedReasons = _rejectedReasons(response);
    _borrowCart.clear();
    return true;
  }

  Future<bool> renewBook(String bookId) async {
    // Renewing does not have a mobile API endpoint yet.
    return true;
  }

  List<BorrowedBook> _borrowedBooksFromResponse(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is! List) return const [];

    return data
        .map((item) => BorrowedBook.fromJson(_asMap(item)))
        .toList(growable: false);
  }

  List<String> _rejectedReasons(Map<String, dynamic> response) {
    final data = _asMap(response['data']);
    final rejected = data['rejected'];
    if (rejected is! List) return const [];

    return rejected
        .map((item) {
          final rejectedItem = _asMap(item);
          final title = rejectedItem['title']?.toString();
          final reason = rejectedItem['reason']?.toString();
          if (reason == null || reason.isEmpty) return null;
          if (title == null || title.isEmpty) return reason;
          return '$title: $reason';
        })
        .whereType<String>()
        .toList(growable: false);
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }
}

class BorrowCartItem {
  final String bookId;
  final String? title;
  final String? author;
  final String? callNumber;
  final String? accessionNo;
  final String? barcode;
  final String? coverUrl;

  const BorrowCartItem({
    required this.bookId,
    this.title,
    this.author,
    this.callNumber,
    this.accessionNo,
    this.barcode,
    this.coverUrl,
  });

  String get displayTitle =>
      title == null || title!.isEmpty ? 'Book $bookId' : title!;
  String get displayAuthor =>
      author == null || author!.isEmpty ? 'Unknown author' : author!;
  String get displayCallNumber => callNumber == null || callNumber!.isEmpty
      ? 'No call number'
      : callNumber!;
}

class BorrowLimits {
  final int maxActiveLoans;
  final int currentActiveLoans;
  final int remainingLoans;
  final bool hasOverdue;
  final bool canBorrow;
  final int reborrowCooldownDays;
  final bool fineSettingsConfigured;
  final int? loanDurationDays;
  final int? gracePeriodDays;

  const BorrowLimits({
    required this.maxActiveLoans,
    required this.currentActiveLoans,
    required this.remainingLoans,
    required this.hasOverdue,
    required this.canBorrow,
    required this.reborrowCooldownDays,
    required this.fineSettingsConfigured,
    this.loanDurationDays,
    this.gracePeriodDays,
  });

  factory BorrowLimits.fromJson(Map<String, dynamic> json) {
    return BorrowLimits(
      maxActiveLoans: _intValue(json['max_active_loans']),
      currentActiveLoans: _intValue(json['current_active_loans']),
      remainingLoans: _intValue(json['remaining_loans']),
      hasOverdue: _boolValue(json['has_overdue']),
      canBorrow: _boolValue(json['can_borrow']),
      reborrowCooldownDays: _intValue(json['reborrow_cooldown_days']),
      fineSettingsConfigured: _boolValue(json['fine_settings_configured']),
      loanDurationDays: _nullableIntValue(json['loan_duration_days']),
      gracePeriodDays: _nullableIntValue(json['grace_period_days']),
    );
  }
}

int _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _nullableIntValue(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

bool _boolValue(Object? value) {
  if (value is bool) return value;
  final stringValue = value?.toString().toLowerCase();
  return stringValue == 'true' || stringValue == '1';
}
