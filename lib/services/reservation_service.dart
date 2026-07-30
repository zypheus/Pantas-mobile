import '../core/cache/memory_cache_store.dart';
import '../core/network/api_client.dart';
import '../models/book_reservation.dart';
import 'notification_service.dart';

/// Manages book reservations (the "reserve" queue) for the OPAC.
///
/// When a book has no available copies, a student may reserve it. The student
/// is placed in a queue. When a copy is returned, the backend notifies the
/// next student in the queue (in-app, email, or SMS) and holds the copy for
/// them until the reservation expires.
class ReservationService {
  static final ReservationService _instance = ReservationService._internal();

  factory ReservationService() => _instance;

  ReservationService._internal();

  final ApiClient _apiClient = ApiClient();
  final MemoryCacheStore _cache = MemoryCacheStore.instance;
  String? lastMessage;

  static const _reservationsTtl = Duration(minutes: 2);
  static const _reservationDetailsTtl = Duration(minutes: 2);

  /// Reserve a book (join the queue) when no copies are available.
  ///
  /// [bookId] is the catalog book group id. Returns the created reservation
  /// with the student's initial queue position.
  Future<BookReservation> reserveBook(String bookId) async {
    final response = await _apiClient.post(
      '/books/reservations',
      body: {
        'book_id': int.tryParse(bookId) ?? bookId,
      },
    );

    lastMessage = response['message']?.toString();
    invalidateReservationCaches();

    return BookReservation.fromJson(_asMap(response['data']));
  }

  /// Cancel an active reservation (leave the queue).
  Future<BookReservation> cancelReservation(String reservationId) async {
    final response = await _apiClient.delete(
      '/books/reservations/$reservationId',
    );

    lastMessage = response['message']?.toString();
    invalidateReservationCaches();
    _cache.remove('books:reservation:$reservationId');

    return BookReservation.fromJson(_asMap(response['data']));
  }

  /// Get the current student's active and past reservations.
  Future<List<BookReservation>> getMyReservations({
    bool refresh = false,
  }) async {
    return _cache.getOrFetch<List<BookReservation>>(
      'books:reservations:user',
      ttl: _reservationsTtl,
      refresh: refresh,
      fetch: () async {
        final response = await _apiClient.get('/books/reservations');
        final data = response['data'];
        if (data is! List) return const [];

        return data
            .map((item) => BookReservation.fromJson(_asMap(item)))
            .toList(growable: false);
      },
    );
  }

  /// Get details for a single reservation.
  Future<BookReservation> getReservationDetails(
    String id, {
    bool refresh = false,
  }) async {
    return _cache.getOrFetch<BookReservation>(
      'books:reservation:$id',
      ttl: _reservationDetailsTtl,
      refresh: refresh,
      fetch: () async {
        final response = await _apiClient.get('/books/reservations/$id');
        return BookReservation.fromJson(_asMap(response['data']));
      },
    );
  }

  /// Check whether the current student already has an active reservation
  /// for the given [bookId]. Used by the book details screen to toggle the
  /// "Reserve" button into a "Cancel reservation" state.
  Future<BookReservation?> getActiveReservationForBook(String bookId) async {
    final reservations = await getMyReservations();
    for (final reservation in reservations) {
      if (reservation.bookId == bookId && reservation.isActive) {
        return reservation;
      }
    }
    return null;
  }

  /// Refresh notifications after a reservation becomes available so the
  /// notifications list reflects the new "book ready" alert.
  void refreshNotifications() {
    NotificationService().invalidateNotificationCaches();
  }

  void invalidateReservationCaches() {
    _cache.invalidateByPrefix('books:reservations:');
    _cache.invalidateByPrefix('books:reservation:');
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }
}