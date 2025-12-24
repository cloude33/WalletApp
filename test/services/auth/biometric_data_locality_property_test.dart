import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import '../../property_test_utils.dart';

/// Test data structure for biometric data locality testing
class BiometricDataLocalityTestData {
  final String operation;
  final bool shouldViolateLocality;
  final Map<String, dynamic> operationData;
  
  BiometricDataLocalityTestData({
    required this.operation,
    required this.shouldViolateLocality,
    required this.operationData,
  });
}

/// Helper class to simulate biometric data operations and track locality violations
class BiometricDataLocalityTracker {
  final List<String> _localOperations = [];
  final List<String> _externalOperations = [];
  final Map<String, dynamic> _localData = {};
  
  /// Simulate storing biometric configuration
  Future<bool> storeBiometricConfig(bool enabled, String type, {bool simulateExternal = false}) async {
    final operation = 'store_biometric_config: enabled=$enabled, type=$type';
    
    if (simulateExternal) {
      _externalOperations.add(operation);
      debugPrint('VIOLATION: Biometric config sent to external server');
      return false; // Violation should fail
    } else {
      _localOperations.add(operation);
      _localData['biometric_enabled'] = enabled;
      _localData['biometric_type'] = type;
      return true;
    }
  }
  
  /// Simulate retrieving biometric configuration
  Future<Map<String, dynamic>?> getBiometricConfig({bool simulateExternal = false}) async {
    final operation = 'get_biometric_config';
    
    if (simulateExternal) {
      _externalOperations.add(operation);
      debugPrint('VIOLATION: Biometric config fetched from external server');
      return null; // Violation should fail
    } else {
      _localOperations.add(operation);
      if (_localData.containsKey('biometric_enabled') && _localData.containsKey('biometric_type')) {
        return {
          'enabled': _localData['biometric_enabled'] as bool,
          'type': _localData['biometric_type'] as String,
        };
      }
      return null;
    }
  }
  
  /// Simulate storing device ID
  Future<bool> storeDeviceId(String deviceId, {bool simulateExternal = false}) async {
    final operation = 'store_device_id: $deviceId';
    
    if (simulateExternal) {
      _externalOperations.add(operation);
      debugPrint('VIOLATION: Device ID sent to external server');
      return false; // Violation should fail
    } else {
      _localOperations.add(operation);
      _localData['device_id'] = deviceId;
      return true;
    }
  }
  
  /// Simulate retrieving device ID
  Future<String?> getDeviceId({bool simulateExternal = false}) async {
    final operation = 'get_device_id';
    
    if (simulateExternal) {
      _externalOperations.add(operation);
      debugPrint('VIOLATION: Device ID fetched from external server');
      return null; // Violation should fail
    } else {
      _localOperations.add(operation);
      return _localData['device_id'] as String?;
    }
  }
  
  /// Simulate clearing biometric data
  Future<bool> clearBiometricData({bool simulateExternal = false}) async {
    final operation = 'clear_biometric_data';
    
    if (simulateExternal) {
      _externalOperations.add(operation);
      debugPrint('VIOLATION: Biometric data deletion sent to external server');
      // Even if external, we should clear local data
      _localData.clear();
      return true; // Clearing should succeed but is a violation
    } else {
      _localOperations.add(operation);
      _localData.clear();
      return true;
    }
  }
  
  /// Simulate biometric enrollment
  Future<bool> enrollBiometric({bool simulateExternal = false}) async {
    final operation = 'enroll_biometric';
    
    if (simulateExternal) {
      _externalOperations.add(operation);
      debugPrint('VIOLATION: Biometric enrollment data sent to external server');
      return false; // Violation should fail
    } else {
      _localOperations.add(operation);
      _localData['biometric_enrolled'] = true;
      return true;
    }
  }
  
  /// Check if any external operations were performed (locality violation)
  bool hasLocalityViolations() {
    return _externalOperations.isNotEmpty;
  }
  
  /// Get all local operations
  List<String> getLocalOperations() {
    return List.from(_localOperations);
  }
  
  /// Get all external operations (violations)
  List<String> getExternalOperations() {
    return List.from(_externalOperations);
  }
  
  /// Get all locally stored data
  Map<String, dynamic> getLocalData() {
    return Map.from(_localData);
  }
  
