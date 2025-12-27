import 'package:flutter/material.dart';
import '../../services/statistics_service.dart';
import 'average_comparison_card.dart';
class AverageComparisonExample extends StatefulWidget {
  const AverageComparisonExample({super.key});

  @override
  State<AverageComparisonExample> createState() => _AverageComparisonExampleState();
}

class _AverageComparisonExampleState extends State<AverageComparisonExample> {
  final StatisticsService _statisticsService = StatisticsService();
  AverageComparisonData? _comparisonData;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadComparisonData();
  }

  Future<void> _loadComparisonData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final now = DateTime.now();
      final currentMonthStart = DateTime(now.year, now.month, 1);
      final currentMonthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final data = await _statisticsService.compareWithAverages(
        currentPeriodStart: currentMonthStart,
        currentPeriodEnd: currentMonthEnd,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ortalama Karşılaştırması'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadComparisonData,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Hata',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadComparisonData,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_comparisonData == null) {
      return const Center(
        child: Text('Veri bulunamadı'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue[700],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Bu ekran mevcut dönem performansınızı geçmiş dönem ortalamalarıyla karşılaştırır. '
                      '3, 6 ve 12 aylık ortalamalarla karşılaştırma yaparak finansal performansınızı değerlendirebilirsiniz.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          AverageComparisonCard(
            comparisonData: _comparisonData!,
          ),
          const SizedBox(height: 16),
          _buildAdditionalInfo(),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performans Derecelendirmesi',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildRatingInfo(
              'Mükemmel',
              'Ortalamanın %20 üzerinde performans',
              Colors.green,
              Icons.star,
            ),
            const SizedBox(height: 8),
            _buildRatingInfo(
              'İyi',
              'Ortalamanın %10-20 üzerinde performans',
              Colors.lightGreen,
              Icons.thumb_up,
            ),
            const SizedBox(height: 8),
            _buildRatingInfo(
              'Ortalama',
              'Ortalamanın ±%10 içinde performans',
              Colors.orange,
              Icons.remove,
            ),
            const SizedBox(height: 8),
            _buildRatingInfo(
              'Altında',
              'Ortalamanın %10-20 altında performans',
              Colors.deepOrange,
              Icons.trending_down,
            ),
            const SizedBox(height: 8),
            _buildRatingInfo(
              'Zayıf',
              'Ortalamanın %20 altında performans',
              Colors.red,
              Icons.warning,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingInfo(
    String label,
    String description,
    Color color,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color,
                  fontSize: 13,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
