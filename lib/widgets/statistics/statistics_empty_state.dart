import 'package:flutter/material.dart';

/// Empty state widget for statistics screens
class StatisticsEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  const StatisticsEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: iconColor ?? Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Predefined empty states for statistics screens
class StatisticsEmptyStates {
  /// No transactions in the selected period
  static Widget noTransactions({VoidCallback? onAddTransaction}) {
    return StatisticsEmptyState(
      icon: Icons.receipt_long_outlined,
      title: 'Henüz İşlem Yok',
      message:
          'Seçilen tarih aralığında hiç işlem bulunmuyor.\nİşlem ekleyerek istatistiklerinizi görüntüleyin.',
      actionLabel: onAddTransaction != null ? 'İşlem Ekle' : null,
      onAction: onAddTransaction,
    );
  }

  /// No data for cash flow analysis
  static Widget noCashFlowData() {
    return const StatisticsEmptyState(
      icon: Icons.trending_up_outlined,
      title: 'Nakit Akışı Verisi Yok',
      message:
          'Nakit akışı analizi için yeterli veri bulunmuyor.\nEn az bir gelir veya gider işlemi ekleyin.',
    );
  }

  /// No spending data
  static Widget noSpendingData() {
    return const StatisticsEmptyState(
      icon: Icons.shopping_cart_outlined,
      title: 'Harcama Verisi Yok',
      message:
          'Harcama analizi için veri bulunmuyor.\nGider işlemleri ekleyerek harcamalarınızı takip edin.',
    );
  }

  /// No credit card data
  static Widget noCreditCards({VoidCallback? onAddCard}) {
    return StatisticsEmptyState(
      icon: Icons.credit_card_outlined,
      title: 'Kredi Kartı Yok',
      message:
          'Kredi kartı analizi için kart bulunmuyor.\nKredi kartı ekleyerek borçlarınızı takip edin.',
      actionLabel: onAddCard != null ? 'Kredi Kartı Ekle' : null,
      onAction: onAddCard,
    );
  }

  /// No KMH accounts
  static Widget noKmhAccounts({VoidCallback? onAddAccount}) {
    return StatisticsEmptyState(
      icon: Icons.account_balance_outlined,
      title: 'KMH Hesabı Yok',
      message:
          'KMH analizi için hesap bulunmuyor.\nKMH hesabı ekleyerek borçlarınızı takip edin.',
      actionLabel: onAddAccount != null ? 'KMH Hesabı Ekle' : null,
      onAction: onAddAccount,
    );
  }

  /// No assets
  static Widget noAssets({VoidCallback? onAddWallet}) {
    return StatisticsEmptyState(
      icon: Icons.account_balance_wallet_outlined,
      title: 'Varlık Yok',
      message:
          'Varlık analizi için cüzdan bulunmuyor.\nCüzdan ekleyerek varlıklarınızı takip edin.',
      actionLabel: onAddWallet != null ? 'Cüzdan Ekle' : null,
      onAction: onAddWallet,
    );
  }

  /// No reports
  static Widget noReports() {
    return const StatisticsEmptyState(
      icon: Icons.description_outlined,
      title: 'Rapor Yok',
      message:
          'Henüz rapor oluşturulmamış.\nRapor oluşturmak için tarih aralığı ve filtreler seçin.',
    );
  }

  /// No search results
  static Widget noSearchResults() {
    return const StatisticsEmptyState(
      icon: Icons.search_off_outlined,
      title: 'Sonuç Bulunamadı',
      message:
          'Arama kriterlerinize uygun sonuç bulunamadı.\nFarklı anahtar kelimeler deneyin.',
    );
  }

  /// No filter results
  static Widget noFilterResults() {
    return const StatisticsEmptyState(
      icon: Icons.filter_alt_off_outlined,
      title: 'Filtre Sonucu Yok',
      message:
          'Seçilen filtrelere uygun veri bulunamadı.\nFiltreleri değiştirip tekrar deneyin.',
    );
  }

  /// No comparison data
  static Widget noComparisonData() {
    return const StatisticsEmptyState(
      icon: Icons.compare_arrows_outlined,
      title: 'Karşılaştırma Verisi Yok',
      message:
          'Karşılaştırma için yeterli veri bulunmuyor.\nEn az iki farklı dönemde veri olmalıdır.',
    );
  }

  /// No budget set
  static Widget noBudget({VoidCallback? onSetBudget}) {
    return StatisticsEmptyState(
      icon: Icons.savings_outlined,
      title: 'Bütçe Belirlenmemiş',
      message:
          'Bütçe takibi için henüz bütçe belirlenmemiş.\nKategoriler için bütçe belirleyin.',
      actionLabel: onSetBudget != null ? 'Bütçe Belirle' : null,
      onAction: onSetBudget,
    );
  }

  /// No goals set
  static Widget noGoals({VoidCallback? onSetGoal}) {
    return StatisticsEmptyState(
      icon: Icons.flag_outlined,
      title: 'Hedef Belirlenmemiş',
      message:
          'Hedef karşılaştırması için henüz hedef belirlenmemiş.\nFinansal hedeflerinizi belirleyin.',
      actionLabel: onSetGoal != null ? 'Hedef Belirle' : null,
      onAction: onSetGoal,
    );
  }
}
