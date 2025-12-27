import 'package:flutter/material.dart';

/// Helper class for managing dark mode colors in statistics widgets
class StatisticsDarkModeColors {
  // Card backgrounds
  static Color getCardBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF1C1C1E) : Colors.white;
  }

  static Color getSecondaryCardBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7);
  }

  // Text colors
  static Color getPrimaryTextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white : const Color(0xFF1C1C1E);
  }

  static Color getSecondaryTextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFFE5E5EA) : const Color(0xFF8E8E93);
  }

  static Color getTertiaryTextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFFAAAAAA) : const Color(0xFF8E8E93);
  }

  // Icon colors
  static Color getPrimaryIconColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white : const Color(0xFF1C1C1E);
  }

  static Color getSecondaryIconColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFFAAAAAA) : const Color(0xFF8E8E93);
  }

  // Border colors
  static Color getBorderColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA);
  }

  static Color getDividerColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA);
  }

  // Chart grid colors
  static Color getChartGridColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return (isDark ? Colors.white : Colors.grey).withValues(alpha: 0.1);
  }

  static Color getChartBorderColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return (isDark ? Colors.white : Colors.grey).withValues(alpha: 0.2);
  }

  // Chart axis label colors
  static Color getChartAxisLabelColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white70 : Colors.grey;
  }

  // Tooltip colors
  static Color getTooltipBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.grey[850]! : Colors.black87;
  }

  // Overlay colors
  static Color getOverlayColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.05);
  }

  // Shimmer/skeleton colors
  static Color getShimmerBaseColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE0E0E0);
  }

  static Color getShimmerHighlightColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF38383A) : const Color(0xFFF5F5F5);
  }

  // Progress bar colors
  static Color getProgressBarBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.grey[800]! : Colors.grey[200]!;
  }

  // Filter chip colors
  static Color getFilterChipBackground(BuildContext context, bool selected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (selected) {
      return Theme.of(context).primaryColor;
    }
    return isDark ? Colors.grey[800]! : Colors.grey[200]!;
  }

  static Color getFilterChipBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.grey[700]! : Colors.grey[300]!;
  }

  static Color getFilterChipText(BuildContext context, bool selected) {
    if (selected) {
      return Colors.white;
    }
    return Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
  }

  // Empty state colors
  static Color getEmptyStateIconColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.grey[700]! : Colors.grey[300]!;
  }

  static Color getEmptyStateTextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.grey[600]! : Colors.grey[500]!;
  }

  // Shadow colors
  static Color getShadowColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.black.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.1);
  }

  // Highlight colors
  static Color getHighlightColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7);
  }

  // Splash colors
  static Color getSplashColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    return primaryColor.withValues(alpha: isDark ? 0.2 : 0.1);
  }
}
