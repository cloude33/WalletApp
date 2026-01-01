import 'package:flutter/material.dart';
import '../../models/backup_optimization/backup_config.dart';
import '../../models/backup_optimization/backup_enums.dart';
import '../../services/backup_optimization/enhanced_backup_manager.dart';
import '../../services/backup_optimization/performance_service.dart';

/// Widget for backup strategy selection and configuration
class BackupSettingsWidget extends StatefulWidget {
  final BackupConfig? initialConfig;
  final Function(BackupConfig)? onConfigChanged;
  final bool showPerformanceMetrics;

  const BackupSettingsWidget({
    super.key,
    this.initialConfig,
    this.onConfigChanged,
    this.showPerformanceMetrics = true,
  });

  @override
  State<BackupSettingsWidget> createState() => _BackupSettingsWidgetState();
}

class _BackupSettingsWidgetState extends State<BackupSettingsWidget> {
  final EnhancedBackupManager _backupManager = EnhancedBackupManager();
  final PerformanceService _performanceService = PerformanceService();

  late BackupConfig _config;
  BackupMetrics? _latestMetrics;
  PerformanceTrendAnalysis? _trendAnalysis;
  List<OptimizationRecommendation> _recommendations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig ?? BackupConfig.full();
    _loadPerformanceData();
  }

  Future<void> _loadPerformanceData() async {
    if (!widget.showPerformanceMetrics) return;

    setState(() => _isLoading = true);

    try {
      _trendAnalysis = await _performanceService.analyzePerformanceTrends();
      _recommendations = await _performanceService
          .generateOptimizationRecommendations();

      // Get latest metrics if available
      final history = _performanceService.metricsHistory;
      if (history.isNotEmpty) {
        _latestMetrics = history.last;
      }
    } catch (e) {
      debugPrint('Error loading performance data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateConfig(BackupConfig newConfig) {
    setState(() => _config = newConfig);
    widget.onConfigChanged?.call(newConfig);
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
            _buildStrategySelection(),
            const SizedBox(height: 16),
            _buildDataCategorySelection(),
            const SizedBox(height: 16),
            _buildCompressionSettings(),
            const SizedBox(height: 16),
            _buildAdvancedSettings(),
            if (widget.showPerformanceMetrics) ...[
              const SizedBox(height: 24),
              _buildPerformanceSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.settings, color: Color(0xFF00BFA5)),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Yedekleme Ayarları',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Yedekleme stratejinizi ve tercihlerinizi yapılandırın',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadPerformanceData,
          tooltip: 'Performans verilerini yenile',
        ),
      ],
    );
  }

  Widget _buildStrategySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Yedekleme Stratejisi',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        RadioGroup<BackupType>(
          groupValue: _config.type,
          onChanged: (value) {
            if (value != null) {
              _updateConfig(_config.copyWith(type: value));
            }
          },
          child: Column(
            children: BackupType.values
                .map((type) => _buildStrategyOption(type))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStrategyOption(BackupType type) {
    final isSelected = _config.type == type;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? const Color(0xFF00BFA5).withValues(alpha: 0.1) : null,
      child: RadioListTile<BackupType>(
        value: type,
        title: Text(
          type.displayName,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: Text(_getStrategyDescription(type)),
        secondary: Icon(
          _getStrategyIcon(type),
          color: isSelected ? const Color(0xFF00BFA5) : Colors.grey,
        ),
        activeColor: const Color(0xFF00BFA5),
      ),
    );
  }

  String _getStrategyDescription(BackupType type) {
    switch (type) {
      case BackupType.full:
        return 'Tüm verilerinizi yedekler (en güvenli)';
      case BackupType.incremental:
        return 'Sadece değişen verileri yedekler (hızlı)';
      case BackupType.custom:
        return 'Seçtiğiniz kategorileri yedekler (esnek)';
    }
  }

  IconData _getStrategyIcon(BackupType type) {
    switch (type) {
      case BackupType.full:
        return Icons.backup;
      case BackupType.incremental:
        return Icons.update;
      case BackupType.custom:
        return Icons.tune;
    }
  }

  Widget _buildDataCategorySelection() {
    if (_config.type != BackupType.custom) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Yedeklenecek Veriler',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: DataCategory.values.map((category) {
            final isSelected = _config.includedCategories.contains(category);
            return FilterChip(
              label: Text(category.displayName),
              selected: isSelected,
              onSelected: (selected) {
                final categories = List<DataCategory>.from(
                  _config.includedCategories,
                );
                if (selected) {
                  categories.add(category);
                } else {
                  categories.remove(category);
                }
                _updateConfig(_config.copyWith(includedCategories: categories));
              },
              selectedColor: const Color(0xFF00BFA5).withValues(alpha: 0.2),
              checkmarkColor: const Color(0xFF00BFA5),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCompressionSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sıkıştırma Seviyesi',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SegmentedButton<CompressionLevel>(
          segments: CompressionLevel.values.map((level) {
            return ButtonSegment<CompressionLevel>(
              value: level,
              label: Text(_getCompressionLevelName(level)),
              icon: Icon(_getCompressionLevelIcon(level)),
            );
          }).toList(),
          selected: {_config.compressionLevel},
          onSelectionChanged: (selection) {
            if (selection.isNotEmpty) {
              _updateConfig(
                _config.copyWith(compressionLevel: selection.first),
              );
            }
          },
        ),
        const SizedBox(height: 4),
        Text(
          _getCompressionLevelDescription(_config.compressionLevel),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  String _getCompressionLevelName(CompressionLevel level) {
    switch (level) {
      case CompressionLevel.fast:
        return 'Hızlı';
      case CompressionLevel.balanced:
        return 'Dengeli';
      case CompressionLevel.maximum:
        return 'Maksimum';
    }
  }

  IconData _getCompressionLevelIcon(CompressionLevel level) {
    switch (level) {
      case CompressionLevel.fast:
        return Icons.speed;
      case CompressionLevel.balanced:
        return Icons.balance;
      case CompressionLevel.maximum:
        return Icons.compress;
    }
  }

  String _getCompressionLevelDescription(CompressionLevel level) {
    switch (level) {
      case CompressionLevel.fast:
        return 'Hızlı yedekleme, orta sıkıştırma';
      case CompressionLevel.balanced:
        return 'Hız ve sıkıştırma dengesi';
      case CompressionLevel.maximum:
        return 'En iyi sıkıştırma, daha yavaş';
    }
  }

  Widget _buildAdvancedSettings() {
    return ExpansionTile(
      title: const Text('Gelişmiş Ayarlar'),
      leading: const Icon(Icons.settings_applications),
      children: [
        SwitchListTile(
          title: const Text('Doğrulama Etkin'),
          subtitle: const Text('Yedek bütünlüğünü kontrol et'),
          value: _config.enableValidation,
          onChanged: (value) {
            _updateConfig(_config.copyWith(enableValidation: value));
          },
          secondary: const Icon(Icons.verified_user),
        ),
        ListTile(
          title: const Text('Saklama Politikası'),
          subtitle: Text(
            '${_config.retentionPolicy.maxBackupCount} yedek, '
            '${_config.retentionPolicy.maxAge.inDays} gün',
          ),
          leading: const Icon(Icons.storage),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showRetentionPolicyDialog(),
        ),
      ],
    );
  }

  Widget _buildPerformanceSection() {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Performans Metrikleri',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (_latestMetrics != null) _buildMetricsCard(),
        if (_trendAnalysis != null) _buildTrendAnalysisCard(),
        if (_recommendations.isNotEmpty) _buildRecommendationsCard(),
      ],
    );
  }

  Widget _buildMetricsCard() {
    final metrics = _latestMetrics!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Son Yedekleme Metrikleri',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Süre',
                    _formatDuration(metrics.totalDuration),
                    Icons.timer,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Başarı Oranı',
                    '${(metrics.successRate * 100).toStringAsFixed(1)}%',
                    Icons.check_circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Yükleme Hızı',
                    '${metrics.averageUploadSpeed.toStringAsFixed(1)} MB/s',
                    Icons.upload,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Yeniden Deneme',
                    '${metrics.networkRetries}',
                    Icons.refresh,
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
        Icon(icon, size: 24, color: const Color(0xFF00BFA5)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildTrendAnalysisCard() {
    final analysis = _trendAnalysis!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performans Trendi',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  _getTrendIcon(analysis.trend),
                  color: _getTrendColor(analysis.trend),
                ),
                const SizedBox(width: 8),
                Text(
                  _getTrendText(analysis.trend),
                  style: TextStyle(
                    color: _getTrendColor(analysis.trend),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Ortalama süre: ${_formatDuration(analysis.averageDuration)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              'Başarı oranı: ${(analysis.successRate * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Optimizasyon Önerileri',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ..._recommendations
                .take(3)
                .map((rec) => _buildRecommendationItem(rec)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(OptimizationRecommendation recommendation) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _getRecommendationIcon(recommendation.priority),
            size: 16,
            color: _getRecommendationColor(recommendation.priority),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  recommendation.suggestion,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTrendIcon(PerformanceTrend trend) {
    switch (trend) {
      case PerformanceTrend.improving:
        return Icons.trending_up;
      case PerformanceTrend.stable:
        return Icons.trending_flat;
      case PerformanceTrend.degrading:
        return Icons.trending_down;
    }
  }

  Color _getTrendColor(PerformanceTrend trend) {
    switch (trend) {
      case PerformanceTrend.improving:
        return Colors.green;
      case PerformanceTrend.stable:
        return Colors.blue;
      case PerformanceTrend.degrading:
        return Colors.orange;
    }
  }

  String _getTrendText(PerformanceTrend trend) {
    switch (trend) {
      case PerformanceTrend.improving:
        return 'İyileşiyor';
      case PerformanceTrend.stable:
        return 'Kararlı';
      case PerformanceTrend.degrading:
        return 'Kötüleşiyor';
    }
  }

  IconData _getRecommendationIcon(RecommendationPriority priority) {
    switch (priority) {
      case RecommendationPriority.low:
        return Icons.info_outline;
      case RecommendationPriority.medium:
        return Icons.warning_amber_outlined;
      case RecommendationPriority.high:
        return Icons.priority_high;
      case RecommendationPriority.critical:
        return Icons.error_outline;
    }
  }

  Color _getRecommendationColor(RecommendationPriority priority) {
    switch (priority) {
      case RecommendationPriority.low:
        return Colors.blue;
      case RecommendationPriority.medium:
        return Colors.orange;
      case RecommendationPriority.high:
        return Colors.red;
      case RecommendationPriority.critical:
        return Colors.red.shade700;
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}s ${duration.inMinutes.remainder(60)}d';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}d ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  Future<void> _showRetentionPolicyDialog() async {
    // Implementation for retention policy dialog would go here
    // For now, just show a placeholder
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saklama Politikası'),
        content: const Text(
          'Saklama politikası ayarları burada yapılandırılacak.',
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
}
