import 'package:flutter/material.dart';

/// Skeleton loader for statistics cards
class StatisticsSkeletonLoader extends StatefulWidget {
  final int itemCount;
  final SkeletonType type;

  const StatisticsSkeletonLoader({
    super.key,
    this.itemCount = 3,
    this.type = SkeletonType.card,
  });

  @override
  State<StatisticsSkeletonLoader> createState() =>
      _StatisticsSkeletonLoaderState();
}

class _StatisticsSkeletonLoaderState extends State<StatisticsSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.itemCount,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildSkeletonItem(isDark),
            );
          },
        );
      },
    );
  }

  Widget _buildSkeletonItem(bool isDark) {
    switch (widget.type) {
      case SkeletonType.card:
        return _buildCardSkeleton(isDark);
      case SkeletonType.chart:
        return _buildChartSkeleton(isDark);
      case SkeletonType.list:
        return _buildListSkeleton(isDark);
      case SkeletonType.metric:
        return _buildMetricSkeleton(isDark);
    }
  }

  Widget _buildCardSkeleton(bool isDark) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: _buildGradient(isDark),
      ),
    );
  }

  Widget _buildChartSkeleton(bool isDark) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: _buildGradient(isDark),
      ),
    );
  }

  Widget _buildListSkeleton(bool isDark) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: _buildGradient(isDark),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 16,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: _buildGradient(isDark),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 12,
                width: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: _buildGradient(isDark),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricSkeleton(bool isDark) {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: _buildGradient(isDark),
      ),
    );
  }

  LinearGradient _buildGradient(bool isDark) {
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[200]!;

    return LinearGradient(
      begin: Alignment(_animation.value - 1, 0),
      end: Alignment(_animation.value, 0),
      colors: [
        baseColor,
        highlightColor,
        baseColor,
      ],
    );
  }
}

enum SkeletonType {
  card,
  chart,
  list,
  metric,
}

/// Skeleton loader for specific chart types
class ChartSkeletonLoader extends StatelessWidget {
  final ChartSkeletonType type;

  const ChartSkeletonLoader({
    super.key,
    this.type = ChartSkeletonType.line,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _buildChartSkeleton(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 120,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const Spacer(),
        Container(
          width: 80,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildChartSkeleton(BuildContext context) {
    switch (type) {
      case ChartSkeletonType.line:
        return _buildLineChartSkeleton();
      case ChartSkeletonType.pie:
        return _buildPieChartSkeleton();
      case ChartSkeletonType.bar:
        return _buildBarChartSkeleton();
    }
  }

  Widget _buildLineChartSkeleton() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        7,
        (index) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 50 + (index * 20.0),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPieChartSkeleton() {
    return Center(
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[300],
        ),
      ),
    );
  }

  Widget _buildBarChartSkeleton() {
    return Column(
      children: List.generate(
        4,
        (index) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}

enum ChartSkeletonType {
  line,
  pie,
  bar,
}
