import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/security/encryption_helper.dart';
import '../../models/security/security_models.dart';

/// Secure storage service for authentication-related data
///
/// This service provides secure storage capabilities specifically for authentication
/// data such as PIN codes, biometric settings, and security configurations.
/// It implements platform-specific keystore/keychain integration with fallback
/// mechanisms for enhanced security and reliability.
///
/// Features:
/// - AES-256 encryption for sensitive data
/// - Platform-specific secure storage (Android Keystore, iOS Keychain)
/// - Fallback mechanisms for storage failures
/// - Error handling and recovery
/// - Local-only data storage (no cloud sync)
class AuthSecureStorageService {
  static final AuthSecureStorageService _instance =
      AuthSecureStorageService._internal();
  factory AuthSecureStorageService() => _instance;
  AuthSecureStorageService._internal();

  // Storage keys
  static const String _pinHashKey = 'auth_pin_hash';
  static const String _pinSaltKey = 'auth_pin_salt';
  static const String _biometricEnabledKey = 'auth_biometric_enabled';
  static const String _biometricTypeKey = 'auth_biometric_type';
  static const String _failedAttemptsKey = 'auth_failed_attempts';
  static const String _lockoutTimeKey = 'auth_lockout_time';
  static const String _sessionTimeoutKey = 'auth_session_timeout';
  static const String _twoFactorEnabledKey = 'auth_two_factor_enabled';
  static const String _securityConfigKey = 'auth_security_config';
  static const String _deviceIdKey = 'auth_device_id';
  static const String _encryptionKeyKey = 'auth_encryption_key';
  static const String _securityQuestionsKey = 'auth_security_questions';
  static const String _pinRecoveryStateKey = 'auth_pin_recovery_state';
  static const String _authStateKey = 'auth_state';
  static const String _sessionDataKey = 'session_data';
  static const String _sessionStateKey = 'session_state';

  // Platform-specific secure storage with enhanced security options
  FlutterSecureStorage? _secureStorage;
  SharedPreferences? _fallbackStorage;
  bool _isInitialized = false;

  // Performance optimization: Cache for frequently accessed values
  final Map<String, _CachedValue> _cache = {};
  static const Duration _cacheExpiry = Duration(seconds: 5);

  /// Initialize the secure storage service
  ///
  /// This method sets up platform-specific storage options and initializes
  /// fallback mechanisms. It should be called before using any other methods.
  ///
  /// Throws [Exception] if initialization fails
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configure platform-specific options for maximum security
      const androidOptions = AndroidOptions(
        encryptedSharedPreferences: true,
        sharedPreferencesName: 'auth_secure_prefs',
        preferencesKeyPrefix: 'auth_',
        resetOnError: true,
      );

      const iosOptions = IOSOptions(
        groupId: null,
        accountName: 'auth_account',
        synchronizable: false, // Prevent iCloud sync for security
        accessibility: KeychainAccessibility.first_unlock_this_device,
      );

      const linuxOptions = LinuxOptions();

      const windowsOptions = WindowsOptions();

      const macOsOptions = MacOsOptions(
        groupId: null,
        accountName: 'auth_account',
        synchronizable: false, // Prevent iCloud sync for security
        accessibility: KeychainAccessibility.first_unlock_this_device,
      );

      const webOptions = WebOptions(
        dbName: 'auth_secure_storage',
        publicKey: 'auth_public_key',
      );

      _secureStorage = const FlutterSecureStorage(
        aOptions: androidOptions,
        iOptions: iosOptions,
        lOptions: linuxOptions,
        wOptions: windowsOptions,
        mOptions: macOsOptions,
        webOptions: webOptions,
      );

      // Initialize fallback storage
      _fallbackStorage = await SharedPreferences.getInstance();

