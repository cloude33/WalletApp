import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/asset_analysis.dart';
import '../../models/wallet.dart';
import '../../services/statistics_service.dart';
import '../../services/data_service.dart';
import 'summary_card.dart';
import 'kmh_asset_card.dart';
import 'net_worth_trend_chart.dart';
import 'financial_health_score_card.dart';
class AssetsTab extends StatefulWidget {
  const AssetsTab({super.key});

  @override
  State<AssetsTab> createState() => _AssetsTabState();
}

class _AssetsTabState extends State<AssetsTab> {
  final StatisticsService _statisticsService = StatisticsService();
  final DataService _dataService = DataService();
  AssetAnalysis? _assetAnalysis;
  List<Wallet> _kmhAccounts = [];
  bool _isLoading = true;
  String? _error;
  int? _selectedAssetIndex;

  @override
  void initState() {
    super.initState();
    _loadAssetData();
  }

  Future<void> _loadAssetData() async {
    print('DEBUG: _loadAssetData started');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('DEBUG: Calling analyzeAssets');
      final data = await _statisticsService.analyzeAssets();
      print('DEBUG: analyzeAssets returned');
      final wallets = await _dataService.getWallets();
      print('DEBUG: getWallets returned ${wallets.length} wallets');
      final kmhAccounts = wallets.where((w) => w.isKmhAccount).toList();

      if (mounted) {
        setState(() {
          _assetAnalysis = data;
          _kmhAccounts = kmhAccounts;
          _isLoading = false;
        });
        print('DEBUG: State updated with data');
      }
    } catch (e) {
      print('DEBUG: Error in _loadAssetData: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Hata: $_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAssetData,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_assetAnalysis == null) {
      return const Center(
        child: Text('Veri bulunamadı'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAssetData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          _buildNetWorthSummaryCards(),
          const SizedBox(height: 16),
          _buildLiquidityRatioCard(),
          const SizedBox(height: 16),
          if (_kmhAccounts.isNotEmpty) ...[
            KmhAssetCard(kmhAccounts: _kmhAccounts),
            const SizedBox(height: 16),
          ],
          if (_assetAnalysis!.netWorthTrend.isNotEmpty) ...[
            NetWorthTrendChart(
              trendData: _assetAnalysis!.netWorthTrend,
              targetNetWorth: null,
            ),
            const SizedBox(height: 16),
          ],
          FinancialHealthScoreCard(
            healthScore: _assetAnalysis!.healthScore,
          ),
          const SizedBox(height: 16),
          _buildAssetDistributionCard(),
          const SizedBox(height: 16),
          _buildDebtDistributionCard(),
        ],
      ),
    );
  }
  Widget _buildNetWorthSummaryCards() {
    final data = _assetAnalysis!;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: 'Toplam Varlık',
                value: _formatCurrency(data.totalAssets),
                subtitle: 'Tüm pozitif bakiyeler',
                icon: Icons.account_balance_wallet,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SummaryCard(
                title: 'Toplam Borç',
                value: _formatCurrency(data.totalLiabilities),
                subtitle: 'Kredi kartı + KMH borcu',
                icon: Icons.credit_card,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SummaryCard(
          title: 'Net Varlık',
          value: _formatCurrency(data.netWorth),
          subtitle: data.netWorth >= 0
              ? 'Varlıklar borçlardan fazla'
              : 'Borçlar varlıklardan fazla',
          icon: Icons.trending_up,
          color: data.netWorth >= 0 ? Colors.blue : Colors.orange,
        ),
      ],
    );
  }
  Widget _buildLiquidityRatioCard() {
    final data = _assetAnalysis!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    String liquidityStatus;
    Color liquidityColor;
    IconData liquidityIcon;
    String liquidityDescription;

    if (data.liquidityRatio >= 2.0) {
      liquidityStatus = 'Mükemmel';
      liquidityColor = Colors.green;
      liquidityIcon = Icons.check_circle;
      liquidityDescription = 'Likit varlıklarınız borçlarınızın 2 katından fazla';
    } else if (data.liquidityRatio >= 1.0) {
      liquidityStatus = 'İyi';
      liquidityColor = Colors.blue;
      liquidityIcon = Icons.thumb_up;
      liquidityDescription = 'Likit varlıklarınız borçlarınızı karşılıyor';
    } else if (data.liquidityRatio >= 0.5) {
      liquidityStatus = 'Orta';
      liquidityColor = Colors.orange;
      liquidityIcon = Icons.warning;
      liquidityDescription = 'Likit varlıklarınızı artırmayı düşünün';
    } else {
      liquidityStatus = 'Düşük';
      liquidityColor = Colors.red;
      liquidityIcon = Icons.error;
      liquidityDescription = 'Acil likidite ihtiyacı var';
    }
    final liquidAssets = data.cashAndEquivalents + 
                        data.bankAccounts + 
                        data.positiveKmhBalances;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.water_drop,
                  color: Colors.blue,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Likidite Oranı',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          liquidityIcon,
                          color: liquidityColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          liquidityStatus,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: liquidityColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Oran: ${data.liquidityRatio.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (data.liquidityRatio / 3.0).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(liquidityColor),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              liquidityDescription,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLiquidityItem(
                    'Likit Varlıklar',
                    liquidAssets,
                    Colors.blue,
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                  ),
                  _buildLiquidityItem(
                    'Toplam Borç',
                    data.totalLiabilities,
                    Colors.red,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiquidityItem(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatCurrency(value),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
  Widget _buildAssetDistributionCard() {
    final data = _assetAnalysis!;
    final theme = Theme.of(context);
    final assetData = <String, double>{};
    final assetColors = <String, Color>{};

    if (data.cashAndEquivalents > 0) {
      assetData['Nakit'] = data.cashAndEquivalents;
      assetColors['Nakit'] = Colors.green;
    }
    if (data.bankAccounts > 0) {
      assetData['Banka Hesapları'] = data.bankAccounts;
      assetColors['Banka Hesapları'] = Colors.blue;
    }
    if (data.positiveKmhBalances > 0) {
      assetData['KMH (+)'] = data.positiveKmhBalances;
      assetColors['KMH (+)'] = Colors.purple;
    }
    if (data.investments > 0) {
      assetData['Yatırımlar'] = data.investments;
      assetColors['Yatırımlar'] = Colors.orange;
    }
    final otherAssets = data.totalAssets - 
                       (data.cashAndEquivalents + 
                        data.bankAccounts + 
                        data.positiveKmhBalances + 
                        data.investments);
    if (otherAssets > 0) {
      assetData['Diğer'] = otherAssets;
      assetColors['Diğer'] = Colors.grey;
    }

    if (assetData.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Henüz varlık bulunmamaktadır',
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Varlık Dağılımı',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 60,
                        sections: _buildPieChartSections(assetData, assetColors),
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            if (event is FlTapUpEvent &&
                                pieTouchResponse != null &&
                                pieTouchResponse.touchedSection != null) {
                              setState(() {
                                final index = pieTouchResponse
                                    .touchedSection!.touchedSectionIndex;
                                _selectedAssetIndex =
                                    _selectedAssetIndex == index ? null : index;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: assetData.entries.map((entry) {
                        final index = assetData.keys.toList().indexOf(entry.key);
                        final isSelected = _selectedAssetIndex == index;
                        final percentage =
                            (entry.value / data.totalAssets) * 100;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedAssetIndex =
                                    isSelected ? null : index;
                              });
                            },
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: assetColors[entry.key],
                                    shape: BoxShape.circle,
                                    border: isSelected
                                        ? Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.key,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      Text(
                                        '${percentage.toStringAsFixed(1)}%',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontSize: 10,
                                          color: theme.textTheme.bodySmall?.color
                                              ?.withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedAssetIndex != null &&
                _selectedAssetIndex! < assetData.length) ...[
              const SizedBox(height: 16),
              _buildSelectedAssetDetails(
                assetData.keys.elementAt(_selectedAssetIndex!),
                assetData.values.elementAt(_selectedAssetIndex!),
                assetColors.values.elementAt(_selectedAssetIndex!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(
    Map<String, double> data,
    Map<String, Color> colors,
  ) {
    final total = data.values.fold<double>(0, (sum, value) => sum + value);

    return data.entries.map((entry) {
      final index = data.keys.toList().indexOf(entry.key);
      final isSelected = _selectedAssetIndex == index;
      final percentage = (entry.value / total) * 100;

      return PieChartSectionData(
        color: colors[entry.key],
        value: entry.value,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: isSelected ? 70 : 60,
        titleStyle: TextStyle(
          fontSize: isSelected ? 14 : 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildSelectedAssetDetails(String name, double value, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(
            _formatCurrency(value),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildDebtDistributionCard() {
    final data = _assetAnalysis!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (data.totalLiabilities == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.celebration,
                  size: 48,
                  color: Colors.green,
                ),
                const SizedBox(height: 16),
                Text(
                  'Harika! Hiç borcunuz yok',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Finansal durumunuz çok iyi',
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.credit_card,
                  color: Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Borç Dağılımı',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Toplam Borç',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatCurrency(data.totalLiabilities),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red,
                    size: 32,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Borç Detayları',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Detaylı borç analizi için "Kredi" sekmesini ziyaret edin',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    return '₺${NumberFormat('#,##0.00', 'tr_TR').format(value.abs())}';
  }
}
