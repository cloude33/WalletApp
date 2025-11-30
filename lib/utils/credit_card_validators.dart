/// Credit card validation utilities
class CreditCardValidators {
  /// Validate statement day (1-31)
  static String? validateStatementDay(int? day) {
    if (day == null) {
      return 'Ekstre kesim günü gerekli';
    }
    if (day < 1 || day > 31) {
      return 'Ekstre kesim günü 1-31 arasında olmalı';
    }
    return null;
  }

  /// Validate installment count (1-36)
  static String? validateInstallmentCount(int? count) {
    if (count == null) {
      return 'Taksit sayısı gerekli';
    }
    if (count < 1 || count > 36) {
      return 'Taksit sayısı 1-36 arasında olmalı';
    }
    return null;
  }

  /// Validate interest rate (non-negative)
  static String? validateInterestRate(double? rate, {String fieldName = 'Faiz oranı'}) {
    if (rate == null) {
      return '$fieldName gerekli';
    }
    if (rate < 0) {
      return '$fieldName negatif olamaz';
    }
    if (rate > 100) {
      return '$fieldName %100\'den büyük olamaz';
    }
    return null;
  }

  /// Validate credit limit (positive)
  static String? validateCreditLimit(double? limit) {
    if (limit == null) {
      return 'Kredi limiti gerekli';
    }
    if (limit <= 0) {
      return 'Kredi limiti sıfırdan büyük olmalı';
    }
    return null;
  }

  /// Validate amount (positive)
  static String? validateAmount(double? amount, {String fieldName = 'Tutar'}) {
    if (amount == null) {
      return '$fieldName gerekli';
    }
    if (amount <= 0) {
      return '$fieldName sıfırdan büyük olmalı';
    }
    return null;
  }

