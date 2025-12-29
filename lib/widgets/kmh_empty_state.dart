import 'package:flutter/material.dart';
class KmhEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  const KmhEmptyState({
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
class KmhEmptyStates {
  static Widget noAccounts({VoidCallback? onAddAccount}) {
    return KmhEmptyState(
      icon: Icons.account_balance,
      title: 'Henüz KMH hesabı yok',
      message: 'KMH hesaplarınızı takip etmeye başlamak için\nyeni bir hesap ekleyin',
      actionLabel: 'KMH Hesabı Ekle',
      onAction: onAddAccount,
    );
  }

  static Widget noTransactions() {
    return const KmhEmptyState(
      icon: Icons.receipt_long_outlined,
      title: 'Henüz işlem yok',
      message: 'Bu hesapta henüz hiç işlem yapılmamış',
    );
  }

  static Widget noSearchResults() {
    return const KmhEmptyState(
      icon: Icons.search_off,
      title: 'Sonuç bulunamadı',
      message: 'Arama kriterlerinizi değiştirip tekrar deneyin',
    );
  }

  static Widget noData() {
    return const KmhEmptyState(
      icon: Icons.inbox_outlined,
      title: 'Veri bulunamadı',
      message: 'Seçilen tarih aralığında veri bulunmuyor',
    );
  }

  static Widget noDebt() {
    return KmhEmptyState(
      icon: Icons.check_circle_outline,
      title: 'Borç Bulunmuyor',
      message: 'Bu hesap için borç bulunmamaktadır',
      iconColor: Colors.green[400],
    );
  }
}
