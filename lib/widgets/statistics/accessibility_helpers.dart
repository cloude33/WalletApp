import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:money/models/cash_flow_data.dart';

/// Accessibility helpers for statistics widgets
/// Provides semantic labels, announcements, and accessible components
class StatisticsAccessibility {
  /// Minimum touch target size (48x48 dp) as per Material Design guidelines
  static const double minTouchTargetSize = 48.0;

  /// Announce a message to screen readers
  static void announce(BuildContext context, String message) {
    final view = View.of(context);
    SemanticsService.sendAnnouncement(view, message, TextDirection.ltr);
  }

  /// Format currency value for screen readers
  static String currencyLabel(double amount, {String currency = 'TL'}) {
    final absAmount = amount.abs();
    final formattedAmount = absAmount.toStringAsFixed(2);

    if (amount < 0) {
      return '$formattedAmount $currency eksi';
    } else if (amount > 0) {
      return '$formattedAmount $currency artı';
    } else {
      return 'Sıfır $currency';
    }
  }

  /// Format percentage for screen readers
  static String percentageLabel(double percentage) {
    return 'Yüzde ${percentage.toStringAsFixed(1)}';
  }

  /// Format date for screen readers
  static String dateLabel(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

  /// Format trend direction for screen readers
  static String trendLabel(TrendDirection trend) {
    switch (trend) {
      case TrendDirection.up:
        return 'Artış trendi';
      case TrendDirection.down:
        return 'Azalış trendi';
      case TrendDirection.stable:
        return 'Sabit trend';
    }
  }

  /// Create semantic label for metric card
  static String metricCardLabel({
    required String label,
    required String value,
    String? change,
    TrendDirection? trend,
  }) {
    final buffer = StringBuffer();
    buffer.write('$label: $value');

    if (change != null) {
      buffer.write(', değişim: $change');
    }

    if (trend != null) {
      buffer.write(', ${trendLabel(trend)}');
    }

    return buffer.toString();
  }

  /// Create semantic label for summary card
  static String summaryCardLabel({
    required String title,
    required String value,
    String? subtitle,
  }) {
    final buffer = StringBuffer();
    buffer.write('$title: $value');

    if (subtitle != null) {
      buffer.write(', $subtitle');
    }

    return buffer.toString();
  }

  /// Create semantic label for chart
  static String chartLabel({
    required String title,
    required int dataPointCount,
    String? description,
  }) {
    final buffer = StringBuffer();
    buffer.write('$title grafik, $dataPointCount veri noktası');

    if (description != null) {
      buffer.write(', $description');
    }

    return buffer.toString();
  }

  /// Check if color contrast ratio is sufficient (WCAG AA standard: 4.5:1)
  static bool hasGoodContrast(Color foreground, Color background) {
    final fgLuminance = foreground.computeLuminance();
    final bgLuminance = background.computeLuminance();

    final lighter = fgLuminance > bgLuminance ? fgLuminance : bgLuminance;
    final darker = fgLuminance > bgLuminance ? bgLuminance : fgLuminance;

    final contrastRatio = (lighter + 0.05) / (darker + 0.05);

    // WCAG AA requires 4.5:1 for normal text, 3:1 for large text
    // We use 4.5:1 as the standard
    return contrastRatio >= 4.5;
  }

  /// Get accessible color with good contrast
  static Color getAccessibleColor(Color color, Color background) {
    if (hasGoodContrast(color, background)) {
      return color;
    }

    // If contrast is poor, adjust the color
    final bgLuminance = background.computeLuminance();

    // If background is dark, make color lighter
    if (bgLuminance < 0.5) {
      return color.withValues(
        red: (color.r + 0.3).clamp(0.0, 1.0),
        green: (color.g + 0.3).clamp(0.0, 1.0),
        blue: (color.b + 0.3).clamp(0.0, 1.0),
      );
    } else {
      // If background is light, make color darker
      return color.withValues(
        red: (color.r - 0.3).clamp(0.0, 1.0),
        green: (color.g - 0.3).clamp(0.0, 1.0),
        blue: (color.b - 0.3).clamp(0.0, 1.0),
      );
    }
  }

  static String _getMonthName(int month) {
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    return months[month - 1];
  }
}

/// Accessible button with minimum touch target size
class AccessibleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final String? semanticHint;
  final bool isEnabled;
  final EdgeInsetsGeometry? padding;

  const AccessibleButton({
    super.key,
    required this.child,
    required this.onPressed,
    required this.semanticLabel,
    this.semanticHint,
    this.isEnabled = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: true,
      enabled: isEnabled && onPressed != null,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: StatisticsAccessibility.minTouchTargetSize,
          minHeight: StatisticsAccessibility.minTouchTargetSize,
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          child: Padding(
            padding:
                padding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Accessible icon button with minimum touch target size
class AccessibleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final String? tooltip;
  final Color? color;
  final double? iconSize;

  const AccessibleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.tooltip,
    this.color,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: onPressed != null,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: StatisticsAccessibility.minTouchTargetSize,
          minHeight: StatisticsAccessibility.minTouchTargetSize,
        ),
        child: IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          tooltip: tooltip ?? semanticLabel,
          color: color,
          iconSize: iconSize ?? 24,
        ),
      ),
    );
  }
}

/// Accessible card with semantic label
class AccessibleCard extends StatelessWidget {
  final Widget child;
  final String semanticLabel;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool isButton;

  const AccessibleCard({
    super.key,
    required this.child,
    required this.semanticLabel,
    this.onTap,
    this.padding,
    this.margin,
    this.isButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: isButton && onTap != null,
      excludeSemantics: true,
      child: Card(
        margin: margin,
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
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Accessible chip with minimum touch target size
class AccessibleFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const AccessibleFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final semanticLabel = selected
        ? '$label seçili filtre'
        : '$label filtresi, seçmek için dokunun';

    return Semantics(
      label: semanticLabel,
      button: true,
      selected: selected,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: StatisticsAccessibility.minTouchTargetSize,
        ),
        child: FilterChip(
          label: Text(label),
          avatar: icon != null ? Icon(icon, size: 18) : null,
          selected: selected,
          onSelected: (_) => onTap(),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }
}

/// Accessible progress indicator with semantic value
class AccessibleProgress extends StatelessWidget {
  final double value;
  final String label;
  final Color color;
  final Color? backgroundColor;
  final double height;

  const AccessibleProgress({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    this.backgroundColor,
    this.height = 12,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (value * 100).toStringAsFixed(0);
    final theme = Theme.of(context);

    return Semantics(
      label: '$label: Yüzde $percentage',
      value: percentage,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(height / 2),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor:
                  backgroundColor ?? Colors.grey.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: height,
            ),
          ),
        ],
      ),
    );
  }
}

/// Accessible list tile with semantic label
class AccessibleListTile extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String semanticLabel;

  const AccessibleListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: StatisticsAccessibility.minTouchTargetSize,
        ),
        child: ListTile(
          leading: leading,
          title: title,
          subtitle: subtitle,
          trailing: trailing,
          onTap: onTap,
        ),
      ),
    );
  }
}
