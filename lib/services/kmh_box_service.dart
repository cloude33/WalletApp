import 'package:hive/hive.dart';
import '../models/kmh_transaction.dart';
import 'secure_storage_service.dart';
class KmhBoxService {
  static const String kmhTransactionsBoxName = 'kmh_transactions';

  static Box<KmhTransaction>? _transactionsBox;
  static final SecureStorageService _secureStorage = SecureStorageService();
  static Future<void> init() async {
    final encryptionKey = await _secureStorage.getKmhEncryptionKey();
    final encryptionCipher = HiveAesCipher(encryptionKey);
    _transactionsBox = await Hive.openBox<KmhTransaction>(
      kmhTransactionsBoxName,
      encryptionCipher: encryptionCipher,
    );
  }
  static Box<KmhTransaction> get transactionsBox {
    if (_transactionsBox == null || !_transactionsBox!.isOpen) {
      throw Exception(
        'KMH transactions box not initialized. Call init() first.',
      );
    }
    return _transactionsBox!;
  }
  static Future<void> close() async {
    await _transactionsBox?.close();
  }
  static Future<void> clearAll() async {
    await _transactionsBox?.clear();
  }
}
