# Authentication Services Performance Guide

## Quick Reference

This guide provides quick tips for developers working with the authentication services to maintain optimal performance.

## Performance-Optimized Services

### 1. EncryptionHelper

**Location:** `lib/utils/security/encryption_helper.dart`

**Key Features:**
- Automatic key caching (5 minutes)
- Cache size limit (10 entries)
- Manual cache clearing available

**Usage Tips:**
```dart
// Normal usage - caching is automatic
final encrypted = EncryptionHelper.encrypt(plaintext, password);
final decrypted = EncryptionHelper.decrypt(encrypted, password);

// Clear cache when needed (e.g., on logout)
EncryptionHelper.clearKeyCache();
```

**When to Clear Cache:**
- User logout
- Security settings change
- Memory pressure
- Testing scenarios

### 2. PINService

**Location:** `lib/services/auth/pin_service.dart`

**Key Features:**
- Cached failed attempts (1 second)
- Cached lockout status (1 second)
- Cached PIN existence (5 seconds)
- Automatic cache invalidation on state changes

**Usage Tips:**
```dart
final pinService = PINService();

// These calls use cache when available
final isLocked = await pinService.isLocked();
final attempts = await pinService.getFailedAttempts();
final isPinSet = await pinService.isPINSet();

// Cache is automatically invalidated after:
// - PIN setup
// - PIN verification
// - PIN change
// - PIN reset
```

**Performance Characteristics:**
- First call: Reads from storage (~10-50ms)
- Cached calls: Returns immediately (~0-1ms)
- Cache expires: 1-5 seconds depending on value type

### 3. BiometricService

**Location:** `lib/services/auth/biometric_service.dart`

**Key Features:**
- Cached availability check (1 minute)
- Cached biometric types (1 minute)
- Reduced platform channel calls

**Usage Tips:**
```dart
final biometricService = BiometricServiceSingleton.instance;

// These calls use cache when available
final isAvailable = await biometricService.isBiometricAvailable();
final types = await biometricService.getAvailableBiometrics();

// Actual authentication always goes to platform
final result = await biometricService.authenticate();
```

**Performance Characteristics:**
- First availability check: Platform call (~50-100ms)
- Cached checks: Returns immediately (~0-1ms)
- Cache expires: 1 minute

### 4. AuthSecureStorageService

**Location:** `lib/services/auth/secure_storage_service.dart`

**Key Features:**
- Cached storage reads (5 seconds)
- Automatic cache invalidation on writes
- Fallback encryption for reliability

**Usage Tips:**
```dart
final storage = AuthSecureStorageService();

// Reads use cache when available
final value = await storage.read('key');

// Writes invalidate cache automatically
await storage.write('key', 'value');

// Deletes invalidate cache automatically
await storage.delete('key');
```

**Performance Characteristics:**
- First read: Storage + decryption (~20-100ms)
- Cached reads: Returns immediately (~0-1ms)
- Writes: Storage + encryption (~20-100ms)
- Cache expires: 5 seconds

### 5. AuthService

**Location:** `lib/services/auth/auth_service.dart`

**Key Features:**
- Proper timer cleanup
- Stream controller management
- Memory leak prevention

**Usage Tips:**
```dart
final authService = AuthService();

// Always dispose when done (e.g., in widget dispose)
@override
void dispose() {
  authService.dispose();
  super.dispose();
}

// For testing, use resetForTesting
authService.resetForTesting();
```

## Performance Best Practices

### DO ✓

1. **Use Singleton Instances:**
   ```dart
   final authService = AuthServiceSingleton.instance;
   final biometricService = BiometricServiceSingleton.instance;
   ```

2. **Dispose Services Properly:**
   ```dart
   @override
   void dispose() {
     authService.dispose();
     super.dispose();
   }
   ```

3. **Clear Caches on Security Events:**
   ```dart
   // On logout
   EncryptionHelper.clearKeyCache();
   await authService.logout();
   ```

4. **Batch Operations When Possible:**
   ```dart
   // Good: Single transaction
   await storage.write('key1', 'value1');
   await storage.write('key2', 'value2');
   
   // Better: If you need multiple reads, they'll be cached
   final value1 = await storage.read('key1');
   final value2 = await storage.read('key1'); // Cached!
   ```

