import 'package:flutter_test/flutter_test.dart';
import 'package:parion/services/backup_optimization/delta_detector.dart';
import 'package:parion/models/backup_optimization/backup_enums.dart';
import '../../property_test_utils.dart';

void main() {
  group('Delta Detector Property Tests', () {
    late DeltaDetector deltaDetector;

    setUp(() {
      deltaDetector = DeltaDetector();
    });

    /// **Feature: backup-optimization, Property 2: Hash-Based Change Detection**
    /// **Validates: Requirements 1.2**
    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 2: Hash-Based Change Detection - For any data entity, when creating incremental backup, the system should detect changes by comparing current hash with stored hash values',
      generator: _generateHashComparisonScenario,
      property: (scenario) async {
        final currentData = scenario['currentData'] as Map<String, dynamic>;
        final previousHashes =
            scenario['previousHashes'] as Map<String, String>?;
        final lastBackupDate = scenario['lastBackupDate'] as DateTime;
        final expectedChanges = scenario['expectedChanges'] as List<String>;
        final unchangedEntities = scenario['unchangedEntities'] as List<String>;

        // Detect changes using the delta detector
        final incrementalData = await deltaDetector.detectChanges(
          currentData,
          lastBackupDate,
          previousHashes,
        );

        // Property 1: All entities with different hashes should be detected as changes
        final detectedChangedEntities = incrementalData.changes
            .map((change) => '${change.entityType}_${change.entityId}')
            .toSet();

        final allExpectedChangesDetected = expectedChanges.every(
          (expectedEntity) => detectedChangedEntities.contains(expectedEntity),
        );

        // Property 2: Entities with same hashes should not be detected as changes
        final noUnchangedEntitiesDetected = unchangedEntities.every(
          (unchangedEntity) =>
              !detectedChangedEntities.contains(unchangedEntity),
        );

        // Property 3: Current hashes should be calculated and stored
        final hashesCalculated = incrementalData.entityHashes.isNotEmpty;

        // Property 4: All detected changes should have valid timestamps
        final allChangesHaveValidTimestamps = incrementalData.changes.every(
          (change) => change.timestamp.isBefore(
            DateTime.now().add(const Duration(seconds: 1)),
          ),
        );

        return allExpectedChangesDetected &&
            noUnchangedEntitiesDetected &&
            hashesCalculated &&
            allChangesHaveValidTimestamps;
      },
      iterations: 20,
    );

    /// Additional property test for calculateDeltas method
    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Hash-based delta calculation should detect all differences between data sets',
      generator: _generateDeltaCalculationScenario,
      property: (scenario) async {
        final oldData = scenario['oldData'] as Map<String, dynamic>;
        final newData = scenario['newData'] as Map<String, dynamic>;
        final expectedCreates = scenario['expectedCreates'] as int;
        final expectedUpdates = scenario['expectedUpdates'] as int;
        final expectedDeletes = scenario['expectedDeletes'] as int;

        // Calculate deltas
        final changes = await deltaDetector.calculateDeltas(oldData, newData);

        // Count changes by type
        final creates = changes
            .where((c) => c.type == ChangeType.create)
            .length;
        final updates = changes
            .where((c) => c.type == ChangeType.update)
            .length;
        final deletes = changes
            .where((c) => c.type == ChangeType.delete)
            .length;

        // Property: Change counts should match expected values
        final correctCounts =
            creates == expectedCreates &&
            updates == expectedUpdates &&
            deletes == expectedDeletes;

        // Property: All changes should have valid entity types and IDs
        final validChanges = changes.every(
          (change) =>
              change.entityType.isNotEmpty && change.entityId.isNotEmpty,
        );

        return correctCounts && validChanges;
      },
      iterations: 20,
    );

    test(
      'Hash calculator should produce consistent hashes for same data',
      () async {
        final hashCalculator = HashCalculator();
        final testData = {
          'id': '123',
          'amount': 100.50,
          'description': 'Test transaction',
          'createdAt': DateTime.now().toIso8601String(),
        };

        final hash1 = await hashCalculator.calculateHash(testData);
        final hash2 = await hashCalculator.calculateHash(testData);

        expect(hash1, equals(hash2));
        expect(hash1.isNotEmpty, true);
      },
    );

    test(
      'Hash calculator should produce different hashes for different data',
      () async {
        final hashCalculator = HashCalculator();
        final testData1 = {'id': '123', 'amount': 100.50};
        final testData2 = {
          'id': '123',
          'amount': 200.50, // Different amount
        };

        final hash1 = await hashCalculator.calculateHash(testData1);
        final hash2 = await hashCalculator.calculateHash(testData2);

        expect(hash1, isNot(equals(hash2)));
      },
    );
  });
}

