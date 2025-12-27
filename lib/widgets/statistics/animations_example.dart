import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:money/models/cash_flow_data.dart';
import 'animated_summary_card.dart';
import 'animated_metric_card.dart';
import 'animated_chart_card.dart';
import 'animations/staggered_animation.dart';
import 'animations/fade_in_animation.dart';
import 'animations/slide_transition_animation.dart';
import 'animations/scale_animation.dart';
import 'interactive_line_chart.dart';
import 'interactive_pie_chart.dart';

/// Example screen demonstrating all animation types
class AnimationsExampleScreen extends StatelessWidget {
  const AnimationsExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İstatistik Animasyonları'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section 1: Fade In Animations
          FadeInAnimation(
            delay: const Duration(milliseconds: 100),
            child: Text(
              '1. Fade In Animasyonları',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Animated Summary Cards
          AnimatedSummaryCard(
            title: 'Total Income',
            value: '₺25,000',
            subtitle: 'Bu ay',
            icon: Icons.trending_up,
            color: Colors.green,
            delay: const Duration(milliseconds: 200),
          ),
          const SizedBox(height: 12),
          
          AnimatedSummaryCard(
            title: 'Toplam Gider',
            value: '₺18,500',
            subtitle: 'Bu ay',
            icon: Icons.trending_down,
            color: Colors.red,
            delay: const Duration(milliseconds: 300),
          ),
          const SizedBox(height: 24),

          // Section 2: Slide Transitions
          SlideTransitionAnimation(
            delay: const Duration(milliseconds: 400),
            direction: SlideDirection.left,
            child: Text(
              '2. Slide Transition Animasyonları',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 16),

          // Metric cards with different slide directions
          Row(
            children: [
              Expanded(
                child: AnimatedMetricCard(
                  label: 'Net Akış',
                  value: '₺6,500',
                  change: '+15%',
                  trend: TrendDirection.up,
                  color: Colors.green,
                  delay: const Duration(milliseconds: 500),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedMetricCard(
                  label: 'Ortalama',
                  value: '₺2,100',
                  change: '-5%',
                  trend: TrendDirection.down,
                  color: Colors.red,
                  delay: const Duration(milliseconds: 600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Section 3: Scale Animations
          ScaleAnimation(
            delay: const Duration(milliseconds: 700),
            child: Text(
              '3. Scale Animasyonları',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 16),

          ScaleAnimation(
            delay: const Duration(milliseconds: 800),
            beginScale: 0.8,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Bu kart scale animasyonu ile görünür',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section 4: Chart Animations
          FadeInAnimation(
            delay: const Duration(milliseconds: 900),
            child: Text(
              '4. Grafik Animasyonları',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 16),

          // Animated Line Chart
          AnimatedChartCard(
            title: 'Cash Flow Trend',
            subtitle: 'Son 6 ay',
            delay: const Duration(milliseconds: 1000),
            chart: InteractiveLineChart(
              spots: [
                const FlSpot(0, 3000),
                const FlSpot(1, 4500),
                const FlSpot(2, 3800),
                const FlSpot(3, 5200),
                const FlSpot(4, 4800),
                const FlSpot(5, 6500),
              ],
              color: Colors.blue,
              showArea: true,
              showDots: true,
            ),
          ),
          const SizedBox(height: 16),

          // Animated Pie Chart
          AnimatedChartCard(
            title: 'Category Distribution',
            subtitle: 'Bu ay',
            delay: const Duration(milliseconds: 1100),
            chart: InteractivePieChart(
              data: {
                'Market': 3500,
                'Ulaşım': 1200,
                'Eğlence': 800,
                'Faturalar': 2500,
                'Diğer': 1000,
              },
              colors: {
                'Market': Colors.blue,
                'Ulaşım': Colors.green,
                'Eğlence': Colors.orange,
                'Faturalar': Colors.red,
                'Diğer': Colors.grey,
              },
            ),
          ),
          const SizedBox(height: 24),

          // Section 5: Staggered Animations
          FadeInAnimation(
            delay: const Duration(milliseconds: 1200),
            child: Text(
              '5. Staggered (Kademeli) Animasyonlar',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 16),

          // List with staggered animations
          ...List.generate(5, (index) {
            return StaggeredAnimation(
              index: index,
              staggerDelay: const Duration(milliseconds: 100),
              child: Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text('${index + 1}'),
                  ),
                  title: Text('İşlem ${index + 1}'),
                  subtitle: Text('₺${(index + 1) * 100}'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                ),
              ),
            );
          }),
          const SizedBox(height: 24),

          // Animation controls info
          FadeInAnimation(
            delay: const Duration(milliseconds: 1700),
            child: Card(
              color: Colors.blue.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Animasyon Özellikleri',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Fade In', '300ms', 'Yumuşak görünme'),
                    _buildInfoRow('Slide', '250ms', 'Kayarak gelme'),
                    _buildInfoRow('Scale', '200ms', 'Büyüyerek görünme'),
                    _buildInfoRow('Chart', '500ms', 'Grafik açılma efekti'),
                    _buildInfoRow('Stagger', '50ms/öğe', 'Kademeli görünme'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String name, String duration, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              duration,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
