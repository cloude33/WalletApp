import 'package:flutter/material.dart';

/// Helper class for responsive design
/// Provides utilities for adapting UI based on screen size and orientation
class ResponsiveHelper {
  /// Screen size breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// Check if device is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Check if device is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  /// Check if device is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// Check if device is in landscape mode
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Check if device is in portrait mode
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// Get responsive value based on screen size
  static T getResponsiveValue<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context) && desktop != null) {
      return desktop;
    }
    if (isTablet(context) && tablet != null) {
      return tablet;
    }
    return mobile;
  }

  /// Get number of columns for grid based on screen size
  static int getGridColumns(BuildContext context, {int? mobile, int? tablet, int? desktop}) {
    return getResponsiveValue<int>(
      context: context,
      mobile: mobile ?? 1,
      tablet: tablet ?? 2,
      desktop: desktop ?? 3,
    );
  }

  /// Get padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    return getResponsiveValue(
      context: context,
      mobile: const EdgeInsets.all(16),
      tablet: const EdgeInsets.all(24),
      desktop: const EdgeInsets.all(32),
    );
  }

  /// Get horizontal padding based on screen size
  static EdgeInsets getResponsiveHorizontalPadding(BuildContext context) {
    return getResponsiveValue(
      context: context,
      mobile: const EdgeInsets.symmetric(horizontal: 16),
      tablet: const EdgeInsets.symmetric(horizontal: 32),
      desktop: const EdgeInsets.symmetric(horizontal: 48),
    );
  }

  /// Get font size based on screen size
  static double getResponsiveFontSize(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return getResponsiveValue(
      context: context,
      mobile: mobile,
      tablet: tablet ?? mobile * 1.1,
      desktop: desktop ?? mobile * 1.2,
    );
  }

  /// Get chart height based on screen size and orientation
  static double getChartHeight(BuildContext context) {
    if (isLandscape(context)) {
      return getResponsiveValue(
        context: context,
        mobile: 200,
        tablet: 250,
        desktop: 300,
      );
    }
    return getResponsiveValue(
      context: context,
      mobile: 300,
      tablet: 350,
      desktop: 400,
    );
  }

  /// Get card width for grid layouts
  static double? getCardWidth(BuildContext context) {
    if (isTablet(context) || isDesktop(context)) {
      final screenWidth = MediaQuery.of(context).size.width;
      final columns = getGridColumns(context);
      final padding = getResponsivePadding(context);
      final spacing = 16.0 * (columns - 1);
      return (screenWidth - padding.horizontal - spacing) / columns;
    }
    return null; // Full width on mobile
  }

  /// Get max content width for centered layouts
  static double getMaxContentWidth(BuildContext context) {
    return getResponsiveValue(
      context: context,
      mobile: double.infinity,
      tablet: 800,
      desktop: 1200,
    );
  }

  /// Get spacing between elements
  static double getSpacing(BuildContext context) {
    return getResponsiveValue(
      context: context,
      mobile: 16,
      tablet: 20,
      desktop: 24,
    );
  }

  /// Get icon size based on screen size
  static double getIconSize(BuildContext context) {
    return getResponsiveValue(
      context: context,
      mobile: 24,
      tablet: 28,
      desktop: 32,
    );
  }

  /// Build responsive layout with different widgets for different screen sizes
  static Widget buildResponsive({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    if (isDesktop(context) && desktop != null) {
      return desktop;
    }
    if (isTablet(context) && tablet != null) {
      return tablet;
    }
    return mobile;
  }

  /// Get number of items to show in a row based on screen size
  static int getItemsPerRow(BuildContext context) {
    if (isLandscape(context)) {
      return getResponsiveValue(
        context: context,
        mobile: 2,
        tablet: 3,
        desktop: 4,
      );
    }
    return getResponsiveValue(
      context: context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
    );
  }

  /// Get tab bar scroll behavior
  static bool shouldTabBarScroll(BuildContext context) {
    return isMobile(context) || (isTablet(context) && isPortrait(context));
  }

  /// Get bottom padding for floating action buttons
  static double getBottomPadding(BuildContext context) {
    return getResponsiveValue(
      context: context,
      mobile: 80,
      tablet: 100,
      desktop: 120,
    );
  }

  /// Get dialog width
  static double? getDialogWidth(BuildContext context) {
    if (isMobile(context)) {
      return null; // Full width on mobile
    }
    return getResponsiveValue<double>(
      context: context,
      mobile: 400,
      tablet: 500,
      desktop: 600,
    );
  }

  /// Get sidebar width for tablet/desktop layouts
  static double getSidebarWidth(BuildContext context) {
    return getResponsiveValue(
      context: context,
      mobile: 0,
      tablet: 250,
      desktop: 300,
    );
  }

  /// Check if should use side-by-side layout
  static bool shouldUseSideBySideLayout(BuildContext context) {
    return (isTablet(context) && isLandscape(context)) || isDesktop(context);
  }

  /// Get aspect ratio for cards
  static double getCardAspectRatio(BuildContext context) {
    return getResponsiveValue(
      context: context,
      mobile: 1.5,
      tablet: 1.8,
      desktop: 2.0,
    );
  }
}
