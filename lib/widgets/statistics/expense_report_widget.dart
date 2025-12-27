import 'package:flutter/material.dart';

import 'summary_card.dart';
import '../../models/report_data.dart';

class ExpenseReportWidget extends StatelessWidget {
  final ExpenseReport report;

  const ExpenseReportWidget({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SummaryCard(
            title: 'Toplam Gider',
            value: '₺${report.totalExpense.toStringAsFixed(2)}',
            icon: Icons.trending_down,
            color: Colors.red,
          ),
        ],
      ),
    );
  }
}
