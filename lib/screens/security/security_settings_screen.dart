import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/security/security_models.dart';
import '../../models/security/two_factor_models.dart';
import '../../services/auth/auth_service.dart';
import '../../services/auth/biometric_service.dart';
import '../../services/auth/two_factor_service.dart';
import 'biometric_setup_screen.dart';

/// Güvenlik ayarları ekranı
///
/// Bu ekran kullanıcının kimlik doğrulama yöntemlerini yönetmesini,
/// güvenlik seviyesi konfigürasyonunu ve oturum zaman aşımı ayarlarını
/// yapmasını sağlar.
///
/// Implements Requirements:
/// - 7.1: Mevcut kimlik doğrulama yöntemlerini göstermeli
/// - 7.2: PIN değiştirme seçildiğinde mevcut PIN doğrulaması gerektirmeli
/// - 7.3: Biyometrik ayar değiştirildiğinde yeniden kayıt sürecini başlatmalı
/// - 7.4: İki faktörlü doğrulama etkinleştirildiğinde SMS/email doğrulaması gerektirmeli
/// - 6.5: Özelleştirilebilir zaman aşımı uygulamalı
class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final AuthService _authService = AuthService();
  final BiometricService _biometricService = BiometricServiceSingleton.instance;
  final TwoFactorService _twoFactorService = TwoFactorService();

  SecurityConfig? _securityConfig;
  TwoFactorConfig? _twoFactorConfig;
  List<BiometricType> _availableBiometrics = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Session timeout options (in minutes)
  final List<int> _sessionTimeoutOptions = [1, 2, 5, 10, 15, 30, 60];

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await _authService.initialize();
      await _twoFactorService.initialize();

      await _loadSecuritySettings();
    } catch (e) {
      setState(() {
        _errorMessage = 'Güvenlik ayarları yüklenemedi: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSecuritySettings() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load security configuration
      final securityConfig = await _authService.getSecurityConfig();
      final twoFactorConfig = await _twoFactorService.getConfiguration();

      // Get available biometrics
      List<BiometricType> availableBiometrics = [];
      try {
        if (await _biometricService.isBiometricAvailable()) {
          availableBiometrics = await _biometricService
              .getAvailableBiometrics();
        }
      } catch (e) {
        debugPrint('Failed to get available biometrics: $e');
      }

      setState(() {
        _securityConfig = securityConfig;
        _twoFactorConfig = twoFactorConfig;
        _availableBiometrics = availableBiometrics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ayarlar yüklenirken hata oluştu: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Güvenlik Ayarları',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorState()
          : _buildSettingsContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Hata Oluştu',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadSecuritySettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsContent() {
    if (_securityConfig == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Authentication Methods Section
          _buildSectionHeader('Kimlik Doğrulama Yöntemleri'),
          _buildAuthenticationMethodsCard(),

          const SizedBox(height: 24),

          // Session Settings Section
          _buildSectionHeader('Oturum Ayarları'),
          _buildSessionSettingsCard(),

          const SizedBox(height: 24),

          // Two-Factor Authentication Section
          _buildSectionHeader('İki Faktörlü Doğrulama'),
          _buildTwoFactorAuthCard(),

          const SizedBox(height: 24),

          // Advanced Security Section
          _buildSectionHeader('Gelişmiş Güvenlik'),
          _buildAdvancedSecurityCard(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildAuthenticationMethodsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Biometric Authentication
            _buildSettingTile(
              icon: Icons.fingerprint,
              title: 'Biyometrik Doğrulama',
              subtitle: _getBiometricSubtitle(),
              trailing: Switch(
                value: _securityConfig!.isBiometricEnabled,
                onChanged: _availableBiometrics.isNotEmpty
                    ? (value) => _toggleBiometricAuthentication(value)
                    : null,
                activeThumbColor: Colors.green,
              ),
            ),

            // Biometric Setup Option (only if biometric is available but not enabled)
            if (_availableBiometrics.isNotEmpty &&
                !_securityConfig!.isBiometricEnabled) ...[
              const Divider(),
              _buildActionTile(
                icon: Icons.settings,
                title: 'Biyometrik Kurulum',
                subtitle: 'Parmak izi veya yüz tanıma ayarlayın',
                onTap: _setupBiometric,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSessionSettingsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Session Timeout
            _buildSettingTile(
              icon: Icons.timer,
              title: 'Oturum Zaman Aşımı',
              subtitle:
                  '${_securityConfig!.sessionTimeout.inMinutes} dakika sonra otomatik kilitleme',
              trailing: DropdownButton<int>(
                value: _securityConfig!.sessionTimeout.inMinutes,
                items: _sessionTimeoutOptions.map((minutes) {
                  return DropdownMenuItem<int>(
                    value: minutes,
                    child: Text('$minutes dk'),
                  );
                }).toList(),
                onChanged: (value) => _updateSessionTimeout(value!),
                underline: const SizedBox(),
              ),
            ),

            const Divider(),

            // Background Lock
            _buildSettingTile(
              icon: Icons.lock_clock,
              title: 'Arka Plan Kilitleme',
              subtitle: _securityConfig!.sessionConfig.enableBackgroundLock
                  ? 'Uygulama arka plana geçtiğinde kilitle'
                  : 'Arka plan kilitleme devre dışı',
              trailing: Switch(
                value: _securityConfig!.sessionConfig.enableBackgroundLock,
                onChanged: (value) => _toggleBackgroundLock(value),
                activeThumbColor: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTwoFactorAuthCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Two-Factor Authentication Toggle
            _buildSettingTile(
              icon: Icons.security,
              title: 'İki Faktörlü Doğrulama',
              subtitle: _twoFactorConfig?.isEnabled == true
                  ? 'Etkin - Ek güvenlik katmanı'
                  : 'Devre dışı',
              trailing: Switch(
                value: _twoFactorConfig?.isEnabled ?? false,
                onChanged: (value) => _toggleTwoFactorAuth(value),
                activeThumbColor: Colors.green,
              ),
            ),

            // Two-Factor Methods (only if enabled)
            if (_twoFactorConfig?.isEnabled == true) ...[
              const Divider(),

              // SMS Verification
              _buildSettingTile(
                icon: Icons.sms,
                title: 'SMS Doğrulama',
                subtitle: _twoFactorConfig!.isSMSEnabled
                    ? 'Etkin - ${_maskPhoneNumber(_twoFactorConfig!.phoneNumber)}'
                    : 'Devre dışı',
                trailing: Switch(
                  value: _twoFactorConfig!.isSMSEnabled,
                  onChanged: (value) => _toggleSMSVerification(value),
                  activeThumbColor: Colors.green,
                ),
              ),

              const Divider(),

              // Email Verification
              _buildSettingTile(
                icon: Icons.email,
                title: 'E-posta Doğrulama',
                subtitle: _twoFactorConfig!.isEmailEnabled
                    ? 'Etkin - ${_maskEmail(_twoFactorConfig!.emailAddress)}'
                    : 'Devre dışı',
                trailing: Switch(
                  value: _twoFactorConfig!.isEmailEnabled,
                  onChanged: (value) => _toggleEmailVerification(value),
                  activeThumbColor: Colors.green,
                ),
              ),

              const Divider(),

              // TOTP Verification
              _buildSettingTile(
                icon: Icons.smartphone,
                title: 'Authenticator Uygulaması',
                subtitle: _twoFactorConfig!.isTOTPEnabled
                    ? 'Etkin - TOTP doğrulama'
                    : 'Devre dışı',
                trailing: Switch(
                  value: _twoFactorConfig!.isTOTPEnabled,
                  onChanged: (value) => _toggleTOTPVerification(value),
                  activeThumbColor: Colors.green,
                ),
              ),

              // Backup Codes
              if (_twoFactorConfig!.backupCodes.isNotEmpty) ...[
                const Divider(),
                _buildActionTile(
                  icon: Icons.backup,
                  title: 'Yedek Kodlar',
                  subtitle:
                      '${_getUnusedBackupCodesCount()} adet kullanılmamış kod',
                  onTap: _showBackupCodes,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSecurityCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Security Level Info
            _buildInfoTile(
              icon: Icons.shield,
              title: 'Güvenlik Seviyesi',
              subtitle: _getSecurityLevelText(),
              color: _getSecurityLevelColor(),
            ),

            const Divider(),

            // Reset All Security Settings
            _buildActionTile(
              icon: Icons.restore,
              title: 'Güvenlik Ayarlarını Sıfırla',
              subtitle: 'Tüm güvenlik ayarlarını varsayılana döndür',
              onTap: _resetSecuritySettings,
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.blue[700], size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[600], fontSize: 14),
      ),
      trailing: trailing,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red[50] : Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.red[700] : Colors.blue[700],
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: isDestructive ? Colors.red[700] : null,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[600], fontSize: 14),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[600], fontSize: 14),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  // Helper methods for UI text and state

  String _getBiometricSubtitle() {
    if (_availableBiometrics.isEmpty) {
      return 'Bu cihazda desteklenmiyor';
    }

    if (_securityConfig!.isBiometricEnabled) {
      final types = _availableBiometrics
          .map((type) => type.displayName)
          .join(', ');
      return 'Etkin - $types';
    }

    return 'Mevcut ama devre dışı';
  }

  String _getSecurityLevelText() {
    int score = 0;

    if (_securityConfig!.isBiometricEnabled) score += 40;
    if (_twoFactorConfig?.isEnabled == true) score += 40;
    if (_securityConfig!.sessionConfig.enableBackgroundLock) score += 20;

    if (score >= 80) return 'Yüksek - Mükemmel güvenlik';
    if (score >= 60) return 'Orta - İyi güvenlik';
    if (score >= 40) return 'Düşük - Temel güvenlik';
    return 'Çok Düşük - Güvenlik riski';
  }

  Color _getSecurityLevelColor() {
    int score = 0;

    if (_securityConfig!.isBiometricEnabled) score += 40;
    if (_twoFactorConfig?.isEnabled == true) score += 40;
    if (_securityConfig!.sessionConfig.enableBackgroundLock) score += 20;

    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    if (score >= 40) return Colors.red[300]!;
    return Colors.red;
  }

  String? _maskPhoneNumber(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.length <= 4) return phoneNumber;
    final visiblePart = phoneNumber.substring(phoneNumber.length - 4);
    return '****$visiblePart';
  }

  String? _maskEmail(String? email) {
    if (email == null) return null;
    final atIndex = email.indexOf('@');
    if (atIndex <= 1) return email;

    final username = email.substring(0, atIndex);
    final domain = email.substring(atIndex);

    if (username.length <= 2) return email;

    final maskedUsername =
        username.substring(0, 2) + '*' * (username.length - 2);

    return maskedUsername + domain;
  }

  int _getUnusedBackupCodesCount() {
    if (_twoFactorConfig == null) return 0;

    int unusedCount = 0;
    for (final code in _twoFactorConfig!.backupCodes) {
      if (!_twoFactorConfig!.usedBackupCodes.contains(code)) {
        unusedCount++;
      }
    }
    return unusedCount;
  }

  // Action methods

  Future<void> _toggleBiometricAuthentication(bool enabled) async {
    try {
      if (enabled) {
        // Enable biometric - navigate to biometric setup
        final result = await Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const BiometricSetupScreen()),
        );

        if (result == true) {
          await _loadSecuritySettings();
        }
      } else {
        // Disable biometric
        final confirmed = await _showConfirmationDialog(
          title: 'Biyometrik Doğrulamayı Devre Dışı Bırak',
          message:
              'Biyometrik doğrulama devre dışı bırakılacak. Devam etmek istiyor musunuz?',
          confirmText: 'Devre Dışı Bırak',
        );

        if (confirmed) {
          await _biometricService.disableBiometric();
          await _updateSecurityConfig(
            _securityConfig!.copyWith(isBiometricEnabled: false),
          );
        }
      }
    } catch (e) {
      _showErrorSnackBar('Biyometrik ayar değiştirilemedi: ${e.toString()}');
    }
  }

  Future<void> _setupBiometric() async {
    try {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const BiometricSetupScreen()),
      );

      if (result == true) {
        await _loadSecuritySettings();
        _showSuccessSnackBar('Biyometrik doğrulama başarıyla ayarlandı');
      }
    } catch (e) {
      _showErrorSnackBar(
        'Biyometrik kurulum ekranı açılamadı: ${e.toString()}',
      );
    }
  }

  Future<void> _updateSessionTimeout(int minutes) async {
    try {
      final newConfig = _securityConfig!.copyWith(
        sessionTimeout: Duration(minutes: minutes),
        sessionConfig: _securityConfig!.sessionConfig.copyWith(
          sessionTimeout: Duration(minutes: minutes),
        ),
      );

      await _updateSecurityConfig(newConfig);
      _showSuccessSnackBar('Oturum zaman aşımı güncellendi');
    } catch (e) {
      _showErrorSnackBar('Oturum zaman aşımı güncellenemedi: ${e.toString()}');
    }
  }

  Future<void> _toggleBackgroundLock(bool enabled) async {
    try {
      final newConfig = _securityConfig!.copyWith(
        sessionConfig: _securityConfig!.sessionConfig.copyWith(
          enableBackgroundLock: enabled,
        ),
      );

      await _updateSecurityConfig(newConfig);
      _showSuccessSnackBar(
        enabled
            ? 'Arka plan kilitleme etkinleştirildi'
            : 'Arka plan kilitleme devre dışı bırakıldı',
      );
    } catch (e) {
      _showErrorSnackBar(
        'Arka plan kilitleme ayarı değiştirilemedi: ${e.toString()}',
      );
    }
  }

  Future<void> _toggleTwoFactorAuth(bool enabled) async {
    try {
      if (enabled) {
        // Show two-factor setup options
        await _showTwoFactorSetupDialog();
      } else {
        // Disable two-factor authentication
        final confirmed = await _showConfirmationDialog(
          title: 'İki Faktörlü Doğrulamayı Devre Dışı Bırak',
          message:
              'Tüm iki faktörlü doğrulama yöntemleri devre dışı bırakılacak. Devam etmek istiyor musunuz?',
          confirmText: 'Devre Dışı Bırak',
          isDestructive: true,
        );

        if (confirmed) {
          await _twoFactorService.disableAllMethods();
          await _loadSecuritySettings();
          _showSuccessSnackBar('İki faktörlü doğrulama devre dışı bırakıldı');
        }
      }
    } catch (e) {
      _showErrorSnackBar(
        'İki faktörlü doğrulama ayarı değiştirilemedi: ${e.toString()}',
      );
    }
  }

  Future<void> _toggleSMSVerification(bool enabled) async {
    try {
      if (enabled) {
        await _setupSMSVerification();
      } else {
        await _twoFactorService.disableMethod(TwoFactorMethod.sms);
        await _loadSecuritySettings();
        _showSuccessSnackBar('SMS doğrulama devre dışı bırakıldı');
      }
    } catch (e) {
      _showErrorSnackBar(
        'SMS doğrulama ayarı değiştirilemedi: ${e.toString()}',
      );
    }
  }

  Future<void> _toggleEmailVerification(bool enabled) async {
    try {
      if (enabled) {
        await _setupEmailVerification();
      } else {
        await _twoFactorService.disableMethod(TwoFactorMethod.email);
        await _loadSecuritySettings();
        _showSuccessSnackBar('E-posta doğrulama devre dışı bırakıldı');
      }
    } catch (e) {
      _showErrorSnackBar(
        'E-posta doğrulama ayarı değiştirilemedi: ${e.toString()}',
      );
    }
  }

  Future<void> _toggleTOTPVerification(bool enabled) async {
    try {
      if (enabled) {
        await _setupTOTPVerification();
      } else {
        await _twoFactorService.disableMethod(TwoFactorMethod.totp);
        await _loadSecuritySettings();
        _showSuccessSnackBar('Authenticator doğrulama devre dışı bırakıldı');
      }
    } catch (e) {
      _showErrorSnackBar(
        'Authenticator doğrulama ayarı değiştirilemedi: ${e.toString()}',
      );
    }
  }

  Future<void> _showBackupCodes() async {
    try {
      final unusedCodes = await _twoFactorService.getUnusedBackupCodes();

      if (unusedCodes.isEmpty) {
        final confirmed = await _showConfirmationDialog(
          title: 'Yeni Yedek Kodlar Oluştur',
          message:
              'Tüm yedek kodlar kullanılmış. Yeni yedek kodlar oluşturmak istiyor musunuz?',
          confirmText: 'Oluştur',
        );

        if (confirmed) {
          final newCodes = await _twoFactorService.generateNewBackupCodes();
          if (newCodes.isNotEmpty) {
            await _showBackupCodesDialog(newCodes);
          }
        }
      } else {
        await _showBackupCodesDialog(unusedCodes);
      }
    } catch (e) {
      _showErrorSnackBar('Yedek kodlar gösterilemedi: ${e.toString()}');
    }
  }

  Future<void> _resetSecuritySettings() async {
    try {
      final confirmed = await _showConfirmationDialog(
        title: 'Güvenlik Ayarlarını Sıfırla',
        message:
            'Tüm güvenlik ayarları varsayılan değerlere döndürülecek. Bu işlem geri alınamaz. Devam etmek istiyor musunuz?',
        confirmText: 'Sıfırla',
        isDestructive: true,
      );

      if (confirmed) {
        // Reset all security settings
        await _biometricService.disableBiometric();
        await _twoFactorService.disableAllMethods();

        final defaultConfig = SecurityConfig.defaultConfig();
        await _updateSecurityConfig(defaultConfig);

        _showSuccessSnackBar('Güvenlik ayarları sıfırlandı');
      }
    } catch (e) {
      _showErrorSnackBar('Güvenlik ayarları sıfırlanamadı: ${e.toString()}');
    }
  }

  // Helper methods for dialogs and setup

  Future<void> _updateSecurityConfig(SecurityConfig newConfig) async {
    final success = await _authService.updateSecurityConfig(newConfig);
    if (success) {
      setState(() {
        _securityConfig = newConfig;
      });
    } else {
      throw Exception('Güvenlik konfigürasyonu güncellenemedi');
    }
  }

  Future<bool> _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmText,
    bool isDestructive = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDestructive
                      ? Colors.red
                      : Colors.blue[700],
                  foregroundColor: Colors.white,
                ),
                child: Text(confirmText),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _showTwoFactorSetupDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('İki Faktörlü Doğrulama Kurulumu'),
        content: const Text(
          'İki faktörlü doğrulama için en az bir yöntem seçmelisiniz. Hangi yöntemi kullanmak istiyorsunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _setupSMSVerification();
            },
            child: const Text('SMS'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _setupEmailVerification();
            },
            child: const Text('E-posta'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _setupTOTPVerification();
            },
            child: const Text('Authenticator'),
          ),
        ],
      ),
    );
  }

  Future<void> _setupSMSVerification() async {
    final phoneController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('SMS Doğrulama Kurulumu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'SMS doğrulama kodları alacağınız telefon numarasını girin:',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefon Numarası',
                hintText: '+90 555 123 4567',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(phoneController.text),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final setupResult = await _twoFactorService.enableSMSVerification(result);
      if (setupResult.isSuccess) {
        await _loadSecuritySettings();
        _showSuccessSnackBar('SMS doğrulama başarıyla ayarlandı');

        if (setupResult.backupCodes != null) {
          await _showBackupCodesDialog(setupResult.backupCodes!);
        }
      } else {
        _showErrorSnackBar(
          setupResult.errorMessage ?? 'SMS doğrulama ayarlanamadı',
        );
      }
    }
  }

  Future<void> _setupEmailVerification() async {
    final emailController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('E-posta Doğrulama Kurulumu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'E-posta doğrulama kodları alacağınız e-posta adresini girin:',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-posta Adresi',
                hintText: 'ornek@email.com',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(emailController.text),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final setupResult = await _twoFactorService.enableEmailVerification(
        result,
      );
      if (setupResult.isSuccess) {
        await _loadSecuritySettings();
        _showSuccessSnackBar('E-posta doğrulama başarıyla ayarlandı');

        if (setupResult.backupCodes != null) {
          await _showBackupCodesDialog(setupResult.backupCodes!);
        }
      } else {
        _showErrorSnackBar(
          setupResult.errorMessage ?? 'E-posta doğrulama ayarlanamadı',
        );
      }
    }
  }

  Future<void> _setupTOTPVerification() async {
    final accountController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Authenticator Kurulumu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Authenticator uygulamasında görünecek hesap adını girin:',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: accountController,
              decoration: const InputDecoration(
                labelText: 'Hesap Adı',
                hintText: 'Benim Hesabım',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(accountController.text),
            child: const Text('Devam'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final setupResult = await _twoFactorService.enableTOTPVerification(
        result,
      );
      if (setupResult.isSuccess) {
        await _loadSecuritySettings();
        _showSuccessSnackBar('Authenticator doğrulama başarıyla ayarlandı');

        // Show QR code and secret
        if (setupResult.qrCodeUrl != null && setupResult.totpSecret != null) {
          await _showTOTPSetupDialog(
            setupResult.qrCodeUrl!,
            setupResult.totpSecret!,
          );
        }

        if (setupResult.backupCodes != null) {
          await _showBackupCodesDialog(setupResult.backupCodes!);
        }
      } else {
        _showErrorSnackBar(
          setupResult.errorMessage ?? 'Authenticator doğrulama ayarlanamadı',
        );
      }
    }
  }

  Future<void> _showTOTPSetupDialog(String qrCodeUrl, String secret) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Authenticator Kurulumu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Authenticator uygulamanızda bu QR kodu tarayın veya gizli anahtarı manuel olarak girin:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    'QR Kod URL:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    qrCodeUrl,
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Gizli Anahtar:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    secret,
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Future<void> _showBackupCodesDialog(List<String> codes) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Yedek Kodlar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bu yedek kodları güvenli bir yerde saklayın. Her kod sadece bir kez kullanılabilir:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: codes
                    .map(
                      (code) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: SelectableText(
                          code,
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Copy codes to clipboard
              final codesText = codes.join('\n');
              Clipboard.setData(ClipboardData(text: codesText));
              _showSuccessSnackBar('Yedek kodlar panoya kopyalandı');
            },
            child: const Text('Kopyala'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
