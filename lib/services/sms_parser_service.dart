import 'dart:io' show Platform;
import 'package:uuid/uuid.dart';
import '../models/credit_card_transaction.dart';

/// Service for parsing bank SMS messages and creating transaction suggestions
/// Android only - requires SMS read permission
class SMSParserService {
  final _uuid = const Uuid();

  // Bank SMS patterns for Turkish banks
  final Map<String, RegExp> _bankPatterns = {
    'garanti': RegExp(
      r'(?:GARANTI|Garanti).*?(\d+[.,]\d{2})\s*TL.*?(?:harcama|odeme)',
      caseSensitive: false,
    ),
    'isbank': RegExp(
      r'(?:ISBANK|İşbank).*?(\d+[.,]\d{2})\s*TL.*?(?:harcama|odeme)',
      caseSensitive: false,
    ),
    'akbank': RegExp(
      r'(?:AKBANK|Akbank).*?(\d+[.,]\d{2})\s*TL.*?(?:harcama|odeme)',
      caseSensitive: false,
    ),
    'yapikredi': RegExp(
      r'(?:YAPIKREDI|Yapı Kredi).*?(\d+[.,]\d{2})\s*TL.*?(?:harcama|odeme)',
      caseSensitive: false,
    ),
    'ziraat': RegExp(
      r'(?:ZIRAAT|Ziraat).*?(\d+[.,]\d{2})\s*TL.*?(?:harcama|odeme)',
      caseSensitive: false,
    ),
    'halkbank': RegExp(
      r'(?:HALKBANK|Halkbank).*?(\d+[.,]\d{2})\s*TL.*?(?:harcama|odeme)',
      caseSensitive: false,
    ),
    'vakifbank': RegExp(
      r'(?:VAKIFBANK|Vakıfbank).*?(\d+[.,]\d{2})\s*TL.*?(?:harcama|odeme)',
      caseSensitive: false,
    ),
    'teb': RegExp(
      r'(?:TEB|Teb).*?(\d+[.,]\d{2})\s*TL.*?(?:harcama|odeme)',
      caseSensitive: false,
    ),
    'denizbank': RegExp(
      r'(?:DENIZBANK|Denizbank).*?(\d+[.,]\d{2})\s*TL.*?(?:harcama|odeme)',
      caseSensitive: false,
    ),
    'finansbank': RegExp(
      r'(?:FINANSBANK|QNB Finansbank).*?(\d+[.,]\d{2})\s*TL.*?(?:harcama|odeme)',
      caseSensitive: false,
    ),
  };

  // Date patterns
  final RegExp _datePattern = RegExp(
    r'(\d{1,2})[./](\d{1,2})[./](\d{2,4})',
  );

  // Installment pattern
  final RegExp _installmentPattern = RegExp(
    r'(\d+)\s*taksit',
    caseSensitive: false,
  );

  // Store for suggested transactions
  final List<Map<String, dynamic>> _suggestedTransactions = [];

  /// Request SMS read permission (Android only)
  /// Returns true if permission is granted
  Future<bool> requestSMSPermission() async {
    // Note: This is a placeholder. In a real implementation, you would use
    // permission_handler package to request SMS permission
    // For now, we'll simulate permission check
    
    if (!Platform.isAndroid) {
      return false;
    }

    // In real implementation:
    // final status = await Permission.sms.request();
    // return status.isGranted;
    
    // Simulated for testing
    return true;
  }

  /// Read bank SMS messages
  /// Returns list of SMS message bodies
  Future<List<String>> readBankSMS() async {
    if (!Platform.isAndroid) {
      return [];
    }

    // Note: This is a placeholder. In a real implementation, you would use
    // a platform channel to read SMS messages from Android
    // For now, we'll return an empty list
    
    // In real implementation:
    // final messages = await _platform.invokeMethod('readSMS');
    // return messages.cast<String>();
    
    return [];
  }

  /// Detect which bank sent the SMS
  /// Returns bank name or null if not detected
  String? detectBank(String smsBody) {
    for (final entry in _bankPatterns.entries) {
      if (entry.value.hasMatch(smsBody)) {
        return entry.key;
      }
    }
    return null;
  }

  /// Get bank SMS patterns
  Map<String, RegExp> getBankSMSPatterns() {
    return Map.unmodifiable(_bankPatterns);
  }

