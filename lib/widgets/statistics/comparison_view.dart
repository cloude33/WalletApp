import 'package:flutter/material.dart';
import '../../models/comparison_data.dart';
import '../../services/statistics_service.dart';
import 'comparison_card.dart';
import 'period_selector.dart';
class ComparisonView extends StatefulWidget {
  final StatisticsService statisticsService;
  final PeriodType initialPeriod;

  const ComparisonView({
    super.key,
    required this.statisticsService,
    this.initialPeriod = PeriodType.thisMonthVsLastMonth,
  });

  @override
  State<ComparisonView> createState() => _ComparisonViewState();
}

class _ComparisonViewState extends State<ComparisonView> {
  late PeriodType _selectedPeriod;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  ComparisonData? _comparisonData;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedPeriod = widget.initialPeriod;
    _loadComparisonData();
  }

  Future<void> _loadComparisonData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final periodDates = PeriodHelper.getPeriodDates(
        _selectedPeriod,
        customStart: _customStartDate,
        customEnd: _customEndDate,
      );

      final data = await widget.statisticsService.comparePeriods(
        period1Start: periodDates.period1Start,
        period1End: periodDates.period1End,
        period2Start: periodDates.period2Start,
        period2End: periodDates.period2End,
      );

      setState(() {
        _comparisonData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onPeriodChanged(PeriodType period) {
    setState(() {
      _selectedPeriod = period;
    });
    _loadComparisonData();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PeriodSelector(
          selectedPeriod: _selectedPeriod,
          onPeriodChanged: _onPeriodChanged,
          customStartDate: _customStartDate,
          customEndDate: _customEndDate,
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          ),
        if (_error != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Veri yüklenirken hata oluştu',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadComparisonData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            ),
          ),
        if (_comparisonData != null && !_isLoading) ...[
          ComparisonCard(
            comparisonData: _comparisonData!,
            showPeriodSelector: false,
          ),
          if (_comparisonData!.categoryComparisons.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildCategoryComparisons(),
          ],
        ],
      ],
    );
  }

  Widget _buildCategoryComparisons() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kategori Karşılaştırması',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            ..._comparisonData!.categoryComparisons.map((comparison) {
              final isPositive = comparison.absoluteChange > 0;
              final changeColor = comparison.absoluteChange == 0
                  ? Colors.grey
                  : isPositive
                      ? Colors.red
                      : Colors.green;

              final trendIcon = comparison.absoluteChange == 0
                  ? Icons.trending_flat
                  : isPositive
                      ? Icons.trending_up
                      : Icons.trending_down;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comparison.category,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '₺${comparison.period1Amount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward,
                                    size: 12,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '₺${comparison.period2Amount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: theme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  trendIcon,
                                  size: 16,
                                  color: changeColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${comparison.percentageChange >= 0 ? '+' : ''}${comparison.percentageChange.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: changeColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${comparison.absoluteChange >= 0 ? '+' : ''}₺${comparison.absoluteChange.abs().toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: changeColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (comparison != _comparisonData!.categoryComparisons.last) ...[
                      const SizedBox(height: 12),
                      Divider(
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
