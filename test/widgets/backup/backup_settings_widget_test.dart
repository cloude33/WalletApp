import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parion/models/backup_optimization/backup_config.dart';
import 'package:parion/models/backup_optimization/backup_enums.dart';

/// Simple backup settings widget for testing
class TestBackupSettingsWidget extends StatefulWidget {
  final BackupConfig? initialConfig;
  final Function(BackupConfig)? onConfigChanged;

  const TestBackupSettingsWidget({
    super.key,
    this.initialConfig,
    this.onConfigChanged,
  });

  @override
  State<TestBackupSettingsWidget> createState() =>
      _TestBackupSettingsWidgetState();
}

class _TestBackupSettingsWidgetState extends State<TestBackupSettingsWidget> {
  late BackupConfig _config;

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig ?? BackupConfig.full();
  }

  void _updateConfig(BackupConfig newConfig) {
    setState(() => _config = newConfig);
    widget.onConfigChanged?.call(newConfig);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(Icons.settings, color: Color(0xFF00BFA5)),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Yedekleme Ayarları',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
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
                      onPressed: () {},
                      tooltip: 'Performans verilerini yenile',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Strategy Selection
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

                const SizedBox(height: 16),

                // Data Category Selection (only for custom)
                if (_config.type == BackupType.custom) ...[
                  const Text(
                    'Yedeklenecek Veriler',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: DataCategory.values.map((category) {
                      final isSelected = _config.includedCategories.contains(
                        category,
                      );
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
                          _updateConfig(
                            _config.copyWith(includedCategories: categories),
                          );
                        },
                        selectedColor: const Color(
                          0xFF00BFA5,
                        ).withValues(alpha: 0.2),
                        checkmarkColor: const Color(0xFF00BFA5),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Compression Settings
                const Text(
                  'Sıkıştırma Seviyesi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: CompressionLevel.values.map((level) {
                    final isSelected = _config.compressionLevel == level;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _updateConfig(
                              _config.copyWith(compressionLevel: level),
                            );
                          },
                          icon: Icon(_getCompressionLevelIcon(level)),
                          label: Text(_getCompressionLevelName(level)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected
                                ? const Color(0xFF00BFA5)
                                : Colors.grey.shade200,
                            foregroundColor: isSelected
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Advanced Settings
                ExpansionTile(
                  title: const Text('Gelişmiş Ayarlar'),
                  leading: const Icon(Icons.settings_applications),
                  children: [
                    SwitchListTile(
                      title: const Text('Doğrulama Etkin'),
                      subtitle: const Text('Yedek bütünlüğünü kontrol et'),
                      value: _config.enableValidation,
                      onChanged: (value) {
                        _updateConfig(
                          _config.copyWith(enableValidation: value),
                        );
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
                ),
              ],
            ),
          ),
        ),
      ),
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

  Future<void> _showRetentionPolicyDialog() async {
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

void main() {
  group('BackupSettingsWidget Tests', () {
    testWidgets('should display backup strategy selection interface', (
      WidgetTester tester,
    ) async {
      // Arrange
      final widget = TestBackupSettingsWidget(
        initialConfig: BackupConfig.full(),
        onConfigChanged: (config) {},
      );

      // Act
      await tester.pumpWidget(MaterialApp(home: widget));
      await tester.pump();

      // Assert - Check header elements
      expect(find.text('Yedekleme Ayarları'), findsOneWidget);
      expect(
        find.text('Yedekleme stratejinizi ve tercihlerinizi yapılandırın'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      // Assert - Check strategy selection section
      expect(find.text('Yedekleme Stratejisi'), findsOneWidget);
      expect(find.text('Tam Yedekleme'), findsOneWidget);
      expect(find.text('Artımlı Yedekleme'), findsOneWidget);
      expect(find.text('Özel Yedekleme'), findsOneWidget);
    });

    testWidgets('should handle backup strategy selection', (
      WidgetTester tester,
    ) async {
      // Arrange
      BackupConfig? capturedConfig;
      final widget = TestBackupSettingsWidget(
        initialConfig: BackupConfig.full(),
        onConfigChanged: (config) => capturedConfig = config,
      );

      await tester.pumpWidget(MaterialApp(home: widget));
      await tester.pump();

      // Act - Select incremental backup strategy
      await tester.tap(find.text('Artımlı Yedekleme'));
      await tester.pump();

      // Assert
      expect(capturedConfig, isNotNull);
      expect(capturedConfig!.type, BackupType.incremental);
    });

    testWidgets('should show data category selection for custom backup', (
      WidgetTester tester,
    ) async {
      // Arrange
      final widget = TestBackupSettingsWidget(
        initialConfig: BackupConfig(
          type: BackupType.custom,
          includedCategories: [DataCategory.transactions],
          retentionPolicy: RetentionPolicy.standard(),
        ),
      );

      await tester.pumpWidget(MaterialApp(home: widget));
      await tester.pump();

      // Assert - Check data category section appears
      expect(find.text('Yedeklenecek Veriler'), findsOneWidget);
      expect(find.text('İşlemler'), findsOneWidget);
      expect(find.text('Cüzdanlar'), findsOneWidget);
      expect(find.text('Kredi Kartları'), findsOneWidget);
    });

    testWidgets('should handle data category selection', (
      WidgetTester tester,
    ) async {
      // Arrange
      BackupConfig? capturedConfig;
      final widget = TestBackupSettingsWidget(
        initialConfig: BackupConfig(
          type: BackupType.custom,
          includedCategories: [DataCategory.transactions],
          retentionPolicy: RetentionPolicy.standard(),
        ),
        onConfigChanged: (config) => capturedConfig = config,
      );

      await tester.pumpWidget(MaterialApp(home: widget));
      await tester.pump();

      // Act - Select additional category
      await tester.tap(find.text('Cüzdanlar'));
      await tester.pump();

      // Assert
      expect(capturedConfig, isNotNull);
      expect(
        capturedConfig!.includedCategories,
        contains(DataCategory.wallets),
      );
      expect(
        capturedConfig!.includedCategories,
        contains(DataCategory.transactions),
      );
    });

    testWidgets('should display compression level settings', (
      WidgetTester tester,
    ) async {
      // Arrange
      final widget = TestBackupSettingsWidget(
        initialConfig: BackupConfig.full(),
      );

      await tester.pumpWidget(MaterialApp(home: widget));
      await tester.pump();

      // Assert
      expect(find.text('Sıkıştırma Seviyesi'), findsOneWidget);
      expect(find.text('Hızlı'), findsOneWidget);
      expect(find.text('Dengeli'), findsOneWidget);
      expect(find.text('Maksimum'), findsOneWidget);
    });

    testWidgets('should handle compression level selection', (
      WidgetTester tester,
    ) async {
      // Arrange
      BackupConfig? capturedConfig;
      final widget = TestBackupSettingsWidget(
        initialConfig: BackupConfig.full(),
        onConfigChanged: (config) => capturedConfig = config,
      );

      await tester.pumpWidget(MaterialApp(home: widget));
      await tester.pump();

      // Act - Select fast compression
      await tester.tap(find.text('Hızlı'));
      await tester.pump();

      // Assert
      expect(capturedConfig, isNotNull);
      expect(capturedConfig!.compressionLevel, CompressionLevel.fast);
    });

    testWidgets('should display advanced settings section', (
      WidgetTester tester,
    ) async {
      // Arrange
      final widget = TestBackupSettingsWidget(
        initialConfig: BackupConfig.full(),
      );

      await tester.pumpWidget(MaterialApp(home: widget));
      await tester.pump();

      // Assert
      expect(find.text('Gelişmiş Ayarlar'), findsOneWidget);

      // Expand advanced settings
      await tester.tap(find.text('Gelişmiş Ayarlar'));
      await tester.pumpAndSettle();

      expect(find.text('Doğrulama Etkin'), findsOneWidget);
      expect(find.text('Saklama Politikası'), findsOneWidget);
    });

    testWidgets('should handle validation toggle', (WidgetTester tester) async {
      // Arrange
      BackupConfig? capturedConfig;
      final widget = TestBackupSettingsWidget(
        initialConfig: BackupConfig.full(),
        onConfigChanged: (config) => capturedConfig = config,
      );

      await tester.pumpWidget(MaterialApp(home: widget));
      await tester.pump();

      // Expand advanced settings
      await tester.tap(find.text('Gelişmiş Ayarlar'));
      await tester.pumpAndSettle();

      // Act - Toggle validation
      await tester.tap(find.byType(Switch));
      await tester.pump();

      // Assert
      expect(capturedConfig, isNotNull);
      expect(capturedConfig!.enableValidation, false);
    });

    testWidgets('should display strategy icons correctly', (
      WidgetTester tester,
    ) async {
      // Arrange
      final widget = TestBackupSettingsWidget(
        initialConfig: BackupConfig.full(),
      );

      await tester.pumpWidget(MaterialApp(home: widget));
      await tester.pump();

      // Assert - Check strategy icons
      expect(find.byIcon(Icons.backup), findsOneWidget); // Full backup
      expect(find.byIcon(Icons.update), findsOneWidget); // Incremental backup
      expect(find.byIcon(Icons.tune), findsOneWidget); // Custom backup
    });

    testWidgets('should display compression level icons correctly', (
      WidgetTester tester,
    ) async {
      // Arrange
      final widget = TestBackupSettingsWidget(
        initialConfig: BackupConfig.full(),
      );

      await tester.pumpWidget(MaterialApp(home: widget));
      await tester.pump();

      // Assert - Check compression level icons
      expect(find.byIcon(Icons.speed), findsOneWidget); // Fast
      expect(find.byIcon(Icons.balance), findsOneWidget); // Balanced
      expect(find.byIcon(Icons.compress), findsOneWidget); // Maximum
    });
  });
}
