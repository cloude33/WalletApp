import 'package:flutter/material.dart';
import '../../utils/currency_helper.dart';
import 'summary_card.dart';
class KmhSummaryCards extends StatelessWidget {
  final double totalDebt;
  final double totalLimit;
  final double utilizationRate;
  final int accountCount;

  const KmhSummaryCards({
    super.key,
    required this.totalDebt,
    required this.totalLimit,
    required this.utilizationRate,
    required this.accountCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'KMH Özeti',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            SummaryCard(
              title: 'Toplam Borç',
              value: CurrencyHelper.formatAmountNoDecimal(totalDebt),
              subtitle: '$accountCount hesap',
              icon: Icons.account_balance,
              color: totalDebt > 0 ? Colors.red : Colors.green,
            ),
            SummaryCard(
              title: 'Toplam Limit',
              value: CurrencyHelper.formatAmountNoDecimal(totalLimit),
              subtitle: 'Kullanılabilir',
              icon: Icons.credit_card,
              color: Colors.blue,
            ),
            SummaryCard(
              title: 'Kullanım Oranı',
              value: '${utilizationRate.toStringAsFixed(1)}%',
              subtitle: _getUtilizationLabel(utilizationRate),
              icon: Icons.pie_chart,
              color: _getUtilizationColor(utilizationRate),
            ),
            SummaryCard(
              title: 'Kalan Limit',
              value: CurrencyHelper.formatAmountNoDecimal(totalLimit - totalDebt),
              subtitle: 'Kullanılabilir',
              icon: Icons.account_balance_wallet,
              color: Colors.green,
            ),
          ],
        ),
      ],
    );
  }
  String _getUtilizationLabel(double rate) {
    if (rate == 0) {
      return 'Borç yok';
    } else if (rate < 30) {
      return 'Düşük';
    } else if (rate < 60) {
      return 'Orta';
    } else if (rate < 80) {
      return 'Yüksek';
    } else {
      return 'Çok yüksek';
    }
  }
  Color _getUtilizationColor(double rate) {
    if (rate == 0) {
      return Colors.green;
    } else if (rate < 30) {
      return Colors.blue;
    } else if (rate < 60) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