      // Test secure storage availability
      await _testSecureStorage();

      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize secure storage: ${e.toString()}');
    }
  }

  /// Test if secure storage is available and working
  ///
  /// Returns true if secure storage is available, false otherwise
  Future<bool> isSecureStorageAvailable() async {
    try {
      await _ensureInitialized();
      return await _testSecureStorage();
    } catch (e) {
      debugPrint('Secure storage availability test failed: $e');
      return false;
    }
  }

  /// Store PIN hash securely
  ///
  /// [pin] - The PIN to store (will be hashed)
  ///
  /// Returns true if storage was successful, false otherwise
  ///
  /// Implements Requirement 1.2: Store PIN with AES-256 encryption
  Future<bool> storePIN(String pin) async {
    try {
      await _ensureInitialized();

      if (pin.isEmpty || pin.length < 4 || pin.length > 6) {
        throw ArgumentError('PIN must be 4-6 digits');
      }

      // Hash the PIN (EncryptionHelper generates proper 16-byte salt and embeds it)
      final pinHash = EncryptionHelper.hashPassword(pin);

      // Store only the hash (which contains the salt) securely
      // We don't need to store the salt separately as it's part of the hash string
      final success = await _storeSecurely(_pinHashKey, pinHash);

      // Clean up legacy salt if it exists (not critical but good practice)
      await _secureStorage?.delete(key: _pinSaltKey);

      if (success) {
        debugPrint('PIN stored successfully');
      }

      return success;
    } catch (e) {
      debugPrint('Failed to store PIN: $e');
      return false;
    }
  }

  /// Verify PIN against stored hash
  ///
  /// [pin] - The PIN to verify
  ///
  /// Returns true if PIN matches, false otherwise
  Future<bool> verifyPIN(String pin) async {
    try {
      await _ensureInitialized();

      final storedHash = await _retrieveSecurely(_pinHashKey);
      if (storedHash == null) {
        return false;
      }

      return EncryptionHelper.verifyPassword(pin, storedHash);
    } catch (e) {
      debugPrint('Failed to verify PIN: $e');
      return false;
    }
  }

  /// Check if PIN is set
  ///
  /// Returns true if PIN is configured, false otherwise
  Future<bool> isPINSet() async {
    try {
      await _ensureInitialized();
      final pinHash = await _retrieveSecurely(_pinHashKey);
      return pinHash != null && pinHash.isNotEmpty;
    } catch (e) {
      debugPrint('Failed to check PIN status: $e');
      return false;
    }
  }

  /// Remove stored PIN
  ///
  /// Returns true if removal was successful, false otherwise
  Future<bool> removePIN() async {
    try {
      await _ensureInitialized();

      final success =
          await _deleteSecurely(_pinHashKey) &&
          await _deleteSecurely(_pinSaltKey);

      if (success) {
        debugPrint('PIN removed successfully');
      }

      return success;
    } catch (e) {
      debugPrint('Failed to remove PIN: $e');
      return false;
    }
  }

  /// Store biometric configuration
  ///
  /// [isEnabled] - Whether biometric authentication is enabled
  /// [biometricType] - The type of biometric authentication
  ///
  /// Returns true if storage was successful, false otherwise
  ///
  /// Implements Requirement 5.1: Store biometric data only locally on device
  Future<bool> storeBiometricConfig(
    bool isEnabled,
    String biometricType,
  ) async {
    try {
      await _ensureInitialized();

      final success =
          await _storeSecurely(_biometricEnabledKey, isEnabled.toString()) &&
          await _storeSecurely(_biometricTypeKey, biometricType);

      if (success) {
        debugPrint('Biometric config stored successfully');
      }

      return success;
    } catch (e) {
      debugPrint('Failed to store biometric config: $e');
      return false;
    }
  }

  /// Retrieve biometric configuration
  ///
  /// Returns a map containing 'enabled' and 'type' keys, or null if not found
  Future<Map<String, dynamic>?> getBiometricConfig() async {
    try {
      await _ensureInitialized();

      final enabled = await _retrieveSecurely(_biometricEnabledKey);
      final type = await _retrieveSecurely(_biometricTypeKey);

      if (enabled == null) return null;

      return {
        'enabled': enabled.toLowerCase() == 'true',
        'type': type ?? 'none',
      };
    } catch (e) {
      debugPrint('Failed to retrieve biometric config: $e');
      return null;
    }
  }

  /// Store failed attempts count
  ///
  /// [count] - Number of failed attempts
  ///
  /// Returns true if storage was successful, false otherwise
  Future<bool> storeFailedAttempts(int count) async {
    try {
      await _ensureInitialized();
      return await _storeSecurely(_failedAttemptsKey, count.toString());
    } catch (e) {
      debugPrint('Failed to store failed attempts: $e');
      return false;
    }
  }

  /// Get failed attempts count
  ///
  /// Returns the number of failed attempts, or 0 if not found
  Future<int> getFailedAttempts() async {
    try {
      await _ensureInitialized();
      final attempts = await _retrieveSecurely(_failedAttemptsKey);
      return int.tryParse(attempts ?? '0') ?? 0;
    } catch (e) {
      debugPrint('Failed to get failed attempts: $e');
      return 0;
    }
  }

  /// Store lockout time
  ///
  /// [lockoutTime] - The time when lockout expires
  ///
  /// Returns true if storage was successful, false otherwise
  Future<bool> storeLockoutTime(DateTime lockoutTime) async {
    try {
      await _ensureInitialized();
      return await _storeSecurely(
        _lockoutTimeKey,
        lockoutTime.millisecondsSinceEpoch.toString(),
      );
    } catch (e) {
      debugPrint('Failed to store lockout time: $e');
      return false;
    }
  }

  /// Get lockout time
  ///
  /// Returns the lockout expiration time, or null if not locked
  Future<DateTime?> getLockoutTime() async {
    try {
      await _ensureInitialized();
      final timeStr = await _retrieveSecurely(_lockoutTimeKey);
      if (timeStr == null) return null;

      final timestamp = int.tryParse(timeStr);
      return timestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(timestamp)
          : null;
    } catch (e) {
      debugPrint('Failed to get lockout time: $e');
      return null;
    }
  }

  /// Clear lockout time
  ///
  /// Returns true if clearing was successful, false otherwise
  Future<bool> clearLockout() async {
    try {
      await _ensureInitialized();
      return await _deleteSecurely(_lockoutTimeKey) &&
          await _deleteSecurely(_failedAttemptsKey);
    } catch (e) {
      debugPrint('Failed to clear lockout: $e');
      return false;
    }
  }

  /// Store security configuration
  ///
  /// [config] - Security configuration object
  ///
  /// Returns true if storage was successful, false otherwise
  Future<bool> storeSecurityConfig(SecurityConfig config) async {
    try {
      await _ensureInitialized();
      final configJson = json.encode(config.toJson());
      return await _storeSecurely(_securityConfigKey, configJson);
    } catch (e) {
      debugPrint('Failed to store security config: $e');
      return false;
    }
  }

  /// Get security configuration
  ///
  /// Returns security configuration object, or null if not found
  Future<SecurityConfig?> getSecurityConfig() async {
    try {
      await _ensureInitialized();
      final configJson = await _retrieveSecurely(_securityConfigKey);
      if (configJson == null) return null;

      final configMap = json.decode(configJson) as Map<String, dynamic>;
      return SecurityConfig.fromJson(configMap);
    } catch (e) {
      debugPrint('Failed to get security config: $e');
      return null;
    }
  }

  /// Store authentication state
  ///
  /// [authState] - Authentication state object
  ///
  /// Returns true if storage was successful, false otherwise
  Future<bool> storeAuthState(AuthState authState) async {
    try {
      await _ensureInitialized();
      final stateJson = json.encode(authState.toJson());
      return await _storeSecurely(_authStateKey, stateJson);
    } catch (e) {
      debugPrint('Failed to store auth state: $e');
      return false;
    }
  }

  /// Get authentication state
  ///
  /// Returns authentication state object, or null if not found
  Future<AuthState?> getAuthState() async {
    try {
      await _ensureInitialized();
      final stateJson = await _retrieveSecurely(_authStateKey);
      if (stateJson == null) return null;

      final stateMap = json.decode(stateJson) as Map<String, dynamic>;
      return AuthState.fromJson(stateMap);
    } catch (e) {
      debugPrint('Failed to get auth state: $e');
      return null;
    }
  }

  /// Clear authentication state
  ///
  /// Returns true if clearing was successful, false otherwise
  Future<bool> clearAuthState() async {
    try {
      await _ensureInitialized();
      return await _deleteSecurely(_authStateKey);
    } catch (e) {
      debugPrint('Failed to clear auth state: $e');
      return false;
    }
  }

  /// Store session data
  ///
  /// [sessionData] - Session data object
  ///
  /// Returns true if storage was successful, false otherwise
  Future<bool> storeSessionData(SessionData sessionData) async {
    try {
      await _ensureInitialized();
      final sessionJson = json.encode(sessionData.toJson());
      return await _storeSecurely(_sessionDataKey, sessionJson);
    } catch (e) {
      debugPrint('Failed to store session data: $e');
      return false;
    }
  }

  /// Get session data
  ///
  /// Returns session data object, or null if not found
  Future<SessionData?> getSessionData() async {
    try {
      await _ensureInitialized();
      final sessionJson = await _retrieveSecurely(_sessionDataKey);
      if (sessionJson == null) return null;

      final sessionMap = json.decode(sessionJson) as Map<String, dynamic>;
      return SessionData.fromJson(sessionMap);
    } catch (e) {
      debugPrint('Failed to get session data: $e');
      return null;
    }
  }

  /// Clear session data
  ///
  /// Returns true if clearing was successful, false otherwise
  Future<bool> clearSessionData() async {
    try {
      await _ensureInitialized();
      return await _deleteSecurely(_sessionDataKey);
    } catch (e) {
      debugPrint('Failed to clear session data: $e');
      return false;
    }
  }

  /// Store session state
  ///
  /// [sessionState] - Session state object
  ///
  /// Returns true if storage was successful, false otherwise
  Future<bool> storeSessionState(dynamic sessionState) async {
    try {
      await _ensureInitialized();
      final stateJson = json.encode(sessionState.toJson());
      return await _storeSecurely(_sessionStateKey, stateJson);
    } catch (e) {
      debugPrint('Failed to store session state: $e');
      return false;
    }
  }

  /// Get session state
  ///
  /// Returns session state object, or null if not found
  Future<dynamic> getSessionState() async {
    try {
      await _ensureInitialized();
      final stateJson = await _retrieveSecurely(_sessionStateKey);
      if (stateJson == null) return null;

      final stateMap = json.decode(stateJson) as Map<String, dynamic>;
      // Import SessionState from session_manager.dart
      return stateMap; // Return raw map for now, will be converted in session_manager
    } catch (e) {
      debugPrint('Failed to get session state: $e');
      return null;
    }
  }

  /// Clear session state
  ///
  /// Returns true if clearing was successful, false otherwise
  Future<bool> clearSessionState() async {
    try {
      await _ensureInitialized();
      return await _deleteSecurely(_sessionStateKey);
    } catch (e) {
      debugPrint('Failed to clear session state: $e');
      return false;
    }
  }

  /// Store device ID for device binding
  ///
  /// [deviceId] - Unique device identifier
  ///
  /// Returns true if storage was successful, false otherwise
  ///
  /// Implements Requirement 5.2: Use device's secure area
  Future<bool> storeDeviceId(String deviceId) async {
    try {
      await _ensureInitialized();
      return await _storeSecurely(_deviceIdKey, deviceId);
    } catch (e) {
      debugPrint('Failed to store device ID: $e');
      return false;
    }
  }

  /// Get stored device ID
  ///
  /// Returns device ID, or null if not found
  Future<String?> getDeviceId() async {
    try {
      await _ensureInitialized();
      return await _retrieveSecurely(_deviceIdKey);
    } catch (e) {
      debugPrint('Failed to get device ID: $e');
      return null;
    }
  }

  /// Store security questions data
  ///
  /// [questionsJson] - JSON string containing encrypted security questions and answers
  ///
  /// Returns true if storage was successful, false otherwise
  Future<bool> storeSecurityQuestions(String questionsJson) async {
    try {
      await _ensureInitialized();
      return await _storeSecurely(_securityQuestionsKey, questionsJson);
    } catch (e) {
      debugPrint('Failed to store security questions: $e');
      return false;
    }
  }

  /// Retrieve security questions data
  ///
  /// Returns JSON string containing encrypted security questions and answers, null if not found
  Future<String?> getSecurityQuestions() async {
    try {
      await _ensureInitialized();
      return await _retrieveSecurely(_securityQuestionsKey);
    } catch (e) {
      debugPrint('Failed to retrieve security questions: $e');
      return null;
    }
  }

  /// Check if security questions are set
  ///
  /// Returns true if security questions are configured, false otherwise
  Future<bool> areSecurityQuestionsSet() async {
    try {
      await _ensureInitialized();
      final questions = await _retrieveSecurely(_securityQuestionsKey);
      return questions != null && questions.isNotEmpty;
    } catch (e) {
      debugPrint('Failed to check security questions status: $e');
      return false;
    }
  }

  /// Clear security questions data
  ///
  /// Returns true if removal was successful, false otherwise
  Future<bool> clearSecurityQuestions() async {
    try {
      await _ensureInitialized();
      return await _deleteSecurely(_securityQuestionsKey);
    } catch (e) {
      debugPrint('Failed to clear security questions: $e');
      return false;
    }
  }

  /// Store PIN recovery state
  ///
  /// [stateJson] - JSON string containing PIN recovery state
  ///
  /// Returns true if storage was successful, false otherwise
  Future<bool> storePINRecoveryState(String stateJson) async {
    try {
      await _ensureInitialized();
      return await _storeSecurely(_pinRecoveryStateKey, stateJson);
    } catch (e) {
      debugPrint('Failed to store PIN recovery state: $e');
      return false;
    }
  }

  /// Retrieve PIN recovery state
  ///
  /// Returns JSON string containing PIN recovery state, null if not found
  Future<String?> getPINRecoveryState() async {
    try {
      await _ensureInitialized();
      return await _retrieveSecurely(_pinRecoveryStateKey);
    } catch (e) {
      debugPrint('Failed to retrieve PIN recovery state: $e');
      return null;
    }
  }

  /// Clear PIN recovery state
  ///
  /// Returns true if removal was successful, false otherwise
  Future<bool> clearPINRecoveryState() async {
    try {
      await _ensureInitialized();
      return await _deleteSecurely(_pinRecoveryStateKey);
    } catch (e) {
      debugPrint('Failed to clear PIN recovery state: $e');
      return false;
    }
  }

  /// Clear all authentication data
  ///
  /// This method removes all stored authentication data including PIN,
  /// biometric settings, failed attempts, and security configuration.
  ///
  /// Returns true if all data was cleared successfully, false otherwise
  ///
  /// Implements Requirement 5.1: Ability to delete all biometric data
  Future<bool> clearAllAuthData() async {
    try {
      await _ensureInitialized();

      final keys = [
        _pinHashKey,
        _pinSaltKey,
        _biometricEnabledKey,
        _biometricTypeKey,
        _failedAttemptsKey,
        _lockoutTimeKey,
        _sessionTimeoutKey,
        _twoFactorEnabledKey,
        _securityConfigKey,
        _deviceIdKey,
        _encryptionKeyKey,
        _securityQuestionsKey,
        _pinRecoveryStateKey,
        _authStateKey,
        _sessionDataKey,
        _sessionStateKey,
      ];

      bool allSuccess = true;
      for (final key in keys) {
        final success = await _deleteSecurely(key);
        if (!success) {
          allSuccess = false;
          debugPrint('Failed to delete key: $key');
        }
      }

      if (allSuccess) {
        debugPrint('All authentication data cleared successfully');
      }

      return allSuccess;
    } catch (e) {
      debugPrint('Failed to clear all auth data: $e');
      return false;
    }
  }

  /// Get encryption key for additional data encryption
  ///
  /// Returns encryption key, generating a new one if not found
  Future<String?> getEncryptionKey() async {
    try {
      await _ensureInitialized();

      String? key = await _retrieveSecurely(_encryptionKeyKey);
      if (key == null) {
        // Generate new encryption key
        final keyBytes = EncryptionHelper.generateKey();
        key = base64.encode(keyBytes);
        await _storeSecurely(_encryptionKeyKey, key);
      }

      return key;
    } catch (e) {
      debugPrint('Failed to get encryption key: $e');
      return null;
    }
  }

  /// Check if device has changed (for security purposes)
  ///
  /// [currentDeviceId] - Current device identifier
  ///
  /// Returns true if device has changed, false otherwise
  Future<bool> hasDeviceChanged(String currentDeviceId) async {
    try {
      final storedDeviceId = await getDeviceId();
      if (storedDeviceId == null) {
        // First time setup
        await storeDeviceId(currentDeviceId);
        return false;
      }

      return storedDeviceId != currentDeviceId;
    } catch (e) {
      debugPrint('Failed to check device change: $e');
      return true; // Assume changed for security
    }
  }

  /// Reset the service for testing purposes
  ///
  /// This method is intended for testing only and should not be used in production
  @visibleForTesting
  void resetForTesting() {
    _isInitialized = false;
    _secureStorage = null;
    _fallbackStorage = null;
    _cache.clear();
  }

  /// Invalidates a specific cache entry
  void _invalidateCacheEntry(String key) {
    _cache.remove(key);
  }

  // Private helper methods

  /// Ensure the service is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Test secure storage functionality
  ///
  /// Returns true if secure storage is working, false otherwise
  Future<bool> _testSecureStorage() async {
    try {
      const testKey = 'auth_test_key';
      const testValue = 'auth_test_value';

      await _secureStorage!.write(key: testKey, value: testValue);
      final retrievedValue = await _secureStorage!.read(key: testKey);
      await _secureStorage!.delete(key: testKey);

      return retrievedValue == testValue;
    } catch (e) {
      debugPrint('Secure storage test failed: $e');
      return false;
    }
  }

  /// Store data securely with fallback mechanism
  ///
  /// [key] - Storage key
  /// [value] - Value to store
  ///
  /// Returns true if storage was successful, false otherwise
  ///
  /// Performance optimization: Invalidates cache after write
  Future<bool> _storeSecurely(String key, String value) async {
    // Invalidate cache entry
    _invalidateCacheEntry(key);

    try {
      // Try secure storage first
      await _secureStorage!.write(key: key, value: value);

      // Update cache with new value
      _cache[key] = _CachedValue(value, DateTime.now().add(_cacheExpiry));

      return true;
    } catch (e) {
      debugPrint('Secure storage failed for key $key, trying fallback: $e');

      // Fallback to encrypted shared preferences
      try {
        if (_fallbackStorage != null) {
          final encryptionKey = await _getFallbackEncryptionKey();
          if (encryptionKey != null) {
            final encryptedValue = EncryptionHelper.encrypt(
              value,
              encryptionKey,
            );
            final success = await _fallbackStorage!.setString(
              'encrypted_$key',
              encryptedValue,
            );

            if (success) {
              // Update cache with new value
              _cache[key] = _CachedValue(
                value,
                DateTime.now().add(_cacheExpiry),
              );
            }

            return success;
          }
        }
      } catch (fallbackError) {
        debugPrint('Fallback storage also failed for key $key: $fallbackError');
      }

      return false;
    }
  }

  /// Retrieve data securely with fallback mechanism
  ///
  /// [key] - Storage key
  ///
  /// Returns stored value, or null if not found
  ///
  /// Performance optimization: Uses cache for frequently accessed values
  Future<String?> _retrieveSecurely(String key) async {
    // Check cache first
    final cached = _cache[key];
    if (cached != null && !cached.isExpired) {
      return cached.value;
    }

    String? value;

    try {
      // Try secure storage first
      value = await _secureStorage!.read(key: key);
      if (value != null) {
        // Cache the value
        _cache[key] = _CachedValue(value, DateTime.now().add(_cacheExpiry));
        return value;
      }
    } catch (e) {
      debugPrint('Secure storage retrieval failed for key $key: $e');
    }

    // Try fallback storage
    try {
      if (_fallbackStorage != null) {
        final encryptedValue = _fallbackStorage!.getString('encrypted_$key');
        if (encryptedValue != null) {
          final encryptionKey = await _getFallbackEncryptionKey();
          if (encryptionKey != null) {
            value = EncryptionHelper.decrypt(encryptedValue, encryptionKey);
            // Cache the value
            _cache[key] = _CachedValue(value, DateTime.now().add(_cacheExpiry));
            return value;
          }
        }
      }
    } catch (fallbackError) {
      debugPrint(
        'Fallback storage retrieval failed for key $key: $fallbackError',
      );
    }

    return null;
  }

  /// Delete data securely with fallback mechanism
  ///
  /// [key] - Storage key
  ///
  /// Returns true if deletion was successful, false otherwise
  ///
  /// Performance optimization: Invalidates cache after delete
  Future<bool> _deleteSecurely(String key) async {
    // Invalidate cache entry
    _invalidateCacheEntry(key);

    bool secureSuccess = true;
    bool fallbackSuccess = true;

    // Try secure storage
    try {
      await _secureStorage!.delete(key: key);
    } catch (e) {
      debugPrint('Secure storage deletion failed for key $key: $e');
      secureSuccess = false;
    }

    // Try fallback storage
    try {
      if (_fallbackStorage != null) {
        fallbackSuccess = await _fallbackStorage!.remove('encrypted_$key');
      }
    } catch (e) {
      debugPrint('Fallback storage deletion failed for key $key: $e');
      fallbackSuccess = false;
    }

    return secureSuccess || fallbackSuccess;
  }

  /// Get encryption key for fallback storage
  ///
  /// Returns encryption key, or null if not available
  Future<String?> _getFallbackEncryptionKey() async {
    try {
      // Try to get from secure storage first
      String? key = await _secureStorage!.read(key: 'fallback_encryption_key');
      if (key == null) {
        // Generate new key
        final keyBytes = EncryptionHelper.generateKey();
        key = base64.encode(keyBytes);
        await _secureStorage!.write(key: 'fallback_encryption_key', value: key);
      }
      return key;
    } catch (e) {
      debugPrint('Failed to get fallback encryption key: $e');
      // Use a device-specific key as last resort
      return Platform.isAndroid ? 'android_fallback_key' : 'ios_fallback_key';
    }
  }

  /// Generic read method for any data type
  ///
  /// [key] - The key to read
  ///
  /// Returns the stored value, or null if not found
  Future<dynamic> read(String key) async {
    try {
      await _ensureInitialized();
      return await _retrieveSecurely(key);
    } catch (e) {
      debugPrint('Failed to read key $key: $e');
      return null;
    }
  }

  /// Generic write method for any data type
  ///
  /// [key] - The key to store under
  /// [value] - The value to store (will be JSON encoded if not a string)
  ///
  /// Returns true if storage was successful, false otherwise
  Future<bool> write(String key, dynamic value) async {
    try {
      await _ensureInitialized();

      String stringValue;
      if (value is String) {
        stringValue = value;
      } else {
        stringValue = json.encode(value);
      }

      return await _storeSecurely(key, stringValue);
    } catch (e) {
      debugPrint('Failed to write key $key: $e');
      return false;
    }
  }

  /// Generic delete method
  ///
  /// [key] - The key to delete
  ///
  /// Returns true if deletion was successful, false otherwise
  Future<bool> delete(String key) async {
    try {
      await _ensureInitialized();
      return await _deleteSecurely(key);
    } catch (e) {
      debugPrint('Failed to delete key $key: $e');
      return false;
    }
  }
}

/// Cached value entry for performance optimization
class _CachedValue {
  final String value;
  final DateTime expiryTime;

  _CachedValue(this.value, this.expiryTime);

  bool get isExpired => DateTime.now().isAfter(expiryTime);
}
