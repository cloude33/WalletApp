import 'package:flutter_test/flutter_test.dart';
import 'package:parion/models/backup_metadata.dart';

void main() {
  group('Backup Metadata Tests', () {
    test('BackupMetadata should create correctly', () {
      final metadata = BackupMetadata(
        version: '2.0',
        createdAt: DateTime.now(),
        transactionCount: 10,
        walletCount: 3,
        platform: 'android',
        deviceModel: 'Test Device',
      );

      expect(metadata.version, '2.0');
      expect(metadata.transactionCount, 10);
      expect(metadata.walletCount, 3);
      expect(metadata.isAndroidBackup, true);
      expect(metadata.isIOSBackup, false);
      expect(metadata.isCrossPlatformCompatible, true);
    });

    test('BackupMetadata should handle JSON serialization', () {
      final now = DateTime.now();
      final metadata = BackupMetadata(
        version: '2.0',
        createdAt: now,
        transactionCount: 5,
        walletCount: 2,
        platform: 'ios',
        deviceModel: 'iPhone 15',
      );

      final json = metadata.toJson();
      final restored = BackupMetadata.fromJson(json);

      expect(restored.version, metadata.version);
      expect(restored.createdAt, metadata.createdAt);
      expect(restored.transactionCount, metadata.transactionCount);
      expect(restored.walletCount, metadata.walletCount);
      expect(restored.platform, metadata.platform);
      expect(restored.deviceModel, metadata.deviceModel);
    });

    test('BackupMetadata should detect cross-platform compatibility', () {
      final androidMetadata = BackupMetadata(
        version: '2.0',
        createdAt: DateTime.now(),
        transactionCount: 1,
        walletCount: 1,
        platform: 'android',
      );

      final iosMetadata = BackupMetadata(
        version: '2.0',
        createdAt: DateTime.now(),
        transactionCount: 1,
        walletCount: 1,
        platform: 'ios',
      );

      final oldMetadata = BackupMetadata(
        version: '0.9',
        createdAt: DateTime.now(),
        transactionCount: 1,
        walletCount: 1,
        platform: 'android',
      );

      expect(androidMetadata.isCrossPlatformCompatible, true);
      expect(iosMetadata.isCrossPlatformCompatible, true);
      expect(oldMetadata.isCrossPlatformCompatible, false);
    });

    test('BackupMetadata should handle different platforms', () {
      final platforms = ['android', 'ios', 'unknown'];
      
      for (final platform in platforms) {
        final metadata = BackupMetadata(
          version: '2.0',
          createdAt: DateTime.now(),
          transactionCount: 1,
          walletCount: 1,
          platform: platform,
        );

        switch (platform) {
          case 'android':
            expect(metadata.isAndroidBackup, true);
            expect(metadata.isIOSBackup, false);
            break;
          case 'ios':
            expect(metadata.isAndroidBackup, false);
            expect(metadata.isIOSBackup, true);
            break;
          default:
            expect(metadata.isAndroidBackup, false);
            expect(metadata.isIOSBackup, false);
        }
      }
    });

    test('BackupMetadata should handle version compatibility', () {
      final compatibleVersions = ['1.0', '2.0', '2.1', '2.5'];
      final incompatibleVersions = ['0.9', '0.5', '3.0'];

      for (final version in compatibleVersions) {
        final metadata = BackupMetadata(
          version: version,
          createdAt: DateTime.now(),
          transactionCount: 1,
          walletCount: 1,
          platform: 'android',
        );
        expect(metadata.isCrossPlatformCompatible, true, 
               reason: 'Version $version should be compatible');
      }

      for (final version in incompatibleVersions) {
        final metadata = BackupMetadata(
          version: version,
          createdAt: DateTime.now(),
          transactionCount: 1,
          walletCount: 1,
          platform: 'android',
        );
        expect(metadata.isCrossPlatformCompatible, false, 
               reason: 'Version $version should be incompatible');
      }
    });
  });
}