import 'package:flutter/material.dart';
import '../../models/goal_comparison.dart';
import '../../services/statistics_service.dart';
class GoalComparisonCard extends StatelessWidget {
  final GoalComparisonSummary summary;
  final VoidCallback? onGoalTap;

  const GoalComparisonCard({super.key, required this.summary, this.onGoalTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hedef Karşılaştırma',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (onGoalTap != null)
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: onGoalTap,
                    tooltip: 'Yeni Hedef Ekle',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildOverallSummary(context),
            const SizedBox(height: 16),
            _buildGoalStatistics(context),
            const SizedBox(height: 16),
            if (summary.goals.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 8),
              ...summary.goals.map((goal) => _buildGoalItem(context, goal)),
            ],
            if (summary.insights.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _buildInsights(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOverallSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Genel Başarı Oranı',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '%${summary.overallAchievementRate.toStringAsFixed(1)}',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: _getAchievementColor(summary.overallAchievementRate),
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: summary.overallAchievementRate / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              _getAchievementColor(summary.overallAchievementRate),
            ),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildGoalStatistics(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'Toplam',
            summary.totalGoals.toString(),
            Icons.flag,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            context,
            'Tamamlanan',
            summary.achievedGoals.toString(),
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            context,
            'Devam Eden',
            summary.inProgressGoals.toString(),
            Icons.pending,
            Colors.orange,
          ),
        ),
        if (summary.overdueGoals > 0) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              context,
              'Gecikmiş',
              summary.overdueGoals.toString(),
              Icons.warning,
              Colors.red,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGoalItem(BuildContext context, GoalComparison goal) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  goal.goalName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _buildStatusChip(context, goal.status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₺${goal.actualAmount.toStringAsFixed(2)} / ₺${goal.targetAmount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '%${goal.achievementPercentage.toStringAsFixed(1)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getAchievementColor(goal.achievementPercentage),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: goal.achievementPercentage / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              _getAchievementColor(goal.achievementPercentage),
            ),
            minHeight: 6,
          ),
          if (goal.deadline != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: goal.isOverdue == true ? Colors.red : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  goal.isOverdue == true
                      ? 'Süre doldu (${goal.daysRemaining!.abs()} gün önce)'
                      : '${goal.daysRemaining} gün kaldı',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: goal.isOverdue == true
                        ? Colors.red
                        : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, GoalStatus status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case GoalStatus.achieved:
        color = Colors.green;
        label = 'Tamamlandı';
        icon = Icons.check_circle;
        break;
      case GoalStatus.inProgress:
        color = Colors.blue;
        label = 'Devam Ediyor';
        icon = Icons.pending;
        break;
      case GoalStatus.behindSchedule:
        color = Colors.orange;
        label = 'Geride';
        icon = Icons.schedule;
        break;
      case GoalStatus.overdue:
        color = Colors.red;
        label = 'Gecikmiş';
        icon = Icons.warning;
        break;
      case GoalStatus.atRisk:
        color = Colors.deepOrange;
        label = 'Risk Altında';
        icon = Icons.error_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsights(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'İçgörüler',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...summary.insights.map(
          (insight) => Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: Colors.amber,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    insight,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getAchievementColor(double percentage) {
    if (percentage >= 90) {
      return Colors.green;
    } else if (percentage >= 70) {
      return Colors.lightGreen;
    } else if (percentage >= 50) {
      return Colors.orange;
    } else if (percentage >= 25) {
      return Colors.deepOrange;
    } else {
      return Colors.red;
    }
  }
}
