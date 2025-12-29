import 'package:flutter/material.dart';
import '../../models/security/security_status.dart';
import '../../models/security/auth_state.dart';

/// Güvenlik seviyesi göstergesi widget'ı
///
/// Mevcut güvenlik seviyesini görsel olarak gösterir.
/// Renk kodlu gösterge ile kullanıcıya güvenlik durumunu iletir.
///
/// Implements Requirement 10.1: Güvenlik dashboard açıldığında güvenlik durumu özetini göstermeli
class SecurityLevelIndicator extends StatelessWidget {
  /// Güvenlik seviyesi
  final SecurityLevel level;

  /// Widget boyutu
  final double size;

  /// Açıklama gösterilsin mi?
  final bool showDescription;

  /// Animasyon etkin mi?
  final bool animated;

  const SecurityLevelIndicator({
    super.key,
    required this.level,
    this.size = 80.0,
    this.showDescription = true,
    this.animated = true,
  });

  @override
  Widget build(BuildContext context) {
    // Cache color to avoid repeated Color() calls
    final levelColor = Color(level.color);

    return RepaintBoundary(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Güvenlik seviyesi göstergesi
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: levelColor.withValues(alpha: 0.2),
              border: Border.all(color: levelColor, width: 3),
            ),
            child: Center(
              child: Icon(
                _getIconForLevel(level),
                size: size * 0.5,
                color: levelColor,
              ),
            ),
          ),

