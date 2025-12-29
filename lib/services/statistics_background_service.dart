import '../models/cash_flow_data.dart';
import '../models/spending_analysis.dart';
import '../models/credit_analysis.dart';
import '../models/asset_analysis.dart';
import '../models/comparison_data.dart';
import '../utils/background_compute.dart';
import 'statistics_service.dart';
class StatisticsBackgroundService {
  final StatisticsService _statisticsService = StatisticsService();
  Future<CashFlowData> calculateCashFlowInBackground({
    required DateTime startDate,
    required DateTime endDate,
    String? walletId,
    String? category,
    bool includePreviousPeriod = false,
    ProgressCallback? onProgress,
  }) async {
    final input = _CashFlowInput(
      startDate: startDate,
      endDate: endDate,
      walletId: walletId,
      category: category,
      includePreviousPeriod: includePreviousPeriod,
    );

    if (BackgroundCompute.isAvailable) {
      return await BackgroundCompute.runWithProgress(
        _computeCashFlow,
        input,
        onProgress: onProgress,
        debugLabel: 'Calculate Cash Flow',
      );
    } else {
      return await _statisticsService.calculateCashFlow(
        startDate: startDate,
        endDate: endDate,
        walletId: walletId,
        category: category,
        includePreviousPeriod: includePreviousPeriod,
      );
    }
  }
  static Future<CashFlowData> _computeCashFlow(_CashFlowInput input) async {
    final service = StatisticsService();
    return await service.calculateCashFlow(
      startDate: input.startDate,
      endDate: input.endDate,
      walletId: input.walletId,
      category: input.category,
      includePreviousPeriod: input.includePreviousPeriod,
    );
  }
  Future<SpendingAnalysis> analyzeSpendingInBackground({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? categories,
    Map<String, double>? budgets,
    ProgressCallback? onProgress,
  }) async {
    final input = _SpendingAnalysisInput(
      startDate: startDate,
      endDate: endDate,
      categories: categories,
      budgets: budgets,
    );

    if (BackgroundCompute.isAvailable) {
      return await BackgroundCompute.runWithProgress(
        _computeSpendingAnalysis,
        input,
        onProgress: onProgress,
        debugLabel: 'Analyze Spending',
      );
    } else {
      return await _statisticsService.analyzeSpending(
        startDate: startDate,
        endDate: endDate,
        categories: categories,
        budgets: budgets,
      );
    }
  }
  static Future<SpendingAnalysis> _computeSpendingAnalysis(
    _SpendingAnalysisInput input,
  ) async {
    final service = StatisticsService();
    return await service.analyzeSpending(
      startDate: input.startDate,
      endDate: input.endDate,
      categories: input.categories,
      budgets: input.budgets,
    );
  }
  Future<CreditAnalysis> analyzeCreditAndKmhInBackground({
    ProgressCallback? onProgress,
  }) async {
    if (BackgroundCompute.isAvailable) {
      return await BackgroundCompute.runWithProgress(
        _computeCreditAnalysis,
        null,
        onProgress: onProgress,
        debugLabel: 'Analyze Credit and KMH',
      );
    } else {
      return await _statisticsService.analyzeCreditAndKmh();
    }
  }
  static Future<CreditAnalysis> _computeCreditAnalysis(dynamic _) async {
    final service = StatisticsService();
    return await service.analyzeCreditAndKmh();
  }
  Future<AssetAnalysis> analyzeAssetsInBackground({
    ProgressCallback? onProgress,
  }) async {
    if (BackgroundCompute.isAvailable) {
      return await BackgroundCompute.runWithProgress(
        _computeAssetAnalysis,
        null,
        onProgress: onProgress,
        debugLabel: 'Analyze Assets',
      );
    } else {
      return await _statisticsService.analyzeAssets();
    }
  }
  static Future<AssetAnalysis> _computeAssetAnalysis(dynamic _) async {
    final service = StatisticsService();
    return await service.analyzeAssets();
  }
  Future<ComparisonData> comparePeriodsInBackground({
    required DateTime period1Start,
    required DateTime period1End,
    required DateTime period2Start,
    required DateTime period2End,
    String? period1Label,
    String? period2Label,
    String? walletId,
    String? category,
    ProgressCallback? onProgress,
  }) async {
    final input = _ComparisonInput(
      period1Start: period1Start,
      period1End: period1End,
      period2Start: period2Start,
      period2End: period2End,
      period1Label: period1Label,
      period2Label: period2Label,
      walletId: walletId,
      category: category,
    );

    if (BackgroundCompute.isAvailable) {
      return await BackgroundCompute.runWithProgress(
        _computeComparison,
        input,
        onProgress: onProgress,
        debugLabel: 'Compare Periods',
      );
    } else {
      return await _statisticsService.comparePeriods(
        period1Start: period1Start,
        period1End: period1End,
        period2Start: period2Start,
        period2End: period2End,
        period1Label: period1Label,
        period2Label: period2Label,
        walletId: walletId,
        category: category,
      );
    }
  }
  static Future<ComparisonData> _computeComparison(
    _ComparisonInput input,
  ) async {
    final service = StatisticsService();
    return await service.comparePeriods(
      period1Start: input.period1Start,
      period1End: input.period1End,
      period2Start: input.period2Start,
      period2End: input.period2End,
      period1Label: input.period1Label,
      period2Label: input.period2Label,
      walletId: input.walletId,
      category: input.category,
    );
  }
  Future<BatchStatisticsResult> runBatchOperations({
    required List<StatisticsOperation> operations,
    ProgressCallback? onProgress,
  }) async {
    final results = <String, dynamic>{};
    int completed = 0;

    for (final operation in operations) {
      dynamic result;

      switch (operation.type) {
        case StatisticsOperationType.cashFlow:
          final params = operation.parameters as CashFlowParameters;
          result = await calculateCashFlowInBackground(
            startDate: params.startDate,
            endDate: params.endDate,
            walletId: params.walletId,
            category: params.category,
            includePreviousPeriod: params.includePreviousPeriod,
          );
          break;

        case StatisticsOperationType.spending:
          final params = operation.parameters as SpendingParameters;
          result = await analyzeSpendingInBackground(
            startDate: params.startDate,
            endDate: params.endDate,
            categories: params.categories,
            budgets: params.budgets,
          );
          break;

        case StatisticsOperationType.creditAnalysis:
          result = await analyzeCreditAndKmhInBackground();
          break;

        case StatisticsOperationType.assetAnalysis:
          result = await analyzeAssetsInBackground();
          break;

        case StatisticsOperationType.comparison:
          final params = operation.parameters as ComparisonParameters;
          result = await comparePeriodsInBackground(
            period1Start: params.period1Start,
            period1End: params.period1End,
            period2Start: params.period2Start,
            period2End: params.period2End,
            period1Label: params.period1Label,
            period2Label: params.period2Label,
            walletId: params.walletId,
            category: params.category,
          );
          break;
      }

      results[operation.key] = result;
      completed++;
      onProgress?.call(completed / operations.length);
    }

    return BatchStatisticsResult(results);
  }
}
class _CashFlowInput extends ComputationInput {
  final DateTime startDate;
  final DateTime endDate;
  final String? walletId;
  final String? category;
  final bool includePreviousPeriod;

