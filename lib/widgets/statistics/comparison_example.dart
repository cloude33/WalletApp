import 'package:flutter/material.dart';
import '../../models/comparison_data.dart';
import '../../models/cash_flow_data.dart';
import 'comparison_card.dart';
import 'period_selector.dart';
class ComparisonExample extends StatelessWidget {
  const ComparisonExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Karşılaştırma Örnekleri')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            '1. Basit Karşılaştırma Kartı',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ComparisonCard(
            comparisonData: _createSampleComparisonData(),
            showPeriodSelector: false,
          ),
          const SizedBox(height: 24),
          Text(
            '2. Dönem Seçicili Karşılaştırma',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ComparisonCard(
            comparisonData: _createSampleComparisonData(),
            onPeriodChanged: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Dönem değiştir tıklandı')),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            '3. Dönem Seçici',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          PeriodSelector(
            selectedPeriod: PeriodType.thisMonthVsLastMonth,
            onPeriodChanged: (period) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Dönem değişti: ${period.name}')),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            '4. Kullanım Notları',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNote(
                    '✓ ComparisonCard: Tek bir karşılaştırma göstermek için',
                  ),
                  _buildNote(
                    '✓ PeriodSelector: Kullanıcının dönem seçmesi için',
                  ),
                  _buildNote(
                    '✓ ComparisonView: Tam özellikli karşılaştırma ekranı için',
                  ),
                  _buildNote('✓ Tüm widget\'lar karanlık modu destekler'),
                  _buildNote(
                    '✓ Trend göstergeleri otomatik hesaplanır (↗️ ↘️)',
                  ),
                  _buildNote('✓ Yüzde ve mutlak değer gösterimi'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNote(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }

  ComparisonData _createSampleComparisonData() {
    return ComparisonData(
      period1Start: DateTime(2024, 10, 1),
      period1End: DateTime(2024, 10, 31),
      period2Start: DateTime(2024, 11, 1),
      period2End: DateTime(2024, 11, 30),
      period1Label: 'Ekim 2024',
      period2Label: 'Kasım 2024',
      income: ComparisonMetric(
        label: 'Gelir',
        period1Value: 15000.0,
        period2Value: 18000.0,
        absoluteChange: 3000.0,
        percentageChange: 20.0,
        trend: TrendDirection.up,
      ),
      expense: ComparisonMetric(
        label: 'Gider',
        period1Value: 12000.0,
        period2Value: 11000.0,
        absoluteChange: -1000.0,
        percentageChange: -8.33,
        trend: TrendDirection.down,
      ),
      netCashFlow: ComparisonMetric(
        label: 'Net Akış',
        period1Value: 3000.0,
        period2Value: 7000.0,
        absoluteChange: 4000.0,
        percentageChange: 133.33,
        trend: TrendDirection.up,
      ),
      savingsRate: ComparisonMetric(
        label: 'Tasarruf Oranı',
        period1Value: 20.0,
        period2Value: 38.89,
        absoluteChange: 18.89,
        percentageChange: 94.45,
        trend: TrendDirection.up,
      ),
      categoryComparisons: [
        CategoryComparison(
          category: 'Market',
          period1Amount: 3000.0,
          period2Amount: 2500.0,
          absoluteChange: -500.0,
          percentageChange: -16.67,
          trend: TrendDirection.down,
        ),
        CategoryComparison(
          category: 'Ulaşım',
          period1Amount: 1500.0,
          period2Amount: 1800.0,
          absoluteChange: 300.0,
          percentageChange: 20.0,
          trend: TrendDirection.up,
        ),
        CategoryComparison(
          category: 'Eğlence',
          period1Amount: 2000.0,
          period2Amount: 1500.0,
          absoluteChange: -500.0,
          percentageChange: -25.0,
          trend: TrendDirection.down,
        ),
      ],
      overallTrend: TrendDirection.up,
      insights: [
        'Geliriniz %20 arttı, bu harika bir gelişme!',
        'Giderleriniz %8.33 azaldı, tasarruf hedeflerinize yaklaşıyorsunuz.',
        'Net nakit akışınız %133 arttı.',
        'Market harcamalarınız %16.67 azaldı.',
      ],
    );
  }
}
