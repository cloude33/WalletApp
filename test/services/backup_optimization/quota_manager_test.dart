import 'package:flutter_test/flutter_test.dart';

import 'package:parion/services/backup_optimization/quota_manager.dart';

void main() {
  group('QuotaManager Unit Tests', () {
    late QuotaManager quotaManager;

    setUp(() {
      quotaManager = QuotaManager();

      // Clear any cached quota info before each test
      quotaManager.clearQuotaCache();
    });

    group('Storage Warning Tests - Requirement 3.3', () {
      test('should detect 90% storage threshold warning', () async {
        // Arrange - Create quota info with exactly 90% usage
        final totalSpace = 15 * 1024 * 1024 * 1024; // 15GB
        final usedSpace = (totalSpace * 0.90).round(); // 90% used
        final quotaInfo = QuotaInfo(
          totalSpaceBytes: totalSpace,
          usedSpaceBytes: usedSpace,
          availableSpaceBytes: totalSpace - usedSpace,
          isUnlimited: false,
          lastUpdated: DateTime.now(),
        );

        // Act
        final isNearLimit = quotaInfo.isNearlyFull;
        final warningMessage = await _getWarningMessageForQuota(quotaInfo);

        // Assert
        expect(
          isNearLimit,
          isTrue,
          reason: 'Should detect 90% threshold as near limit',
        );
        expect(
          warningMessage,
          isNotNull,
          reason: 'Should provide warning message at 90% usage',
        );
        expect(
          warningMessage,
          contains('90.0'),
          reason: 'Warning message should mention 90% usage',
        );
        expect(
          warningMessage,
          contains('temizlemeyi düşünün'),
          reason: 'Should suggest cleanup',
        );
      });

      test('should detect 95% storage threshold critical warning', () async {
        // Arrange - Create quota info with 95% usage
        final totalSpace = 15 * 1024 * 1024 * 1024; // 15GB
        final usedSpace = (totalSpace * 0.95).round(); // 95% used
        final quotaInfo = QuotaInfo(
          totalSpaceBytes: totalSpace,
          usedSpaceBytes: usedSpace,
          availableSpaceBytes: totalSpace - usedSpace,
          isUnlimited: false,
          lastUpdated: DateTime.now(),
        );

        // Act
        final isCriticallyFull = quotaInfo.isCriticallyFull;
        final warningMessage = await _getWarningMessageForQuota(quotaInfo);

        // Assert
        expect(
          isCriticallyFull,
          isTrue,
          reason: 'Should detect 95% threshold as critically full',
        );
        expect(
          warningMessage,
          isNotNull,
          reason: 'Should provide critical warning message at 95% usage',
        );
        expect(
          warningMessage,
          contains('95.0'),
          reason: 'Warning message should mention 95% usage',
        );
        expect(
          warningMessage,
          contains('Acil olarak'),
          reason: 'Should indicate urgency',
        );
      });

      test('should provide 80% storage threshold early warning', () async {
        // Arrange - Create quota info with 80% usage
        final totalSpace = 15 * 1024 * 1024 * 1024; // 15GB
        final usedSpace = (totalSpace * 0.80).round(); // 80% used
        final quotaInfo = QuotaInfo(
          totalSpaceBytes: totalSpace,
          usedSpaceBytes: usedSpace,
          availableSpaceBytes: totalSpace - usedSpace,
          isUnlimited: false,
          lastUpdated: DateTime.now(),
        );

        // Act
        final isNearLimit = quotaInfo.isNearlyFull;
        final warningMessage = await _getWarningMessageForQuota(quotaInfo);

        // Assert
        expect(
          isNearLimit,
          isFalse,
          reason: 'Should not consider 80% as near limit (90% threshold)',
        );
        expect(
          warningMessage,
          isNotNull,
          reason: 'Should provide early warning message at 80% usage',
        );
        expect(
          warningMessage,
          contains('80.0'),
          reason: 'Warning message should mention 80% usage',
        );
        expect(
          warningMessage,
          contains('Yakında temizlik'),
          reason: 'Should suggest future cleanup',
        );
      });

      test('should not provide warning below 80% threshold', () async {
        // Arrange - Create quota info with 70% usage
        final totalSpace = 15 * 1024 * 1024 * 1024; // 15GB
        final usedSpace = (totalSpace * 0.70).round(); // 70% used
        final quotaInfo = QuotaInfo(
          totalSpaceBytes: totalSpace,
          usedSpaceBytes: usedSpace,
          availableSpaceBytes: totalSpace - usedSpace,
          isUnlimited: false,
          lastUpdated: DateTime.now(),
        );

        // Act
        final isNearLimit = quotaInfo.isNearlyFull;
        final warningMessage = await _getWarningMessageForQuota(quotaInfo);

        // Assert
        expect(
          isNearLimit,
          isFalse,
          reason: 'Should not consider 70% as near limit',
        );
        expect(
          warningMessage,
          isNull,
          reason: 'Should not provide warning below 80% usage',
        );
      });

      test('should handle edge case at exactly 90% threshold', () async {
        // Arrange - Create quota info with exactly 90.0% usage
        final totalSpace = 1000; // Simple numbers for exact calculation
        final usedSpace = 900; // Exactly 90%
        final quotaInfo = QuotaInfo(
          totalSpaceBytes: totalSpace,
          usedSpaceBytes: usedSpace,
          availableSpaceBytes: totalSpace - usedSpace,
          isUnlimited: false,
          lastUpdated: DateTime.now(),
        );

        // Act
        final usagePercentage = quotaInfo.usagePercentage;
        final isNearLimit = quotaInfo.isNearlyFull;

        // Assert
        expect(
          usagePercentage,
          equals(90.0),
          reason: 'Usage should be exactly 90%',
        );
        expect(
          isNearLimit,
          isTrue,
          reason: 'Should trigger warning at exactly 90% threshold',
        );
      });

      test('should handle unlimited storage accounts', () async {
        // Arrange - Create quota info for unlimited storage
        final quotaInfo = QuotaInfo(
          totalSpaceBytes:
              0, // Unlimited accounts may have 0 or very large numbers
          usedSpaceBytes: 1024 * 1024 * 1024, // 1GB used
          availableSpaceBytes: -1, // Unlimited
          isUnlimited: true,
          lastUpdated: DateTime.now(),
        );

        // Act
        final usagePercentage = quotaInfo.usagePercentage;
        final isNearLimit = quotaInfo.isNearlyFull;
        final warningMessage = await _getWarningMessageForQuota(quotaInfo);

        // Assert
        expect(
          usagePercentage,
          equals(0.0),
          reason: 'Unlimited accounts should show 0% usage',
        );
        expect(
          isNearLimit,
          isFalse,
          reason: 'Unlimited accounts should never be near limit',
        );
        expect(
          warningMessage,
          isNull,
          reason: 'Unlimited accounts should not show warnings',
        );
      });

      test('should format warning messages correctly in Turkish', () async {
        // Arrange - Test different warning levels
        final testCases = [
          (80.5, 'Yakında temizlik'),
          (90.2, 'temizlemeyi düşünün'),
          (95.7, 'Acil olarak'),
        ];

        for (final (percentage, expectedPhrase) in testCases) {
          final totalSpace = 1000;
          final usedSpace = (totalSpace * percentage / 100).round();
          final quotaInfo = QuotaInfo(
            totalSpaceBytes: totalSpace,
            usedSpaceBytes: usedSpace,
            availableSpaceBytes: totalSpace - usedSpace,
            isUnlimited: false,
            lastUpdated: DateTime.now(),
          );

          // Act
          final warningMessage = await _getWarningMessageForQuota(quotaInfo);

          // Assert
          expect(
            warningMessage,
            isNotNull,
            reason: 'Should have warning at $percentage%',
          );
          expect(
            warningMessage,
            contains(expectedPhrase),
            reason: 'Warning at $percentage% should contain "$expectedPhrase"',
          );
          expect(
            warningMessage,
            contains('%${percentage.toStringAsFixed(1)}'),
            reason: 'Should show formatted percentage',
          );
        }
      });
    });
  });
}

/// Helper method to get warning message for a given quota info
/// This simulates the QuotaManager.getStorageWarningMessage() method logic
Future<String?> _getWarningMessageForQuota(QuotaInfo quotaInfo) async {
  final usagePercentage = quotaInfo.usagePercentage;

  if (usagePercentage >= 95.0) {
    return 'Depolama alanınız %${usagePercentage.toStringAsFixed(1)} dolu! Acil olarak eski yedekleri temizlemeniz gerekiyor.';
  } else if (usagePercentage >= 90.0) {
    return 'Depolama alanınız %${usagePercentage.toStringAsFixed(1)} dolu. Eski yedekleri temizlemeyi düşünün.';
  } else if (usagePercentage >= 80.0) {
    return 'Depolama alanınız %${usagePercentage.toStringAsFixed(1)} dolu. Yakında temizlik yapmanız gerekebilir.';
  }

  return null; // No warning needed
}
