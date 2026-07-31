import '../models/book.dart';
import '../models/borrowed_book.dart';
import '../core/cache/memory_cache_store.dart';
import '../core/network/api_client.dart';

class CatalogService {
  static final CatalogService _instance = CatalogService._internal();

  factory CatalogService() => _instance;

  CatalogService._internal();

  final ApiClient _apiClient = ApiClient();
  final MemoryCacheStore _cache = MemoryCacheStore.instance;

  static const _newArrivalsTtl = Duration(minutes: 10);
  static const _filtersTtl = Duration(minutes: 30);
  static const _searchTtl = Duration(minutes: 5);
  static const _bookDetailsTtl = Duration(minutes: 5);
  static const _homeOverviewTtl = Duration(minutes: 1);

  Future<HomeOverview> getHomeOverview({bool refresh = false}) async {
    return _cache.getOrFetch<HomeOverview>(
      'mobile:home',
      ttl: _homeOverviewTtl,
      refresh: refresh,
      fetch: () async {
        final response = await _apiClient.get('/home');
        final data = _asMap(response['data']);
        final newArrivals = data['new_arrivals'];
        final activeLoans = data['active_loans'];
        final loanStats = _asMap(data['loan_stats']);
        final recommendedRaw = data['recommended_books'] ??
            data['recommendations'];

        List<Book> recommendedBooks = const [];
        if (recommendedRaw is List) {
          recommendedBooks = recommendedRaw
              .map((item) => Book.fromJson(_asMap(item)))
              .toList(growable: false);
        }

        return HomeOverview(
          newArrivals: newArrivals is List
              ? newArrivals
                    .map((item) => Book.fromJson(_asMap(item)))
                    .toList(growable: false)
              : const [],
          activeLoans: activeLoans is List
              ? activeLoans
                    .map((item) => BorrowedBook.fromJson(_asMap(item)))
                    .toList(growable: false)
              : const [],
          loanStats: HomeLoanStats.fromJson(loanStats),
          recommendedBooks: recommendedBooks,
          recommendationContext: RecommendationContext.fromJson(
            _asMap(data['recommendation_context']),
          ),
        );
      },
    );
  }

  Future<List<Book>> getRecommendations({bool refresh = false}) async {
    return _cache.getOrFetch<List<Book>>(
      'mobile:home:recommendations',
      ttl: const Duration(minutes: 15),
      refresh: refresh,
      fetch: () async {
        final response = await _apiClient.get('/home/recommendations');
        final data = response['data'];
        if (data is! List) return const [];

        return data
            .map((item) => Book.fromJson(_asMap(item)))
            .toList(growable: false);
      },
    );
  }

  Future<List<Book>> getNewArrivals({
    int limit = 12,
    String? course,
    bool refresh = false,
  }) async {
    final queryParameters = {
      'limit': limit,
      'course': course,
    }..removeWhere((_, value) => value == null || value == '');

    return _cache.getOrFetch<List<Book>>(
      _cacheKey('catalog:new-arrivals', queryParameters),
      ttl: _newArrivalsTtl,
      refresh: refresh,
      fetch: () async {
        final response = await _apiClient.get(
          '/catalog/new-arrivals',
          authenticated: false,
          queryParameters: queryParameters,
        );

        final data = response['data'];
        if (data is! List) return const [];

        return data
            .map((item) => Book.fromJson(_asMap(item)))
            .toList(growable: false);
      },
    );
  }

  Future<List<Book>> searchBooks(
    String query, {
    String? format,
    String? section,
    String? subject,
    String? course,
    int page = 1,
    int perPage = 10,
    bool refresh = false,
  }) async {
    final catalogPage = await searchCatalog(
      query,
      format: format,
      section: section,
      subject: subject,
      course: course,
      page: page,
      perPage: perPage,
      refresh: refresh,
    );

    return catalogPage.books;
  }

