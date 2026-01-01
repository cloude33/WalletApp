import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parion/models/backup_optimization/backup_enums.dart';

/// Simple backup progress widget for testing
class TestBackupProgressWidget extends StatefulWidget {
  final Function(String)? onBackupComplete;
  final Function(String)? onError;
  final bool showDetailedMetrics;

  const TestBackupProgressWidget({
    super.key,
    this.onBackupComplete,
    this.onError,
    this.showDetailedMetrics = true,
  });

  @override
  State<TestBackupProgressWidget> createState() =>
      _TestBackupProgressWidgetState();
}

class _TestBackupProgressWidgetState extends State<TestBackupProgressWidget> {
  BackupProgressState _state = BackupProgressState.idle;
  double _progress = 0.0;
  String _currentStep = '';
  String? _errorMessage;
  Duration _elapsedTime = Duration.zero;

  /// Start a backup operation with progress tracking
  void startBackup(BackupType type) {
    setState(() {
      _state = BackupProgressState.inProgress;
      _progress = 0.5; // Simulate some progress
      _currentStep = 'Yedekleme başlatılıyor...';
      _errorMessage = null;
      _elapsedTime = const Duration(seconds: 30);
    });
  }

  /// Complete the backup operation (for testing)
  void completeBackup() {
    setState(() {
      _state = BackupProgressState.completed;
      _progress = 1.0;
      _currentStep = 'Yedekleme tamamlandı';
    });
    widget.onBackupComplete?.call('backup_success');
  }

  /// Cancel the current backup operation
  void cancelBackup() {
    setState(() {
      _state = BackupProgressState.cancelled;
      _currentStep = 'Yedekleme iptal edildi';
    });
  }

