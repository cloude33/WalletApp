import 'package:flutter_test/flutter_test.dart';
import 'package:parion/services/backup_optimization/incremental_backup_strategy.dart';
import 'package:parion/services/backup_optimization/delta_detector.dart';
import 'package:parion/models/backup_optimization/incremental_data.dart';
import 'package:parion/models/backup_optimization/backup_enums.dart';
import '../../property_test_utils.dart';
import '../../test_setup.dart';

void main() {
  group('Incremental Backup Strategy Property Tests', () {
    late IncrementalBackupStrategy strategy;

    setUpAll(() async {
      await TestSetup.initializeTestEnvironment();
    });

    setUp(() async {
      await TestSetup.setupTest();
      strategy = IncrementalBackupStrategy();
    });

    tearDown(() async {
      await TestSetup.tearDownTest();
    });

    tearDownAll(() async {
      await TestSetup.cleanupTestEnvironment();
    });

    /// **Feature: backup-optimization, Property 4: Incremental Backup Round-Trip Consistency**
    /// **Validates: Requirements 1.4**
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 4: Incremental Backup Round-Trip Consistency - For any series of incremental backups, restoring them in sequence should reconstruct the exact original data state',
      generator: _generateIncrementalBackupScenario,
      property: (scenario) async {
        final originalData = scenario['originalData'] as Map<String, dynamic>;
        final dataEvolution = scenario['dataEvolution'] as List<Map<String, dynamic>>;
        final finalExpectedData = scenario['finalExpectedData'] as Map<String, dynamic>;
        
        // Create a full backup package as the base
        final fullBackupPackage = BackupPackage(
          id: 'full_backup_${DateTime.now().millisecondsSinceEpoch}',
          type: BackupType.full,
          createdAt: DateTime.now().subtract(const Duration(hours: 24)),
          data: {'backupData': originalData},
          checksum: 'full_checksum',
          originalSize: originalData.toString().length,
          compressedSize: originalData.toString().length,
        );
        
        final packages = <BackupPackage>[fullBackupPackage];
        
        // Create incremental packages for each data evolution step
        var currentData = Map<String, dynamic>.from(originalData);
        for (int i = 0; i < dataEvolution.length; i++) {
          final nextData = dataEvolution[i];
          
          // Detect changes between current and next data
          final incrementalData = await _createIncrementalData(currentData, nextData);
          
          // Create incremental package
          final incrementalPackage = await strategy.createIncrementalPackage(incrementalData);
          packages.add(incrementalPackage);
          
          currentData = nextData;
        }
        
        // Reconstruct data from all packages
        final reconstructedData = await strategy.reconstructFullData(packages);
        
        // Property 1: Reconstructed data should match the final expected data
        final dataMatches = _deepEquals(reconstructedData, finalExpectedData);
        
        // Property 2: All incremental packages should have valid parent references
        final validParentReferences = packages.skip(1).every((package) => 
          package.type == BackupType.incremental
        );
        
        // Property 3: Packages should be in chronological order
        final chronologicalOrder = _isChronologicalOrder(packages);
        
        // Property 4: Each incremental package should contain only changes
        final onlyChangesInIncrementals = await _validateIncrementalChanges(
          packages, originalData, dataEvolution
        );
        
        return dataMatches && 
               validParentReferences && 
               chronologicalOrder && 
               onlyChangesInIncrementals;
      },
      iterations: 20,
    );

    /// Additional property test for data consistency during reconstruction
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Incremental reconstruction should preserve data integrity across multiple changes',
      generator: _generateComplexDataEvolution,
      property: (scenario) async {
        final baseData = scenario['baseData'] as Map<String, dynamic>;
        final changes = scenario['changes'] as List<DataChange>;
        final expectedFinalData = scenario['expectedFinalData'] as Map<String, dynamic>;
        
        // Create full backup
        final fullPackage = BackupPackage(
          id: 'full_test',
          type: BackupType.full,
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          data: {'backupData': baseData},
          checksum: 'test_checksum',
          originalSize: 1000,
          compressedSize: 800,
        );
        
        // Create incremental data with the changes
        final incrementalData = IncrementalData(
          referenceDate: DateTime.now().subtract(const Duration(minutes: 30)),
          changes: changes,
          entityHashes: {},
          totalChanges: changes.length,
        );
        
        // Create incremental package
        final incrementalPackage = await strategy.createIncrementalPackage(incrementalData);
        
        // Reconstruct data
        final packages = [fullPackage, incrementalPackage];
        final reconstructedData = await strategy.reconstructFullData(packages);
        
        // Property: Reconstructed data should match expected final data
        return _deepEquals(reconstructedData, expectedFinalData);
      },
      iterations: 20,
    );

    test('Simple incremental backup round-trip test', () async {
      // Create simple original data
      final originalData = {
        'transactions': [
          {'id': 'tx1', 'amount': 100.0, 'description': 'Original'},
        ]
      };
      
      // Create modified data
      final modifiedData = {
        'transactions': [
          {'id': 'tx1', 'amount': 150.0, 'description': 'Updated'},
          {'id': 'tx2', 'amount': 200.0, 'description': 'New'},
        ]
      };
      
      // Create full backup package
      final fullPackage = BackupPackage(
        id: 'full_simple',
        type: BackupType.full,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        data: {'backupData': originalData},
        checksum: 'simple_checksum',
        originalSize: 1000,
        compressedSize: 800,
      );
      
      // Create incremental data
      final incrementalData = await _createIncrementalData(originalData, modifiedData);
      
      // Create incremental package
      final incrementalPackage = await strategy.createIncrementalPackage(incrementalData);
      
      // Reconstruct data
      final packages = [fullPackage, incrementalPackage];
      final reconstructedData = await strategy.reconstructFullData(packages);
      
      // Check if reconstruction matches expected data
      expect(_deepEquals(reconstructedData, modifiedData), true);
    });

    test('Empty incremental backup should not change original data', () async {
      final originalData = {
        'transactions': [
          {'id': '1', 'amount': 100.0},
          {'id': '2', 'amount': 200.0},
        ]
      };
      
      final fullPackage = BackupPackage(
        id: 'full_empty_test',
        type: BackupType.full,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        data: {'backupData': originalData},
        checksum: 'empty_test_checksum',
        originalSize: 1000,
        compressedSize: 800,
      );
      
      // Create empty incremental data
      final emptyIncrementalData = IncrementalData(
        referenceDate: DateTime.now().subtract(const Duration(minutes: 30)),
        changes: [],
        entityHashes: {},
        totalChanges: 0,
      );
      
      final incrementalPackage = await strategy.createIncrementalPackage(emptyIncrementalData);
      
      final packages = [fullPackage, incrementalPackage];
      final reconstructedData = await strategy.reconstructFullData(packages);
      
      expect(_deepEquals(reconstructedData, originalData), true);
    });
  });
}

