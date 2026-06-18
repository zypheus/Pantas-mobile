import '../models/book.dart';
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

  Future<List<Book>> getNewArrivals({
    int limit = 12,
    bool refresh = false,
  }) async {
    return _cache.getOrFetch<List<Book>>(
      'catalog:new-arrivals:$limit',
      ttl: _newArrivalsTtl,
      refresh: refresh,
      fetch: () async {
        final response = await _apiClient.get(
          '/catalog/new-arrivals',
          authenticated: false,
          queryParameters: {'limit': limit},
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