  _CashFlowInput({
    required this.startDate,
    required this.endDate,
    this.walletId,
    this.category,
    required this.includePreviousPeriod,
  });
}
class _SpendingAnalysisInput extends ComputationInput {
  final DateTime startDate;
  final DateTime endDate;
  final List<String>? categories;
  final Map<String, double>? budgets;

  _SpendingAnalysisInput({
    required this.startDate,
    required this.endDate,
    this.categories,
    this.budgets,
  });
}
class _ComparisonInput extends ComputationInput {
  final DateTime period1Start;
  final DateTime period1End;
  final DateTime period2Start;
  final DateTime period2End;
  final String? period1Label;
  final String? period2Label;
  final String? walletId;
  final String? category;

  _ComparisonInput({
    required this.period1Start,
    required this.period1End,
    required this.period2Start,
    required this.period2End,
    this.period1Label,
    this.period2Label,
    this.walletId,
    this.category,
  });
}
enum StatisticsOperationType {
  cashFlow,
  spending,
  creditAnalysis,
  assetAnalysis,
  comparison,
}
class StatisticsOperation {
  final String key;
  final StatisticsOperationType type;
  final dynamic parameters;

  StatisticsOperation._({
    required this.key,
    required this.type,
    required this.parameters,
  });
  factory StatisticsOperation.cashFlow(
    DateTime startDate,
    DateTime endDate, {
    String? walletId,
    String? category,
    bool includePreviousPeriod = false,
    String? key,
  }) {
    return StatisticsOperation._(
      key: key ?? 'cashFlow',
      type: StatisticsOperationType.cashFlow,
      parameters: CashFlowParameters(
        startDate: startDate,
        endDate: endDate,
        walletId: walletId,
        category: category,
        includePreviousPeriod: includePreviousPeriod,
      ),
    );
  }
  factory StatisticsOperation.spending(
    DateTime startDate,
    DateTime endDate, {
    List<String>? categories,
    Map<String, double>? budgets,
    String? key,
  }) {
    return StatisticsOperation._(
      key: key ?? 'spending',
      type: StatisticsOperationType.spending,
      parameters: SpendingParameters(
        startDate: startDate,
        endDate: endDate,
        categories: categories,
        budgets: budgets,
      ),
    );
  }
  factory StatisticsOperation.creditAnalysis({String? key}) {
    return StatisticsOperation._(
      key: key ?? 'creditAnalysis',
      type: StatisticsOperationType.creditAnalysis,
      parameters: null,
    );
  }
  factory StatisticsOperation.assetAnalysis({String? key}) {
    return StatisticsOperation._(
      key: key ?? 'assetAnalysis',
      type: StatisticsOperationType.assetAnalysis,
      parameters: null,
    );
  }
  factory StatisticsOperation.comparison(
    DateTime period1Start,
    DateTime period1End,
    DateTime period2Start,
    DateTime period2End, {
    String? period1Label,
    String? period2Label,
    String? walletId,
    String? category,
    String? key,
  }) {
    return StatisticsOperation._(
      key: key ?? 'comparison',
      type: StatisticsOperationType.comparison,
      parameters: ComparisonParameters(
        period1Start: period1Start,
        period1End: period1End,
        period2Start: period2Start,
        period2End: period2End,
        period1Label: period1Label,
        period2Label: period2Label,
        walletId: walletId,
        category: category,
      ),
    );
  }
}
class CashFlowParameters {
  final DateTime startDate;
  final DateTime endDate;
  final String? walletId;
  final String? category;
  final bool includePreviousPeriod;

