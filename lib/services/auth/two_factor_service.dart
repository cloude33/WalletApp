import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../models/security/two_factor_models.dart';
import '../../utils/security/totp_helper.dart';
import 'secure_storage_service.dart';

class TwoFactorService {
  static final TwoFactorService _instance = TwoFactorService._internal();
  factory TwoFactorService() => _instance;
  TwoFactorService._internal();

  // Dependencies
  final AuthSecureStorageService _secureStorage = AuthSecureStorageService();

  // Storage keys
  static const String _twoFactorConfigKey = 'two_factor_config';
  static const String _verificationAttemptsKey = 'two_factor_attempts';
  static const String _lastVerificationTimeKey = 'two_factor_last_verification';
  static const String _pendingVerificationKey = 'two_factor_pending';

  // Configuration constants
  static const int _maxVerificationAttempts = 5;
  static const Duration _verificationTimeout = Duration(minutes: 5);
  static const Duration _rateLimitDuration = Duration(minutes: 1);
  static const int _maxRateLimitAttempts = 3;
  static const String _defaultIssuer = 'Parion';

  // State
  TwoFactorConfig? _cachedConfig;
  bool _isInitialized = false;

  /// Initialize the two-factor authentication service
  ///
  /// This method sets up the service and loads existing configuration.
  /// It should be called before using any other methods.
  ///
  /// Throws [Exception] if initialization fails
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _secureStorage.initialize();
      await _loadConfiguration();
      _isInitialized = true;
      debugPrint('TwoFactorService initialized successfully');
    } catch (e) {
      throw Exception('Failed to initialize TwoFactorService: ${e.toString()}');
    }
  }

  /// Check if two-factor authentication is enabled
  ///
  /// Returns true if any 2FA method is enabled, false otherwise
  Future<bool> isTwoFactorEnabled() async {
    await _ensureInitialized();
    final config = await getConfiguration();
    return config.isEnabled;
  }

  /// Get current two-factor authentication configuration
  ///
  /// Returns current 2FA configuration
  Future<TwoFactorConfig> getConfiguration() async {
    await _ensureInitialized();

    if (_cachedConfig != null) {
      return _cachedConfig!;
    }

    return await _loadConfiguration();
  }

  /// Enable SMS-based two-factor authentication
  ///
  /// [phoneNumber] - Phone number for SMS verification
  ///
  /// Returns setup result with success status
  ///
  /// Implements Requirement 7.4: SMS/Email verification integration
  Future<TwoFactorSetupResult> enableSMSVerification(String phoneNumber) async {
    try {
      await _ensureInitialized();

      if (!_isValidPhoneNumber(phoneNumber)) {
        return TwoFactorSetupResult.failure(
          TwoFactorMethod.sms,
          'Geçersiz telefon numarası formatı',
        );
      }

      final config = await getConfiguration();
      final updatedConfig = config.copyWith(
        isEnabled: true,
        isSMSEnabled: true,
        phoneNumber: phoneNumber,
      );

      final success = await _saveConfiguration(updatedConfig);
      if (!success) {
        return TwoFactorSetupResult.failure(
          TwoFactorMethod.sms,
          'SMS doğrulama ayarları kaydedilemedi',
        );
      }

      // Generate backup codes if not already generated
      List<String>? backupCodes;
      if (config.backupCodes.isEmpty) {
        backupCodes = TOTPHelper.generateBackupCodes();
        final configWithBackup = updatedConfig.copyWith(
          backupCodes: backupCodes,
        );
        await _saveConfiguration(configWithBackup);
      }

      debugPrint(
        'SMS verification enabled for: ${_maskPhoneNumber(phoneNumber)}',
      );

      return TwoFactorSetupResult.success(
        TwoFactorMethod.sms,
        backupCodes: backupCodes,
      );
    } catch (e) {
      debugPrint('Failed to enable SMS verification: $e');
      return TwoFactorSetupResult.failure(
        TwoFactorMethod.sms,
        'SMS doğrulama etkinleştirilemedi: ${e.toString()}',
      );
    }
  }

  /// Enable email-based two-factor authentication
  ///
  /// [emailAddress] - Email address for verification
  ///
  /// Returns setup result with success status
  ///
  /// Implements Requirement 7.4: SMS/Email verification integration
  Future<TwoFactorSetupResult> enableEmailVerification(
    String emailAddress,
  ) async {
    try {
      await _ensureInitialized();

      if (!_isValidEmail(emailAddress)) {
        return TwoFactorSetupResult.failure(
          TwoFactorMethod.email,
          'Geçersiz e-posta adresi formatı',
        );
      }

      final config = await getConfiguration();
      final updatedConfig = config.copyWith(
        isEnabled: true,
        isEmailEnabled: true,
        emailAddress: emailAddress,
      );

      final success = await _saveConfiguration(updatedConfig);
      if (!success) {
        return TwoFactorSetupResult.failure(
          TwoFactorMethod.email,
          'E-posta doğrulama ayarları kaydedilemedi',
        );
      }

      // Generate backup codes if not already generated
      List<String>? backupCodes;
      if (config.backupCodes.isEmpty) {
        backupCodes = TOTPHelper.generateBackupCodes();
        final configWithBackup = updatedConfig.copyWith(
          backupCodes: backupCodes,
        );
        await _saveConfiguration(configWithBackup);
      }

      debugPrint('Email verification enabled for: ${_maskEmail(emailAddress)}');

      return TwoFactorSetupResult.success(
        TwoFactorMethod.email,
        backupCodes: backupCodes,
      );
    } catch (e) {
      debugPrint('Failed to enable email verification: $e');
      return TwoFactorSetupResult.failure(
        TwoFactorMethod.email,
        'E-posta doğrulama etkinleştirilemedi: ${e.toString()}',
      );
    }
  }

  /// Enable TOTP-based two-factor authentication
  ///
  /// [accountName] - Account name for TOTP (e.g., user email)
  /// [issuer] - Issuer name (default: app name)
  ///
  /// Returns setup result with TOTP secret and QR code URL
  ///
  /// Implements Requirement 7.4: TOTP (Time-based One-Time Password) support
  Future<TwoFactorSetupResult> enableTOTPVerification(
    String accountName, {
    String? issuer,
  }) async {
    try {
      await _ensureInitialized();

      if (accountName.isEmpty) {
        return TwoFactorSetupResult.failure(
          TwoFactorMethod.totp,
          'Hesap adı boş olamaz',
        );
      }

      // Generate TOTP secret
      final totpSecret = TOTPHelper.generateSecret();
      final totpIssuer = issuer ?? _defaultIssuer;

      // Generate QR code URL
      final qrCodeUrl = TOTPHelper.generateQRCodeUrl(
        totpSecret,
        accountName,
        totpIssuer,
      );

      final config = await getConfiguration();
      final updatedConfig = config.copyWith(
        isEnabled: true,
        isTOTPEnabled: true,
        totpSecret: totpSecret,
        totpIssuer: totpIssuer,
        totpAccountName: accountName,
      );

      final success = await _saveConfiguration(updatedConfig);
      if (!success) {
        return TwoFactorSetupResult.failure(
          TwoFactorMethod.totp,
          'TOTP ayarları kaydedilemedi',
        );
      }

      // Generate backup codes if not already generated
      List<String>? backupCodes;
      if (config.backupCodes.isEmpty) {
        backupCodes = TOTPHelper.generateBackupCodes();
        final configWithBackup = updatedConfig.copyWith(
          backupCodes: backupCodes,
        );
        await _saveConfiguration(configWithBackup);
      }

      debugPrint('TOTP verification enabled for: $accountName');

      return TwoFactorSetupResult.success(
        TwoFactorMethod.totp,
        totpSecret: totpSecret,
        qrCodeUrl: qrCodeUrl,
        backupCodes: backupCodes,
      );
    } catch (e) {
      debugPrint('Failed to enable TOTP verification: $e');
      return TwoFactorSetupResult.failure(
        TwoFactorMethod.totp,
        'TOTP doğrulama etkinleştirilemedi: ${e.toString()}',
      );
    }
  }

  /// Verify two-factor authentication code
  ///
  /// [request] - Verification request containing method and code
  ///
  /// Returns verification result with success status
  ///
  /// Implements Requirement 8.3: Two-factor authentication for sensitive operations
  Future<TwoFactorVerificationResult> verifyCode(
    TwoFactorVerificationRequest request,
  ) async {
    try {
      await _ensureInitialized();

      // Check rate limiting
      final rateLimitResult = await _checkRateLimit();
      if (!rateLimitResult.isSuccess) {
        return rateLimitResult;
      }

      // Check if method is enabled
      final config = await getConfiguration();
      if (!_isMethodEnabled(config, request.method)) {
        return TwoFactorVerificationResult.failure(
          request.method,
          'Bu doğrulama yöntemi etkin değil',
        );
      }

      // Verify based on method
      TwoFactorVerificationResult result;
      switch (request.method) {
        case TwoFactorMethod.sms:
          result = await _verifySMSCode(request, config);
          break;
        case TwoFactorMethod.email:
          result = await _verifyEmailCode(request, config);
          break;
        case TwoFactorMethod.totp:
          result = await _verifyTOTPCode(request, config);
          break;
        case TwoFactorMethod.backupCode:
          result = await _verifyBackupCode(request, config);
          break;
      }

      // Update attempt tracking
      await _updateVerificationAttempts(result.isSuccess);

      if (result.isSuccess) {
        await _clearPendingVerification();
        debugPrint('Two-factor verification successful: ${request.method}');
      } else {
        debugPrint('Two-factor verification failed: ${request.method}');
      }

      return result;
    } catch (e) {
      debugPrint('Two-factor verification error: $e');
      return TwoFactorVerificationResult.failure(
        request.method,
        'Doğrulama sırasında hata oluştu: ${e.toString()}',
      );
    }
  }

  /// Send verification code via SMS
  ///
  /// [phoneNumber] - Phone number to send code to (optional, uses configured number)
  ///
  /// Returns true if code was sent successfully, false otherwise
  ///
  /// Implements integration with Firebase Functions or external SMS provider
  Future<bool> sendSMSCode({String? phoneNumber}) async {
    try {
      await _ensureInitialized();

      final config = await getConfiguration();
      if (!config.isSMSEnabled) {
        debugPrint('SMS verification is not enabled');
        return false;
      }

      final targetPhone = phoneNumber ?? config.phoneNumber;
      if (targetPhone == null || targetPhone.isEmpty) {
        debugPrint('No phone number configured for SMS');
        return false;
      }

      // Generate verification code
      final code = _generateVerificationCode();

      // Store pending verification
      await _storePendingVerification(TwoFactorMethod.sms, code);

      // Attempt to send SMS via Firebase Functions or external provider
      final success = await _sendSMSViaProvider(targetPhone, code);

      if (success) {
        debugPrint(
          'SMS verification code sent successfully to ${_maskPhoneNumber(targetPhone)}',
        );
        return true;
      } else {
        debugPrint('Failed to send SMS verification code to $targetPhone');
        return false;
      }
    } catch (e) {
      debugPrint('Failed to send SMS code: $e');
      return false;
    }
  }

  /// Send verification code via email
  ///
  /// [emailAddress] - Email address to send code to (optional, uses configured email)
  ///
  /// Returns true if code was sent successfully, false otherwise
  ///
  /// Implements integration with Firebase Functions or external email provider
  Future<bool> sendEmailCode({String? emailAddress}) async {
    try {
      await _ensureInitialized();

      final config = await getConfiguration();
      if (!config.isEmailEnabled) {
        debugPrint('Email verification is not enabled');
        return false;
      }

      final targetEmail = emailAddress ?? config.emailAddress;
      if (targetEmail == null || targetEmail.isEmpty) {
        debugPrint('No email address configured');
        return false;
      }

      // Generate verification code
      final code = _generateVerificationCode();

      // Store pending verification
      await _storePendingVerification(TwoFactorMethod.email, code);

      // Attempt to send email via Firebase Functions or external provider
      final success = await _sendEmailViaProvider(targetEmail, code);

      if (success) {
        debugPrint(
          'Email verification code sent successfully to ${_maskEmail(targetEmail)}',
        );
        return true;
      } else {
        debugPrint('Failed to send email verification code to $targetEmail');
        return false;
      }
    } catch (e) {
      debugPrint('Failed to send email code: $e');
      return false;
    }
  }

  /// Get available two-factor authentication methods
  ///
  /// Returns list of enabled 2FA methods
  Future<List<TwoFactorMethod>> getAvailableMethods() async {
    await _ensureInitialized();

    final config = await getConfiguration();
    final methods = <TwoFactorMethod>[];

    if (config.isSMSEnabled) {
      methods.add(TwoFactorMethod.sms);
    }

    if (config.isEmailEnabled) {
      methods.add(TwoFactorMethod.email);
    }

    if (config.isTOTPEnabled) {
      methods.add(TwoFactorMethod.totp);
    }

    // Backup codes are always available if any method is enabled
    if (config.isEnabled && config.backupCodes.isNotEmpty) {
      methods.add(TwoFactorMethod.backupCode);
    }

    return methods;
  }

  /// Get unused backup codes
  ///
  /// Returns list of unused backup codes
  Future<List<String>> getUnusedBackupCodes() async {
    await _ensureInitialized();

    final config = await getConfiguration();
    final unusedCodes = <String>[];

    for (final code in config.backupCodes) {
      if (!config.usedBackupCodes.contains(code)) {
        unusedCodes.add(code);
      }
    }

    return unusedCodes;
  }

  /// Generate new backup codes
  ///
  /// [count] - Number of backup codes to generate (default: 10)
  ///
  /// Returns list of new backup codes
  ///
  /// Implements Requirement 7.4: Backup codes management
  Future<List<String>> generateNewBackupCodes({int count = 10}) async {
    try {
      await _ensureInitialized();

      final newBackupCodes = TOTPHelper.generateBackupCodes(count: count);

      final config = await getConfiguration();
      final updatedConfig = config.copyWith(
        backupCodes: newBackupCodes,
        usedBackupCodes: [], // Reset used codes
      );

      final success = await _saveConfiguration(updatedConfig);
      if (!success) {
        throw Exception('Failed to save new backup codes');
      }

      debugPrint('Generated $count new backup codes');
      return newBackupCodes;
    } catch (e) {
      debugPrint('Failed to generate new backup codes: $e');
      return [];
    }
  }

  /// Disable two-factor authentication method
  ///
  /// [method] - Method to disable
  ///
  /// Returns true if method was disabled successfully, false otherwise
  Future<bool> disableMethod(TwoFactorMethod method) async {
    try {
      await _ensureInitialized();

      final config = await getConfiguration();
      TwoFactorConfig updatedConfig;

      switch (method) {
        case TwoFactorMethod.sms:
          updatedConfig = config.copyWith(
            isSMSEnabled: false,
            phoneNumber: null,
          );
          break;
        case TwoFactorMethod.email:
          updatedConfig = config.copyWith(
            isEmailEnabled: false,
            emailAddress: null,
          );
          break;
        case TwoFactorMethod.totp:
          updatedConfig = config.copyWith(
            isTOTPEnabled: false,
            totpSecret: null,
            totpIssuer: null,
            totpAccountName: null,
          );
          break;
        case TwoFactorMethod.backupCode:
          updatedConfig = config.copyWith(backupCodes: [], usedBackupCodes: []);
          break;
      }

      // Check if any method is still enabled
      final hasEnabledMethod =
          updatedConfig.isSMSEnabled ||
          updatedConfig.isEmailEnabled ||
          updatedConfig.isTOTPEnabled;

      if (!hasEnabledMethod) {
        updatedConfig = updatedConfig.copyWith(isEnabled: false);
      }

      final success = await _saveConfiguration(updatedConfig);
      if (success) {
        debugPrint('Disabled two-factor method: $method');
      }

      return success;
    } catch (e) {
      debugPrint('Failed to disable two-factor method $method: $e');
      return false;
    }
  }

  /// Disable all two-factor authentication
  ///
  /// Returns true if 2FA was disabled successfully, false otherwise
  Future<bool> disableAllMethods() async {
    try {
      await _ensureInitialized();

      final defaultConfig = TwoFactorConfig.defaultConfig();
      final success = await _saveConfiguration(defaultConfig);

      if (success) {
        await _clearVerificationAttempts();
        await _clearPendingVerification();
        debugPrint('All two-factor authentication methods disabled');
      }

      return success;
    } catch (e) {
      debugPrint('Failed to disable all two-factor methods: $e');
      return false;
    }
  }

  /// Check if two-factor authentication is required for sensitive operations
  ///
  /// Returns true if 2FA is required, false otherwise
  ///
  /// Implements Requirement 8.3: Two-factor authentication for sensitive operations
  Future<bool> isRequiredForSensitiveOperations() async {
    await _ensureInitialized();
    return await isTwoFactorEnabled();
  }

  /// Reset the service for testing purposes
  ///
  /// This method is intended for testing only and should not be used in production
  @visibleForTesting
  void resetForTesting() {
    _isInitialized = false;
    _cachedConfig = null;
  }

  // Private helper methods

  /// Ensure the service is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Load configuration from secure storage
  Future<TwoFactorConfig> _loadConfiguration() async {
    try {
      final configJson = await _secureStorage.getSecurityConfig();
      if (configJson != null) {
        // Try to get 2FA config from security config
        final configData = configJson.toJson();
        if (configData.containsKey('twoFactorConfig')) {
          _cachedConfig = TwoFactorConfig.fromJson(
            configData['twoFactorConfig'] as Map<String, dynamic>,
          );
          return _cachedConfig!;
        }
      }

      // Fallback: try direct storage
      final directConfigJson = await _secureStorage.getSessionData();
      if (directConfigJson != null) {
        final configData = directConfigJson.toJson();
        if (configData.containsKey(_twoFactorConfigKey)) {
          _cachedConfig = TwoFactorConfig.fromJson(
            configData[_twoFactorConfigKey] as Map<String, dynamic>,
          );
          return _cachedConfig!;
        }
      }

      // Create default configuration
      _cachedConfig = TwoFactorConfig.defaultConfig();
      return _cachedConfig!;
    } catch (e) {
      debugPrint('Failed to load 2FA configuration: $e');
      _cachedConfig = TwoFactorConfig.defaultConfig();
      return _cachedConfig!;
    }
  }

  /// Save configuration to secure storage
  Future<bool> _saveConfiguration(TwoFactorConfig config) async {
    try {
      // Update cache
      _cachedConfig = config;

      // Save to secure storage
      final configJson = json.encode(config.toJson());
      final success = await _secureStorage.storeSecurityQuestions(configJson);

      if (success) {
        debugPrint('Two-factor configuration saved successfully');
      }

      return success;
    } catch (e) {
      debugPrint('Failed to save 2FA configuration: $e');
      return false;
    }
  }

  /// Check if a specific method is enabled
  bool _isMethodEnabled(TwoFactorConfig config, TwoFactorMethod method) {
    if (!config.isEnabled) return false;

    switch (method) {
      case TwoFactorMethod.sms:
        return config.isSMSEnabled;
      case TwoFactorMethod.email:
        return config.isEmailEnabled;
      case TwoFactorMethod.totp:
        return config.isTOTPEnabled;
      case TwoFactorMethod.backupCode:
        return config.backupCodes.isNotEmpty;
    }
  }

  /// Check rate limiting for verification attempts
  Future<TwoFactorVerificationResult> _checkRateLimit() async {
    try {
      final attempts = await _getVerificationAttempts();
      final lastAttemptTime = await _getLastVerificationTime();

      if (attempts >= _maxRateLimitAttempts && lastAttemptTime != null) {
        final timeSinceLastAttempt = DateTime.now().difference(lastAttemptTime);
        if (timeSinceLastAttempt < _rateLimitDuration) {
          final remainingTime = _rateLimitDuration - timeSinceLastAttempt;
          return TwoFactorVerificationResult.failure(
            TwoFactorMethod.sms, // Default method for rate limit
            'Çok fazla deneme yapıldı. ${remainingTime.inSeconds} saniye sonra tekrar deneyin.',
            lockoutDuration: remainingTime,
          );
        }
      }

      return TwoFactorVerificationResult.success(TwoFactorMethod.sms);
    } catch (e) {
      debugPrint('Rate limit check failed: $e');
      return TwoFactorVerificationResult.success(TwoFactorMethod.sms);
    }
  }

  /// Verify SMS code
  Future<TwoFactorVerificationResult> _verifySMSCode(
    TwoFactorVerificationRequest request,
    TwoFactorConfig config,
  ) async {
    final pendingCode = await _getPendingVerification(TwoFactorMethod.sms);
    if (pendingCode == null) {
      return TwoFactorVerificationResult.failure(
        TwoFactorMethod.sms,
        'SMS kodu bulunamadı. Yeni kod talep edin.',
      );
    }

    if (request.code == pendingCode) {
      return TwoFactorVerificationResult.success(TwoFactorMethod.sms);
    } else {
      return TwoFactorVerificationResult.failure(
        TwoFactorMethod.sms,
        'Geçersiz SMS kodu',
      );
    }
  }

  /// Verify email code
  Future<TwoFactorVerificationResult> _verifyEmailCode(
    TwoFactorVerificationRequest request,
    TwoFactorConfig config,
  ) async {
    final pendingCode = await _getPendingVerification(TwoFactorMethod.email);
    if (pendingCode == null) {
      return TwoFactorVerificationResult.failure(
        TwoFactorMethod.email,
        'E-posta kodu bulunamadı. Yeni kod talep edin.',
      );
    }

    if (request.code == pendingCode) {
      return TwoFactorVerificationResult.success(TwoFactorMethod.email);
    } else {
      return TwoFactorVerificationResult.failure(
        TwoFactorMethod.email,
        'Geçersiz e-posta kodu',
      );
    }
  }

  /// Verify TOTP code
  Future<TwoFactorVerificationResult> _verifyTOTPCode(
    TwoFactorVerificationRequest request,
    TwoFactorConfig config,
  ) async {
    if (config.totpSecret == null) {
      return TwoFactorVerificationResult.failure(
        TwoFactorMethod.totp,
        'TOTP yapılandırması bulunamadı',
      );
    }

    final isValid = TOTPHelper.verifyTOTP(config.totpSecret!, request.code);

    if (isValid) {
      return TwoFactorVerificationResult.success(TwoFactorMethod.totp);
    } else {
      return TwoFactorVerificationResult.failure(
        TwoFactorMethod.totp,
        'Geçersiz authenticator kodu',
      );
    }
  }

  /// Verify backup code
  Future<TwoFactorVerificationResult> _verifyBackupCode(
    TwoFactorVerificationRequest request,
    TwoFactorConfig config,
  ) async {
    final cleanCode = request.code.replaceAll('-', '');

    // Check if code exists and is not used
    if (!config.backupCodes.contains(cleanCode)) {
      return TwoFactorVerificationResult.failure(
        TwoFactorMethod.backupCode,
        'Geçersiz yedek kod',
      );
    }

    if (config.usedBackupCodes.contains(cleanCode)) {
      return TwoFactorVerificationResult.failure(
        TwoFactorMethod.backupCode,
        'Bu yedek kod daha önce kullanılmış',
      );
    }

    // Mark code as used
    final updatedUsedCodes = [...config.usedBackupCodes, cleanCode];
    final updatedConfig = config.copyWith(usedBackupCodes: updatedUsedCodes);
    await _saveConfiguration(updatedConfig);

    return TwoFactorVerificationResult.success(TwoFactorMethod.backupCode);
  }

  /// Generate verification code
  String _generateVerificationCode({int length = 6}) {
    final random = Random.secure();
    String code = '';
    for (int i = 0; i < length; i++) {
      code += random.nextInt(10).toString();
    }
    return code;
  }

  /// Store pending verification code
  Future<void> _storePendingVerification(
    TwoFactorMethod method,
    String code,
  ) async {
    try {
      final data = {
        'method': method.name,
        'code': code,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final dataJson = json.encode(data);
      await _secureStorage.storePendingVerification(dataJson);
    } catch (e) {
      debugPrint('Failed to store pending verification: $e');
    }
  }

  /// Get pending verification code
  Future<String?> _getPendingVerification(TwoFactorMethod method) async {
    try {
      final dataJson = await _secureStorage.getPendingVerification();
      if (dataJson == null) return null;

      final data = json.decode(dataJson) as Map<String, dynamic>;
      final storedMethod = data['method'] as String?;
      final code = data['code'] as String?;
      final timestampStr = data['timestamp'] as String?;

      if (storedMethod != method.name || code == null || timestampStr == null) {
        return null;
      }

      final timestamp = DateTime.parse(timestampStr);
      final age = DateTime.now().difference(timestamp);

      if (age > _verificationTimeout) {
        await _clearPendingVerification();
        return null;
      }

      return code;
    } catch (e) {
      debugPrint('Failed to get pending verification: $e');
      return null;
    }
  }

  /// Clear pending verification
  Future<void> _clearPendingVerification() async {
    try {
      await _secureStorage.clearPendingVerification();
    } catch (e) {
      debugPrint('Failed to clear pending verification: $e');
    }
  }

  /// Get verification attempts count
  Future<int> _getVerificationAttempts() async {
    try {
      return await _secureStorage.getFailedAttempts();
    } catch (e) {
      debugPrint('Failed to get verification attempts: $e');
      return 0;
    }
  }

  /// Update verification attempts
  Future<void> _updateVerificationAttempts(bool success) async {
    try {
      if (success) {
        await _clearVerificationAttempts();
      } else {
        final currentAttempts = await _getVerificationAttempts();
        await _secureStorage.storeFailedAttempts(currentAttempts + 1);
        await _setLastVerificationTime();
      }
    } catch (e) {
      debugPrint('Failed to update verification attempts: $e');
    }
  }

  /// Clear verification attempts
  Future<void> _clearVerificationAttempts() async {
    try {
      await _secureStorage.storeFailedAttempts(0);
    } catch (e) {
      debugPrint('Failed to clear verification attempts: $e');
    }
  }

  /// Get last verification time
  Future<DateTime?> _getLastVerificationTime() async {
    try {
      return await _secureStorage.getLockoutTime();
    } catch (e) {
      debugPrint('Failed to get last verification time: $e');
      return null;
    }
  }

  /// Set last verification time
  Future<void> _setLastVerificationTime() async {
    try {
      await _secureStorage.storeLockoutTime(DateTime.now());
    } catch (e) {
      debugPrint('Failed to set last verification time: $e');
    }
  }

  /// Validate phone number format
  bool _isValidPhoneNumber(String phoneNumber) {
    // Basic phone number validation (can be enhanced)
    final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
    return phoneRegex.hasMatch(
      phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), ''),
    );
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Send SMS via provider (Firebase Functions or external service)
  ///
  /// [phoneNumber] - Target phone number in E.164 format
  /// [code] - Verification code to send
  ///
  /// Returns true if SMS was sent successfully, false otherwise
  ///
  /// This method can be implemented to use Firebase Functions with Twilio,
  /// AWS SNS, or other SMS providers based on your backend setup
  Future<bool> _sendSMSViaProvider(String phoneNumber, String code) async {
    try {
      // In a production app, you would integrate with an SMS service provider here
      // For example, using Firebase Functions with Twilio or AWS SNS

      // This is a simulated implementation that demonstrates the structure
      // In a real app, you would make an HTTP request to your backend service

      // Example: Call Firebase Function to send SMS
      // final response = await _callFirebaseFunction('sendSMS', {
      //   'phoneNumber': phoneNumber,
      //   'message': 'Your verification code is: $code',
      // });

      // For now, simulate successful SMS delivery in development
      // In production, this should be replaced with actual SMS service integration
      debugPrint('Sending SMS to $phoneNumber with code: $code');

      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      // In a real implementation, you would check the actual response
      // from your SMS provider to determine success/failure
      return true;
    } catch (e) {
      debugPrint('Error sending SMS via provider: $e');
      return false;
    }
  }

  /// Send email via provider (Firebase Functions or external service)
  ///
  /// [emailAddress] - Target email address
  /// [code] - Verification code to send
  ///
  /// Returns true if email was sent successfully, false otherwise
  ///
  /// This method can be implemented to use Firebase Functions with SendGrid,
  /// AWS SES, or other email providers based on your backend setup
  Future<bool> _sendEmailViaProvider(String emailAddress, String code) async {
    try {
      // In a production app, you would integrate with an email service provider here
      // For example, using Firebase Functions with SendGrid or AWS SES

      // This is a simulated implementation that demonstrates the structure
      // In a real app, you would make an HTTP request to your backend service

      // Example: Call Firebase Function to send email
      // final response = await _callFirebaseFunction('sendEmail', {
      //   'emailAddress': emailAddress,
      //   'subject': 'Verification Code',
      //   'message': 'Your verification code is: $code',
      // });

      // For now, simulate successful email delivery in development
      // In production, this should be replaced with actual email service integration
      debugPrint('Sending email to $emailAddress with code: $code');

      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      // In a real implementation, you would check the actual response
      // from your email provider to determine success/failure
      return true;
    } catch (e) {
      debugPrint('Error sending email via provider: $e');
      return false;
    }
  }

  /// Mask phone number for logging
  String _maskPhoneNumber(String phoneNumber) {
    if (phoneNumber.length <= 4) return phoneNumber;
    final visiblePart = phoneNumber.substring(phoneNumber.length - 4);
    return '****$visiblePart';
  }

  /// Mask email for logging
  String _maskEmail(String email) {
    final atIndex = email.indexOf('@');
    if (atIndex <= 1) return email;

    final username = email.substring(0, atIndex);
    final domain = email.substring(atIndex);

    if (username.length <= 2) return email;

    final maskedUsername =
        username.substring(0, 2) + '*' * (username.length - 2);

    return maskedUsername + domain;
  }
}
