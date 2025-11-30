import 'package:hive/hive.dart';
import '../models/credit_card.dart';
import '../models/credit_card_transaction.dart';
import '../models/credit_card_statement.dart';
import '../models/credit_card_payment.dart';

class CreditCardBoxService {
  static const String creditCardsBoxName = 'credit_cards';
  static const String transactionsBoxName = 'cc_transactions';
  static const String statementsBoxName = 'cc_statements';
  static const String paymentsBoxName = 'cc_payments';

  static Box<CreditCard>? _creditCardsBox;
  static Box<CreditCardTransaction>? _transactionsBox;
  static Box<CreditCardStatement>? _statementsBox;
  static Box<CreditCardPayment>? _paymentsBox;

  /// Initialize all credit card boxes
  static Future<void> init() async {
    _creditCardsBox = await Hive.openBox<CreditCard>(creditCardsBoxName);
    _transactionsBox = await Hive.openBox<CreditCardTransaction>(transactionsBoxName);
    _statementsBox = await Hive.openBox<CreditCardStatement>(statementsBoxName);
    _paymentsBox = await Hive.openBox<CreditCardPayment>(paymentsBoxName);
  }

  /// Get credit cards box
  static Box<CreditCard> get creditCardsBox {
    if (_creditCardsBox == null || !_creditCardsBox!.isOpen) {
      throw Exception('Credit cards box not initialized. Call init() first.');
    }
    return _creditCardsBox!;
  }

  /// Get transactions box
  static Box<CreditCardTransaction> get transactionsBox {
    if (_transactionsBox == null || !_transactionsBox!.isOpen) {
      throw Exception('Transactions box not initialized. Call init() first.');
    }
    return _transactionsBox!;
  }

  /// Get statements box
  static Box<CreditCardStatement> get statementsBox {
    if (_statementsBox == null || !_statementsBox!.isOpen) {
      throw Exception('Statements box not initialized. Call init() first.');
    }
    return _statementsBox!;
  }

  /// Get payments box
  static Box<CreditCardPayment> get paymentsBox {
    if (_paymentsBox == null || !_paymentsBox!.isOpen) {
      throw Exception('Payments box not initialized. Call init() first.');
    }
    return _paymentsBox!;
  }

  /// Close all boxes
  static Future<void> close() async {
    await _creditCardsBox?.close();
    await _transactionsBox?.close();
    await _statementsBox?.close();
    await _paymentsBox?.close();
  }

  /// Clear all data (for testing or reset)
  static Future<void> clearAll() async {
    await _creditCardsBox?.clear();
    await _transactionsBox?.clear();
    await _statementsBox?.clear();
    await _paymentsBox?.clear();
  }
}