  Future<CatalogPage> searchCatalog(
    String query, {
    String? format,
    String? section,
    String? subject,
    String? course,
    int page = 1,
    int perPage = 10,
    bool refresh = false,
  }) async {
    final queryParameters = {
      'search': query.trim(),
      'view': format == 'ebooks' || format == 'E-book' ? 'ebooks' : 'books',
      'course': course,
      'content_type': format == 'ebooks' || format == 'E-book' ? null : format,
      'section': section,
      'subject_topic': subject,
      'page': page,
      'per_page': perPage,
    }..removeWhere((_, value) => value == null || value == '');

    return _cache.getOrFetch<CatalogPage>(
      _cacheKey('catalog:search', queryParameters),
      ttl: _searchTtl,
      refresh: refresh,
      fetch: () async {
        final response = await _apiClient.get(
          '/catalog/search',
          authenticated: false,
          queryParameters: queryParameters,
        );

        return CatalogPage.fromJson(response);
      },
    );
  }

  Future<Book?> getBookDetails(String bookId, {bool refresh = false}) async {
    final details = await getBookDetail(bookId, refresh: refresh);
    return details.book;
  }

  Future<BookDetails> getBookDetail(
    String bookId, {
    bool refresh = false,
  }) async {
    return _cache.getOrFetch<BookDetails>(
      'catalog:book:$bookId',
      ttl: _bookDetailsTtl,
      refresh: refresh,
      fetch: () async {
        final response = await _apiClient.get(
          '/catalog/books/$bookId',
          authenticated: false,
        );

        return BookDetails.fromJson(response);
      },
    );
  }

  Future<CatalogFilters> getFilters({bool refresh = false}) async {
    return _cache.getOrFetch<CatalogFilters>(
      'catalog:filters',
      ttl: _filtersTtl,
      refresh: refresh,
      fetch: () async {
        final response = await _apiClient.get(
          '/catalog/filters',
          authenticated: false,
        );

        return CatalogFilters.fromJson(_asMap(response['data']));
      },
    );
  }

  void invalidateCatalogCache() {
    _cache.invalidateByPrefix('catalog:');
    _cache.invalidateByPrefix('mobile:');
  }

  void invalidateBookDetail(String bookId) {
    _cache.remove('catalog:book:$bookId');
  }

  Future<List<Book>> getFavorites() async {
    // Favorites do not have a mobile API endpoint yet.
    return [];
  }

  Future<bool> addToFavorites(String bookId) async {
    // Favorites do not have a mobile API endpoint yet.
    return true;
  }

  Future<bool> removeFromFavorites(String bookId) async {
    // Favorites do not have a mobile API endpoint yet.
    return true;
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }

  String _cacheKey(String prefix, Map<String, dynamic> values) {
    final entries = values.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final query = entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('&');

    return '$prefix:$query';
  }
}

class HomeOverview {
  final List<Book> newArrivals;
  final List<BorrowedBook> activeLoans;
  final HomeLoanStats loanStats;
  final List<Book> recommendedBooks;
  final RecommendationContext recommendationContext;

  const HomeOverview({
    required this.newArrivals,
    required this.activeLoans,
    required this.loanStats,
    this.recommendedBooks = const [],
    this.recommendationContext = const RecommendationContext(),
  });
}

class RecommendationContext {
  final String? course;
  final String? programName;

  const RecommendationContext({
    this.course,
    this.programName,
  });

  factory RecommendationContext.fromJson(Map<String, dynamic> json) {
    return RecommendationContext(
      course: _nullableString(json['course']),
      programName: _nullableString(json['program_name']),
    );
  }

  String? get displayLabel {
    if (programName != null && programName!.isNotEmpty) {
      return programName;
    }
    if (course != null && course!.isNotEmpty) {
      return course;
    }
    return null;
  }
}

String? _nullableString(Object? value) {
  final stringValue = value?.toString();
  return stringValue == null || stringValue.isEmpty ? null : stringValue;
}

class HomeLoanStats {
  final int activeCount;
  final int dueSoonCount;
  final int overdueCount;

  const HomeLoanStats({
    required this.activeCount,
    required this.dueSoonCount,
    required this.overdueCount,
  });

  factory HomeLoanStats.fromJson(Map<String, dynamic> json) {
    return HomeLoanStats(
      activeCount: _intValue(json['active_count']),
      dueSoonCount: _intValue(json['due_soon_count']),
      overdueCount: _intValue(json['overdue_count']),
    );
  }
}

int _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