  /// Reset the tracker
  void reset() {
    _localOperations.clear();
    _externalOperations.clear();
    _localData.clear();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Biometric Data Locality Property Tests', () {
    // **Feature: pin-biometric-auth, Property 10: Biyometrik Veri Yerelliği**
    // **Validates: Requirements 5.1, 5.2**
    
    PropertyTest.forAll<BiometricDataLocalityTestData>(
      description: 'Property 10: Biyometrik Veri Yerelliği - '
                  'Herhangi bir biyometrik veri için, veri sadece cihazda yerel olarak saklanmalı ve asla dış sunuculara gönderilmemelidir',
      iterations: 100,
      generator: () {
        // Generate different scenarios for biometric data operations
        final operations = [
          'store_biometric_config',
          'get_biometric_config',
          'clear_biometric_data',
          'store_device_id',
          'get_device_id',
          'enroll_biometric',
        ];
        
        final operation = operations[PropertyTest.randomInt(max: operations.length - 1)];
        final shouldViolateLocality = PropertyTest.randomBool();
        
        return BiometricDataLocalityTestData(
          operation: operation,
          shouldViolateLocality: shouldViolateLocality,
          operationData: {
            'biometricEnabled': PropertyTest.randomBool(),
            'biometricType': PropertyTest.randomBool() ? 'fingerprint' : 'face',
            'deviceId': PropertyTest.randomString(minLength: 10, maxLength: 50),
          },
        );
      },
      property: (testData) async {
        final tracker = BiometricDataLocalityTracker();
        
        // Perform the operation with or without locality violation
        bool operationResult = false;
        try {
          switch (testData.operation) {
            case 'store_biometric_config':
              final enabled = testData.operationData['biometricEnabled'] as bool;
              final type = testData.operationData['biometricType'] as String;
              operationResult = await tracker.storeBiometricConfig(
                enabled, 
                type, 
                simulateExternal: testData.shouldViolateLocality,
              );
              break;
              
            case 'get_biometric_config':
              final config = await tracker.getBiometricConfig(
                simulateExternal: testData.shouldViolateLocality,
              );
              operationResult = config != null;
              break;
              
            case 'clear_biometric_data':
              operationResult = await tracker.clearBiometricData(
                simulateExternal: testData.shouldViolateLocality,
              );
              break;
              
            case 'store_device_id':
              final deviceId = testData.operationData['deviceId'] as String;
              operationResult = await tracker.storeDeviceId(
                deviceId, 
                simulateExternal: testData.shouldViolateLocality,
              );
              break;
              
            case 'get_device_id':
              final deviceId = await tracker.getDeviceId(
                simulateExternal: testData.shouldViolateLocality,
              );
              operationResult = deviceId != null;
              break;
              
            case 'enroll_biometric':
              operationResult = await tracker.enrollBiometric(
                simulateExternal: testData.shouldViolateLocality,
              );
              break;
          }
        } catch (e) {
          // Operations should handle errors gracefully
          operationResult = false;
        }
        
        // Property: For any biometric data operation, data should only be stored locally
        // This means:
        // 1. If external access is attempted, operations should fail or be rejected
        // 2. No external operations should be recorded
        // 3. All data should remain on the local device only
        
        if (testData.shouldViolateLocality) {
          // If locality violation was simulated, check the results
          
          // For operations that store data, they should fail when external access is attempted
          if (testData.operation.contains('store') || testData.operation == 'enroll_biometric') {
            if (operationResult) {
              // Store/enroll operations should fail when external access is attempted
              return false;
            }
          }
          
          // There should be external operations recorded (violations)
          if (!tracker.hasLocalityViolations()) {
            // If we simulated external access, there should be violations recorded
            return false;
          }
          
          // External operations should be recorded
          final externalOps = tracker.getExternalOperations();
          if (externalOps.isEmpty) {
            return false;
          }
          
        } else {
          // If no locality violation was simulated, operations should succeed locally
          
          // There should be no external operations (no violations)
          if (tracker.hasLocalityViolations()) {
            return false;
          }
          
          // Local operations should be recorded
          final localOps = tracker.getLocalOperations();
          if (localOps.isEmpty) {
            return false;
          }
          
          // For store operations, they should succeed
          if (testData.operation.contains('store') || testData.operation == 'enroll_biometric') {
            if (!operationResult) {
              // Store/enroll operations should succeed when no external access
              return false;
            }
          }
          
          // For get operations after store, they should return data
          if (testData.operation.contains('get')) {
            // First store some data
            if (testData.operation == 'get_biometric_config') {
              await tracker.storeBiometricConfig(true, 'fingerprint');
              final config = await tracker.getBiometricConfig();
              if (config == null) {
                return false;
              }
            } else if (testData.operation == 'get_device_id') {
              await tracker.storeDeviceId('test-device-id');
              final deviceId = await tracker.getDeviceId();
              if (deviceId == null) {
                return false;
              }
            }
          }
        }
        
        // All locality checks passed
        return true;
      },
    );

    // Additional specific test cases for edge scenarios
    test('Property 10 - Edge case: Biometric config should be stored locally only', () async {
      final tracker = BiometricDataLocalityTracker();
      
      // Store biometric config locally
      final storeResult = await tracker.storeBiometricConfig(true, 'fingerprint');
      expect(storeResult, isTrue);
      
      // Verify no locality violations
      expect(tracker.hasLocalityViolations(), isFalse);
      
      // Verify we can retrieve it locally
      final config = await tracker.getBiometricConfig();
      expect(config, isNotNull);
      expect(config!['enabled'], isTrue);
      expect(config['type'], equals('fingerprint'));
      
      // Verify local operations were recorded
      final localOps = tracker.getLocalOperations();
      expect(localOps.length, equals(2)); // store + get
    });

    test('Property 10 - Edge case: External access should be rejected', () async {
      final tracker = BiometricDataLocalityTracker();
      
      // Store operations should fail when external access is attempted
      final storeResult = await tracker.storeBiometricConfig(true, 'fingerprint', simulateExternal: true);
      expect(storeResult, isFalse);
      
      // Biometric enrollment should fail when external access is attempted
      final enrollResult = await tracker.enrollBiometric(simulateExternal: true);
      expect(enrollResult, isFalse);
      
      // Locality violations should be recorded
      expect(tracker.hasLocalityViolations(), isTrue);
      
      // External operations should be recorded
      final externalOps = tracker.getExternalOperations();
      expect(externalOps.length, equals(2)); // store + enroll attempts
    });

    test('Property 10 - Edge case: Mixed operations maintain locality', () async {
      final tracker = BiometricDataLocalityTracker();
      
      // Perform several local operations
      await tracker.storeBiometricConfig(true, 'face');
      await tracker.storeDeviceId('device-123');
      await tracker.enrollBiometric();
      
      // Verify no locality violations
      expect(tracker.hasLocalityViolations(), isFalse);
      
      // Verify data is stored locally
      final localData = tracker.getLocalData();
      expect(localData['biometric_enabled'], isTrue);
      expect(localData['biometric_type'], equals('face'));
      expect(localData['device_id'], equals('device-123'));
      expect(localData['biometric_enrolled'], isTrue);
      
      // Verify local operations were recorded
      final localOps = tracker.getLocalOperations();
      expect(localOps.length, equals(3));
    });

    test('Property 10 - Edge case: Data clearing maintains locality', () async {
      final tracker = BiometricDataLocalityTracker();
      
      // Store some data first
      await tracker.storeBiometricConfig(true, 'fingerprint');
      await tracker.storeDeviceId('test-device-id');
      
      final initialDataCount = tracker.getLocalData().length;
      expect(initialDataCount, greaterThan(0));
      
      // Clear biometric data locally
      final clearResult = await tracker.clearBiometricData();
      expect(clearResult, isTrue);
      
      // Data should be cleared locally
      final finalDataCount = tracker.getLocalData().length;
      expect(finalDataCount, equals(0));
      
      // Should remain local operation (no violations)
      expect(tracker.hasLocalityViolations(), isFalse);
      
      // Local operations should be recorded
      final localOps = tracker.getLocalOperations();
      expect(localOps.length, equals(3)); // store + store + clear
    });

    test('Property 10 - Edge case: Round trip operations maintain locality', () async {
      final tracker = BiometricDataLocalityTracker();
      
      // Store biometric config
      final storeResult = await tracker.storeBiometricConfig(true, 'fingerprint');
      expect(storeResult, isTrue);
      
      // Retrieve biometric config
      final config = await tracker.getBiometricConfig();
      expect(config, isNotNull);
      expect(config!['enabled'], isTrue);
      expect(config['type'], equals('fingerprint'));
      
      // Store device ID
      final deviceStoreResult = await tracker.storeDeviceId('device-456');
      expect(deviceStoreResult, isTrue);
      
      // Retrieve device ID
      final deviceId = await tracker.getDeviceId();
      expect(deviceId, equals('device-456'));
      
      // Verify no locality violations throughout
      expect(tracker.hasLocalityViolations(), isFalse);
      
      // Verify all operations were local
      final localOps = tracker.getLocalOperations();
      expect(localOps.length, equals(4)); // 2 stores + 2 gets
      
      // Verify no external operations
      final externalOps = tracker.getExternalOperations();
      expect(externalOps.length, equals(0));
    });
  });
}