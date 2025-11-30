import 'dart:collection';
import 'dart:convert';

/// LRU cache service with size limits
class CacheService {
  final int maxSizeBytes;
  final Map<String, CacheEntry> _cache = {};
  final LinkedHashMap<String, DateTime> _accessOrder = LinkedHashMap();

  CacheService({this.maxSizeBytes = 50 * 1024 * 1024}); // 50MB default

  /// Get cached value
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    // Update access time
    _accessOrder.remove(key);
    _accessOrder[key] = DateTime.now();

    return entry.value as T?;
  }

  /// Put value in cache
  void put<T>(String key, T value) {
    // Calculate size
    final sizeBytes = _calculateSize(value);

    // Remove old entry if exists
    if (_cache.containsKey(key)) {
      _cache.remove(key);
      _accessOrder.remove(key);
    }

    // Evict items if necessary
    while (getCurrentSize() + sizeBytes > maxSizeBytes && _cache.isNotEmpty) {
      _evictLRU();
    }

    // Add new entry
    final entry = CacheEntry(
      key: key,
      value: value,
      sizeBytes: sizeBytes,
      createdAt: DateTime.now(),
      lastAccessedAt: DateTime.now(),
    );

    _cache[key] = entry;
    _accessOrder[key] = DateTime.now();
  }

  /// Invalidate specific cache entry
  void invalidate(String key) {
    _cache.remove(key);
    _accessOrder.remove(key);
  }

  /// Invalidate entries matching pattern
  void invalidatePattern(String pattern) {
    final regex = RegExp(pattern);
    final keysToRemove = _cache.keys.where((key) => regex.hasMatch(key)).toList();

    for (final key in keysToRemove) {
      _cache.remove(key);
      _accessOrder.remove(key);
    }
  }

  /// Clear all cache
  void clear() {
    _cache.clear();
    _accessOrder.clear();
  }

  /// Get current cache size in bytes
  int getCurrentSize() {
    return _cache.values.fold(0, (sum, entry) => sum + entry.sizeBytes);
  }

  /// Get cache statistics
  CacheStats getStats() {
    return CacheStats(
      entryCount: _cache.length,
      totalSizeBytes: getCurrentSize(),
      maxSizeBytes: maxSizeBytes,
      utilizationPercent: (getCurrentSize() / maxSizeBytes * 100).toInt(),
    );
  }

  /// Evict least recently used item
  void _evictLRU() {
    if (_accessOrder.isEmpty) return;

    final oldestKey = _accessOrder.keys.first;
    _cache.remove(oldestKey);
    _accessOrder.remove(oldestKey);
  }

  /// Calculate approximate size of value in bytes
  int _calculateSize(dynamic value) {
    try {
      final json = jsonEncode(value);
      return json.length;
    } catch (e) {
      // Fallback: estimate based on type
      if (value is String) return value.length;
      if (value is List) return value.length * 100; // Rough estimate
      if (value is Map) return value.length * 200; // Rough estimate
      return 1024; // Default 1KB
    }
  }
}

/// Cache entry model
class CacheEntry {
  final String key;
  final dynamic value;
  final int sizeBytes;
  final DateTime createdAt;
  final DateTime lastAccessedAt;

  CacheEntry({
    required this.key,
    required this.value,
    required this.sizeBytes,
    required this.createdAt,
    required this.lastAccessedAt,
  });
}

/// Cache statistics
class CacheStats {
  final int entryCount;
  final int totalSizeBytes;
  final int maxSizeBytes;
  final int utilizationPercent;

  CacheStats({
    required this.entryCount,
    required this.totalSizeBytes,
    required this.maxSizeBytes,
    required this.utilizationPercent,
  });

  String get totalSizeMB => (totalSizeBytes / (1024 * 1024)).toStringAsFixed(2);
  String get maxSizeMB => (maxSizeBytes / (1024 * 1024)).toStringAsFixed(2);
}
