import 'package:flutter/material.dart';
import 'lib/utils/background_lock_debug.dart';

/// Simple test runner for background lock functionality
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🧪 Starting Background Lock Test...');
  
  try {
    // Run debug test
    await BackgroundLockDebug.debugBackgroundLock();
    
    print('✅ Test completed successfully');
  } catch (e) {
    print('❌ Test failed: $e');
  }
}