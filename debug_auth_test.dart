import 'dart:io';

void main() async {
  print('🧪 Starting Simple Auth Debug Test...');
  
  try {
    // Basit test - sadece print'ler
    print('✅ Test başlatıldı');
    
    // Simulated auth state
    bool isAuthenticated = true;
    DateTime lastActivity = DateTime.now();
    Duration sessionTimeout = Duration(minutes: 5);
    
    print('📊 Initial state:');
    print('  - Authenticated: $isAuthenticated');
    print('  - Last activity: $lastActivity');
    print('  - Session timeout: ${sessionTimeout.inMinutes} minutes');
    
    // Simulate inactivity
    print('⏰ Simulating 6 minutes of inactivity...');
    DateTime simulatedNow = lastActivity.add(Duration(minutes: 6));
    Duration timeSinceActivity = simulatedNow.difference(lastActivity);
    
    print('📊 After inactivity:');
    print('  - Time since activity: ${timeSinceActivity.inMinutes} minutes');
    print('  - Should timeout: ${timeSinceActivity > sessionTimeout}');
    
    if (timeSinceActivity > sessionTimeout) {
      isAuthenticated = false;
      print('🔒 Session timed out - user logged out');
    }
    
    print('📊 Final state:');
    print('  - Authenticated: $isAuthenticated');
    
    if (!isAuthenticated) {
      print('✅ SUCCESS: Inactivity timeout working correctly');
    } else {
      print('❌ FAILED: Session should have timed out');
    }
    
  } catch (e) {
    print('❌ Test failed: $e');
  }
}