  /// Parse bank SMS and extract transaction information
  /// Returns map with amount, date, transactionType, bank, installments
  /// Returns null if SMS cannot be parsed
  Future<Map<String, dynamic>?> parseBankSMS(String smsBody) async {
    // Detect bank
    final bank = detectBank(smsBody);
    if (bank == null) {
      return null;
    }

    // Extract amount
    final pattern = _bankPatterns[bank]!;
    final match = pattern.firstMatch(smsBody);
    if (match == null) {
      return null;
    }

    final amountStr = match.group(1);
    if (amountStr == null) {
      return null;
    }

    // Parse amount (handle both comma and dot as decimal separator)
    final amount = double.tryParse(amountStr.replaceAll(',', '.'));
    if (amount == null) {
      return null;
    }

    // Extract date
    DateTime? transactionDate;
    final dateMatch = _datePattern.firstMatch(smsBody);
    if (dateMatch != null) {
      try {
        final day = int.parse(dateMatch.group(1)!);
        final month = int.parse(dateMatch.group(2)!);
        var year = int.parse(dateMatch.group(3)!);
        
        // Handle 2-digit year
        if (year < 100) {
          year += 2000;
        }
        
        transactionDate = DateTime(year, month, day);
      } catch (e) {
        // If date parsing fails, use current date
        transactionDate = DateTime.now();
      }
    } else {
      transactionDate = DateTime.now();
    }

    // Detect transaction type (harcama vs odeme)
    final isPayment = smsBody.toLowerCase().contains('odeme') ||
        smsBody.toLowerCase().contains('ödeme');
    final transactionType = isPayment ? 'payment' : 'purchase';

    // Extract installment count if present
    int? installments;
    final installmentMatch = _installmentPattern.firstMatch(smsBody);
    if (installmentMatch != null) {
      installments = int.tryParse(installmentMatch.group(1)!);
    }

    return {
      'amount': amount,
      'date': transactionDate,
      'transactionType': transactionType,
      'bank': bank,
      'installments': installments ?? 1,
      'rawSMS': smsBody,
    };
  }

  /// Create a transaction suggestion from parsed SMS
  /// Returns CreditCardTransaction or null if cannot create
  Future<CreditCardTransaction?> createTransactionFromSMS(
    String smsBody, {
    String? cardId,
  }) async {
    final parsed = await parseBankSMS(smsBody);
    if (parsed == null) {
      return null;
    }

    // If it's a payment, we don't create a transaction suggestion
    if (parsed['transactionType'] == 'payment') {
      return null;
    }

    // Create transaction
    final transaction = CreditCardTransaction(
      id: _uuid.v4(),
      cardId: cardId ?? '', // Will be set when user confirms
      amount: parsed['amount'] as double,
      description: 'SMS\'ten: ${parsed['bank']}',
      transactionDate: parsed['date'] as DateTime,
      category: 'Diğer', // Default category
      installmentCount: parsed['installments'] as int,
      installmentsPaid: 0,
      createdAt: DateTime.now(),
      isCashAdvance: false,
    );

    // Add to suggestions
    _suggestedTransactions.add({
      'transaction': transaction,
      'rawSMS': parsed['rawSMS'],
      'bank': parsed['bank'],
      'isConfirmed': false,
    });

    return transaction;
  }

  /// Get list of suggested transactions
  Future<List<Map<String, dynamic>>> getSuggestedTransactions() async {
    return List.unmodifiable(_suggestedTransactions);
  }

  /// Confirm a suggested transaction and assign it to a card
  Future<CreditCardTransaction?> confirmSuggestion(
    String transactionId,
    String cardId,
  ) async {
    final index = _suggestedTransactions.indexWhere(
      (s) => (s['transaction'] as CreditCardTransaction).id == transactionId,
    );

    if (index == -1) {
      return null;
    }

    final suggestion = _suggestedTransactions[index];
    final transaction = suggestion['transaction'] as CreditCardTransaction;
    
    // Update transaction with card ID
    final confirmedTransaction = transaction.copyWith(cardId: cardId);
    
    // Mark as confirmed
    _suggestedTransactions[index]['isConfirmed'] = true;
    _suggestedTransactions[index]['transaction'] = confirmedTransaction;

    return confirmedTransaction;
  }

  /// Remove a suggestion
  Future<void> removeSuggestion(String transactionId) async {
    _suggestedTransactions.removeWhere(
      (s) => (s['transaction'] as CreditCardTransaction).id == transactionId,
    );
  }

  /// Clear all suggestions
  Future<void> clearSuggestions() async {
    _suggestedTransactions.clear();
  }

  /// Get unconfirmed suggestions count
  int getUnconfirmedCount() {
    return _suggestedTransactions
        .where((s) => s['isConfirmed'] == false)
        .length;
  }
}