### DON'T ✗

1. **Don't Create Multiple Service Instances:**
   ```dart
   // Bad
   final service1 = PINService();
   final service2 = PINService();
   
   // Good
   final service = PINService(); // Singleton
   ```

2. **Don't Forget to Dispose:**
   ```dart
   // Bad - memory leak
   final authService = AuthService();
   // ... use service ...
   // (no dispose call)
   
   // Good
   final authService = AuthService();
   // ... use service ...
   authService.dispose();
   ```

3. **Don't Clear Cache Unnecessarily:**
   ```dart
   // Bad - defeats caching purpose
   for (int i = 0; i < 10; i++) {
     EncryptionHelper.clearKeyCache();
     EncryptionHelper.encrypt(data, password);
   }
   
   // Good - let cache work
   for (int i = 0; i < 10; i++) {
     EncryptionHelper.encrypt(data, password);
   }
   ```

4. **Don't Ignore Async Operations:**
   ```dart
   // Bad - not awaiting
   pinService.verifyPIN(pin);
   
   // Good
   await pinService.verifyPIN(pin);
   ```

## Performance Monitoring

### Key Metrics to Track

1. **Response Times:**
   - PIN verification time
   - Biometric authentication time
   - Session initialization time

2. **Cache Performance:**
   - Cache hit rate
   - Cache miss rate
   - Average response time (cached vs uncached)

3. **Memory Usage:**
   - Service memory footprint
   - Cache memory usage
   - Peak memory during operations

### Example Monitoring Code

```dart
// Measure operation time
final stopwatch = Stopwatch()..start();
await pinService.verifyPIN(pin);
stopwatch.stop();
print('PIN verification took: ${stopwatch.elapsedMilliseconds}ms');

// Check if within requirements
assert(stopwatch.elapsedMilliseconds < 500, 'PIN verification too slow');
```

## Troubleshooting

### Slow Performance

**Symptom:** Operations taking longer than expected

**Possible Causes:**
1. Cache not being used (check cache expiry)
2. Too many cache clears
3. Storage encryption overhead
4. Platform channel delays

**Solutions:**
1. Verify cache is enabled
2. Reduce unnecessary cache clears
3. Check storage performance
4. Profile platform calls

### Memory Issues

**Symptom:** High memory usage or leaks

**Possible Causes:**
1. Services not disposed
2. Timers not cancelled
3. Stream controllers not closed
4. Cache growing too large

**Solutions:**
1. Always call dispose()
2. Check timer cleanup
3. Verify stream closure
4. Monitor cache size

### Inconsistent State

**Symptom:** Cached values don't match storage

**Possible Causes:**
1. Cache not invalidated on write
2. Cache expiry too long
3. Concurrent modifications

**Solutions:**
1. Verify cache invalidation logic
2. Reduce cache expiry time
3. Add synchronization if needed

## Testing Performance

### Unit Tests

```dart
test('should complete within time limit', () async {
  final stopwatch = Stopwatch()..start();
  await pinService.verifyPIN('1234');
  stopwatch.stop();
  
  expect(stopwatch.elapsedMilliseconds, lessThan(500));
});
```

### Integration Tests

```dart
testWidgets('authentication flow performance', (tester) async {
  final stopwatch = Stopwatch()..start();
  
  // Perform full authentication flow
  await tester.pumpWidget(MyApp());
  await tester.enterText(find.byType(TextField), '1234');
  await tester.tap(find.byType(ElevatedButton));
  await tester.pumpAndSettle();
  
  stopwatch.stop();
  expect(stopwatch.elapsedMilliseconds, lessThan(1000));
});
```

### Benchmark Tests

See `test/services/auth/performance_optimization_test.dart` for comprehensive performance benchmarks.

## Related Documentation

- [Performance Optimization Implementation](../../../docs/performance_optimization_implementation.md)
- [PERF-001 Summary](.kiro/specs/pin-biometric-auth/PERF-001-SUMMARY.md)
- [Design Document](.kiro/specs/pin-biometric-auth/design.md)

## Support

For performance-related issues or questions:
1. Check this guide first
2. Review the performance tests
3. Profile the specific operation
4. Consult the implementation documentation
