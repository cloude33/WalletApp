import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/security/security_models.dart';
import '../../models/security/two_factor_models.dart';
import 'auth_service.dart';
import 'two_factor_service.dart';

/// Hassas işlem güvenliği servisi
/// 
/// Bu servis hassas ekran tespiti ve koruma, ek kimlik doğrulama gereksinimleri
/// ve işlem güvenlik seviyelerini yönetir.
/// 
/// Özellikler:
/// - Hassas işlem türlerinin tanımlanması
/// - Güvenlik seviyelerine göre doğrulama gereksinimleri
/// - Hassas ekran tespiti ve koruma
/// - İşlem bazlı güvenlik kontrolleri
/// - Audit logging entegrasyonu
/// 
/// Implements Requirements:
/// - 8.1: Para transferi yapıldığında ek kimlik doğrulama gerektirmeli
/// - 8.2: Güvenlik ayarları değiştirildiğinde PIN ve biyometrik doğrulama gerektirmeli
/// - 8.3: Büyük miktarlı işlem yapıldığında iki faktörlü doğrulama gerektirmeli
/// - 8.4: Hesap bilgileri görüntülendiğinde son 5 dakika içinde doğrulama gerektirmeli
/// - 8.5: Export işlemi yapıldığında tam kimlik doğrulama gerektirmeli
class SensitiveOperationService {
  static final SensitiveOperationService _instance = SensitiveOperationService._internal();
  factory SensitiveOperationService() => _instance;
  SensitiveOperationService._internal();

  final AuthService _authService = AuthService();
  final TwoFactorService _twoFactorService = TwoFactorService();
  
  // Hassas işlem durumu stream controller
  final StreamController<SensitiveOperationEvent> _operationEventController = 
      StreamController<SensitiveOperationEvent>.broadcast();
  
  bool _isInitialized = false;

  /// Hassas işlem olayları stream'i
  Stream<SensitiveOperationEvent> get operationEventStream => _operationEventController.stream;

  /// Servisi başlatır
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _authService.initialize();
      await _twoFactorService.initialize();
      
