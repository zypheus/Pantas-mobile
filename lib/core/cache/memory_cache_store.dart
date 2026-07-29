class MemoryCacheEntry<T> {
  final T value;
  final DateTime createdAt;
  final DateTime expiresAt;

  MemoryCacheEntry({
    required this.value,
    required this.createdAt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class MemoryCacheStore {
  MemoryCacheStore._();

  static final MemoryCacheStore instance = MemoryCacheStore._();

  final Map<String, MemoryCacheEntry<Object?>> _entries = {};
  final Map<String, Future<Object?>> _inFlight = {};

  T? get<T>(String key, {bool allowExpired = false}) {
    final entry = _entries[key];

    if (entry == null) return null;

    if (entry.isExpired && !allowExpired) {
      _entries.remove(key);
      return null;
    }

    final value = entry.value;
    if (value is T) return value;

    return null;
  }

  void set<T>(String key, T value, Duration ttl) {
    final now = DateTime.now();
    _entries[key] = MemoryCacheEntry<T>(
      value: value,
      createdAt: now,
      expiresAt: now.add(ttl),
    );
  }

  Future<T> getOrFetch<T>(
    String key, {
    required Duration ttl,
    required Future<T> Function() fetch,
    bool refresh = false,
  }) async {
    if (!refresh) {
      final cached = get<T>(key);
      if (cached != null) return cached;
    }

    final existing = _inFlight[key];
    if (existing != null) {
      return await existing as T;
    }

    final future = () async {
      final value = await fetch();
      set<T>(key, value, ttl);
      return value;
    }();

    _inFlight[key] = future;

    try {
      return await future;
    } finally {
      if (identical(_inFlight[key], future)) {
        _inFlight.remove(key);
      }
    }
  }

  void remove(String key) {
    _entries.remove(key);
    _inFlight.remove(key);
  }

  void clear() {
    _entries.clear();
    _inFlight.clear();
  }

  void invalidateByPrefix(String prefix) {
    _entries.removeWhere((key, _) => key.startsWith(prefix));
    _inFlight.removeWhere((key, _) => key.startsWith(prefix));
  }
}
