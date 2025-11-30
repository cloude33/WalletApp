import 'package:intl/intl.dart';

class TransactionFormValidator {
  static String? validate({
    required String amountText,
    required String description,
    required String? category,
    required String? walletId,
    required String selectedType,
    required bool isInstallment,
    required int installmentCount,
    required bool isCreditCardWallet,
  }) {
    // Amount checks
    if (amountText.trim().isEmpty) {
      return 'Lütfen tutar girin';
    }
    final cleanAmountText = amountText.replaceAll('.', '').replaceAll(',', '.');
    final amount = double.tryParse(cleanAmountText);
    if (amount == null) {
      return 'Tutar formatı geçersiz';
    }
    if (amount <= 0) {
      return 'Tutar 0’dan büyük olmalı';
    }

    // Description
    if (description.trim().isEmpty) {
      return 'Lütfen açıklama girin';
    }

    // Wallet
    if (walletId == null || walletId.isEmpty) {
      return 'Lütfen bir cüzdan seçin';
    }

    // Category (enforce for expense/income)
    if ((selectedType == 'expense' || selectedType == 'income') &&
        (category == null || category.isEmpty)) {
      return 'Lütfen bir kategori seçin';
    }

    // Installment rules
    if (isInstallment) {
      if (!isCreditCardWallet) {
        return 'Taksitli işlem sadece kredi kartı cüzdanında yapılabilir';
      }
      if (installmentCount < 2) {
        return 'Taksit sayısı en az 2 olmalı';
      }
      if (installmentCount > 24) {
        return 'Taksit sayısı en fazla 24 olabilir';
      }
    }

    return null; // No errors
  }

  static String formatAmountTurkish(double amount) {
    return NumberFormat('#,##0.00', 'tr_TR').format(amount);
  }
}