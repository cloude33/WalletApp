import 'package:flutter/material.dart';
import '../../utils/currency_helper.dart';
class KmhInterestCard extends StatelessWidget {
  final double dailyInterest;
  final double monthlyInterest;
  final double annualInterest;

  const KmhInterestCard({
    super.key,
    required this.dailyInterest,
    required this.monthlyInterest,
    required this.annualInterest,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasInterest = dailyInterest > 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: hasInterest
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.orange.withValues(alpha: isDark ? 0.2 : 0.1),
                    Colors.red.withValues(alpha: isDark ? 0.2 : 0.1),
                  ],
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: hasInterest
                          ? Colors.orange.withValues(alpha: isDark ? 0.3 : 0.2)
                          : Colors.green.withValues(alpha: isDark ? 0.3 : 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      hasInterest ? Icons.trending_up : Icons.check_circle,
                      color: hasInterest ? Colors.orange : Colors.green,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Faiz Bilgileri',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasInterest
                              ? 'Tahakkuk eden faiz tutarları'
                              : 'Faiz tahakkuku bulunmamaktadır',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (hasInterest) ...[
                const SizedBox(height: 20),
                _buildInterestRow(
                  context: context,
                  icon: Icons.today,
                  label: 'Günlük Faiz',
                  amount: dailyInterest,
                  color: Colors.orange,
                  subtitle: 'Her gün tahakkuk eden',
                ),

                const SizedBox(height: 12),

                _buildInterestRow(
                  context: context,
                  icon: Icons.calendar_month,
                  label: 'Aylık Faiz (Tahmini)',
                  amount: monthlyInterest,
                  color: Colors.deepOrange,
                  subtitle: '30 günlük projeksiyon',
                ),

                const SizedBox(height: 12),

                _buildInterestRow(
                  context: context,
                  icon: Icons.calendar_today,
                  label: 'Yıllık Faiz (Tahmini)',
                  amount: annualInterest,
                  color: Colors.red,
                  subtitle: '365 günlük projeksiyon',
                ),

                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Faiz tutarları günlük olarak hesaplanır ve borcunuza eklenir. Erken ödeme yaparak faiz maliyetini azaltabilirsiniz.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'KMH hesaplarınızda borç bulunmadığı için faiz tahakkuku yoktur.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInterestRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required double amount,
    required Color color,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            CurrencyHelper.formatAmount(amount),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
