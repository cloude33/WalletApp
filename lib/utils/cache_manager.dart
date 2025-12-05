/// Simple in-memory cache manager for dashboard and frequently accessed data
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  final Map<String, _CacheEntry> _cache = {};

  /// Default cache duration (5 minutes)
  static const Duration defaultDuration = Duration(minutes: 5);

  /// Set a value in cache with optional duration
  void set<T>(String key, T value, {Duration? duration}) {
    _cache[key] = _CacheEntry(
      value: value,
      expiresAt: DateTime.now().add(duration ?? defaultDuration),
    );
  }

  /// Get a value from cache
  /// Returns null if not found or expired
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) {
      return null;
    }

    // Check if expired
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _cache.remove(key);
      return null;
    }

    return entry.value as T?;
  }

  /// Check if a key exists and is not expired
  bool has(String key) {
    final entry = _cache[key];
    if (entry == null) {
      return false;
    }

    if (DateTime.now().isAfter(entry.expiresAt)) {
      _cache.remove(key);
      return false;
    }

    return true;
  }

  /// Remove a specific key from cache
  void remove(String key) {
    _cache.remove(key);
  }

  /// Clear all cache
  void clear() {
    _cache.clear();
  }

  /// Clear expired entries
  void clearExpired() {
    final now = DateTime.now();
    _cache.removeWhere((key, entry) => now.isAfter(entry.expiresAt));
  }

  /// Get cache size
  int get size => _cache.length;

  /// Clear cache for a specific pattern (e.g., all card-related cache)
  void clearPattern(String pattern) {
    _cache.removeWhere((key, value) => key.contains(pattern));
  }
}

class _CacheEntry {
  final dynamic value;
  final DateTime expiresAt;

  _CacheEntry({
    required this.value,
    required this.expiresAt,
  });
}

/// Cache keys for common data
class CacheKeys {
  static const String dashboardSummary = 'dashboard_summary';
  static const String totalDebt = 'total_debt';
  static const String totalLimit = 'total_limit';
  static const String totalAvailableCredit = 'total_available_credit';
  static const String utilizationPercentage = 'utilization_percentage';
  static const String upcomingPayments = 'upcoming_payments';

  /// Generate card-specific cache key
  static String cardDebt(String cardId) => 'card_debt_$cardId';
  static String cardUtilization(String cardId) => 'card_utilization_$cardId';
  static String cardDetails(String cardId) => 'card_details_$cardId';
  static String cardTransactions(String cardId) => 'card_transactions_$cardId';

  /// Clear all card-related cache
  static void clearCardCache(String cardId) {
    final cache = CacheManager();
    cache.remove(cardDebt(cardId));
    cache.remove(cardUtilization(cardId));
    cache.remove(cardDetails(cardId));
    cache.remove(cardTransactions(cardId));
  }

  /// Clear all dashboard cache
  static void clearDashboardCache() {
    final cache = CacheManager();
    cache.remove(dashboardSummary);
    cache.remove(totalDebt);
    cache.remove(totalLimit);
    cache.remove(totalAvailableCredit);
    cache.remove(utilizationPercentage);
    cache.remove(upcomingPayments);
  }
}
