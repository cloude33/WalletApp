import 'package:hive/hive.dart';
import '../models/credit_card.dart';
import '../models/credit_card_transaction.dart';
import '../models/credit_card_statement.dart';
import '../models/credit_card_payment.dart';
import '../models/reward_points.dart';
import '../models/reward_transaction.dart';
import '../models/limit_alert.dart';

class CreditCardBoxService {
  static const String creditCardsBoxName = 'credit_cards';
  static const String transactionsBoxName = 'cc_transactions';
  static const String statementsBoxName = 'cc_statements';
  static const String paymentsBoxName = 'cc_payments';
  static const String rewardPointsBoxName = 'reward_points';
  static const String rewardTransactionsBoxName = 'reward_transactions';
  static const String limitAlertsBoxName = 'limit_alerts';

  static Box<CreditCard>? _creditCardsBox;
  static Box<CreditCardTransaction>? _transactionsBox;
  static Box<CreditCardStatement>? _statementsBox;
  static Box<CreditCardPayment>? _paymentsBox;
  static Box<RewardPoints>? _rewardPointsBox;
  static Box<RewardTransaction>? _rewardTransactionsBox;
  static Box<LimitAlert>? _limitAlertsBox;
  static Future<void> init() async {
    _creditCardsBox = await Hive.openBox<CreditCard>(creditCardsBoxName);
    _transactionsBox = await Hive.openBox<CreditCardTransaction>(
      transactionsBoxName,
    );
    _statementsBox = await Hive.openBox<CreditCardStatement>(statementsBoxName);
    _paymentsBox = await Hive.openBox<CreditCardPayment>(paymentsBoxName);
    _rewardPointsBox = await Hive.openBox<RewardPoints>(rewardPointsBoxName);
    _rewardTransactionsBox = await Hive.openBox<RewardTransaction>(
      rewardTransactionsBoxName,
    );
    _limitAlertsBox = await Hive.openBox<LimitAlert>(limitAlertsBoxName);
  }
  static Box<CreditCard> get creditCardsBox {
    if (_creditCardsBox == null || !_creditCardsBox!.isOpen) {
      throw Exception('Credit cards box not initialized. Call init() first.');
    }
    return _creditCardsBox!;
  }
  static Box<CreditCardTransaction> get transactionsBox {
    if (_transactionsBox == null || !_transactionsBox!.isOpen) {
      throw Exception('Transactions box not initialized. Call init() first.');
    }
    return _transactionsBox!;
  }
  static Box<CreditCardStatement> get statementsBox {
    if (_statementsBox == null || !_statementsBox!.isOpen) {
      throw Exception('Statements box not initialized. Call init() first.');
    }
    return _statementsBox!;
  }
  static Box<CreditCardPayment> get paymentsBox {
    if (_paymentsBox == null || !_paymentsBox!.isOpen) {
      throw Exception('Payments box not initialized. Call init() first.');
    }
    return _paymentsBox!;
  }
  static Box<RewardPoints> get rewardPointsBox {
    if (_rewardPointsBox == null || !_rewardPointsBox!.isOpen) {
      throw Exception('Reward points box not initialized. Call init() first.');
    }
    return _rewardPointsBox!;
  }
  static Box<RewardTransaction> get rewardTransactionsBox {
    if (_rewardTransactionsBox == null || !_rewardTransactionsBox!.isOpen) {
      throw Exception(
        'Reward transactions box not initialized. Call init() first.',
      );
    }
    return _rewardTransactionsBox!;
  }
  static Box<LimitAlert> get limitAlertsBox {
    if (_limitAlertsBox == null || !_limitAlertsBox!.isOpen) {
      throw Exception('Limit alerts box not initialized. Call init() first.');
    }
    return _limitAlertsBox!;
  }
  static Future<void> close() async {
    await _creditCardsBox?.close();
    await _transactionsBox?.close();
    await _statementsBox?.close();
    await _paymentsBox?.close();
    await _rewardPointsBox?.close();
    await _rewardTransactionsBox?.close();
    await _limitAlertsBox?.close();
  }
  static Future<void> clearAll() async {
    await _creditCardsBox?.clear();
    await _transactionsBox?.clear();
    await _statementsBox?.clear();
    await _paymentsBox?.clear();
    await _rewardPointsBox?.clear();
    await _rewardTransactionsBox?.clear();
    await _limitAlertsBox?.clear();
  }
}