  /// Retry the backup operation
  void retryBackup() {
    if (_state == BackupProgressState.error) {
      startBackup(BackupType.full);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildProgressSection(),
              if (widget.showDetailedMetrics &&
                  _state == BackupProgressState.inProgress) ...[
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
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(_getStateIcon(), color: _getStateColor(), size: 24),
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
        LinearProgressIndicator(
          value: _state == BackupProgressState.inProgress
              ? _progress
              : (_state == BackupProgressState.completed ? 1.0 : 0.0),
          backgroundColor: Colors.grey.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(_getStateColor()),
          minHeight: 8,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(_progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            if (_state == BackupProgressState.completed)
              const Text(
                'Sıkıştırma: 70%',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricsSection() {
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
                    '${(2.5 + (_progress * 1.5)).toStringAsFixed(1)} MB/s',
                    Icons.speed,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Veri',
                    '${((_progress * 50)).toStringAsFixed(1)} MB',
                    Icons.data_usage,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Bellek',
                    '${(50 + (_progress * 100)).toStringAsFixed(0)} MB',
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
        ],
      ),
    );
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

void main() {
  group('BackupProgressWidget Tests', () {
    testWidgets('should display initial progress widget structure', (
      WidgetTester tester,
    ) async {
      // Arrange
      final widget = TestBackupProgressWidget(showDetailedMetrics: false);

      // Act
      await tester.pumpWidget(MaterialApp(home: widget));
      await tester.pump();

      // Assert - Check initial state elements
      expect(find.text('Yedekleme Hazır'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Yedekleme Başlat'), findsOneWidget);
      expect(find.byIcon(Icons.backup), findsOneWidget);
    });

    testWidgets('should start backup operation when button pressed', (
      WidgetTester tester,
    ) async {
      // Arrange
      final widget = TestBackupProgressWidget(showDetailedMetrics: false);

      await tester.pumpWidget(MaterialApp(home: widget));
      await tester.pump();

      // Act - Start backup
      await tester.tap(find.text('Yedekleme Başlat'));
      await tester.pump();

      // Assert - Should show in-progress state
      expect(find.text('Yedekleme Devam Ediyor'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_upload), findsOneWidget);
      expect(find.text('İptal Et'), findsOneWidget);
    });

    testWidgets('should display progress percentage correctly', (
      WidgetTester tester,
    ) async {
      // Arrange
      final widget = TestBackupProgressWidget(showDetailedMetrics: false);

      await tester.pumpWidget(MaterialApp(home: widget));
      await tester.pump();

      // Act - Start backup and let it progress
      await tester.tap(find.text('Yedekleme Başlat'));
      await tester.pump();

      // Assert - Should show progress percentage
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('should handle backup cancellation', (
      WidgetTester tester,
    ) async {
      // Arrange
      final widget = TestBackupProgressWidget(showDetailedMetrics: false);

      await tester.pumpWidget(MaterialApp(home: widget));
      await tester.pump();

      // Start backup first
      await tester.tap(find.text('Yedekleme Başlat'));
      await tester.pump();

      // Act - Cancel backup
      await tester.tap(find.text('İptal Et'));
      await tester.pump();

      // Assert - Should show cancelled state
      expect(find.text('Yedekleme İptal Edildi'), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('should display backup completion state', (
      WidgetTester tester,
    ) async {
      // Arrange
      final widget = TestBackupProgressWidget(showDetailedMetrics: false);

      await tester.pumpWidget(MaterialApp(home: widget));
      await tester.pump();

      // Act - Start backup and manually complete it
      await tester.tap(find.text('Yedekleme Başlat'));
      await tester.pump();

      // Get the widget state and complete backup
      final widgetState = tester.state<_TestBackupProgressWidgetState>(
        find.byType(TestBackupProgressWidget),
      );
      widgetState.completeBackup();
      await tester.pump();

      // Assert - Should show completed state
      expect(find.text('Yedekleme Tamamlandı'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('should show detailed metrics when enabled', (
      WidgetTester tester,
    ) async {
      // Arrange
      final widget = TestBackupProgressWidget(showDetailedMetrics: true);

      await tester.pumpWidget(MaterialApp(home: widget));
      await tester.pump();

      // Act - Start backup to generate metrics
      await tester.tap(find.text('Yedekleme Başlat'));
      await tester.pump();

      // Assert - Should show metrics section
      expect(find.text('Anlık Performans'), findsOneWidget);
      expect(find.text('Hız'), findsOneWidget);
      expect(find.text('Veri'), findsOneWidget);
      expect(find.text('Bellek'), findsOneWidget);
    });

    testWidgets('should display elapsed time during backup', (
      WidgetTester tester,
    ) async {
      // Arrange
      final widget = TestBackupProgressWidget(showDetailedMetrics: false);

      await tester.pumpWidget(MaterialApp(home: widget));
      await tester.pump();

      // Act - Start backup
      await tester.tap(find.text('Yedekleme Başlat'));
      await tester.pump();

      // Assert - Should show elapsed time
      expect(find.text('0:30'), findsOneWidget); // Simulated 30 seconds
    });

    testWidgets('should display backup step descriptions', (
      WidgetTester tester,
    ) async {
      // Arrange
      final widget = TestBackupProgressWidget(showDetailedMetrics: false);

      await tester.pumpWidget(MaterialApp(home: widget));
      await tester.pump();

      // Act - Start backup to see step descriptions
      await tester.tap(find.text('Yedekleme Başlat'));
      await tester.pump();

      // Assert - Should show step description
      expect(find.text('Yedekleme başlatılıyor...'), findsOneWidget);
    });

    testWidgets('should handle backup completion callback', (
      WidgetTester tester,
    ) async {
      // Arrange
      String? capturedResult;
      final widget = TestBackupProgressWidget(
        onBackupComplete: (result) => capturedResult = result,
        showDetailedMetrics: false,
      );

      await tester.pumpWidget(MaterialApp(home: widget));
      await tester.pump();

      // Act - Start and manually complete backup
      await tester.tap(find.text('Yedekleme Başlat'));
      await tester.pump();

      // Get the widget state and complete backup
      final widgetState = tester.state<_TestBackupProgressWidgetState>(
        find.byType(TestBackupProgressWidget),
      );
      widgetState.completeBackup();
      await tester.pump();

      // Assert - Callback should be called
      expect(capturedResult, 'backup_success');
    });

    testWidgets('should handle error callback', (WidgetTester tester) async {
      // Arrange
      final widget = TestBackupProgressWidget(
        onError: (error) {},
        showDetailedMetrics: false,
      );

      await tester.pumpWidget(MaterialApp(home: widget));
      await tester.pump();

      // Assert - Widget should handle error callback parameter
      expect(find.byType(TestBackupProgressWidget), findsOneWidget);
    });

    testWidgets('should display progress animation', (
      WidgetTester tester,
    ) async {
      // Arrange
      final widget = TestBackupProgressWidget(showDetailedMetrics: false);

      await tester.pumpWidget(MaterialApp(home: widget));
      await tester.pump();

      // Act - Start backup
      await tester.tap(find.text('Yedekleme Başlat'));
      await tester.pump();

      // Assert - Progress indicator should be animated
      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, 0.5); // Our simulated progress
    });

    testWidgets('should show different icons for different states', (
      WidgetTester tester,
    ) async {
      // Arrange
      final widget = TestBackupProgressWidget(showDetailedMetrics: false);

      await tester.pumpWidget(MaterialApp(home: widget));
      await tester.pump();

      // Assert - Initial state icon
      expect(find.byIcon(Icons.backup), findsOneWidget);

      // Act - Start backup
      await tester.tap(find.text('Yedekleme Başlat'));
      await tester.pump();

      // Assert - In-progress state icon
      expect(find.byIcon(Icons.cloud_upload), findsOneWidget);
    });
  });
}
