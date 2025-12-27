import 'package:flutter/material.dart';
import '../../utils/responsive_helper.dart';

/// Responsive layout wrapper for statistics content
/// Adapts layout based on screen size and orientation
class ResponsiveStatisticsLayout extends StatelessWidget {
  final List<Widget> children;
  final double? bottomPadding;
  final bool useGrid;

  const ResponsiveStatisticsLayout({
    super.key,
    required this.children,
    this.bottomPadding,
    this.useGrid = false,
  });

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getResponsivePadding(context);
    final spacing = ResponsiveHelper.getSpacing(context);
    final bottom = bottomPadding ?? ResponsiveHelper.getBottomPadding(context);

    // Use grid layout for tablet/desktop
    if (useGrid && ResponsiveHelper.shouldUseSideBySideLayout(context)) {
      return _buildGridLayout(context, padding, spacing, bottom);
    }

    // Use list layout for mobile or when grid is disabled
    return _buildListLayout(context, padding, spacing, bottom);
  }

  Widget _buildListLayout(
    BuildContext context,
    EdgeInsets padding,
    double spacing,
    double bottom,
  ) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        padding.left,
        padding.top,
        padding.right,
        bottom,
      ),
      itemCount: children.length,
      separatorBuilder: (context, index) => SizedBox(height: spacing),
      itemBuilder: (context, index) => children[index],
    );
  }

  Widget _buildGridLayout(
    BuildContext context,
    EdgeInsets padding,
    double spacing,
    double bottom,
  ) {
    final columns = ResponsiveHelper.getGridColumns(context);

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(
        padding.left,
        padding.top,
        padding.right,
        bottom,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: ResponsiveHelper.getCardAspectRatio(context),
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// Responsive card wrapper that adapts to screen size
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  final double? elevation;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardPadding = padding ?? ResponsiveHelper.getResponsivePadding(context);

    return Container(
      padding: cardPadding,
      decoration: BoxDecoration(
        color: color ?? (isDark ? const Color(0xFF1C1C1E) : Theme.of(context).cardColor),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: elevation ?? 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Responsive row that wraps to column on small screens
class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;

  const ResponsiveRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    // Use column on mobile portrait
    if (ResponsiveHelper.isMobile(context) && ResponsiveHelper.isPortrait(context)) {
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _addSpacing(children, spacing, isVertical: true),
      );
    }

    // Use row on tablet/desktop or landscape
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: _addSpacing(children, spacing, isVertical: false),
    );
  }

  List<Widget> _addSpacing(List<Widget> widgets, double spacing, {required bool isVertical}) {
    if (widgets.isEmpty) return widgets;

    final result = <Widget>[];
    for (int i = 0; i < widgets.length; i++) {
      result.add(widgets[i]);
      if (i < widgets.length - 1) {
        result.add(isVertical ? SizedBox(height: spacing) : SizedBox(width: spacing));
      }
    }
    return result;
  }
}

/// Responsive chart container with adaptive height
class ResponsiveChartContainer extends StatelessWidget {
  final Widget chart;
  final String? title;
  final String? subtitle;
  final List<Widget>? actions;

  const ResponsiveChartContainer({
    super.key,
    required this.chart,
    this.title,
    this.subtitle,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final height = ResponsiveHelper.getChartHeight(context);
    final fontSize = ResponsiveHelper.getResponsiveFontSize(context, mobile: 16);

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title!,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: fontSize * 0.75,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (actions != null) ...actions!,
              ],
            ),
            SizedBox(height: ResponsiveHelper.getSpacing(context)),
          ],
          SizedBox(
            height: height,
            child: chart,
          ),
        ],
      ),
    );
  }
}

/// Responsive grid for summary cards
class ResponsiveSummaryGrid extends StatelessWidget {
  final List<Widget> cards;

  const ResponsiveSummaryGrid({
    super.key,
    required this.cards,
  });

  @override
  Widget build(BuildContext context) {
    final itemsPerRow = ResponsiveHelper.getItemsPerRow(context);
    final spacing = ResponsiveHelper.getSpacing(context);

    // Group cards into rows
    final rows = <List<Widget>>[];
    for (int i = 0; i < cards.length; i += itemsPerRow) {
      final end = (i + itemsPerRow < cards.length) ? i + itemsPerRow : cards.length;
      rows.add(cards.sublist(i, end));
    }

    return Column(
      children: rows.map((rowCards) {
        return Padding(
          padding: EdgeInsets.only(bottom: spacing),
          child: Row(
            children: rowCards.map((card) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: rowCards.last == card ? 0 : spacing,
                  ),
                  child: card,
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

/// Adaptive tab bar that scrolls on mobile
class AdaptiveTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController controller;
  final List<Widget> tabs;
  final Color? indicatorColor;
  final Color? labelColor;
  final Color? unselectedLabelColor;

  const AdaptiveTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.indicatorColor,
    this.labelColor,
    this.unselectedLabelColor,
  });

  @override
  Widget build(BuildContext context) {
    final shouldScroll = ResponsiveHelper.shouldTabBarScroll(context);
    final fontSize = ResponsiveHelper.getResponsiveFontSize(context, mobile: 14);

    return TabBar(
      controller: controller,
      isScrollable: shouldScroll,
      indicatorColor: indicatorColor ?? const Color(0xFF00BFA5),
      indicatorWeight: 3,
      labelColor: labelColor ?? const Color(0xFF00BFA5),
      unselectedLabelColor: unselectedLabelColor ?? Colors.grey,
      labelStyle: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: fontSize,
      ),
      tabs: tabs,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(48);
}