/// Generate a scenario for testing hash-based change detection
Map<String, dynamic> _generateHashComparisonScenario() {
  final lastBackupDate = PropertyTest.randomDateTime(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now().subtract(const Duration(hours: 1)),
  );

  final currentData = <String, dynamic>{};
  final previousHashes = <String, String>{};
  final expectedChanges = <String>[];
  final unchangedEntities = <String>[];

  // Generate some unchanged entities (same hash)
  final unchangedCount = PropertyTest.randomInt(min: 1, max: 3);
  for (int i = 0; i < unchangedCount; i++) {
    final entityId = 'unchanged_${PropertyTest.randomString(maxLength: 8)}';
    final entityData = {
      'id': entityId,
      'amount': PropertyTest.randomPositiveDouble(),
      'createdAt': lastBackupDate
          .subtract(Duration(hours: PropertyTest.randomInt(min: 1, max: 24)))
          .toIso8601String(),
    };

    // Add to transactions list
    if (!currentData.containsKey('transactions')) {
      currentData['transactions'] = <Map<String, dynamic>>[];
    }
    (currentData['transactions'] as List<Map<String, dynamic>>).add(entityData);

    // Calculate hash and add to previous hashes (simulating unchanged data)
    final entityKey = 'transactions_$entityId';
    previousHashes[entityKey] = _calculateSimpleHash(entityData);
    unchangedEntities.add(entityKey);
  }

  // Generate some changed entities (different hash)
  final changedCount = PropertyTest.randomInt(min: 1, max: 3);
  for (int i = 0; i < changedCount; i++) {
    final entityId = 'changed_${PropertyTest.randomString(maxLength: 8)}';
    final entityData = {
      'id': entityId,
      'amount': PropertyTest.randomPositiveDouble(),
      'createdAt': lastBackupDate
          .subtract(Duration(hours: PropertyTest.randomInt(min: 1, max: 24)))
          .toIso8601String(),
      'updatedAt': lastBackupDate
          .add(Duration(hours: PropertyTest.randomInt(min: 1, max: 24)))
          .toIso8601String(),
    };

    // Add to transactions list
    if (!currentData.containsKey('transactions')) {
      currentData['transactions'] = <Map<String, dynamic>>[];
    }
    (currentData['transactions'] as List<Map<String, dynamic>>).add(entityData);

    // Add old hash to previous hashes (simulating changed data)
    final entityKey = 'transactions_$entityId';
    final oldEntityData = Map<String, dynamic>.from(entityData);
    oldEntityData['amount'] =
        (entityData['amount'] as double) - 10.0; // Different amount
    previousHashes[entityKey] = _calculateSimpleHash(oldEntityData);
    expectedChanges.add(entityKey);
  }

  // Generate some new entities (no previous hash)
  final newCount = PropertyTest.randomInt(min: 1, max: 3);
  for (int i = 0; i < newCount; i++) {
    final entityId = 'new_${PropertyTest.randomString(maxLength: 8)}';
    final entityData = {
      'id': entityId,
      'amount': PropertyTest.randomPositiveDouble(),
      'createdAt': lastBackupDate
          .add(Duration(hours: PropertyTest.randomInt(min: 1, max: 24)))
          .toIso8601String(),
    };

    // Add to transactions list
    if (!currentData.containsKey('transactions')) {
      currentData['transactions'] = <Map<String, dynamic>>[];
    }
    (currentData['transactions'] as List<Map<String, dynamic>>).add(entityData);

    // No previous hash for new entities
    final entityKey = 'transactions_$entityId';
    expectedChanges.add(entityKey);
  }

  return {
    'currentData': currentData,
    'previousHashes': previousHashes,
    'lastBackupDate': lastBackupDate,
    'expectedChanges': expectedChanges,
    'unchangedEntities': unchangedEntities,
  };
}

/// Generate a scenario for testing delta calculation
Map<String, dynamic> _generateDeltaCalculationScenario() {
  final oldData = <String, dynamic>{};
  final newData = <String, dynamic>{};

  int expectedCreates = 0;
  int expectedUpdates = 0;
  int expectedDeletes = 0;

  // Generate some entities that exist in both (potential updates)
  final commonCount = PropertyTest.randomInt(min: 1, max: 3);
  for (int i = 0; i < commonCount; i++) {
    final entityId = 'common_${PropertyTest.randomString(maxLength: 8)}';
    final oldEntityData = {
      'id': entityId,
      'amount': PropertyTest.randomPositiveDouble(),
    };
    final newEntityData = Map<String, dynamic>.from(oldEntityData);

    // Randomly decide if this entity is updated
    if (PropertyTest.randomBool()) {
      newEntityData['amount'] = (oldEntityData['amount'] as double) + 10.0;
      expectedUpdates++;
    }

    // Add to old and new data
    if (!oldData.containsKey('transactions')) {
      oldData['transactions'] = <Map<String, dynamic>>[];
    }
    if (!newData.containsKey('transactions')) {
      newData['transactions'] = <Map<String, dynamic>>[];
    }

    (oldData['transactions'] as List<Map<String, dynamic>>).add(oldEntityData);
    (newData['transactions'] as List<Map<String, dynamic>>).add(newEntityData);
  }

  // Generate some entities that only exist in old data (deletes)
  final deleteCount = PropertyTest.randomInt(min: 0, max: 2);
  for (int i = 0; i < deleteCount; i++) {
    final entityId = 'deleted_${PropertyTest.randomString(maxLength: 8)}';
    final entityData = {
      'id': entityId,
      'amount': PropertyTest.randomPositiveDouble(),
    };

    if (!oldData.containsKey('transactions')) {
      oldData['transactions'] = <Map<String, dynamic>>[];
    }
    (oldData['transactions'] as List<Map<String, dynamic>>).add(entityData);
    expectedDeletes++;
  }

  // Generate some entities that only exist in new data (creates)
  final createCount = PropertyTest.randomInt(min: 0, max: 2);
  for (int i = 0; i < createCount; i++) {
    final entityId = 'created_${PropertyTest.randomString(maxLength: 8)}';
    final entityData = {
      'id': entityId,
      'amount': PropertyTest.randomPositiveDouble(),
    };

    if (!newData.containsKey('transactions')) {
      newData['transactions'] = <Map<String, dynamic>>[];
    }
    (newData['transactions'] as List<Map<String, dynamic>>).add(entityData);
    expectedCreates++;
  }

  return {
    'oldData': oldData,
    'newData': newData,
    'expectedCreates': expectedCreates,
    'expectedUpdates': expectedUpdates,
    'expectedDeletes': expectedDeletes,
  };
}

/// Simple hash calculation for testing (mimics the real hash calculation)
String _calculateSimpleHash(Map<String, dynamic> data) {
  return data.toString().hashCode.toString();
}
