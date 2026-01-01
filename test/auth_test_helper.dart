import 'package:flutter_test/flutter_test.dart';
import 'package:parion/services/auth/auth_service.dart';
import 'package:parion/services/auth/secure_storage_service.dart';
import 'test_setup.dart';

class AuthTestHelper {
  static AuthService? _authService;
  static AuthSecureStorageService? _storageService;

  /// Initialize AuthService for testing with proper mocks
  static Future<AuthService> initializeAuthService() async {
    // Ensure test environment is set up
    await TestSetup.initializeTestEnvironment();

    // Reset services to clean state
    _authService = AuthService();
    _storageService = AuthSecureStorageService();
    
    // Reset for testing
    _authService!.resetForTesting();
    _storageService!.resetForTesting();

    try {
      // Try to initialize - if it fails due to plugin issues, that's expected in test environment
      await _authService!.initialize();
    } catch (e) {
      // Expected in test environment due to plugin mocking
      print('AuthService initialization skipped in test environment: $e');
    }

    return _authService!;
  }

  /// Clean up AuthService after testing
  static void cleanupAuthService() {
    try {
      _authService?.resetForTesting();
      _storageService?.resetForTesting();
      _authService?.dispose();
    } catch (e) {
      print('AuthService cleanup warning: $e');
    }
    _authService = null;
    _storageService = null;
  }

  /// Get current AuthService instance (for tests that need it)
  static AuthService? get authService => _authService;

  /// Get current StorageService instance (for tests that need it)
  static AuthSecureStorageService? get storageService => _storageService;
}