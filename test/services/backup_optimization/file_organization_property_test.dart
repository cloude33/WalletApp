import 'package:flutter_test/flutter_test.dart';
import 'package:parion/services/backup_optimization/drive_manager.dart';
import 'package:parion/models/backup_optimization/backup_enums.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import '../../property_test_utils.dart';

void main() {
  setUpAll(() async {
    // Initialize Turkish locale for date formatting
    await initializeDateFormatting('tr_TR', null);
  });

  group('File Organization Property Tests', () {
    late FileManager fileManager;

    setUp(() {
      fileManager = FileManager();
    });

    /// **Feature: backup-optimization, Property 10: Date-Based File Organization**
    /// **Validates: Requirements 3.2**
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 10: Date-Based File Organization - For any backup upload, the drive manager should organize files into date-based folder structures',
      generator: _generateFileOrganizationScenario,
      property: (scenario) async {
        final metadata = scenario['metadata'] as BackupMetadata;
        final expectedYear = scenario['expectedYear'] as String;
        final expectedMonth = scenario['expectedMonth'] as String;
        final expectedFolderPath = scenario['expectedFolderPath'] as String;
        
        // Test 1: Generate optimal file name should include timestamp and type information
        final fileName = await fileManager.generateOptimalFileName(metadata);
        
        // Property 1: File name should contain timestamp in correct format
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(metadata.createdAt);
        final containsTimestamp = fileName.contains(timestamp);
        
        // Property 2: File name should contain backup type
        final type = metadata.type?.name ?? 'backup';
        final containsType = fileName.contains(type);
        
        // Property 3: File name should have correct extension
        final hasCorrectExtension = fileName.endsWith('.mbk');
        
        // Property 4: File name should contain platform information
        final platform = metadata.platform ?? 'unknown';
        final containsPlatform = fileName.contains(platform);
        
        // Test 2: Folder path generation should follow date-based structure
        final mockBackupFile = _createMockDriveFile(metadata.createdAt);
        final folderPath = await fileManager.getFolderPath(mockBackupFile);
        
        // Property 5: Folder path should match expected year/month structure
        final correctFolderPath = folderPath == expectedFolderPath;
        
        // Property 6: Folder path should contain year
        final containsYear = folderPath.contains(expectedYear);
        
        // Property 7: Folder path should contain month in correct format
        final containsMonth = folderPath.contains(expectedMonth);
        
        // Property 8: Folder path should start and end with forward slashes
        final correctPathFormat = folderPath.startsWith('/') && folderPath.endsWith('/');
        
        return containsTimestamp && 
               containsType && 
               hasCorrectExtension && 
               containsPlatform &&
               correctFolderPath &&
               containsYear &&
               containsMonth &&
               correctPathFormat;
      },
      iterations: 20,
    );

    /// Additional property test for date-based folder creation consistency
    PropertyTest.forAll<DateTime>(
      description: 'Date-based folder creation should be consistent for same dates',
      generator: () => PropertyTest.randomDateTime(
        start: DateTime(2020, 1, 1),
        end: DateTime(2030, 12, 31),
      ),
      property: (createdTime) async {
        // Create two mock files with the same creation time
        final mockFile1 = _createMockDriveFile(createdTime);
        final mockFile2 = _createMockDriveFile(createdTime);
        
        // Get folder paths for both files
        final folderPath1 = await fileManager.getFolderPath(mockFile1);
        final folderPath2 = await fileManager.getFolderPath(mockFile2);
        
        // Property: Same creation time should result in same folder path
        final sameFolderPath = folderPath1 == folderPath2;
        
        // Property: Folder path should be deterministic based on date
        final expectedYear = createdTime.year.toString();
        final expectedMonth = DateFormat('MM-MMMM', 'tr_TR').format(createdTime);
        final expectedPath = '/$expectedYear/$expectedMonth/';
        final correctPath = folderPath1 == expectedPath;
        
        return sameFolderPath && correctPath;
      },
      iterations: 20,
    );

    /// Property test for file name uniqueness across different timestamps
    PropertyTest.forAll<List<DateTime>>(
      description: 'File names should be unique for different timestamps',
      generator: () => List.generate(
        PropertyTest.randomInt(min: 2, max: 5),
        (_) => PropertyTest.randomDateTime(
          start: DateTime(2020, 1, 1),
          end: DateTime(2030, 12, 31),
        ),
      ),
      property: (timestamps) async {
        final fileNames = <String>[];
        
        // Generate file names for all timestamps
        for (final timestamp in timestamps) {
          final metadata = BackupMetadata(
            type: BackupType.values[PropertyTest.randomInt(max: BackupType.values.length - 1)],
            createdAt: timestamp,
            platform: 'test',
          );
          
          final fileName = await fileManager.generateOptimalFileName(metadata);
          fileNames.add(fileName);
        }
        
        // Property: All file names should be unique if timestamps are different
        final uniqueTimestamps = timestamps.toSet();
        final uniqueFileNames = fileNames.toSet();
        
        // If all timestamps are unique, all file names should be unique
        final correctUniqueness = uniqueTimestamps.length == uniqueFileNames.length;
        
        return correctUniqueness;
      },
      iterations: 20,
    );

    /// Property test for folder path format consistency
    PropertyTest.forAll<DateTime>(
      description: 'Folder paths should always follow the correct format pattern',
      generator: () => PropertyTest.randomDateTime(
        start: DateTime(1990, 1, 1),
        end: DateTime(2050, 12, 31),
      ),
      property: (createdTime) async {
        final mockFile = _createMockDriveFile(createdTime);
        final folderPath = await fileManager.getFolderPath(mockFile);
        
        // Property 1: Path should start with '/'
        final startsWithSlash = folderPath.startsWith('/');
        
        // Property 2: Path should end with '/'
        final endsWithSlash = folderPath.endsWith('/');
        
        // Property 3: Path should contain exactly 3 slashes (/, year/, month/)
        final pathParts = folderPath.split('/').where((part) => part.isNotEmpty).toList();
        final correctPartCount = pathParts.length == 2; // year and month parts
        
        // Property 4: Path should contain valid year (4 digits)
        final yearPart = pathParts.isNotEmpty ? pathParts[0] : '';
        final validYear = RegExp(r'^\d{4}$').hasMatch(yearPart);
        
        // Property 5: Path should contain valid month format (MM-MMMM)
        final monthPart = pathParts.length > 1 ? pathParts[1] : '';
        final validMonth = RegExp(r'^\d{2}-.+$').hasMatch(monthPart);
        
        // Debug information for failed tests
        if (!(startsWithSlash && endsWithSlash && correctPartCount && validYear && validMonth)) {
          print('Debug info for $createdTime:');
          print('  folderPath: $folderPath');
          print('  pathParts: $pathParts');
          print('  yearPart: $yearPart');
          print('  monthPart: $monthPart');
          print('  startsWithSlash: $startsWithSlash');
          print('  endsWithSlash: $endsWithSlash');
          print('  correctPartCount: $correctPartCount');
          print('  validYear: $validYear');
          print('  validMonth: $validMonth');
        }
        
        return startsWithSlash && 
               endsWithSlash && 
               correctPartCount && 
               validYear && 
               validMonth;
      },
      iterations: 20,
    );

    test('File manager should handle null creation time gracefully', () async {
      final mockFile = _createMockDriveFile(null);
      final folderPath = await fileManager.getFolderPath(mockFile);
      
      // Should return root path for null creation time
      expect(folderPath, equals('/'));
    });

    test('File name generation should handle all backup types', () async {
      for (final backupType in BackupType.values) {
        final metadata = BackupMetadata(
          type: backupType,
          createdAt: DateTime.now(),
          platform: 'test',
        );
        
        final fileName = await fileManager.generateOptimalFileName(metadata);
        
        expect(fileName.contains(backupType.name), true);
        expect(fileName.endsWith('.mbk'), true);
      }
    });
  });
}

