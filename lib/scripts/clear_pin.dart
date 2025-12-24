import 'package:flutter/material.dart';
import 'package:money/services/auth/secure_storage_service.dart';

/// Temporary script to clear PIN and security data
/// Run this once to reset PIN
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final storage = AuthSecureStorageService();
  await storage.initialize();
  
  print('Clearing all authentication data...');
  final success = await storage.clearAllAuthData();
  
  if (success) {
    print('✅ Successfully cleared all authentication data including PIN');
  } else {
    print('❌ Failed to clear authentication data');
  }
}
