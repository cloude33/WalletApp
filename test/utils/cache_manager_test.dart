import 'package:flutter_test/flutter_test.dart';
import 'package:money/utils/cache_manager.dart';

void main() {
  late CacheManager cache;

  setUp(() {
    cache = CacheManager();
    cache.clear(); // Start with clean cache
  });

  tearDown(() {
    cache.clear();
  });

  group('CacheManager Basic Operations', () {
    test('should set and get a value', () {
      cache.set('test_key', 'test_value');
      
      final result = cache.get<String>('test_key');
      
      expect(result, equals('test_value'));
    });

    test('should return null for non-existent key', () {
      final result = cache.get<String>('non_existent');
      
      expect(result, isNull);
    });

    test('should check if key exists', () {
      cache.set('test_key', 'test_value');
      
      expect(cache.has('test_key'), isTrue);
      expect(cache.has('non_existent'), isFalse);
    });

    test('should remove a specific key', () {
      cache.set('test_key', 'test_value');
      cache.remove('test_key');
      
      expect(cache.has('test_key'), isFalse);
    });

    test('should clear all cache', () {
      cache.set('key1', 'value1');
      cache.set('key2', 'value2');
      cache.set('key3', 'value3');
      
      cache.clear();
      
      expect(cache.size, equals(0));
      expect(cache.has('key1'), isFalse);
      expect(cache.has('key2'), isFalse);
      expect(cache.has('key3'), isFalse);
    });

    test('should get cache size', () {
      cache.set('key1', 'value1');
      cache.set('key2', 'value2');
      cache.set('key3', 'value3');
      
      expect(cache.size, equals(3));
    });
  });

  group('CacheManager Expiration', () {
    test('should expire entries after duration', () async {
      cache.set('test_key', 'test_value', duration: const Duration(milliseconds: 100));
      
      // Should exist immediately
      expect(cache.has('test_key'), isTrue);
      
      // Wait for expiration
      await Future.delayed(const Duration(milliseconds: 150));
      
      // Should be expired
      expect(cache.has('test_key'), isFalse);
      expect(cache.get<String>('test_key'), isNull);
    });

    test('should clear expired entries', () async {
      cache.set('key1', 'value1', duration: const Duration(milliseconds: 100));
      cache.set('key2', 'value2', duration: const Duration(seconds: 10));
      
      await Future.delayed(const Duration(milliseconds: 150));
      
      cache.clearExpired();
      
      expect(cache.has('key1'), isFalse);
      expect(cache.has('key2'), isTrue);
    });

    test('should use default duration when not specified', () {
      cache.set('test_key', 'test_value');
      
      expect(cache.has('test_key'), isTrue);
    });
  });

  group('CacheManager Pattern Matching', () {
    test('should clear cache by pattern', () {
      cache.set('card_debt_123', 100.0);
      cache.set('card_debt_456', 200.0);
      cache.set('kmh_summary_789', 'summary');
      cache.set('other_data', 'data');
      
      cache.clearPattern('card_debt_');
      
      expect(cache.has('card_debt_123'), isFalse);
      expect(cache.has('card_debt_456'), isFalse);
      expect(cache.has('kmh_summary_789'), isTrue);
      expect(cache.has('other_data'), isTrue);
    });

    test('should clear multiple patterns', () {
      cache.set('cash_flow_2024', 'data1');
      cache.set('spending_2024', 'data2');
      cache.set('credit_analysis_current', 'data3');
      cache.set('other_data', 'data4');
      
      cache.clearPattern('cash_flow_');
      cache.clearPattern('spending_');
      
      expect(cache.has('cash_flow_2024'), isFalse);
      expect(cache.has('spending_2024'), isFalse);
      expect(cache.has('credit_analysis_current'), isTrue);
      expect(cache.has('other_data'), isTrue);
    });
  });

  group('CacheManager Memory Management', () {
    test('should estimate memory usage', () {
      cache.set('key1', 'short');
      cache.set('key2', 'a much longer string value');
      cache.set('key3', [1, 2, 3, 4, 5]);
      
      final memoryBytes = cache.estimatedMemoryBytes;
      
      expect(memoryBytes, greaterThan(0));
    });

    test('should enforce size limits', () {
      // Add many entries to trigger size limit
      for (int i = 0; i < 150; i++) {
        cache.set('key_$i', 'value_$i');
      }
      
      // Should not exceed max size
      expect(cache.size, lessThanOrEqualTo(CacheManager.maxCacheSize));
    });

    test('should get cache statistics', () {
      cache.set('key1', 'value1');
      cache.set('key2', 'value2');
      cache.set('key3', 'value3');
      
      final stats = cache.getStats();
      
      expect(stats.totalEntries, equals(3));
      expect(stats.validEntries, equals(3));
      expect(stats.expiredEntries, equals(0));
      expect(stats.estimatedMemoryBytes, greaterThan(0));
    });

    test('should track expired entries in stats', () async {
      cache.set('key1', 'value1', duration: const Duration(milliseconds: 100));
      cache.set('key2', 'value2', duration: const Duration(seconds: 10));
      
      await Future.delayed(const Duration(milliseconds: 150));
      
      final stats = cache.getStats();
      
      expect(stats.totalEntries, equals(2));
      expect(stats.validEntries, equals(1));
      expect(stats.expiredEntries, equals(1));
    });
  });

  group('CacheManager Invalidation', () {
    test('should invalidate transaction-related cache', () {
      cache.set('cash_flow_2024', 'data');
      cache.set('spending_2024', 'data');
      cache.set('comparison_2024', 'data');
      cache.set('credit_analysis_current', 'data');
      
      cache.invalidateRelated('transaction');
      
      expect(cache.has('cash_flow_2024'), isFalse);
      expect(cache.has('spending_2024'), isFalse);
      expect(cache.has('comparison_2024'), isFalse);
    });

    test('should invalidate credit card-related cache', () {
      cache.set('card_debt_123', 100.0);
      cache.set('credit_analysis_current', 'data');
      cache.set('asset_analysis_current', 'data');
      cache.set('cash_flow_2024', 'data');
      
      cache.invalidateRelated('credit_card', id: '123');
      
      expect(cache.has('card_debt_123'), isFalse);
      expect(cache.has('credit_analysis_current'), isFalse);
      expect(cache.has('asset_analysis_current'), isFalse);
    });

    test('should invalidate KMH-related cache', () {
      cache.set('kmh_summary_789', 'data');
      cache.set('credit_analysis_current', 'data');
      cache.set('asset_analysis_current', 'data');
      
      cache.invalidateRelated('kmh', id: '789');
      
      expect(cache.has('kmh_summary_789'), isFalse);
      expect(cache.has('credit_analysis_current'), isFalse);
      expect(cache.has('asset_analysis_current'), isFalse);
    });

    test('should invalidate goal-related cache', () {
      cache.set('goal_comparison_2024', 'data');
      cache.set('cash_flow_2024', 'data');
      
      cache.invalidateRelated('goal');
      
      expect(cache.has('goal_comparison_2024'), isFalse);
      expect(cache.has('cash_flow_2024'), isTrue);
    });
  });

  group('CacheKeys', () {
    test('should generate cash flow cache key', () {
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 31);
      
      final key = CacheKeys.cashFlow(
        startDate: startDate,
        endDate: endDate,
      );
      
      expect(key, contains('cash_flow_'));
      expect(key, contains('2024-01-01'));
      expect(key, contains('2024-01-31'));
    });

    test('should generate spending analysis cache key', () {
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 31);
      
      final key = CacheKeys.spendingAnalysis(
        startDate: startDate,
        endDate: endDate,
        categories: ['Food', 'Transport'],
      );
      
      expect(key, contains('spending_'));
      expect(key, contains('Food'));
      expect(key, contains('Transport'));
    });

    test('should generate comparison cache key', () {
      final p1Start = DateTime(2024, 1, 1);
      final p1End = DateTime(2024, 1, 31);
      final p2Start = DateTime(2024, 2, 1);
      final p2End = DateTime(2024, 2, 29);
      
      final key = CacheKeys.comparison(
        period1Start: p1Start,
        period1End: p1End,
        period2Start: p2Start,
        period2End: p2End,
      );
      
      expect(key, contains('comparison_'));
      expect(key, contains('2024-01'));
      expect(key, contains('2024-02'));
    });

    test('should generate goal comparison cache key', () {
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 12, 31);
      
      final key = CacheKeys.goalComparison(
        startDate: startDate,
        endDate: endDate,
      );
      
      expect(key, contains('goal_comparison_'));
      expect(key, contains('2024'));
    });

    test('should generate report cache key', () {
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 31);
      
      final key = CacheKeys.report(
        reportType: 'income',
        startDate: startDate,
        endDate: endDate,
        category: 'Salary',
      );
      
      expect(key, contains('report_income'));
      expect(key, contains('cat_Salary'));
    });
  });

  group('CacheKeys Clearing Methods', () {
    test('should clear statistics cache', () {
      cache.set('cash_flow_2024', 'data');
      cache.set('spending_2024', 'data');
      cache.set('credit_analysis_current', 'data');
      cache.set('other_data', 'data');
      
      CacheKeys.clearStatisticsCache();
      
      expect(cache.has('cash_flow_2024'), isFalse);
      expect(cache.has('spending_2024'), isFalse);
      expect(cache.has('credit_analysis_current'), isFalse);
      expect(cache.has('other_data'), isTrue);
    });

    test('should clear cash flow cache', () {
      cache.set('cash_flow_2024', 'data');
      cache.set('spending_2024', 'data');
      
      CacheKeys.clearCashFlowCache();
      
      expect(cache.has('cash_flow_2024'), isFalse);
      expect(cache.has('spending_2024'), isTrue);
    });

    test('should clear spending cache', () {
      cache.set('spending_2024', 'data');
      cache.set('cash_flow_2024', 'data');
      
      CacheKeys.clearSpendingCache();
      
      expect(cache.has('spending_2024'), isFalse);
      expect(cache.has('cash_flow_2024'), isTrue);
    });

    test('should clear comparison cache', () {
      cache.set('comparison_2024', 'data');
      cache.set('goal_comparison_2024', 'data');
      cache.set('avg_comparison_2024', 'data');
      cache.set('cash_flow_2024', 'data');
      
      CacheKeys.clearComparisonCache();
      
      expect(cache.has('comparison_2024'), isFalse);
      expect(cache.has('goal_comparison_2024'), isFalse);
      expect(cache.has('avg_comparison_2024'), isFalse);
      expect(cache.has('cash_flow_2024'), isTrue);
    });
  });

  group('CacheManager LRU Eviction', () {
    test('should evict entries when size limit reached', () {
      // Add entries up to the limit
      for (int i = 0; i < CacheManager.maxCacheSize + 10; i++) {
        cache.set('key_$i', 'value_$i');
      }
      
      // Cache should not exceed max size
      expect(cache.size, lessThanOrEqualTo(CacheManager.maxCacheSize));
    });

    test('should update last accessed time on get', () async {
      cache.set('old_key', 'old_value');
      cache.set('new_key', 'new_value');
      
      await Future.delayed(const Duration(milliseconds: 10));
      
      // Access old_key to update its last accessed time
      final value = cache.get<String>('old_key');
      expect(value, equals('old_value'));
      
      // Add many more entries to trigger eviction
      for (int i = 0; i < CacheManager.maxCacheSize; i++) {
        cache.set('key_$i', 'value_$i');
      }
      
      // Cache should not exceed max size
      expect(cache.size, lessThanOrEqualTo(CacheManager.maxCacheSize));
    });
  });
}