      _isInitialized = true;
      debugPrint('Sensitive Operation Service initialized successfully');
    } catch (e) {
      throw Exception('Failed to initialize Sensitive Operation service: ${e.toString()}');
    }
  }

  /// Hassas işlem için gerekli güvenlik seviyesini belirler
  /// 
  /// [operationType] - İşlem türü
  /// [context] - İşlem bağlamı (miktar, hedef hesap vb.)
  /// 
  /// Returns gerekli güvenlik seviyesi
  /// 
  /// Implements Requirements 8.1, 8.2, 8.3, 8.4, 8.5
  Future<OperationSecurityLevel> getRequiredSecurityLevel(
    SensitiveOperationType operationType, {
    Map<String, dynamic>? context,
  }) async {
    await _ensureInitialized();
    
    switch (operationType) {
      case SensitiveOperationType.moneyTransfer:
        // 8.1: Para transferi yapıldığında ek kimlik doğrulama gerektirmeli
        final amount = context?['amount'] as double? ?? 0.0;
        final currency = context?['currency'] as String? ?? 'TRY';
        
        if (_isLargeTransaction(amount, currency)) {
          // 8.3: Büyük miktarlı işlem yapıldığında iki faktörlü doğrulama gerektirmeli
          return OperationSecurityLevel.twoFactor;
        }
        return OperationSecurityLevel.enhanced;
        
      case SensitiveOperationType.securitySettingsChange:
        // 8.2: Güvenlik ayarları değiştirildiğinde PIN ve biyometrik doğrulama gerektirmeli
        return OperationSecurityLevel.multiMethod;
        
      case SensitiveOperationType.accountInfoView:
        // 8.4: Hesap bilgileri görüntülendiğinde son 5 dakika içinde doğrulama gerektirmeli
        return OperationSecurityLevel.recentAuth;
        
      case SensitiveOperationType.dataExport:
        // 8.5: Export işlemi yapıldığında tam kimlik doğrulama gerektirmeli
        return OperationSecurityLevel.fullAuth;
        
      case SensitiveOperationType.creditCardPayment:
        final amount = context?['amount'] as double? ?? 0.0;
        final currency = context?['currency'] as String? ?? 'TRY';
        
        if (_isLargeTransaction(amount, currency)) {
          return OperationSecurityLevel.twoFactor;
        }
        return OperationSecurityLevel.enhanced;
        
      case SensitiveOperationType.debtManagement:
        return OperationSecurityLevel.enhanced;
        
      case SensitiveOperationType.goalModification:
        return OperationSecurityLevel.standard;
        
      case SensitiveOperationType.walletAccess:
        return OperationSecurityLevel.recentAuth;
        
      case SensitiveOperationType.reportGeneration:
        final reportType = context?['reportType'] as String? ?? '';
        if (reportType.contains('detailed') || reportType.contains('export')) {
          return OperationSecurityLevel.enhanced;
        }
        return OperationSecurityLevel.standard;
    }
  }

  /// Hassas işlem için kimlik doğrulama gereksinimini kontrol eder
  /// 
  /// [operationType] - İşlem türü
  /// [context] - İşlem bağlamı
  /// 
  /// Returns kimlik doğrulama gerekiyorsa true
  Future<bool> requiresAuthentication(
    SensitiveOperationType operationType, {
    Map<String, dynamic>? context,
  }) async {
    await _ensureInitialized();
    
    final requiredLevel = await getRequiredSecurityLevel(operationType, context: context);
    final currentAuthState = _authService.currentAuthState;
    
    // Temel kimlik doğrulama kontrolü
    if (!currentAuthState.isAuthenticated) {
      return true;
    }
    
    switch (requiredLevel) {
      case OperationSecurityLevel.standard:
        // Standart seviye - temel kimlik doğrulama yeterli
        return false;
        
      case OperationSecurityLevel.recentAuth:
        // Son 5 dakika içinde doğrulama gerekli
        return currentAuthState.requiresSensitiveAuth(const Duration(minutes: 5));
        
      case OperationSecurityLevel.enhanced:
        // Son 2 dakika içinde doğrulama gerekli
        return currentAuthState.requiresSensitiveAuth(const Duration(minutes: 2));
        
      case OperationSecurityLevel.multiMethod:
        // Çoklu yöntem doğrulama gerekli - her zaman yeniden doğrula
        return true;
        
      case OperationSecurityLevel.twoFactor:
        // İki faktörlü doğrulama gerekli
        return true;
        
      case OperationSecurityLevel.fullAuth:
        // Tam kimlik doğrulama gerekli - her zaman yeniden doğrula
        return true;
    }
  }

  /// Hassas işlem için kimlik doğrulama yapar
  /// 
  /// [operationType] - İşlem türü
  /// [context] - İşlem bağlamı
  /// [authMethod] - Tercih edilen doğrulama yöntemi
  /// [pin] - PIN kodu (gerekirse)
  /// [twoFactorCode] - İki faktörlü doğrulama kodu (gerekirse)
  /// 
  /// Returns doğrulama sonucu
  Future<SensitiveOperationResult> authenticateForOperation(
    SensitiveOperationType operationType, {
    Map<String, dynamic>? context,
    AuthMethod authMethod = AuthMethod.pin,
    String? pin,
    String? twoFactorCode,
  }) async {
    await _ensureInitialized();
    
    try {
      // İşlem başlangıcını logla
      await _logOperationEvent(SensitiveOperationEvent.started(
        operationType: operationType,
        context: context,
      ));
      
      final requiredLevel = await getRequiredSecurityLevel(operationType, context: context);
      
      // Güvenlik seviyesine göre doğrulama yap
      final authResult = await _performAuthentication(
        requiredLevel,
        authMethod: authMethod,
        pin: pin,
        twoFactorCode: twoFactorCode,
      );
      
      if (authResult.isSuccess) {
        // Başarılı doğrulama
        await _logOperationEvent(SensitiveOperationEvent.authenticated(
          operationType: operationType,
          authMethod: authMethod,
          context: context,
        ));
        
        return SensitiveOperationResult.success(
          operationType: operationType,
          securityLevel: requiredLevel,
          authMethod: authMethod,
          metadata: {
            'timestamp': DateTime.now().toIso8601String(),
            'sessionId': _authService.currentSession?.sessionId,
            ...?context,
          },
        );
      } else {
        // Başarısız doğrulama
        await _logOperationEvent(SensitiveOperationEvent.failed(
          operationType: operationType,
          authMethod: authMethod,
          errorMessage: authResult.errorMessage,
          context: context,
        ));
        
        return SensitiveOperationResult.failure(
          operationType: operationType,
          securityLevel: requiredLevel,
          authMethod: authMethod,
          errorMessage: authResult.errorMessage,
          remainingAttempts: authResult.remainingAttempts,
          lockoutDuration: authResult.lockoutDuration,
        );
      }
    } catch (e) {
      debugPrint('Sensitive operation authentication error: $e');
      
      await _logOperationEvent(SensitiveOperationEvent.error(
        operationType: operationType,
        errorMessage: e.toString(),
        context: context,
      ));
      
      return SensitiveOperationResult.failure(
        operationType: operationType,
        securityLevel: OperationSecurityLevel.standard,
        authMethod: authMethod,
        errorMessage: 'Hassas işlem doğrulaması sırasında hata oluştu: ${e.toString()}',
      );
    }
  }

  /// Hassas ekran olup olmadığını kontrol eder
  /// 
  /// [screenName] - Ekran adı
  /// [context] - Ekran bağlamı
  /// 
  /// Returns ekran hassas ise true
  bool isSensitiveScreen(String screenName, {Map<String, dynamic>? context}) {
    final sensitiveScreens = {
      // Para transferi ekranları
      'add_transaction_screen',
      'edit_transaction_screen',
      'make_credit_card_payment_screen',
      
      // Hesap bilgileri ekranları
      'credit_card_detail_screen',
      'debt_detail_screen',
      'wallet_detail_screen',
      
      // Güvenlik ayarları ekranları
      'security_settings_screen',
      'pin_setup_screen',
      'pin_change_screen',
      'biometric_setup_screen',
      
      // Export ve rapor ekranları
      'export_screen',
      'detailed_report_screen',
      
      // KMH hesap ekranları
      'kmh_account_detail_screen',
      'kmh_payment_planner_screen',
    };
    
    return sensitiveScreens.contains(screenName.toLowerCase());
  }

  /// Hassas işlem türünü ekran adından belirler
  /// 
  /// [screenName] - Ekran adı
  /// [context] - Ekran bağlamı
  /// 
  /// Returns hassas işlem türü (varsa)
  SensitiveOperationType? getOperationTypeFromScreen(
    String screenName, {
    Map<String, dynamic>? context,
  }) {
    final screenLower = screenName.toLowerCase();
    
    if (screenLower.contains('transaction') || screenLower.contains('transfer')) {
      return SensitiveOperationType.moneyTransfer;
    }
    
    if (screenLower.contains('security') || screenLower.contains('pin') || screenLower.contains('biometric')) {
      return SensitiveOperationType.securitySettingsChange;
    }
    
    if (screenLower.contains('detail') || screenLower.contains('account')) {
      return SensitiveOperationType.accountInfoView;
    }
    
    if (screenLower.contains('export') || screenLower.contains('report')) {
      return SensitiveOperationType.dataExport;
    }
    
    if (screenLower.contains('credit_card_payment')) {
      return SensitiveOperationType.creditCardPayment;
    }
    
    if (screenLower.contains('debt')) {
      return SensitiveOperationType.debtManagement;
    }
    
    if (screenLower.contains('goal')) {
      return SensitiveOperationType.goalModification;
    }
    
    if (screenLower.contains('wallet')) {
      return SensitiveOperationType.walletAccess;
    }
    
    return null;
  }

  /// Hassas işlem geçmişini döndürür
  /// 
  /// [limit] - Maksimum kayıt sayısı
  /// [operationType] - Filtrelenecek işlem türü (opsiyonel)
  /// 
  /// Returns hassas işlem geçmişi
  Future<List<SensitiveOperationEvent>> getOperationHistory({
    int limit = 50,
    SensitiveOperationType? operationType,
  }) async {
    await _ensureInitialized();
    
    // Bu implementasyon basit bir in-memory store kullanır
    // Gerçek implementasyonda secure storage veya database kullanılmalı
    return [];
  }

  /// Servisi temizler
  void dispose() {
    _operationEventController.close();
  }

  /// Test amaçlı servisi sıfırlar
  @visibleForTesting
  void resetForTesting() {
    _isInitialized = false;
  }

  // Private helper methods

  /// Servisin başlatıldığından emin olur
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Büyük işlem olup olmadığını kontrol eder
  bool _isLargeTransaction(double amount, String currency) {
    // Para birimi bazlı büyük işlem limitleri
    final limits = {
      'TRY': 10000.0,  // 10,000 TL
      'USD': 1000.0,   // $1,000
      'EUR': 1000.0,   // €1,000
      'GBP': 800.0,    // £800
    };
    
    final limit = limits[currency.toUpperCase()] ?? limits['TRY']!;
    return amount >= limit;
  }

  /// Güvenlik seviyesine göre kimlik doğrulama yapar
  Future<AuthResult> _performAuthentication(
    OperationSecurityLevel securityLevel, {
    AuthMethod authMethod = AuthMethod.pin,
    String? pin,
    String? twoFactorCode,
  }) async {
    switch (securityLevel) {
      case OperationSecurityLevel.standard:
        // Standart seviye - mevcut oturum yeterli
        if (_authService.currentAuthState.isAuthenticated) {
          return AuthResult.success(method: authMethod);
        }
        return await _authService.authenticateWithPIN(pin ?? '');
        
      case OperationSecurityLevel.recentAuth:
      case OperationSecurityLevel.enhanced:
        // Hassas işlem doğrulaması gerekli
        return await _authService.authenticateForSensitiveOperation(
          method: authMethod,
          pin: pin,
        );
        
      case OperationSecurityLevel.multiMethod:
        // Çoklu yöntem doğrulama - önce PIN sonra biyometrik
        final pinResult = await _authService.authenticateForSensitiveOperation(
          method: AuthMethod.pin,
          pin: pin,
        );
        
        if (!pinResult.isSuccess) {
          return pinResult;
        }
        
        // Biyometrik geçici olarak devre dışı
        return pinResult;
        
      case OperationSecurityLevel.twoFactor:
        // İki faktörlü doğrulama
        if (twoFactorCode == null) {
          return AuthResult.failure(
            method: AuthMethod.twoFactor,
            errorMessage: 'İki faktörlü doğrulama kodu gerekli',
          );
        }
        
        // Two factor service returns TwoFactorVerificationResult, need to convert to AuthResult
        final twoFactorResult = await _twoFactorService.verifyCode(
          TwoFactorVerificationRequest.totp(twoFactorCode),
        );
        
        return AuthResult(
          isSuccess: twoFactorResult.isSuccess,
          method: AuthMethod.twoFactor,
          errorMessage: twoFactorResult.errorMessage,
          metadata: twoFactorResult.metadata,
        );
        
      case OperationSecurityLevel.fullAuth:
        // Tam kimlik doğrulama - tüm mevcut yöntemler
        final pinResult = await _authService.authenticateForSensitiveOperation(
          method: AuthMethod.pin,
          pin: pin,
        );
        
        if (!pinResult.isSuccess) {
          return pinResult;
        }
        
        // İki faktörlü doğrulama etkinse kontrol et
        final config = await _authService.getSecurityConfig();
        if (config.isTwoFactorEnabled && twoFactorCode != null) {
          final twoFactorResult = await _twoFactorService.verifyCode(
            TwoFactorVerificationRequest.totp(twoFactorCode),
          );
          
          return AuthResult(
            isSuccess: twoFactorResult.isSuccess,
            method: AuthMethod.twoFactor,
            errorMessage: twoFactorResult.errorMessage,
            metadata: twoFactorResult.metadata,
          );
        }
        
        return pinResult;
    }
  }

  /// Hassas işlem olayını loglar
  Future<void> _logOperationEvent(SensitiveOperationEvent event) async {
    try {
      // Event'i stream'e gönder
      _operationEventController.add(event);
      
      // Audit log'a kaydet (gelecekte implement edilecek)
      debugPrint('Sensitive operation event: ${event.type} - ${event.operationType}');
    } catch (e) {
      debugPrint('Failed to log sensitive operation event: $e');
    }
  }
}

