class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  final Map<String, _CacheEntry> _cache = {};
  static const Duration defaultDuration = Duration(minutes: 5);
  static const int maxCacheSize = 100;
  static const int maxMemoryBytes = 50 * 1024 * 1024;
  void set<T>(String key, T value, {Duration? duration}) {
    _enforceMemoryLimits();

    _cache[key] = _CacheEntry(
      value: value,
      expiresAt: DateTime.now().add(duration ?? defaultDuration),
      createdAt: DateTime.now(),
    );
  }
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) {
      return null;
    }
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _cache.remove(key);
      return null;
    }
    entry.lastAccessed = DateTime.now();

    return entry.value as T?;
  }
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
  void remove(String key) {
    _cache.remove(key);
  }
  void clear() {
    _cache.clear();
  }
  void clearExpired() {
    final now = DateTime.now();
    _cache.removeWhere((key, entry) => now.isAfter(entry.expiresAt));
  }
  int get size => _cache.length;
  int get estimatedMemoryBytes {
    int total = 0;
    for (final entry in _cache.values) {
      total += entry.estimatedSize;
    }
    return total;
  }
  void clearPattern(String pattern) {
    _cache.removeWhere((key, value) => key.contains(pattern));
  }
  void _enforceMemoryLimits() {
    clearExpired();
    if (_cache.length >= maxCacheSize) {
      _evictLRU(maxCacheSize ~/ 4);
    }
    if (estimatedMemoryBytes > maxMemoryBytes) {
      _evictLRU(maxCacheSize ~/ 4);
    }
  }
  void _evictLRU(int count) {
    if (_cache.isEmpty) return;
    final entries = _cache.entries.toList()
      ..sort((a, b) => a.value.lastAccessed.compareTo(b.value.lastAccessed));
    final toRemove = entries.take(count);
    for (final entry in toRemove) {
      _cache.remove(entry.key);
    }
  }
  CacheStats getStats() {
    final now = DateTime.now();
    int expired = 0;
    int valid = 0;

    for (final entry in _cache.values) {
      if (now.isAfter(entry.expiresAt)) {
        expired++;
      } else {
        valid++;
      }
    }

    return CacheStats(
      totalEntries: _cache.length,
      validEntries: valid,
      expiredEntries: expired,
      estimatedMemoryBytes: estimatedMemoryBytes,
    );
  }
  void invalidateRelated(String dataType, {String? id}) {
    switch (dataType) {
      case 'transaction':
        clearPattern('cash_flow_');
        clearPattern('spending_');
        clearPattern('comparison_');
        CacheKeys.clearDashboardCache();
        break;
      case 'credit_card':
        if (id != null) {
          CacheKeys.clearCardCache(id);
        }
        clearPattern('credit_analysis_');
        clearPattern('asset_analysis_');
        CacheKeys.clearDashboardCache();
        break;
      case 'kmh':
        if (id != null) {
          CacheKeys.clearKmhCache(id);
        }
        clearPattern('credit_analysis_');
        clearPattern('asset_analysis_');
        CacheKeys.clearDashboardCache();
        break;
      case 'wallet':
        clearPattern('asset_analysis_');
        CacheKeys.clearDashboardCache();
        break;
      case 'goal':
        clearPattern('goal_comparison_');
        break;
      default:
        clearPattern('cash_flow_');
        clearPattern('spending_');
        clearPattern('credit_analysis_');
        clearPattern('asset_analysis_');
        clearPattern('comparison_');
        clearPattern('goal_comparison_');
    }
  }
}

class _CacheEntry {
  final dynamic value;
  final DateTime expiresAt;
  final DateTime createdAt;
  DateTime lastAccessed;

  _CacheEntry({
    required this.value,
    required this.expiresAt,
    required this.createdAt,
  }) : lastAccessed = createdAt;
  int get estimatedSize {
    if (value == null) return 100;
    
    if (value is String) {
      return (value as String).length * 2 + 100;
    } else if (value is List) {
      return (value as List).length * 1000 + 100;
    } else if (value is Map) {
      return (value as Map).length * 1000 + 100;
    } else {
      return 1000;
    }
  }
}
class CacheStats {
  final int totalEntries;
  final int validEntries;
  final int expiredEntries;
  final int estimatedMemoryBytes;

  CacheStats({
    required this.totalEntries,
    required this.validEntries,
    required this.expiredEntries,
    required this.estimatedMemoryBytes,
  });

  double get hitRate => validEntries / totalEntries;
  double get memoryUsageMB => estimatedMemoryBytes / (1024 * 1024);