  CashFlowParameters({
    required this.startDate,
    required this.endDate,
    this.walletId,
    this.category,
    required this.includePreviousPeriod,
  });
}
class SpendingParameters {
  final DateTime startDate;
  final DateTime endDate;
  final List<String>? categories;
  final Map<String, double>? budgets;

  SpendingParameters({
    required this.startDate,
    required this.endDate,
    this.categories,
    this.budgets,
  });
}
class ComparisonParameters {
  final DateTime period1Start;
  final DateTime period1End;
  final DateTime period2Start;
  final DateTime period2End;
  final String? period1Label;
  final String? period2Label;
  final String? walletId;
  final String? category;

  ComparisonParameters({
    required this.period1Start,
    required this.period1End,
    required this.period2Start,
    required this.period2End,
    this.period1Label,
    this.period2Label,
    this.walletId,
    this.category,
  });
}
class BatchStatisticsResult {
  final Map<String, dynamic> results;

  BatchStatisticsResult(this.results);
  CashFlowData? getCashFlow(String key) {
    return results[key] as CashFlowData?;
  }
  SpendingAnalysis? getSpending(String key) {
    return results[key] as SpendingAnalysis?;
  }
  CreditAnalysis? getCreditAnalysis(String key) {
    return results[key] as CreditAnalysis?;
  }
  AssetAnalysis? getAssetAnalysis(String key) {
    return results[key] as AssetAnalysis?;
  }
  ComparisonData? getComparison(String key) {
    return results[key] as ComparisonData?;
  }
}
