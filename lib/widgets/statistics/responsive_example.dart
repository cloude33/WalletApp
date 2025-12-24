import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/responsive_helper.dart';
import 'responsive_statistics_layout.dart';
import 'summary_card.dart';
import 'interactive_line_chart.dart';

/// Example of using responsive design in statistics screen
class ResponsiveStatisticsExample extends StatelessWidget {
  const ResponsiveStatisticsExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Responsive Statistics'),
      ),
      body: ResponsiveStatisticsLayout(
        // Use grid layout on tablet/desktop landscape
        useGrid: ResponsiveHelper.shouldUseSideBySideLayout(context),
        children: [
          // Summary cards with responsive grid
          _buildSummarySection(context),
          
          // Chart with adaptive height
          _buildChartSection(context),
          
          // Details with responsive row
          _buildDetailsSection(context),
        ],
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary',
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(
                context,
                mobile: 18,
                tablet: 20,
                desktop: 22,
              ),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getSpacing(context)),
          ResponsiveSummaryGrid(
            cards: [
              SummaryCard(
                title: 'Total Income',
                value: '₺10,000',
                icon: Icons.trending_up,
                color: Colors.green,
              ),
              SummaryCard(
                title: 'Total Expense',
                value: '₺7,500',
                icon: Icons.trending_down,
                color: Colors.red,
              ),
              SummaryCard(
                title: 'Net Balance',
                value: '₺2,500',
                icon: Icons.account_balance_wallet,
                color: Colors.blue,
              ),
              SummaryCard(
                title: 'Savings Rate',
                value: '25%',
                icon: Icons.savings,
                color: Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(BuildContext context) {
    return ResponsiveChartContainer(
      title: 'Cash Flow Trend',
      subtitle: 'Last 12 months',
      chart: InteractiveLineChart(
        spots: _generateSampleData(),
        color: Colors.blue,
        showArea: true,
        showDots: true,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildDetailsSection(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Details',
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(
                context,
                mobile: 18,
              ),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getSpacing(context)),
          // This row will wrap to column on mobile portrait
          ResponsiveRow(
            children: [
              Expanded(
                child: _buildDetailItem(
                  'Average Daily',
                  '₺333',
                  Icons.calendar_today,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  'Highest Day',
                  '₺1,200',
                  Icons.arrow_upward,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  'Lowest Day',
                  '₺50',
                  Icons.arrow_downward,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: Colors.blue),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _generateSampleData() {
    return List.generate(
      12,
      (index) => FlSpot(
        index.toDouble(),
        (index * 100 + 500).toDouble(),
      ),
    );
  }
}

/// Example showing conditional rendering based on screen size
class ConditionalRenderingExample extends StatelessWidget {
  const ConditionalRenderingExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Different layouts for different screen sizes
    if (ResponsiveHelper.isMobile(context)) {
      return _buildMobileLayout(context);
    } else if (ResponsiveHelper.isTablet(context)) {
      return _buildTabletLayout(context);
    } else {
      return _buildDesktopLayout(context);
    }
  }

  Widget _buildMobileLayout(BuildContext context) {
    return ListView(
      padding: ResponsiveHelper.getResponsivePadding(context),
      children: [
        const Text('Mobile Layout'),
        const SizedBox(height: 16),
        _buildContent(context),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Row(
      children: [
        // Sidebar
        Container(
          width: ResponsiveHelper.getSidebarWidth(context),
          color: Colors.grey[200],
          child: const Center(child: Text('Sidebar')),
        ),
        // Main content
        Expanded(
          child: ListView(
            padding: ResponsiveHelper.getResponsivePadding(context),
            children: [
              const Text('Tablet Layout'),
              const SizedBox(height: 16),
              _buildContent(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Sidebar
        Container(
          width: ResponsiveHelper.getSidebarWidth(context),
          color: Colors.grey[200],
          child: const Center(child: Text('Sidebar')),
        ),
        // Main content with max width
        Expanded(
          child: Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: ResponsiveHelper.getMaxContentWidth(context),
              ),
              child: ListView(
                padding: ResponsiveHelper.getResponsivePadding(context),
                children: [
                  const Text('Desktop Layout'),
                  const SizedBox(height: 16),
                  _buildContent(context),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        children: [
          Text(
            'Content',
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(
                context,
                mobile: 16,
                tablet: 18,
                desktop: 20,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Screen width: ${MediaQuery.of(context).size.width.toStringAsFixed(0)}px',
          ),
          Text(
            'Is Mobile: ${ResponsiveHelper.isMobile(context)}',
          ),
          Text(
            'Is Tablet: ${ResponsiveHelper.isTablet(context)}',
          ),
          Text(
            'Is Desktop: ${ResponsiveHelper.isDesktop(context)}',
          ),
          Text(
            'Is Landscape: ${ResponsiveHelper.isLandscape(context)}',
          ),
        ],
      ),
    );
  }
}
