import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/backup_optimization/backup_enums.dart' hide BackupResult;

import '../../services/backup_optimization/enhanced_backup_manager.dart';
import '../../services/backup_optimization/performance_service.dart';

/// Widget for displaying real-time backup progress and status
class BackupProgressWidget extends StatefulWidget {
  final String? operationId;
  final Function(BackupResult)? onBackupComplete;
  final Function(String)? onError;
  final bool showDetailedMetrics;

  const BackupProgressWidget({
    super.key,
    this.operationId,
    this.onBackupComplete,
    this.onError,
    this.showDetailedMetrics = true,
  });

  @override
  State<BackupProgressWidget> createState() => _BackupProgressWidgetState();
}

class _BackupProgressWidgetState extends State<BackupProgressWidget>
    with TickerProviderStateMixin {
  final EnhancedBackupManager _backupManager = EnhancedBackupManager();
  final PerformanceService _performanceService = PerformanceService();

  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;

  BackupProgressState _state = BackupProgressState.idle;
  double _progress = 0.0;
  String _currentStep = '';
  String? _errorMessage;
  BackupMetrics? _currentMetrics;
  Duration _elapsedTime = Duration.zero;
  Timer? _timer;
  String? _trackingId;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startElapsedTimer();
  }

  void _initializeAnimations() {
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
  }

  void _startElapsedTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_state == BackupProgressState.inProgress) {
        setState(() {
          _elapsedTime = Duration(seconds: _elapsedTime.inSeconds + 1);
        });
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  /// Start a backup operation with progress tracking
  Future<void> startBackup(BackupType type) async {
    setState(() {
      _state = BackupProgressState.inProgress;
      _progress = 0.0;
      _currentStep = 'Yedekleme başlatılıyor...';
      _errorMessage = null;
      _elapsedTime = Duration.zero;
    });

    try {
      // Start performance tracking
      _trackingId = await _performanceService.startMetricsCollection(
        'backup_${type.name}_${DateTime.now().millisecondsSinceEpoch}',
      );

      // Simulate backup steps with progress updates
      await _simulateBackupProgress(type);

      // Complete the backup
      final result = await _completeBackup(type);

      setState(() {
        _state = BackupProgressState.completed;
        _progress = 1.0;
        _currentStep = 'Yedekleme tamamlandı';
      });

      widget.onBackupComplete?.call(result);
    } catch (e) {
      setState(() {
        _state = BackupProgressState.error;
        _errorMessage = e.toString();
        _currentStep = 'Yedekleme başarısız';
      });

      widget.onError?.call(e.toString());
    }
  }

  Future<void> _simulateBackupProgress(BackupType type) async {
    final steps = _getBackupSteps(type);

    for (int i = 0; i < steps.length; i++) {
      setState(() {
        _currentStep = steps[i];
        _progress = (i + 1) / steps.length;
      });

      _progressController.animateTo(_progress);

      // Simulate step duration
      await Future.delayed(Duration(milliseconds: 500 + (i * 200)));

      // Update metrics periodically
      if (i % 2 == 0 && _trackingId != null) {
        await _updateCurrentMetrics();
      }
    }
  }

  List<String> _getBackupSteps(BackupType type) {
    switch (type) {
      case BackupType.full:
        return [
          'Veriler toplanıyor...',
          'Tam yedekleme hazırlanıyor...',
          'Veriler sıkıştırılıyor...',
          'Bütünlük kontrolü yapılıyor...',
          'Buluta yükleniyor...',
          'Doğrulama yapılıyor...',
        ];
      case BackupType.incremental:
        return [
          'Değişiklikler tespit ediliyor...',
          'Delta hesaplanıyor...',
          'Artımlı paket oluşturuluyor...',
          'Sıkıştırma uygulanıyor...',
          'Buluta yükleniyor...',
        ];
      case BackupType.custom:
        return [
          'Seçili kategoriler toplanıyor...',
          'Özel yedekleme hazırlanıyor...',
          'Veriler optimize ediliyor...',
          'Buluta yükleniyor...',
        ];
    }
  }

  Future<void> _updateCurrentMetrics() async {
    if (_trackingId == null) return;

    try {
      // In a real implementation, this would get live metrics
      // For now, we'll simulate some metrics
      setState(() {
        _currentMetrics = BackupMetrics(
          operationId: _trackingId!,
          startTime: DateTime.now().subtract(_elapsedTime),
          endTime: DateTime.now(),
          totalDuration: _elapsedTime,
          compressionTime: Duration(
            seconds: (_elapsedTime.inSeconds * 0.3).round(),
          ),
          uploadTime: Duration(seconds: (_elapsedTime.inSeconds * 0.5).round()),
          validationTime: Duration(
            seconds: (_elapsedTime.inSeconds * 0.1).round(),
          ),
          networkRetries: 0,
          averageUploadSpeed:
              2.5 + (_progress * 1.5), // Simulate increasing speed
          memoryUsage: ((50 + (_progress * 100)) * 1024 * 1024)
              .toInt(), // MB to bytes
          cpuIntensiveDuration: Duration(
            seconds: (_elapsedTime.inSeconds * 0.8).round(),
          ),
          networkBytesTransferred: ((_progress * 50) * 1024 * 1024)
              .round(), // MB to bytes
          successRate: 1.0,
        );
      });
    } catch (e) {
      debugPrint('Error updating metrics: $e');
    }
  }

  Future<BackupResult> _completeBackup(BackupType type) async {
    // Stop performance tracking
    if (_trackingId != null) {
      _currentMetrics = await _performanceService.stopMetricsCollection(
        _trackingId!,
      );
    }

    // In a real implementation, this would call the actual backup manager
    return BackupResult(
      success: true,
      backupId: 'backup_${DateTime.now().millisecondsSinceEpoch}',
      duration: _elapsedTime,
      originalSize: 1024 * 1024 * 10, // 10MB
      compressedSize: 1024 * 1024 * 7, // 7MB
    );
  }

  /// Cancel the current backup operation
  void cancelBackup() {
    setState(() {
      _state = BackupProgressState.cancelled;
      _currentStep = 'Yedekleme iptal edildi';
    });

    _timer?.cancel();
  }

  /// Retry the backup operation
  Future<void> retryBackup() async {
    if (_state == BackupProgressState.error) {
      // Get the last attempted backup type (would be stored in real implementation)
      await startBackup(BackupType.full);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildProgressSection(),
            if (widget.showDetailedMetrics && _currentMetrics != null) ...[
              const SizedBox(height: 16),
              _buildMetricsSection(),
            ],
            if (_state == BackupProgressState.error) ...[
              const SizedBox(height: 16),
              _buildErrorSection(),
            ],
            const SizedBox(height: 16),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _state == BackupProgressState.inProgress
                  ? _pulseAnimation.value
                  : 1.0,
              child: Icon(_getStateIcon(), color: _getStateColor(), size: 24),
            );
          },
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getStateTitle(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _currentStep,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        if (_state == BackupProgressState.inProgress)
          Text(
            _formatDuration(_elapsedTime),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
      ],
    );
  }

  Widget _buildProgressSection() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return LinearProgressIndicator(
              value: _state == BackupProgressState.inProgress
                  ? _progressAnimation.value
                  : (_state == BackupProgressState.completed ? 1.0 : 0.0),
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(_getStateColor()),
              minHeight: 8,
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(_progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            if (_state == BackupProgressState.completed &&
                _currentMetrics != null)
              Text(
                'Sıkıştırma: ${((_currentMetrics!.networkBytesTransferred * 0.6) / _currentMetrics!.networkBytesTransferred * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricsSection() {
    final metrics = _currentMetrics!;

    return Card(
      color: Colors.grey.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Anlık Performans',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Hız',
                    '${metrics.averageUploadSpeed.toStringAsFixed(1)} MB/s',
                    Icons.speed,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Veri',
                    '${(metrics.networkBytesTransferred / (1024 * 1024)).toStringAsFixed(1)} MB',
                    Icons.data_usage,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Bellek',
                    '${(metrics.memoryUsage / (1024 * 1024)).toStringAsFixed(0)} MB',
                    Icons.memory,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF00BFA5)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildErrorSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text(
                'Hata Detayları',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Bilinmeyen hata oluştu',
            style: const TextStyle(fontSize: 12, color: Colors.red),
          ),
          const SizedBox(height: 8),
          _buildErrorRecoveryOptions(),
        ],
      ),
    );
  }

  Widget _buildErrorRecoveryOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Önerilen Çözümler:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 4),
        ..._getRecoveryOptions().map(
          (option) => Padding(
            padding: const EdgeInsets.only(left: 8, top: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(color: Colors.red)),
                Expanded(
                  child: Text(
                    option,
                    style: const TextStyle(fontSize: 11, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<String> _getRecoveryOptions() {
    // In a real implementation, this would analyze the error and provide specific solutions
    return [
      'İnternet bağlantınızı kontrol edin',
      'Depolama alanınızın yeterli olduğundan emin olun',
      'Uygulamayı yeniden başlatmayı deneyin',
      'Daha sonra tekrar deneyin',
    ];
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (_state == BackupProgressState.inProgress) ...[
          TextButton(onPressed: cancelBackup, child: const Text('İptal Et')),
        ] else if (_state == BackupProgressState.error) ...[
          TextButton(onPressed: retryBackup, child: const Text('Tekrar Dene')),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => startBackup(BackupType.full),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BFA5),
              foregroundColor: Colors.white,
            ),
            child: const Text('Yeni Yedekleme'),
          ),
        ] else if (_state == BackupProgressState.idle) ...[
          ElevatedButton(
            onPressed: () => startBackup(BackupType.full),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BFA5),
              foregroundColor: Colors.white,
            ),
            child: const Text('Yedekleme Başlat'),
          ),
        ],
      ],
    );
  }

  IconData _getStateIcon() {
    switch (_state) {
      case BackupProgressState.idle:
        return Icons.backup;
      case BackupProgressState.inProgress:
        return Icons.cloud_upload;
      case BackupProgressState.completed:
        return Icons.check_circle;
      case BackupProgressState.error:
        return Icons.error;
      case BackupProgressState.cancelled:
        return Icons.cancel;
    }
  }

  Color _getStateColor() {
    switch (_state) {
      case BackupProgressState.idle:
        return Colors.grey;
      case BackupProgressState.inProgress:
        return const Color(0xFF00BFA5);
      case BackupProgressState.completed:
        return Colors.green;
      case BackupProgressState.error:
        return Colors.red;
      case BackupProgressState.cancelled:
        return Colors.orange;
    }
  }

  String _getStateTitle() {
    switch (_state) {
      case BackupProgressState.idle:
        return 'Yedekleme Hazır';
      case BackupProgressState.inProgress:
        return 'Yedekleme Devam Ediyor';
      case BackupProgressState.completed:
        return 'Yedekleme Tamamlandı';
      case BackupProgressState.error:
        return 'Yedekleme Başarısız';
      case BackupProgressState.cancelled:
        return 'Yedekleme İptal Edildi';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}:${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}';
    } else {
      return '${duration.inMinutes}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}';
    }
  }
}

/// Enum for backup progress states
enum BackupProgressState { idle, inProgress, completed, error, cancelled }
