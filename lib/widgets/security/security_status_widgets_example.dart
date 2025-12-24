import 'package:flutter/material.dart';
import '../../models/security/security_status.dart';
import '../../models/security/auth_state.dart';
import 'security_status_widgets.dart';

/// Güvenlik durumu widget'larının kullanım örnekleri
/// 
/// Bu dosya, güvenlik durumu widget'larının nasıl kullanılacağını gösterir.
class SecurityStatusWidgetsExample extends StatefulWidget {
  const SecurityStatusWidgetsExample({super.key});

  @override
  State<SecurityStatusWidgetsExample> createState() => _SecurityStatusWidgetsExampleState();
}

class _SecurityStatusWidgetsExampleState extends State<SecurityStatusWidgetsExample> {
  // Örnek güvenlik durumu
  late SecurityStatus _securityStatus;
  
  // Örnek kimlik doğrulama durumu
  late AuthState _authState;
  
  // Örnek uyarılar
  late List<SecurityWarning> _warnings;
  
  // Kilitleme durumu
  bool _isLocked = false;
  final Duration _remainingDuration = const Duration(minutes: 5);
  int _failedAttempts = 0;
  final int _maxAttempts = 5;

  @override
  void initState() {
    super.initState();
    _initializeExampleData();
  }

  void _initializeExampleData() {
    // Güvenlik durumu örneği
    _securityStatus = SecurityStatus(
      isDeviceSecure: true,
      isRootDetected: false,
      isScreenshotBlocked: true,
      isBackgroundBlurEnabled: true,
      isClipboardSecurityEnabled: true,
      securityLevel: SecurityLevel.high,
      warnings: [],
    );

    // Kimlik doğrulama durumu örneği
    _authState = AuthState.authenticated(
      sessionId: 'example-session-123',
      authMethod: AuthMethod.pin,
    );

    // Uyarılar örneği
    _warnings = [
      SecurityWarning(
        type: SecurityWarningType.weakSecurity,
        severity: SecurityWarningSeverity.medium,
        message: 'Zayıf PIN kodu kullanıyorsunuz',
        description: 'Daha güvenli bir PIN kodu seçmenizi öneririz',
      ),
      SecurityWarning(
        type: SecurityWarningType.suspiciousActivity,
        severity: SecurityWarningSeverity.high,
        message: 'Şüpheli giriş denemesi tespit edildi',
        description: 'Bilinmeyen bir cihazdan giriş denemesi yapıldı',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Güvenlik Widget Örnekleri'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Güvenlik Seviyesi Göstergeleri
          _buildSection(
            'Güvenlik Seviyesi Göstergeleri',
            Column(
              children: [
                const Text('Yüksek Güvenlik'),
                const SizedBox(height: 8),
                const SecurityLevelIndicator(
                  level: SecurityLevel.high,
                ),
                const SizedBox(height: 24),
                
                const Text('Orta Güvenlik'),
                const SizedBox(height: 8),
                const SecurityLevelIndicator(
                  level: SecurityLevel.medium,
                ),
                const SizedBox(height: 24),
                
                const Text('Düşük Güvenlik'),
                const SizedBox(height: 8),
                const SecurityLevelIndicator(
                  level: SecurityLevel.low,
                ),
                const SizedBox(height: 24),
                
                const Text('Kritik Risk'),
                const SizedBox(height: 8),
                const SecurityLevelIndicator(
                  level: SecurityLevel.critical,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Kilitleme Durumu Widget'ı
          _buildSection(
            'Kilitleme Durumu',
            Column(
              children: [
                LockStatusWidget(
                  isLocked: _isLocked,
                  remainingDuration: _isLocked ? _remainingDuration : null,
                  failedAttempts: _failedAttempts,
                  maxAttempts: _maxAttempts,
                ),
                const SizedBox(height: 16),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _failedAttempts = (_failedAttempts + 1).clamp(0, _maxAttempts);
                          if (_failedAttempts >= _maxAttempts) {
                            _isLocked = true;
                          }
                        });
                      },
                      child: const Text('Başarısız Deneme Ekle'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isLocked = false;
                          _failedAttempts = 0;
                        });
                      },
                      child: const Text('Sıfırla'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Güvenlik Uyarıları
          _buildSection(
            'Güvenlik Uyarıları',
            Column(
              children: [
                SecurityWarningWidget(
                  warning: SecurityWarning(
                    type: SecurityWarningType.rootDetected,
                    severity: SecurityWarningSeverity.critical,
                    message: 'Root/Jailbreak tespit edildi',
                    description: 'Cihazınızda root erişimi tespit edildi. Bu durum güvenlik risklerine yol açabilir.',
                  ),
                  onDismiss: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Uyarı kapatıldı')),
                    );
                  },
                  onShowDetails: () {
                    _showWarningDetails(context, 'Root/Jailbreak Detayları');
                  },
                ),
                const SizedBox(height: 8),
                
                SecurityWarningWidget(
                  warning: SecurityWarning(
                    type: SecurityWarningType.suspiciousActivity,
                    severity: SecurityWarningSeverity.high,
                    message: 'Şüpheli aktivite tespit edildi',
                  ),
                  onShowDetails: () {
                    _showWarningDetails(context, 'Şüpheli Aktivite Detayları');
                  },
                ),
                const SizedBox(height: 8),
                
                SecurityWarningWidget(
                  warning: SecurityWarning(
                    type: SecurityWarningType.weakSecurity,
                    severity: SecurityWarningSeverity.medium,
                    message: 'Zayıf güvenlik ayarları',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Güvenlik Uyarı Listesi
          _buildSection(
            'Güvenlik Uyarı Listesi',
            SecurityWarningsList(
              warnings: _warnings,
              maxWarnings: 2,
              onDismissWarning: (warning) {
                setState(() {
                  _warnings.remove(warning);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${warning.message} kapatıldı')),
                );
              },
              onShowWarningDetails: (warning) {
                _showWarningDetails(context, warning.message);
              },
            ),
          ),

          const SizedBox(height: 24),

          // Güvenlik Durumu Kartı
          _buildSection(
            'Güvenlik Durumu Kartı',
            SecurityStatusCard(
              status: _securityStatus,
              authState: _authState,
              onShowDetails: () {
                _showSecurityDetails(context);
              },
            ),
          ),

          const SizedBox(height: 24),

          // Güvenlik Durumu Değiştirme Kontrolleri
          _buildSection(
            'Güvenlik Durumu Kontrolleri',
            Column(
              children: [
                SwitchListTile(
                  title: const Text('Cihaz Güvenliği'),
                  value: _securityStatus.isDeviceSecure,
                  onChanged: (value) {
                    setState(() {
                      _securityStatus = _securityStatus.copyWith(
                        isDeviceSecure: value,
                      );
                      _updateSecurityLevel();
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Root Tespit Edildi'),
                  value: _securityStatus.isRootDetected,
                  onChanged: (value) {
                    setState(() {
                      _securityStatus = _securityStatus.copyWith(
                        isRootDetected: value,
                      );
                      _updateSecurityLevel();
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Ekran Görüntüsü Koruması'),
                  value: _securityStatus.isScreenshotBlocked,
                  onChanged: (value) {
                    setState(() {
                      _securityStatus = _securityStatus.copyWith(
                        isScreenshotBlocked: value,
                      );
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Arka Plan Bulanıklaştırma'),
                  value: _securityStatus.isBackgroundBlurEnabled,
                  onChanged: (value) {
                    setState(() {
                      _securityStatus = _securityStatus.copyWith(
                        isBackgroundBlurEnabled: value,
                      );
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Clipboard Güvenliği'),
                  value: _securityStatus.isClipboardSecurityEnabled,
                  onChanged: (value) {
                    setState(() {
                      _securityStatus = _securityStatus.copyWith(
                        isClipboardSecurityEnabled: value,
                      );
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  void _updateSecurityLevel() {
    SecurityLevel newLevel = SecurityLevel.high;
    
    if (_securityStatus.isRootDetected) {
      newLevel = SecurityLevel.critical;
    } else if (!_securityStatus.isDeviceSecure) {
      newLevel = SecurityLevel.low;
    } else if (_warnings.isNotEmpty) {
      newLevel = SecurityLevel.medium;
    }
    
    setState(() {
      _securityStatus = _securityStatus.copyWith(
        securityLevel: newLevel,
      );
    });
  }

  void _showWarningDetails(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text(
          'Bu bir örnek detay gösterimidir. Gerçek uygulamada '
          'burada uyarı ile ilgili detaylı bilgiler gösterilir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showSecurityDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Güvenlik Detayları'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Güvenlik Seviyesi: ${_securityStatus.securityLevel.description}'),
              const SizedBox(height: 8),
              Text('Cihaz Güvenli: ${_securityStatus.isDeviceSecure ? "Evet" : "Hayır"}'),
              const SizedBox(height: 8),
              Text('Root Tespit: ${_securityStatus.isRootDetected ? "Evet" : "Hayır"}'),
              const SizedBox(height: 8),
              Text('Ekran Koruması: ${_securityStatus.isScreenshotBlocked ? "Aktif" : "Pasif"}'),
              const SizedBox(height: 8),
              Text('Arka Plan Bulanık: ${_securityStatus.isBackgroundBlurEnabled ? "Aktif" : "Pasif"}'),
              const SizedBox(height: 8),
              Text('Clipboard Güvenlik: ${_securityStatus.isClipboardSecurityEnabled ? "Aktif" : "Pasif"}'),
              const SizedBox(height: 8),
              Text('Uyarı Sayısı: ${_warnings.length}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }
}

/// Basit kullanım örneği
class SimpleSecurityStatusExample extends StatelessWidget {
  const SimpleSecurityStatusExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Örnek güvenlik durumu
    final securityStatus = SecurityStatus(
      isDeviceSecure: true,
      isRootDetected: false,
      isScreenshotBlocked: true,
      isBackgroundBlurEnabled: true,
      isClipboardSecurityEnabled: true,
      securityLevel: SecurityLevel.high,
    );

    // Örnek kimlik doğrulama durumu
    final authState = AuthState.authenticated(
      sessionId: 'session-123',
      authMethod: AuthMethod.biometric,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Basit Güvenlik Durumu'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Güvenlik durumu kartı
            SecurityStatusCard(
              status: securityStatus,
              authState: authState,
              onShowDetails: () {
                // Detay gösterme işlemi
              },
            ),
            
            const SizedBox(height: 24),
            
            // Güvenlik seviyesi göstergesi
            const SecurityLevelIndicator(
              level: SecurityLevel.high,
            ),
          ],
        ),
      ),
    );
  }
}
