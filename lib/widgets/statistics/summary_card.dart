import 'package:flutter/material.dart';
import 'package:money/widgets/statistics/accessibility_helpers.dart';

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Create semantic label for screen readers
    final semanticLabel = StatisticsAccessibility.summaryCardLabel(
      title: title,
      value: value,
      subtitle: subtitle,
    );
    
    // Ensure good color contrast
    final accessibleColor = StatisticsAccessibility.getAccessibleColor(
      color,
      theme.cardColor,
    );

    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      excludeSemantics: true,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: onTap != null
                ? const BoxConstraints(
                    minHeight: StatisticsAccessibility.minTouchTargetSize,
                  )
                : const BoxConstraints(),
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
                          color: accessibleColor.withValues(alpha: isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          icon,
                          color: accessibleColor,
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
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
