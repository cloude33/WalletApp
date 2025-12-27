import 'cache_manager.dart';
import '../services/statistics_service.dart';
void basicCacheExample() {
  final cache = CacheManager();
  cache.set('user_preferences', {'theme': 'dark', 'language': 'tr'});
  final prefs = cache.get<Map<String, String>>('user_preferences');
  print('Preferences: $prefs');
  if (cache.has('user_preferences')) {
    print('Preferences are cached');
  }
  cache.remove('user_preferences');
  cache.clear();
}
Future<void> statisticsCachingExample() async {
  final statisticsService = StatisticsService();

  final startDate = DateTime(2024, 1, 1);
  final endDate = DateTime(2024, 1, 31);
  print('First call - calculating...');
  final stopwatch1 = Stopwatch()..start();
  final cashFlow1 = await statisticsService.calculateCashFlow(
    startDate: startDate,
    endDate: endDate,
  );
  stopwatch1.stop();
  print('First call took: ${stopwatch1.elapsedMilliseconds}ms');
  print('Total income: ${cashFlow1.totalIncome}');
  print('\nSecond call - using cache...');
  final stopwatch2 = Stopwatch()..start();
  final cashFlow2 = await statisticsService.calculateCashFlow(
    startDate: startDate,
    endDate: endDate,
  );
  stopwatch2.stop();
  print('Second call took: ${stopwatch2.elapsedMilliseconds}ms');
  print('Total income: ${cashFlow2.totalIncome}');

  print(
    '\nSpeed improvement: ${stopwatch1.elapsedMilliseconds ~/ stopwatch2.elapsedMilliseconds}x faster!',
  );
}
Future<void> cacheInvalidationExample() async {
  final cache = CacheManager();
  cache.invalidateRelated('transaction');

  print('Transaction-related caches cleared');
}
void patternClearingExample() {
  final cache = CacheManager();
  cache.set('cash_flow_2024_01', 'data1');
  cache.set('cash_flow_2024_02', 'data2');
  cache.set('spending_2024_01', 'data3');
  cache.set('other_data', 'data4');
  cache.clearPattern('cash_flow_');

  print('Cash flow cache cleared');
  print('cash_flow_2024_01 exists: ${cache.has('cash_flow_2024_01')}');
  print('spending_2024_01 exists: ${cache.has('spending_2024_01')}');
  print('other_data exists: ${cache.has('other_data')}');
}
Future<void> cacheKeysExample() async {
  final cache = CacheManager();

  final startDate = DateTime(2024, 1, 1);
  final endDate = DateTime(2024, 1, 31);
  final cashFlowKey = CacheKeys.cashFlow(
    startDate: startDate,
    endDate: endDate,
    walletId: 'wallet_123',
  );
  if (cache.has(cashFlowKey)) {
    print('Cash flow data is cached');
    final data = cache.get(cashFlowKey);
    print('Cached data: $data');
  } else {
    print('Cash flow data not cached, need to calculate');
  }
  final spendingKey = CacheKeys.spendingAnalysis(
    startDate: startDate,
    endDate: endDate,
    categories: ['Food', 'Transport'],
  );

  print('Spending key: $spendingKey');
}
void cacheStatsExample() {
  final cache = CacheManager();
  cache.set('key1', 'value1');
  cache.set('key2', 'value2');
  cache.set('key3', 'value3');
  final stats = cache.getStats();

  print('Cache Statistics:');
  print('  Total entries: ${stats.totalEntries}');
  print('  Valid entries: ${stats.validEntries}');
  print('  Expired entries: ${stats.expiredEntries}');
  print('  Memory usage: ${stats.memoryUsageMB.toStringAsFixed(2)}MB');
  print('  Hit rate: ${(stats.hitRate * 100).toStringAsFixed(1)}%');
}
void customDurationExample() {
  final cache = CacheManager();
  cache.set('live_price', 100.50, duration: const Duration(minutes: 1));
  cache.set('statistics', {'income': 5000, 'expense': 3000});
  cache.set('user_profile', {
    'name': 'John',
    'email': 'john@example.com',
  }, duration: const Duration(minutes: 30));

  print('Data cached with different durations');
}
void clearSpecificStatsExample() {
  CacheKeys.clearStatisticsCache();
  CacheKeys.clearCashFlowCache();
  CacheKeys.clearSpendingCache();
  CacheKeys.clearCreditAnalysisCache();
  CacheKeys.clearAssetAnalysisCache();
  CacheKeys.clearComparisonCache();
  CacheKeys.clearReportCache();

  print('Specific statistics caches cleared');
}
class ExampleRepository {
  final cache = CacheManager();

  Future<List<dynamic>> getTransactions(String walletId) async {
    final cacheKey = 'transactions_$walletId';
    final cached = cache.get<List<dynamic>>(cacheKey);

    if (cached != null) {
      print('Returning cached transactions');
      return cached;
    }
    print('Fetching transactions from database');
    final transactions = await _fetchFromDatabase(walletId);
    cache.set(cacheKey, transactions, duration: const Duration(minutes: 5));

    return transactions;
  }

  Future<void> addTransaction(dynamic transaction) async {
    await _addToDatabase(transaction);
    cache.invalidateRelated('transaction');

    print('Transaction added and caches invalidated');
  }

  Future<List<dynamic>> _fetchFromDatabase(String walletId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [];
  }

  Future<void> _addToDatabase(dynamic transaction) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }
}
Future<void> statisticsScreenExample() async {
  final statisticsService = StatisticsService();
  final cache = CacheManager();

  print('=== Statistics Screen Loading ===\n');
  print('Loading cash flow...');
  final cashFlow = await statisticsService.calculateCashFlow(
    startDate: DateTime(2024, 1, 1),
    endDate: DateTime(2024, 1, 31),
  );
  print(
    'Cash flow loaded: Income ${cashFlow.totalIncome}, Expense ${cashFlow.totalExpense}\n',
  );
  print('Loading spending analysis...');
  final spending = await statisticsService.analyzeSpending(
    startDate: DateTime(2024, 1, 1),
    endDate: DateTime(2024, 1, 31),
  );
  print('Spending loaded: Total ${spending.totalSpending}\n');
  print('Loading credit analysis...');
  final credit = await statisticsService.analyzeCreditAndKmh();
  print('Credit loaded: Total debt ${credit.totalDebt}\n');
  print('=== User Returns to Statistics Screen ===\n');
  print('Loading cash flow (cached)...');
  await statisticsService.calculateCashFlow(
    startDate: DateTime(2024, 1, 1),
    endDate: DateTime(2024, 1, 31),
  );
  print('Cash flow loaded instantly from cache!\n');
  final stats = cache.getStats();
  print(
    'Cache stats: ${stats.validEntries} entries, ${stats.memoryUsageMB.toStringAsFixed(2)}MB',
  );
}
void main() async {
  print('=== Cache System Examples ===\n');
  print('1. Basic Cache Usage:');
  basicCacheExample();

  print('\n2. Statistics Caching:');

  print('\n3. Pattern Clearing:');
  patternClearingExample();

  print('\n4. Cache Keys:');

  print('\n5. Cache Statistics:');
  cacheStatsExample();

  print('\n6. Custom Duration:');
  customDurationExample();

  print('\n7. Clear Specific Stats:');
  clearSpecificStatsExample();

  print('\n=== Examples Complete ===');
}
