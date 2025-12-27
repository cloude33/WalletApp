import 'dart:collection';
import 'dart:convert';
class CacheService {
  final int maxSizeBytes;
  final Map<String, CacheEntry> _cache = {};
  final LinkedHashMap<String, DateTime> _accessOrder = LinkedHashMap();

  CacheService({this.maxSizeBytes = 50 * 1024 * 1024});
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    _accessOrder.remove(key);
    _accessOrder[key] = DateTime.now();

    return entry.value as T?;
  }
  void put<T>(String key, T value) {
    final sizeBytes = _calculateSize(value);
    if (_cache.containsKey(key)) {
      _cache.remove(key);
      _accessOrder.remove(key);
    }
    while (getCurrentSize() + sizeBytes > maxSizeBytes && _cache.isNotEmpty) {
      _evictLRU();
    }
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
  void invalidate(String key) {
    _cache.remove(key);
    _accessOrder.remove(key);
  }
  void invalidatePattern(String pattern) {
    final regex = RegExp(pattern);
    final keysToRemove = _cache.keys
        .where((key) => regex.hasMatch(key))
        .toList();

    for (final key in keysToRemove) {
      _cache.remove(key);
      _accessOrder.remove(key);
    }
  }
  void clear() {
    _cache.clear();
    _accessOrder.clear();
  }
  int getCurrentSize() {
    return _cache.values.fold(0, (sum, entry) => sum + entry.sizeBytes);
  }
  CacheStats getStats() {
    return CacheStats(
      entryCount: _cache.length,
      totalSizeBytes: getCurrentSize(),
      maxSizeBytes: maxSizeBytes,
      utilizationPercent: (getCurrentSize() / maxSizeBytes * 100).toInt(),
    );
  }
  void _evictLRU() {
    if (_accessOrder.isEmpty) return;

    final oldestKey = _accessOrder.keys.first;
    _cache.remove(oldestKey);
    _accessOrder.remove(oldestKey);
  }
  int _calculateSize(dynamic value) {
    try {
      final json = jsonEncode(value);
      return json.length;
    } catch (e) {
      if (value is String) return value.length;
      if (value is List) return value.length * 100;
      if (value is Map) return value.length * 200;
      return 1024;
    }
  }
}
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