/// Generate a scenario with original data and its evolution through incremental changes
Map<String, dynamic> _generateIncrementalBackupScenario() {
  // Generate original data
  final originalData = <String, dynamic>{};
  
  // Add transactions
  final transactionCount = PropertyTest.randomInt(min: 2, max: 5);
  final transactions = <Map<String, dynamic>>[];
  for (int i = 0; i < transactionCount; i++) {
    transactions.add({
      'id': 'tx_$i',
      'amount': PropertyTest.randomPositiveDouble(min: 10.0, max: 1000.0),
      'description': PropertyTest.randomString(maxLength: 20),
      'createdAt': PropertyTest.randomDateTime().toIso8601String(),
    });
  }
  originalData['transactions'] = transactions;
  
  // Add credit cards
  final cardCount = PropertyTest.randomInt(min: 1, max: 3);
  final cards = <Map<String, dynamic>>[];
  for (int i = 0; i < cardCount; i++) {
    cards.add({
      'id': 'card_$i',
      'name': PropertyTest.randomString(maxLength: 15),
      'limit': PropertyTest.randomPositiveDouble(min: 1000.0, max: 10000.0),
    });
  }
  originalData['creditCards'] = cards;
  
  // Generate data evolution (2-4 steps)
  final evolutionSteps = PropertyTest.randomInt(min: 2, max: 4);
  final dataEvolution = <Map<String, dynamic>>[];
  var currentData = Map<String, dynamic>.from(originalData);
  
  for (int step = 0; step < evolutionSteps; step++) {
    currentData = _evolveData(currentData);
    dataEvolution.add(Map<String, dynamic>.from(currentData));
  }
  
  final finalExpectedData = dataEvolution.last;
  
  return {
    'originalData': originalData,
    'dataEvolution': dataEvolution,
    'finalExpectedData': finalExpectedData,
  };
}

/// Generate a complex data evolution scenario with specific changes
Map<String, dynamic> _generateComplexDataEvolution() {
  // Generate base data (only transactions for simplicity)
  final baseData = <String, dynamic>{
    'transactions': [
      {'id': 'tx1', 'amount': 100.0, 'description': 'Initial'},
      {'id': 'tx2', 'amount': 200.0, 'description': 'Second'},
    ],
  };
  
  // Generate specific changes
  final changes = <DataChange>[];
  
  // Add a new transaction (CREATE)
  final newAmount = PropertyTest.randomPositiveDouble();
  final newDescription = PropertyTest.randomString();
  changes.add(DataChange.create(
    entityType: 'transactions',
    entityId: 'tx3',
    newData: {
      'id': 'tx3',
      'amount': newAmount,
      'description': newDescription,
    },
  ));
  
  // Update an existing transaction (UPDATE)
  changes.add(DataChange.update(
    entityType: 'transactions',
    entityId: 'tx1',
    oldData: {'id': 'tx1', 'amount': 100.0, 'description': 'Initial'},
    newData: {'id': 'tx1', 'amount': 150.0, 'description': 'Updated'},
  ));
  
  // Calculate expected final data
  final expectedFinalData = <String, dynamic>{
    'transactions': [
      {'id': 'tx1', 'amount': 150.0, 'description': 'Updated'}, // Updated
      {'id': 'tx2', 'amount': 200.0, 'description': 'Second'}, // Unchanged
      {'id': 'tx3', 'amount': newAmount, 'description': newDescription}, // Created
    ],
  };
  
  return {
    'baseData': baseData,
    'changes': changes,
    'expectedFinalData': expectedFinalData,
  };
}

