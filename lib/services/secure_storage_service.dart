import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:math';
class SecureStorageService {
  static final SecureStorageService _instance =
      SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String _kmhEncryptionKeyName = 'kmh_encryption_key';
  static const String _walletEncryptionKeyName = 'wallet_encryption_key';
  Future<List<int>> getKmhEncryptionKey() async {
    return await _getOrGenerateKey(_kmhEncryptionKeyName);
  }
  Future<List<int>> getWalletEncryptionKey() async {
    return await _getOrGenerateKey(_walletEncryptionKeyName);
  }
  Future<List<int>> _getOrGenerateKey(String keyName) async {
    try {
      final keyString = await _secureStorage.read(key: keyName);

      if (keyString != null) {
        final keyList = json.decode(keyString) as List<dynamic>;
        return keyList.cast<int>();
      }
      final newKey = _generateEncryptionKey();
      await _secureStorage.write(key: keyName, value: json.encode(newKey));

      return newKey;
    } catch (e) {
      return _generateEncryptionKey();
    }
  }
  List<int> _generateEncryptionKey() {
    final random = Random.secure();
    return List<int>.generate(32, (_) => random.nextInt(256));
  }
  Future<void> deleteAllKeys() async {
    try {
      await _secureStorage.delete(key: _kmhEncryptionKeyName);
      await _secureStorage.delete(key: _walletEncryptionKeyName);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }
  Future<bool> isSecureStorageAvailable() async {
    try {
      await _secureStorage.write(key: 'test_key', value: 'test_value');
      await _secureStorage.delete(key: 'test_key');
      return true;
    } catch (e) {
      return false;
    }
  }
}
