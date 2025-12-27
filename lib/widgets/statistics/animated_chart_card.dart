import 'package:flutter/material.dart';
import 'animations/chart_animation.dart';
import 'animations/fade_in_animation.dart';

/// Animated wrapper for chart widgets
class AnimatedChartCard extends StatelessWidget {
  final String title;
  final Widget chart;
  final String? subtitle;
  final List<Widget>? actions;
  final Duration delay;
  final bool enableAnimation;

  const AnimatedChartCard({
    super.key,
    required this.title,
    required this.chart,
    this.subtitle,
    this.actions,
    this.delay = Duration.zero,
    this.enableAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget cardContent = Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color
                                ?.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (actions != null) ...actions!,
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: enableAnimation
                  ? ChartRevealAnimation(
                      delay: delay + const Duration(milliseconds: 200),
                      child: chart,
                    )
                  : chart,
            ),
          ],
        ),
      ),
    );

    if (!enableAnimation) {
      return cardContent;
    }

    // Fade in the card container
    return FadeInAnimation(
      delay: delay,
      duration: const Duration(milliseconds: 300),
      child: cardContent,
    );
  }
}