  @override
  String toString() {
    return 'CacheStats(total: $totalEntries, valid: $validEntries, '
        'expired: $expiredEntries, memory: ${memoryUsageMB.toStringAsFixed(2)}MB)';
  }
}
class CacheKeys {
  static const String dashboardSummary = 'dashboard_summary';
  static const String totalDebt = 'total_debt';
  static const String totalLimit = 'total_limit';
  static const String totalAvailableCredit = 'total_available_credit';
  static const String utilizationPercentage = 'utilization_percentage';
  static const String upcomingPayments = 'upcoming_payments';
  static String cardDebt(String cardId) => 'card_debt_$cardId';
  static String cardUtilization(String cardId) => 'card_utilization_$cardId';
  static String cardDetails(String cardId) => 'card_details_$cardId';
  static String cardTransactions(String cardId) => 'card_transactions_$cardId';
  static String kmhSummary(String walletId) => 'kmh_summary_$walletId';
  static String kmhTransactions(String walletId) => 'kmh_transactions_$walletId';
  static String kmhStatement(String walletId, String dateRange) => 
      'kmh_statement_${walletId}_$dateRange';
  static String kmhInterestCalculation(String walletId) => 
      'kmh_interest_calc_$walletId';
  static String kmhTotalDebt = 'kmh_total_debt';
  static String kmhTotalCredit = 'kmh_total_credit';
  static String kmhAllAccounts = 'kmh_all_accounts';
  static String cashFlow({
    required DateTime startDate,
    required DateTime endDate,
    String? walletId,
    String? category,
  }) {
    final key = 'cash_flow_${startDate.toIso8601String()}_${endDate.toIso8601String()}';
    if (walletId != null) return '${key}_wallet_$walletId';
    if (category != null) return '${key}_cat_$category';
    return key;
  }
  static String spendingAnalysis({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? categories,
  }) {
    final key = 'spending_${startDate.toIso8601String()}_${endDate.toIso8601String()}';
    if (categories != null && categories.isNotEmpty) {
      return '${key}_cats_${categories.join('_')}';
    }
    return key;
  }
  static const String creditAnalysis = 'credit_analysis_current';
  static const String assetAnalysis = 'asset_analysis_current';
  static String comparison({
    required DateTime period1Start,
    required DateTime period1End,
    required DateTime period2Start,
    required DateTime period2End,
  }) {
    return 'comparison_'
        '${period1Start.toIso8601String()}_${period1End.toIso8601String()}_'
        '${period2Start.toIso8601String()}_${period2End.toIso8601String()}';
  }
  static String goalComparison({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return 'goal_comparison_${startDate.toIso8601String()}_${endDate.toIso8601String()}';
  }
  static String averageComparison({
    required DateTime currentStart,
    required DateTime currentEnd,
    required int months,
  }) {
    return 'avg_comparison_${currentStart.toIso8601String()}_'
        '${currentEnd.toIso8601String()}_${months}m';
  }
  static String trendData(String dataType, DateTime startDate, DateTime endDate) {
    return 'trend_${dataType}_${startDate.toIso8601String()}_${endDate.toIso8601String()}';
  }
  static String report({
    required String reportType,
    required DateTime startDate,
    required DateTime endDate,
    String? category,
    String? walletId,
  }) {
    var key = 'report_${reportType}_${startDate.toIso8601String()}_${endDate.toIso8601String()}';
    if (category != null) key += '_cat_$category';
    if (walletId != null) key += '_wallet_$walletId';
    return key;
  }
  static void clearCardCache(String cardId) {
    final cache = CacheManager();
    cache.remove(cardDebt(cardId));
    cache.remove(cardUtilization(cardId));
    cache.remove(cardDetails(cardId));
    cache.remove(cardTransactions(cardId));
  }
  static void clearDashboardCache() {
    final cache = CacheManager();
    cache.remove(dashboardSummary);
    cache.remove(totalDebt);
    cache.remove(totalLimit);
    cache.remove(totalAvailableCredit);
    cache.remove(utilizationPercentage);
    cache.remove(upcomingPayments);
  }
  static void clearKmhCache(String walletId) {
    final cache = CacheManager();
    cache.remove(kmhSummary(walletId));
    cache.remove(kmhTransactions(walletId));
    cache.remove(kmhInterestCalculation(walletId));
    cache.clearPattern('kmh_statement_$walletId');
  }
  static void clearAllKmhCache() {
    final cache = CacheManager();
    cache.clearPattern('kmh_');
  }
  static void clearStatisticsCache() {
    final cache = CacheManager();
    cache.clearPattern('cash_flow_');
    cache.clearPattern('spending_');
    cache.clearPattern('credit_analysis_');
    cache.clearPattern('asset_analysis_');
    cache.clearPattern('comparison_');
    cache.clearPattern('goal_comparison_');
    cache.clearPattern('avg_comparison_');
    cache.clearPattern('trend_');
    cache.clearPattern('report_');
  }
  static void clearCashFlowCache() {
    final cache = CacheManager();
    cache.clearPattern('cash_flow_');
  }
  static void clearSpendingCache() {
    final cache = CacheManager();
    cache.clearPattern('spending_');
  }
  static void clearCreditAnalysisCache() {
    final cache = CacheManager();
    cache.clearPattern('credit_analysis_');
  }
  static void clearAssetAnalysisCache() {
    final cache = CacheManager();
    cache.clearPattern('asset_analysis_');
  }
  static void clearComparisonCache() {
    final cache = CacheManager();
    cache.clearPattern('comparison_');
    cache.clearPattern('goal_comparison_');
    cache.clearPattern('avg_comparison_');
  }
  static void clearReportCache() {
    final cache = CacheManager();
    cache.clearPattern('report_');
  }
}