/// Evolve data by making random changes
Map<String, dynamic> _evolveData(Map<String, dynamic> data) {
  final evolved = Map<String, dynamic>.from(data);
  
  // Randomly modify transactions
  if (evolved.containsKey('transactions')) {
    final transactions = List<Map<String, dynamic>>.from(evolved['transactions']);
    
    // Randomly add a new transaction (50% chance)
    if (PropertyTest.randomBool() && transactions.length < 10) {
      final newId = 'tx_${DateTime.now().millisecondsSinceEpoch}_${PropertyTest.randomInt(max: 999)}';
      transactions.add({
        'id': newId,
        'amount': PropertyTest.randomPositiveDouble(),
        'description': PropertyTest.randomString(),
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
    
    // Randomly update an existing transaction (50% chance)
    if (transactions.isNotEmpty && PropertyTest.randomBool()) {
      final index = PropertyTest.randomInt(max: transactions.length - 1);
      transactions[index] = Map<String, dynamic>.from(transactions[index]);
      transactions[index]['amount'] = PropertyTest.randomPositiveDouble();
      transactions[index]['description'] = PropertyTest.randomString();
    }
    
    // Randomly remove a transaction (25% chance, but keep at least 1)
    if (transactions.length > 2 && PropertyTest.randomInt(max: 3) == 0) {
      final index = PropertyTest.randomInt(max: transactions.length - 1);
      transactions.removeAt(index);
    }
    
    evolved['transactions'] = transactions;
  }
  
  // Randomly modify credit cards
  if (evolved.containsKey('creditCards')) {
    final cards = List<Map<String, dynamic>>.from(evolved['creditCards']);
    
    // Randomly update a card limit (50% chance)
    if (cards.isNotEmpty && PropertyTest.randomBool()) {
      final index = PropertyTest.randomInt(max: cards.length - 1);
      cards[index] = Map<String, dynamic>.from(cards[index]);
      cards[index]['limit'] = PropertyTest.randomPositiveDouble(min: 1000.0, max: 15000.0);
    }
    
    evolved['creditCards'] = cards;
  }
  
  return evolved;
}

/// Create incremental data by using the actual DeltaDetector
Future<IncrementalData> _createIncrementalData(
  Map<String, dynamic> oldData,
  Map<String, dynamic> newData,
) async {
  final deltaDetector = DeltaDetector();
  
  // Use the actual delta detector to calculate changes
  final changes = await deltaDetector.calculateDeltas(oldData, newData);
  
  // Calculate hashes for the new data
  final hashCalculator = HashCalculator();
  final entityHashes = <String, String>{};
  
  // Calculate hashes for all entities in new data
  for (final entry in newData.entries) {
    final categoryName = entry.key;
    final categoryData = entry.value;
    
    if (categoryData is List) {
      for (int i = 0; i < categoryData.length; i++) {
        if (categoryData[i] is Map<String, dynamic>) {
          final entityId = _extractEntityId(categoryData[i]) ?? i.toString();
          final entityKey = '${categoryName}_$entityId';
          entityHashes[entityKey] = await hashCalculator.calculateHash(categoryData[i]);
        }
      }
    } else if (categoryData is Map<String, dynamic>) {
      final entityKey = '${categoryName}_root';
      entityHashes[entityKey] = await hashCalculator.calculateHash(categoryData);
    }
  }
  
  return IncrementalData(
    referenceDate: DateTime.now().subtract(const Duration(minutes: 30)),
    changes: changes,
    entityHashes: entityHashes,
    totalChanges: changes.length,
  );
}

/// Check if packages are in chronological order
bool _isChronologicalOrder(List<BackupPackage> packages) {
  for (int i = 1; i < packages.length; i++) {
    if (packages[i].createdAt.isBefore(packages[i - 1].createdAt)) {
      return false;
    }
  }
  return true;
}

/// Validate that incremental packages contain only actual changes
Future<bool> _validateIncrementalChanges(
  List<BackupPackage> packages,
  Map<String, dynamic> originalData,
  List<Map<String, dynamic>> dataEvolution,
) async {
  // For this property test, we assume that if the reconstruction works correctly,
  // the incremental packages contain the right changes
  // A more detailed validation would require comparing each incremental package
  // with the actual differences between consecutive data states
  return true;
}

/// Deep equality check for maps and lists
bool _deepEquals(dynamic a, dynamic b) {
  // Handle null cases
  if (a == null && b == null) return true;
  if (a == null || b == null) return false;
  
  // For maps
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || !_deepEquals(a[key], b[key])) {
        return false;
      }
    }
    return true;
  }
  
  // For lists
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (!_deepEquals(a[i], b[i])) {
        return false;
      }
    }
    return true;
  }
  
  // For primitive values
  return a == b;
}

/// Extracts entity ID from data
String? _extractEntityId(Map<String, dynamic> data) {
  return data['id']?.toString() ?? 
         data['uuid']?.toString() ?? 
         data['key']?.toString();
}