  /// Validate bank name (non-empty)
  static String? validateBankName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Banka adı gerekli';
    }
    if (name.trim().length < 2) {
      return 'Banka adı en az 2 karakter olmalı';
    }
    return null;
  }

  /// Validate card name (non-empty)
  static String? validateCardName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Kart adı gerekli';
    }
    if (name.trim().length < 2) {
      return 'Kart adı en az 2 karakter olmalı';
    }
    return null;
  }

  /// Validate last 4 digits
  static String? validateLast4Digits(String? digits) {
    if (digits == null || digits.isEmpty) {
      return 'Son 4 hane gerekli';
    }
    if (digits.length != 4) {
      return 'Son 4 hane 4 karakter olmalı';
    }
    if (!RegExp(r'^\d{4}$').hasMatch(digits)) {
      return 'Son 4 hane sadece rakam içermeli';
    }
    return null;
  }

  /// Validate due date offset (non-negative)
  static String? validateDueDateOffset(int? offset) {
    if (offset == null) {
      return 'Son ödeme günü offset gerekli';
    }
    if (offset < 0) {
      return 'Son ödeme günü offset negatif olamaz';
    }
    if (offset > 60) {
      return 'Son ödeme günü offset 60 günden fazla olamaz';
    }
    return null;
  }

  /// Validate description (non-empty)
  static String? validateDescription(String? description) {
    if (description == null || description.trim().isEmpty) {
      return 'Açıklama gerekli';
    }
    if (description.trim().length < 2) {
      return 'Açıklama en az 2 karakter olmalı';
    }
    return null;
  }

  /// Validate category (non-empty)
  static String? validateCategory(String? category) {
    if (category == null || category.trim().isEmpty) {
      return 'Kategori gerekli';
    }
    return null;
  }

  /// Validate payment method (non-empty)
  static String? validatePaymentMethod(String? method) {
    if (method == null || method.trim().isEmpty) {
      return 'Ödeme yöntemi gerekli';
    }
    return null;
  }

  /// Validate date (not null)
  static String? validateDate(DateTime? date, {String fieldName = 'Tarih'}) {
    if (date == null) {
      return '$fieldName gerekli';
    }
    return null;
  }

  /// Validate date range
  static String? validateDateRange(DateTime? start, DateTime? end) {
    if (start == null) {
      return 'Başlangıç tarihi gerekli';
    }
    if (end == null) {
      return 'Bitiş tarihi gerekli';
    }
    if (end.isBefore(start)) {
      return 'Bitiş tarihi başlangıç tarihinden önce olamaz';
    }
    return null;
  }

  /// Validate installments paid vs total
  static String? validateInstallmentsPaid(int? paid, int? total) {
    if (paid == null) {
      return 'Ödenen taksit sayısı gerekli';
    }
    if (total == null) {
      return 'Toplam taksit sayısı gerekli';
    }
    if (paid < 0) {
      return 'Ödenen taksit sayısı negatif olamaz';
    }
    if (paid > total) {
      return 'Ödenen taksit sayısı toplam taksit sayısından fazla olamaz';
    }
    return null;
  }

  /// Validate minimum payment rate (0.3-0.4)
  static String? validateMinimumPaymentRate(double? rate) {
    if (rate == null) {
      return 'Asgari ödeme oranı gerekli';
    }
    if (rate < 0.3 || rate > 0.4) {
      return 'Asgari ödeme oranı %30-40 arasında olmalı';
    }
    return null;
  }

  /// Validate statement period
  static String? validateStatementPeriod(DateTime? start, DateTime? end, DateTime? dueDate) {
    final dateRangeError = validateDateRange(start, end);
    if (dateRangeError != null) {
      return dateRangeError;
    }
    
    if (dueDate != null && dueDate.isBefore(end!)) {
      return 'Son ödeme tarihi ekstre kesim tarihinden önce olamaz';
    }
    
    return null;
  }

  /// Validate payment amount against statement debt
  static String? validatePaymentAmount(double? payment, double? totalDebt) {
    if (payment == null) {
      return 'Ödeme tutarı gerekli';
    }
    if (payment <= 0) {
      return 'Ödeme tutarı sıfırdan büyük olmalı';
    }
    // Allow overpayment (it will be handled as credit)
    return null;
  }

  /// Validate card ID (non-empty)
  static String? validateCardId(String? id) {
    if (id == null || id.trim().isEmpty) {
      return 'Kart ID gerekli';
    }
    return null;
  }

  /// Validate statement ID (non-empty)
  static String? validateStatementId(String? id) {
    if (id == null || id.trim().isEmpty) {
      return 'Ekstre ID gerekli';
    }
    return null;
  }

  /// Comprehensive credit card validation
  static Map<String, String> validateCreditCard({
    required String? bankName,
    required String? cardName,
    required String? last4Digits,
    required double? creditLimit,
    required int? statementDay,
    required int? dueDateOffset,
    required double? monthlyInterestRate,
    required double? lateInterestRate,
  }) {
    final errors = <String, String>{};

    final bankError = validateBankName(bankName);
    if (bankError != null) errors['bankName'] = bankError;

    final cardError = validateCardName(cardName);
    if (cardError != null) errors['cardName'] = cardError;

    final digitsError = validateLast4Digits(last4Digits);
    if (digitsError != null) errors['last4Digits'] = digitsError;

    final limitError = validateCreditLimit(creditLimit);
    if (limitError != null) errors['creditLimit'] = limitError;

    final statementError = validateStatementDay(statementDay);
    if (statementError != null) errors['statementDay'] = statementError;

    final offsetError = validateDueDateOffset(dueDateOffset);
    if (offsetError != null) errors['dueDateOffset'] = offsetError;

    final monthlyRateError = validateInterestRate(monthlyInterestRate, fieldName: 'Aylık faiz oranı');
    if (monthlyRateError != null) errors['monthlyInterestRate'] = monthlyRateError;

    final lateRateError = validateInterestRate(lateInterestRate, fieldName: 'Gecikme faizi oranı');
    if (lateRateError != null) errors['lateInterestRate'] = lateRateError;

    return errors;
  }

  /// Comprehensive transaction validation
  static Map<String, String> validateTransaction({
    required String? cardId,
    required double? amount,
    required String? description,
    required String? category,
    required DateTime? transactionDate,
    required int? installmentCount,
  }) {
    final errors = <String, String>{};

    final cardError = validateCardId(cardId);
    if (cardError != null) errors['cardId'] = cardError;

    final amountError = validateAmount(amount);
    if (amountError != null) errors['amount'] = amountError;

    final descError = validateDescription(description);
    if (descError != null) errors['description'] = descError;

    final catError = validateCategory(category);
    if (catError != null) errors['category'] = catError;

    final dateError = validateDate(transactionDate, fieldName: 'İşlem tarihi');
    if (dateError != null) errors['transactionDate'] = dateError;

    final installmentError = validateInstallmentCount(installmentCount);
    if (installmentError != null) errors['installmentCount'] = installmentError;

    return errors;
  }

  /// Comprehensive payment validation
  static Map<String, String> validatePayment({
    required String? cardId,
    required String? statementId,
    required double? amount,
    required DateTime? paymentDate,
    required String? paymentMethod,
  }) {
    final errors = <String, String>{};

    final cardError = validateCardId(cardId);
    if (cardError != null) errors['cardId'] = cardError;

    final statementError = validateStatementId(statementId);
    if (statementError != null) errors['statementId'] = statementError;

    final amountError = validateAmount(amount, fieldName: 'Ödeme tutarı');
    if (amountError != null) errors['amount'] = amountError;

    final dateError = validateDate(paymentDate, fieldName: 'Ödeme tarihi');
    if (dateError != null) errors['paymentDate'] = dateError;

    final methodError = validatePaymentMethod(paymentMethod);
    if (methodError != null) errors['paymentMethod'] = methodError;

    return errors;
  }
}
