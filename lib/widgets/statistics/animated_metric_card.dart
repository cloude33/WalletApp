import 'package:flutter/material.dart';
import 'package:parion/models/cash_flow_data.dart';
import 'animations/fade_in_animation.dart';
import 'animations/scale_animation.dart';

/// Animated version of MetricCard with entrance animations
class AnimatedMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String? change;
  final TrendDirection? trend;
  final Color? color;
  final Duration delay;
  final bool enableAnimation;

  const AnimatedMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.change,
    this.trend,
    this.color,
    this.delay = Duration.zero,
    this.enableAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color? trendColor;
    IconData? trendIcon;

    if (trend != null) {
      switch (trend!) {
        case TrendDirection.up:
          trendColor = Colors.green;
          trendIcon = Icons.trending_up;
          break;
        case TrendDirection.down:
          trendColor = Colors.red;
          trendIcon = Icons.trending_down;
          break;
        case TrendDirection.stable:
          trendColor = Colors.grey;
          trendIcon = Icons.trending_flat;
          break;
      }
    }

    Widget card = Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color ?? theme.textTheme.bodyLarge?.color,
              ),
            ),
            if (change != null || trend != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  if (trend != null && trendIcon != null) ...[
                    Icon(
                      trendIcon,
                      size: 16,
                      color: trendColor,
                    ),
                    const SizedBox(width: 4),
                  ],
                  if (change != null)
                    Text(
                      change!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: trendColor ?? theme.textTheme.bodySmall?.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );

    if (!enableAnimation) {
      return card;
    }

    // Combine fade and scale animations
    return FadeInAnimation(
      delay: delay,
      duration: const Duration(milliseconds: 300),
      child: ScaleAnimation(
        delay: delay,
        duration: const Duration(milliseconds: 200),
        beginScale: 0.9,
        child: card,
      ),
    );
  }
}
