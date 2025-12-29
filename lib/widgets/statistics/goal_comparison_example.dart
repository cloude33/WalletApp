import 'package:flutter/material.dart';
import '../../services/statistics_service.dart';
import 'goal_comparison_card.dart';
class GoalComparisonExample extends StatefulWidget {
  const GoalComparisonExample({super.key});

  @override
  State<GoalComparisonExample> createState() => _GoalComparisonExampleState();
}

class _GoalComparisonExampleState extends State<GoalComparisonExample> {
  final StatisticsService _statisticsService = StatisticsService();
  GoalComparisonSummary? _summary;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGoalComparison();
  }

  Future<void> _loadGoalComparison() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final summary = await _statisticsService.compareGoals();
      setState(() {
        _summary = summary;
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
        title: const Text('Hedef Karşılaştırma'),
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
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Hata: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadGoalComparison,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_summary == null) {
      return const Center(
        child: Text('Veri bulunamadı'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGoalComparison,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: GoalComparisonCard(
          summary: _summary!,
          onGoalTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Yeni hedef ekleme ekranına yönlendirilecek'),
              ),
            );
          },
        ),
      ),
    );
  }
}