/// Generate a scenario for testing file organization
Map<String, dynamic> _generateFileOrganizationScenario() {
  final createdAt = PropertyTest.randomDateTime(
    start: DateTime(2020, 1, 1),
    end: DateTime(2030, 12, 31),
  );
  
  final backupType = BackupType.values[
    PropertyTest.randomInt(max: BackupType.values.length - 1)
  ];
  
  final platform = PropertyTest.randomBool() 
    ? ['android', 'ios', 'web', 'windows', 'macos', 'linux'][
        PropertyTest.randomInt(max: 5)
      ]
    : null;
  
  final metadata = BackupMetadata(
    type: backupType,
    createdAt: createdAt,
    platform: platform,
    transactionCount: PropertyTest.randomInt(min: 0, max: 1000),
  );
  
  final expectedYear = createdAt.year.toString();
  final expectedMonth = DateFormat('MM-MMMM', 'tr_TR').format(createdAt);
  final expectedFolderPath = '/$expectedYear/$expectedMonth/';
  
  return {
    'metadata': metadata,
    'expectedYear': expectedYear,
    'expectedMonth': expectedMonth,
    'expectedFolderPath': expectedFolderPath,
  };
}

/// Create a mock Google Drive File for testing
drive.File _createMockDriveFile(DateTime? createdTime) {
  final file = drive.File();
  file.createdTime = createdTime;
  file.name = 'test_backup.mbk';
  file.id = 'test_file_id_${DateTime.now().millisecondsSinceEpoch}';
  return file;
}