// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/security/security_models.dart';
import '../../services/auth/security_service.dart';
import '../../services/auth/audit_logger_service.dart';
import '../../services/auth/auth_service.dart';

class SecurityDashboardScreen extends StatefulWidget {
  const SecurityDashboardScreen({super.key});

  @override
  State<SecurityDashboardScreen> createState() =>
      _SecurityDashboardScreenState();
}

class _SecurityDashboardScreenState extends State<SecurityDashboardScreen> {
  final SecurityService _securityService = SecurityService();
  final AuditLoggerService _auditLogger = AuditLoggerService();
  final AuthService _authService = AuthService();

  SecurityStatus? _securityStatus;
  List<SecurityEvent> _recentEvents = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  /// Dashboard verilerini yükler
  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Güvenlik durumunu al
      final status = await _securityService.getSecurityStatus();

      // Son güvenlik olaylarını al
      final events = await _auditLogger.getSecurityHistory(
        limit: 10,
        startDate: DateTime.now().subtract(const Duration(days: 7)),
      );

      setState(() {
        _securityStatus = status;
        _recentEvents = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Güvenlik verileri yüklenirken hata oluştu: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  /// Güvenlik durumunu yeniler
  Future<void> _refreshSecurityStatus() async {
    await HapticFeedback.lightImpact();
    await _loadDashboardData();
  }

  /// Güvenlik önerilerini oluşturur
  List<SecurityRecommendation> _generateRecommendations() {
    if (_securityStatus == null) return [];

    final recommendations = <SecurityRecommendation>[];

    // Root/jailbreak uyarısı
    if (_securityStatus!.isRootDetected) {
      recommendations.add(
        SecurityRecommendation(
          title: 'Kritik Güvenlik Riski',
          description:
              'Cihazınızda root/jailbreak tespit edildi. Bu durum uygulamanın güvenliğini ciddi şekilde tehlikeye atar.',
          severity: SecurityRecommendationSeverity.critical,
          action: 'Cihazınızı fabrika ayarlarına döndürmeyi düşünün',
          icon: Icons.warning,
        ),
      );
    }

    // Cihaz güvenliği
    if (!_securityStatus!.isDeviceSecure) {
      recommendations.add(
        SecurityRecommendation(
          title: 'Cihaz Güvenliği',
          description: 'Cihazınızda ekran kilidi veya güvenlik ayarları eksik.',
          severity: SecurityRecommendationSeverity.high,
          action: 'Cihaz ayarlarından güvenlik özelliklerini etkinleştirin',
          icon: Icons.lock_open,
        ),
      );
    }

    // Ekran görüntüsü engelleme
    if (!_securityStatus!.isScreenshotBlocked) {
      recommendations.add(
        SecurityRecommendation(
          title: 'Ekran Görüntüsü Koruması',
          description:
              'Ekran görüntüsü engelleme devre dışı. Hassas bilgileriniz risk altında.',
          severity: SecurityRecommendationSeverity.medium,
          action: 'Ekran görüntüsü engellemeyi etkinleştirin',
          icon: Icons.screenshot_monitor,
        ),
      );
    }

    // Clipboard güvenliği
    if (!_securityStatus!.isClipboardSecurityEnabled) {
      recommendations.add(
        SecurityRecommendation(
          title: 'Clipboard Güvenliği',
          description:
              'Clipboard güvenliği devre dışı. Kopyalanan veriler güvende değil.',
          severity: SecurityRecommendationSeverity.medium,
          action: 'Clipboard güvenliğini etkinleştirin',
          icon: Icons.content_paste,
        ),
      );
    }

    // Arka plan bulanıklaştırma
    if (!_securityStatus!.isBackgroundBlurEnabled) {
      recommendations.add(
        SecurityRecommendation(
          title: 'Arka Plan Koruması',
          description: 'Uygulama geçmişinde içerik görünebilir.',
          severity: SecurityRecommendationSeverity.low,
          action: 'Arka plan bulanıklaştırmayı etkinleştirin',
          icon: Icons.blur_on,
        ),
      );
    }

    // Kritik uyarılar varsa
    if (_securityStatus!.hasCriticalWarnings) {
      recommendations.add(
        SecurityRecommendation(
          title: 'Kritik Güvenlik Uyarıları',
          description:
              'Acil müdahale gerektiren güvenlik sorunları tespit edildi.',
          severity: SecurityRecommendationSeverity.critical,
          action: 'Güvenlik uyarılarını inceleyin ve gerekli aksiyonları alın',
          icon: Icons.error,
        ),
      );
    }

    // Güvenlik seviyesi düşükse
    if (_securityStatus!.securityLevel == SecurityLevel.low) {
      recommendations.add(
        SecurityRecommendation(
          title: 'Genel Güvenlik Seviyesi',
          description:
              'Güvenlik seviyeniz düşük. Tüm güvenlik özelliklerini gözden geçirin.',
          severity: SecurityRecommendationSeverity.high,
          action: 'Güvenlik ayarlarını kontrol edin ve güncelleyin',
          icon: Icons.security,
        ),
      );
    }

    return recommendations;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Güvenlik Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshSecurityStatus,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorWidget()
          : _buildDashboardContent(),
    );
  }

  /// Hata widget'ı oluşturur
  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Hata', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshSecurityStatus,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  /// Dashboard içeriğini oluşturur
  Widget _buildDashboardContent() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSecurityStatusCard(),
            const SizedBox(height: 16),
            _buildQuickActionsCard(),
            const SizedBox(height: 16),
            _buildRecommendationsCard(),
            const SizedBox(height: 16),
            _buildRecentEventsCard(),
          ],
        ),
      ),
    );
  }

  /// Güvenlik durumu kartını oluşturur
  Widget _buildSecurityStatusCard() {
    if (_securityStatus == null) return const SizedBox.shrink();

    final status = _securityStatus!;
    final levelColor = Color(status.securityLevel.color);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getSecurityLevelIcon(status.securityLevel),
                  color: levelColor,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Güvenlik Durumu',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        status.securityLevel.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: levelColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSecurityMetrics(status),
            if (status.warnings.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildWarningsSection(status.warnings),
            ],
          ],
        ),
      ),
    );
  }

  /// Güvenlik metrikleri oluşturur
  Widget _buildSecurityMetrics(SecurityStatus status) {
    return Column(
      children: [
        _buildMetricRow(
          'Cihaz Güvenliği',
          status.isDeviceSecure,
          Icons.phone_android,
        ),
        _buildMetricRow(
          'Ekran Koruması',
          status.isScreenshotBlocked,
          Icons.screenshot_monitor,
        ),
        _buildMetricRow(
          'Arka Plan Koruması',
          status.isBackgroundBlurEnabled,
          Icons.blur_on,
        ),
        _buildMetricRow(
          'Clipboard Güvenliği',
          status.isClipboardSecurityEnabled,
          Icons.content_paste,
        ),
        _buildMetricRow(
          'Root/Jailbreak',
          !status.isRootDetected,
          Icons.security,
          isInverted: true,
        ),
      ],
    );
  }

  /// Metrik satırı oluşturur
  Widget _buildMetricRow(
    String title,
    bool isSecure,
    IconData icon, {
    bool isInverted = false,
  }) {
    final color = isSecure ? Colors.green : Colors.red;
    final statusText = isSecure ? 'Güvenli' : 'Risk';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Uyarılar bölümü oluşturur
  Widget _buildWarningsSection(List<SecurityWarning> warnings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Güvenlik Uyarıları',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: Colors.orange[700]),
        ),
        const SizedBox(height: 8),
        ...warnings.take(3).map((warning) => _buildWarningItem(warning)),
        if (warnings.length > 3)
          TextButton(
            onPressed: () {
              // Tüm uyarıları göster
              _showAllWarnings(warnings);
            },
            child: Text('${warnings.length - 3} uyarı daha...'),
          ),
      ],
    );
  }

  /// Uyarı öğesi oluşturur
  Widget _buildWarningItem(SecurityWarning warning) {
    final severityColor = Color(_getSeverityColor(warning.severity));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning, size: 16, color: severityColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              warning.message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: severityColor),
            ),
          ),
        ],
      ),
    );
  }

  /// Hızlı aksiyonlar kartını oluşturur
  Widget _buildQuickActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hızlı Aksiyonlar',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickActionChip(
                  'Güvenlik Taraması',
                  Icons.security,
                  () => _performSecurityScan(),
                ),
                _buildQuickActionChip(
                  'Güvenlik Ayarları',
                  Icons.settings_applications,
                  () => _openSecuritySettings(),
                ),
                _buildQuickActionChip(
                  'Olay Geçmişi',
                  Icons.history,
                  () => _showEventHistory(),
                ),
                _buildQuickActionChip(
                  'Güvenlik Raporu',
                  Icons.assessment,
                  () => _generateSecurityReport(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Hızlı aksiyon chip'i oluşturur
  Widget _buildQuickActionChip(
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onPressed,
    );
  }

  /// Öneriler kartını oluşturur
  Widget _buildRecommendationsCard() {
    final recommendations = _generateRecommendations();

    if (recommendations.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 48),
              const SizedBox(height: 8),
              Text(
                'Güvenlik Durumu İyi',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Şu anda herhangi bir güvenlik önerisi bulunmuyor.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Güvenlik Önerileri',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...recommendations
                .take(3)
                .map((rec) => _buildRecommendationItem(rec)),
            if (recommendations.length > 3)
              TextButton(
                onPressed: () => _showAllRecommendations(recommendations),
                child: Text('${recommendations.length - 3} öneri daha...'),
              ),
          ],
        ),
      ),
    );
  }

  /// Öneri öğesi oluşturur
  Widget _buildRecommendationItem(SecurityRecommendation recommendation) {
    final severityColor = Color(
      _getRecommendationSeverityColor(recommendation.severity),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(recommendation.icon, color: severityColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: severityColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  recommendation.description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  recommendation.action,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: severityColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Son olaylar kartını oluşturur
  Widget _buildRecentEventsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Son Güvenlik Olayları',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: _showEventHistory,
                  child: const Text('Tümünü Gör'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_recentEvents.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Henüz güvenlik olayı bulunmuyor.'),
                ),
              )
            else
              ..._recentEvents.take(5).map((event) => _buildEventItem(event)),
          ],
        ),
      ),
    );
  }

  /// Olay öğesi oluşturur
  Widget _buildEventItem(SecurityEvent event) {
    final severityColor = Color(event.severity.color);
    final timeAgo = _formatTimeAgo(event.timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: severityColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      event.type.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: severityColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• $timeAgo',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Güvenlik seviyesi ikonu alır
  IconData _getSecurityLevelIcon(SecurityLevel level) {
    switch (level) {
      case SecurityLevel.critical:
        return Icons.error;
      case SecurityLevel.low:
        return Icons.warning;
      case SecurityLevel.medium:
        return Icons.info;
      case SecurityLevel.high:
        return Icons.check_circle;
    }
  }

  /// Şiddet rengi alır
  int _getSeverityColor(SecurityWarningSeverity severity) {
    switch (severity) {
      case SecurityWarningSeverity.low:
        return 0xFF2196F3; // Blue
      case SecurityWarningSeverity.medium:
        return 0xFFFF9800; // Orange
      case SecurityWarningSeverity.high:
        return 0xFFFF5722; // Red
      case SecurityWarningSeverity.critical:
        return 0xFFD32F2F; // Dark Red
    }
  }

  /// Öneri şiddet rengi alır
  int _getRecommendationSeverityColor(SecurityRecommendationSeverity severity) {
    switch (severity) {
      case SecurityRecommendationSeverity.low:
        return 0xFF2196F3; // Blue
      case SecurityRecommendationSeverity.medium:
        return 0xFFFF9800; // Orange
      case SecurityRecommendationSeverity.high:
        return 0xFFFF5722; // Red
      case SecurityRecommendationSeverity.critical:
        return 0xFFD32F2F; // Dark Red
    }
  }

  /// Zaman farkını formatlar
  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Az önce';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} saat önce';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  /// Güvenlik taraması yapar
  Future<void> _performSecurityScan() async {
    // Capture context before async operations
    final currentContext = context;

    await HapticFeedback.lightImpact();

    if (!mounted) return;

    showDialog(
      context: currentContext,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Güvenlik taraması yapılıyor...'),
          ],
        ),
      ),
    );

    try {
      // Güvenlik durumunu yenile
      await _securityService.getSecurityStatus();
      await _loadDashboardData();

      // Check if widget is still mounted before using context
      if (!currentContext.mounted) return;
      Navigator.of(currentContext).pop(); // Dialog'u kapat

      if (!currentContext.mounted) return;
      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(
          content: Text('Güvenlik taraması tamamlandı'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Check if widget is still mounted before using context
      if (!currentContext.mounted) return;
      Navigator.of(currentContext).pop(); // Dialog'u kapat

      if (!currentContext.mounted) return;
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(
          content: Text('Güvenlik taraması başarısız: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Güvenlik ayarlarını açar
  void _openSecuritySettings() {
    Navigator.of(context).pushNamed('/security/settings');
  }

  /// Olay geçmişini gösterir
  void _showEventHistory() {
    Navigator.of(context).pushNamed('/security/events');
  }

  /// Güvenlik raporu oluşturur
  Future<void> _generateSecurityReport() async {
    // Capture context before async operations
    final currentContext = context;

    await HapticFeedback.lightImpact();

    if (!mounted) return;

    try {
      showDialog(
        context: currentContext,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Güvenlik raporu oluşturuluyor...'),
            ],
          ),
        ),
      );

      final report = await _auditLogger.generateSecurityReport(
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
      );

      // Check if widget is still mounted before using context
      if (!currentContext.mounted) return;
      Navigator.of(currentContext).pop(); // Dialog'u kapat

      // Raporu göster
      _showSecurityReport(report);
    } catch (e) {
      // Check if widget is still mounted before using context
      if (!currentContext.mounted) return;
      Navigator.of(currentContext).pop(); // Dialog'u kapat

      if (!currentContext.mounted) return;
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(
          content: Text('Rapor oluşturulamadı: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Tüm uyarıları gösterir
  void _showAllWarnings(List<SecurityWarning> warnings) {
    // Capture context before async operations
    final currentContext = context;
    showDialog(
      context: currentContext,
      builder: (context) => AlertDialog(
        title: const Text('Güvenlik Uyarıları'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: warnings.length,
            itemBuilder: (context, index) {
              final warning = warnings[index];
              return ListTile(
                leading: Icon(
                  Icons.warning,
                  color: Color(_getSeverityColor(warning.severity)),
                ),
                title: Text(warning.message),
                subtitle: warning.description != null
                    ? Text(warning.description!)
                    : null,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (!currentContext.mounted) return;
              Navigator.of(currentContext).pop();
            },
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  /// Tüm önerileri gösterir
  void _showAllRecommendations(List<SecurityRecommendation> recommendations) {
    // Capture context before async operations
    final currentContext = context;
    showDialog(
      context: currentContext,
      builder: (context) => AlertDialog(
        title: const Text('Güvenlik Önerileri'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: recommendations.length,
            itemBuilder: (context, index) {
              final rec = recommendations[index];
              return ListTile(
                leading: Icon(
                  rec.icon,
                  color: Color(_getRecommendationSeverityColor(rec.severity)),
                ),
                title: Text(rec.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rec.description),
                    const SizedBox(height: 4),
                    Text(
                      rec.action,
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (!currentContext.mounted) return;
              Navigator.of(currentContext).pop();
            },
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  /// Güvenlik raporunu gösterir
  void _showSecurityReport(SecurityReport report) {
    // Capture context before async operations
    final currentContext = context;
    showDialog(
      context: currentContext,
      builder: (context) => AlertDialog(
        title: const Text('Güvenlik Raporu'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Rapor Dönemi: ${_formatDate(report.startDate)} - ${_formatDate(report.endDate)}',
                ),
                const SizedBox(height: 8),
                Text('Toplam Olay: ${report.totalEvents}'),
                const SizedBox(height: 16),
                const Text(
                  'İstatistikler:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...report.statistics.entries.map((entry) {
                  if (entry.value is Map) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${entry.key}:'),
                        ...(entry.value as Map).entries.map(
                          (subEntry) => Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Text('${subEntry.key}: ${subEntry.value}'),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    );
                  } else {
                    return Text('${entry.key}: ${entry.value}');
                  }
                }),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (!currentContext.mounted) return;
              Navigator.of(currentContext).pop();
            },
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  /// Tarihi formatlar
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Güvenlik önerisi modeli
class SecurityRecommendation {
  final String title;
  final String description;
  final SecurityRecommendationSeverity severity;
  final String action;
  final IconData icon;

  const SecurityRecommendation({
    required this.title,
    required this.description,
    required this.severity,
    required this.action,
    required this.icon,
  });
}

/// Güvenlik önerisi şiddeti
enum SecurityRecommendationSeverity { low, medium, high, critical }
