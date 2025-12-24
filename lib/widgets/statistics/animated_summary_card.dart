import 'package:flutter/material.dart';
import 'animations/fade_in_animation.dart';
import 'animations/slide_transition_animation.dart';
import 'animations/scale_animation.dart';

/// Animated version of SummaryCard with entrance animations
class AnimatedSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final Duration delay;
  final bool enableAnimation;

  const AnimatedSummaryCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
    this.delay = Duration.zero,
    this.enableAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget card = Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
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
      ),
    );

    if (!enableAnimation) {
      return card;
    }

    // Combine fade, slide, and scale animations
    return FadeInAnimation(
      delay: delay,
      duration: const Duration(milliseconds: 300),
      child: SlideTransitionAnimation(
        delay: delay,
        duration: const Duration(milliseconds: 250),
        direction: SlideDirection.up,
        offset: 0.3,
        child: ScaleAnimation(
          delay: delay,
          duration: const Duration(milliseconds: 200),
          beginScale: 0.95,
          child: card,
        ),
      ),
    );
  }
}
