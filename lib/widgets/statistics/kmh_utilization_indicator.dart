import 'package:flutter/material.dart';
import '../../utils/currency_helper.dart';
class KmhUtilizationIndicator extends StatelessWidget {
  final double utilizationRate;
  final double usedAmount;
  final double totalLimit;
  final bool showLabel;
  final bool showAmounts;

  const KmhUtilizationIndicator({
    super.key,
    required this.utilizationRate,
    required this.usedAmount,
    required this.totalLimit,
    this.showLabel = false,
    this.showAmounts = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getUtilizationColor(utilizationRate);
    final label = _getUtilizationLabel(utilizationRate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kullanım Oranı',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: color.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${utilizationRate.toStringAsFixed(1)}%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Stack(
          children: [
            Container(
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            FractionallySizedBox(
              widthFactor: (utilizationRate / 100).clamp(0.0, 1.0),
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        
        if (showAmounts) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kullanılan: ${CurrencyHelper.formatAmountNoDecimal(usedAmount)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              Text(
                'Limit: ${CurrencyHelper.formatAmountNoDecimal(totalLimit)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
  String _getUtilizationLabel(double rate) {
    if (rate == 0) {
      return 'Borç Yok';
    } else if (rate < 30) {
      return 'Düşük';
    } else if (rate < 60) {
      return 'Orta';
    } else if (rate < 80) {
      return 'Yüksek';
    } else {
      return 'Çok Yüksek';
    }
  }
  Color _getUtilizationColor(double rate) {
    if (rate == 0) {
      return Colors.green;
    } else if (rate < 30) {
      return Colors.blue;
    } else if (rate < 60) {
      return Colors.orange;
    } else if (rate < 80) {
      return Colors.deepOrange;
    } else {
      return Colors.red;
    }
  }
}
