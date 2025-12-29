import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/wallet.dart';
class KmhAssetCard extends StatefulWidget {
  final List<Wallet> kmhAccounts;

  const KmhAssetCard({super.key, required this.kmhAccounts});

  @override
  State<KmhAssetCard> createState() => _KmhAssetCardState();
}

class _KmhAssetCardState extends State<KmhAssetCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final positiveKmhAccounts = widget.kmhAccounts
        .where((wallet) => wallet.balance > 0)
        .toList();
    final totalPositiveBalance = positiveKmhAccounts.fold<double>(
      0,
      (sum, wallet) => sum + wallet.balance,
    );

    final totalUnusedLimit = widget.kmhAccounts.fold<double>(0, (sum, wallet) {
      final usedAmount = wallet.balance < 0
          ? wallet.balance.abs()
          : wallet.balance;
      final unused = (wallet.creditLimit - usedAmount).clamp(
        0.0,
        wallet.creditLimit,
      );
      return sum + unused;
    });

    final totalCreditCapacity = widget.kmhAccounts.fold<double>(
      0,
      (sum, wallet) => sum + wallet.creditLimit,
    );
    final liquidityReserve = totalPositiveBalance + totalUnusedLimit;

    if (widget.kmhAccounts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.account_balance_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'KMH hesabı bulunmamaktadır',
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color?.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.account_balance,
                    color: Colors.purple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'KMH Varlık Analizi',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${widget.kmhAccounts.length} hesap',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSummaryMetrics(
              theme: theme,
              isDark: isDark,
              totalPositiveBalance: totalPositiveBalance,
              totalUnusedLimit: totalUnusedLimit,
              liquidityReserve: liquidityReserve,
              totalCreditCapacity: totalCreditCapacity,
            ),
            if (positiveKmhAccounts.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildPositiveBalanceSection(
                theme: theme,
                isDark: isDark,
                accounts: positiveKmhAccounts,
              ),
            ],
            if (_isExpanded) ...[
              const SizedBox(height: 16),
              _buildExpandedDetails(theme: theme, isDark: isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryMetrics({
    required ThemeData theme,
    required bool isDark,
    required double totalPositiveBalance,
    required double totalUnusedLimit,
    required double liquidityReserve,
    required double totalCreditCapacity,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withValues(alpha: 0.1),
            Colors.blue.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.purple.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.water_drop, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                        'Likidite Rezervi',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.purple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatCurrency(liquidityReserve),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                  Text(
                    'Toplam kullanılabilir kaynak',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: theme.textTheme.bodySmall?.color?.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.savings_outlined,
                  color: Colors.purple,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  label: 'Pozitif Bakiye',
                  value: totalPositiveBalance,
                  icon: Icons.add_circle_outline,
                  color: Colors.green,
                  theme: theme,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              Expanded(
                child: _buildMetricItem(
                  label: 'Kullanılmayan Limit',
                  value: totalUnusedLimit,
                  icon: Icons.credit_card,
                  color: Colors.blue,
                  theme: theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required double value,
    required IconData icon,
    required Color color,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: theme.textTheme.bodySmall?.color?.withValues(
                    alpha: 0.7,
                  ),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _formatCurrency(value),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPositiveBalanceSection({
    required ThemeData theme,
    required bool isDark,
    required List<Wallet> accounts,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.trending_up, size: 16, color: Colors.green),
            const SizedBox(width: 8),
            Text(
              'Pozitif Bakiyeli KMH Hesapları',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${accounts.length}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...accounts.map(
          (wallet) => _buildKmhAccountItem(
            theme: theme,
            isDark: isDark,
            wallet: wallet,
            isPositive: true,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedDetails({
    required ThemeData theme,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: isDark ? Colors.grey[700] : Colors.grey[300]),
        const SizedBox(height: 12),
        Text(
          'Tüm KMH Hesapları',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...widget.kmhAccounts.map(
          (wallet) => _buildKmhAccountItem(
            theme: theme,
            isDark: isDark,
            wallet: wallet,
            isPositive: wallet.balance > 0,
          ),
        ),

        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Pozitif bakiyeli KMH hesapları likit varlık olarak değerlendirilir ve acil durumlarda kullanılabilir.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: theme.textTheme.bodySmall?.color?.withValues(
                      alpha: 0.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKmhAccountItem({
    required ThemeData theme,
    required bool isDark,
    required Wallet wallet,
    required bool isPositive,
  }) {
    final usedAmount = wallet.balance < 0
        ? wallet.balance.abs()
        : wallet.balance;
    final unusedLimit = (wallet.creditLimit - usedAmount).clamp(
      0.0,
      wallet.creditLimit,
    );
    final utilizationRate = wallet.creditLimit > 0
        ? (usedAmount / wallet.creditLimit) * 100
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPositive
              ? Colors.green.withValues(alpha: 0.3)
              : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isPositive
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.account_balance,
                        size: 16,
                        color: isPositive ? Colors.green : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            wallet.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (wallet.accountNumber != null)
                            Text(
                              wallet.accountNumber!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                color: theme.textTheme.bodySmall?.color
                                    ?.withValues(alpha: 0.6),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatCurrency(wallet.balance.abs()),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                  ),
                  Text(
                    isPositive ? 'Varlık' : 'Borç',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kullanılmayan Limit',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: theme.textTheme.bodySmall?.color?.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatCurrency(unusedLimit),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Toplam Limit',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: theme.textTheme.bodySmall?.color?.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatCurrency(wallet.creditLimit),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Kullanım',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: theme.textTheme.bodySmall?.color?.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${utilizationRate.toStringAsFixed(1)}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getUtilizationColor(utilizationRate),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (utilizationRate / 100).clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getUtilizationColor(utilizationRate),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getUtilizationColor(double utilizationRate) {
    if (utilizationRate <= 30) {
      return Colors.green;
    } else if (utilizationRate <= 60) {
      return Colors.blue;
    } else if (utilizationRate <= 80) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _formatCurrency(double value) {
    return '₺${NumberFormat('#,##0.00', 'tr_TR').format(value.abs())}';
  }
}
