import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Setup common mocks for platform channels
void setupCommonTestMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock path_provider
  const MethodChannel pathProviderChannel = MethodChannel(
    'plugins.flutter.io/path_provider',
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(pathProviderChannel, (
        MethodCall methodCall,
      ) async {
        return 'test_temp';
      });

  // Mock connectivity_plus
  const MethodChannel connectivityChannel = MethodChannel(
    'dev.fluttercommunity.plus/connectivity',
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(connectivityChannel, (
        MethodCall methodCall,
      ) async {
        if (methodCall.method == 'check') {
          return ['wifi'];
        }
        return null;
      });

  // Mock flutter_secure_storage
  const MethodChannel secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(secureStorageChannel, (
        MethodCall methodCall,
      ) async {
        return null; // For read/write/delete typically returns null or success bool
      });
}
