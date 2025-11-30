import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/recurring_transaction.dart';
import '../services/recurring_transaction_service.dart';
import 'edit_recurring_transaction_screen.dart';

class RecurringTransactionDetailScreen extends StatefulWidget {
  final RecurringTransaction transaction;
  final RecurringTransactionService service;

  const RecurringTransactionDetailScreen({
    super.key,
    required this.transaction,
    required this.service,
  });

  @override
  State<RecurringTransactionDetailScreen> createState() =>
      _RecurringTransactionDetailScreenState();
}

class _RecurringTransactionDetailScreenState
    extends State<RecurringTransactionDetailScreen> {
  final dateFormat = DateFormat('dd MMMM yyyy', 'tr_TR');

  @override
  Widget build(BuildContext context) {
    final transaction = widget.transaction;
    final nextDate = transaction.nextDate;

    return Scaffold(
      appBar: AppBar(
        title: const Text('İşlem Detayı'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditRecurringTransactionScreen(
                    transaction: transaction,
                    service: widget.service,
                  ),
                ),
              );
              if (result == true) {
                setState(() {});
                Navigator.pop(context, true);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteDialog(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${transaction.isIncome ? '+' : '-'}${transaction.amount.toStringAsFixed(2)} ₺',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: transaction.isIncome ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoCard('Genel Bilgiler', [
              _buildInfoRow('Kategori', transaction.category),
              _buildInfoRow('Sıklık', transaction.frequency.displayName),
              _buildInfoRow('Durum', transaction.isActive ? 'Aktif' : 'Pasif'),
              if (transaction.description != null)
                _buildInfoRow('Açıklama', transaction.description!),
            ]),
            const SizedBox(height: 16),
            _buildInfoCard('Tarih Bilgileri', [
              _buildInfoRow('Başlangıç', dateFormat.format(transaction.startDate)),
              if (transaction.endDate != null)
                _buildInfoRow('Bitiş', dateFormat.format(transaction.endDate!)),
              if (transaction.lastCreatedDate != null)
                _buildInfoRow('Son Oluşturma', dateFormat.format(transaction.lastCreatedDate!)),
              if (nextDate != null)
                _buildInfoRow('Sonraki', dateFormat.format(nextDate)),
            ]),
            const SizedBox(height: 16),
            _buildInfoCard('İstatistikler', [
              _buildInfoRow('Oluşturulan İşlem', '${transaction.createdCount}'),
              if (transaction.occurrenceCount != null)
                _buildInfoRow('Toplam Hedef', '${transaction.occurrenceCount}'),
              _buildInfoRow(
                'Toplam Tutar',
                '${(transaction.amount * transaction.createdCount).toStringAsFixed(2)} ₺',
              ),
            ]),
            if (transaction.notificationEnabled) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Bildirim Ayarları', [
                _buildInfoRow('Bildirimler', 'Açık'),
                if (transaction.reminderDaysBefore != null)
                  _buildInfoRow(
                    'Hatırlatma',
                    '${transaction.reminderDaysBefore} gün önce',
                  ),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İşlemi Sil'),
        content: const Text(
          'Bu tekrarlayan işlemi silmek istediğinizden emin misiniz?\n\n'
          'Oluşturulmuş geçmiş işlemler korunacaktır.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (result == true) {
      await widget.service.delete(widget.transaction.id);
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }
}