          if (showDescription) ...[
            const SizedBox(height: 8),
            Text(
              _getLevelText(level),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: levelColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              level.description,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  IconData _getIconForLevel(SecurityLevel level) {
    switch (level) {
      case SecurityLevel.high:
        return Icons.shield_outlined;
      case SecurityLevel.medium:
        return Icons.shield;
      case SecurityLevel.low:
        return Icons.warning_outlined;
      case SecurityLevel.critical:
        return Icons.error_outline;
    }
  }

  String _getLevelText(SecurityLevel level) {
    switch (level) {
      case SecurityLevel.high:
        return 'Güvenli';
      case SecurityLevel.medium:
        return 'Orta Seviye';
      case SecurityLevel.low:
        return 'Düşük Seviye';
      case SecurityLevel.critical:
        return 'Kritik Risk';
    }
  }
}

/// Kilitleme durumu gösterimi widget'ı
///
/// Hesap kilitleme durumunu ve kalan süreyi gösterir.
///
/// Implements Requirement 10.5: Güvenlik açığı tespit edildiğinde kullanıcıyı uyarmalı
class LockStatusWidget extends StatelessWidget {
  /// Hesap kilitli mi?
  final bool isLocked;

  /// Kalan kilitleme süresi
  final Duration? remainingDuration;

  /// Başarısız deneme sayısı
  final int? failedAttempts;

  /// Maksimum deneme sayısı
  final int? maxAttempts;

  const LockStatusWidget({
    super.key,
    required this.isLocked,
    this.remainingDuration,
    this.failedAttempts,
    this.maxAttempts,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLocked && (failedAttempts == null || failedAttempts == 0)) {
      return const SizedBox.shrink();
    }

    return Card(
      color: isLocked ? Colors.red[50] : Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isLocked ? Icons.lock_outline : Icons.warning_amber_outlined,
                  color: isLocked ? Colors.red : Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isLocked ? 'Hesap Kilitli' : 'Güvenlik Uyarısı',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isLocked ? Colors.red[900] : Colors.orange[900],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (isLocked && remainingDuration != null) ...[
              Text(
                'Kalan Süre: ${_formatDuration(remainingDuration!)}',
                style: TextStyle(fontSize: 14, color: Colors.red[700]),
              ),
              const SizedBox(height: 4),
            ],

            if (failedAttempts != null && maxAttempts != null) ...[
              Text(
                'Başarısız Deneme: $failedAttempts / $maxAttempts',
                style: TextStyle(
                  fontSize: 14,
                  color: isLocked ? Colors.red[700] : Colors.orange[700],
                ),
              ),
            ],

            if (isLocked) ...[
              const SizedBox(height: 8),
              Text(
                'Çok fazla başarısız deneme yaptınız. Lütfen belirtilen süre sonunda tekrar deneyin.',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    if (minutes > 0) {
      return '$minutes dakika $seconds saniye';
    } else {
      return '$seconds saniye';
    }
  }
}

/// Güvenlik uyarı widget'ı
///
/// Güvenlik uyarılarını listeler ve gösterir.
///
/// Implements Requirement 10.5: Güvenlik açığı tespit edildiğinde kullanıcıyı uyarmalı ve önerilerde bulunmalı
class SecurityWarningWidget extends StatelessWidget {
  /// Güvenlik uyarısı
  final SecurityWarning warning;

  /// Kapatma callback'i
  final VoidCallback? onDismiss;

  /// Detay gösterme callback'i
  final VoidCallback? onShowDetails;

  const SecurityWarningWidget({
    super.key,
    required this.warning,
    this.onDismiss,
    this.onShowDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _getBackgroundColor(warning.severity),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getIconForSeverity(warning.severity),
                  color: _getIconColor(warning.severity),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    warning.message,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getTextColor(warning.severity),
                    ),
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: onDismiss,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),

            if (warning.description != null) ...[
              const SizedBox(height: 8),
              Text(
                warning.description!,
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],

            if (onShowDetails != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: onShowDetails,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Detayları Gör',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getIconColor(warning.severity),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor(SecurityWarningSeverity severity) {
    switch (severity) {
      case SecurityWarningSeverity.critical:
        return Colors.red[50]!;
      case SecurityWarningSeverity.high:
        return Colors.orange[50]!;
      case SecurityWarningSeverity.medium:
        return Colors.yellow[50]!;
      case SecurityWarningSeverity.low:
        return Colors.blue[50]!;
    }
  }

  Color _getIconColor(SecurityWarningSeverity severity) {
    switch (severity) {
      case SecurityWarningSeverity.critical:
        return Colors.red[700]!;
      case SecurityWarningSeverity.high:
        return Colors.orange[700]!;
      case SecurityWarningSeverity.medium:
        return Colors.yellow[700]!;
      case SecurityWarningSeverity.low:
        return Colors.blue[700]!;
    }
  }

  Color _getTextColor(SecurityWarningSeverity severity) {
    switch (severity) {
      case SecurityWarningSeverity.critical:
        return Colors.red[900]!;
      case SecurityWarningSeverity.high:
        return Colors.orange[900]!;
      case SecurityWarningSeverity.medium:
        return Colors.yellow[900]!;
      case SecurityWarningSeverity.low:
        return Colors.blue[900]!;
    }
  }

  IconData _getIconForSeverity(SecurityWarningSeverity severity) {
    switch (severity) {
      case SecurityWarningSeverity.critical:
        return Icons.error_outline;
      case SecurityWarningSeverity.high:
        return Icons.warning_amber_outlined;
      case SecurityWarningSeverity.medium:
        return Icons.info_outline;
      case SecurityWarningSeverity.low:
        return Icons.info_outline;
    }
  }
}

/// Güvenlik uyarı listesi widget'ı
///
/// Birden fazla güvenlik uyarısını liste halinde gösterir.
class SecurityWarningsList extends StatelessWidget {
  /// Güvenlik uyarıları listesi
  final List<SecurityWarning> warnings;

  /// Uyarı kapatma callback'i
  final void Function(SecurityWarning)? onDismissWarning;

  /// Uyarı detay gösterme callback'i
  final void Function(SecurityWarning)? onShowWarningDetails;

  /// Maksimum gösterilecek uyarı sayısı
  final int? maxWarnings;

  const SecurityWarningsList({
    super.key,
    required this.warnings,
    this.onDismissWarning,
    this.onShowWarningDetails,
    this.maxWarnings,
  });

  @override
  Widget build(BuildContext context) {
    if (warnings.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayWarnings =
        maxWarnings != null && warnings.length > maxWarnings!
        ? warnings.take(maxWarnings!).toList()
        : warnings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Güvenlik Uyarıları (${warnings.length})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        ...displayWarnings.map(
          (warning) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: SecurityWarningWidget(
              warning: warning,
              onDismiss: onDismissWarning != null
                  ? () => onDismissWarning!(warning)
                  : null,
              onShowDetails: onShowWarningDetails != null
                  ? () => onShowWarningDetails!(warning)
                  : null,
            ),
          ),
        ),

        if (maxWarnings != null && warnings.length > maxWarnings!) ...[
          TextButton(
            onPressed: () {
              // Tüm uyarıları göster
            },
            child: Text('${warnings.length - maxWarnings!} uyarı daha göster'),
          ),
        ],
      ],
    );
  }
}

/// Güvenlik durumu özet kartı
///
/// Genel güvenlik durumunu özetleyen kart widget'ı.
///
/// Implements Requirement 10.1: Güvenlik dashboard açıldığında güvenlik durumu özetini göstermeli
class SecurityStatusCard extends StatelessWidget {
  /// Güvenlik durumu
  final SecurityStatus status;

  /// Kimlik doğrulama durumu
  final AuthState? authState;

  /// Detay gösterme callback'i
  final VoidCallback? onShowDetails;

  const SecurityStatusCard({
    super.key,
    required this.status,
    this.authState,
    this.onShowDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Güvenlik Durumu',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Son Kontrol: ${_formatDateTime(status.lastSecurityCheck)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                SecurityLevelIndicator(
                  level: status.securityLevel,
                  size: 60,
                  showDescription: false,
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Güvenlik özellikleri
            _buildSecurityFeature(
              'Cihaz Güvenliği',
              status.isDeviceSecure,
              Icons.phone_android,
            ),
            const SizedBox(height: 8),
            _buildSecurityFeature(
              'Ekran Görüntüsü Koruması',
              status.isScreenshotBlocked,
              Icons.screenshot,
            ),
            const SizedBox(height: 8),
            _buildSecurityFeature(
              'Arka Plan Bulanıklaştırma',
              status.isBackgroundBlurEnabled,
              Icons.blur_on,
            ),
            const SizedBox(height: 8),
            _buildSecurityFeature(
              'Clipboard Güvenliği',
              status.isClipboardSecurityEnabled,
              Icons.content_paste,
            ),

            if (authState != null && authState!.isAuthenticated) ...[
              const SizedBox(height: 8),
              _buildAuthInfo(authState!),
            ],

            if (status.isRootDetected) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Root/Jailbreak tespit edildi!',
                        style: TextStyle(
                          color: Colors.red[900],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (onShowDetails != null) ...[
              const SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  onPressed: onShowDetails,
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Detaylı Bilgi'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityFeature(String title, bool enabled, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: enabled ? Colors.green : Colors.grey),
        const SizedBox(width: 8),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 14))),
        Icon(
          enabled ? Icons.check_circle : Icons.cancel,
          size: 20,
          color: enabled ? Colors.green : Colors.grey,
        ),
      ],
    );
  }

  Widget _buildAuthInfo(AuthState authState) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user, color: Colors.green[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Oturum Aktif',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[900],
                  ),
                ),
                if (authState.authMethod != null)
                  Text(
                    'Yöntem: ${authState.authMethod!.displayName}',
                    style: TextStyle(fontSize: 12, color: Colors.green[700]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Az önce';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    } else {
      return '${difference.inDays} gün önce';
    }
  }
}
