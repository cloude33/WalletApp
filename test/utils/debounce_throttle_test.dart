import 'package:flutter_test/flutter_test.dart';
import 'package:parion/utils/debounce_throttle.dart';

void main() {
  group('Debouncer Tests', () {
    test('should delay execution until after delay period', () async {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 100));
      int callCount = 0;

      debouncer.call(() => callCount++);
      
      // Should not execute immediately
      expect(callCount, 0);
      
      // Wait for delay
      await Future.delayed(const Duration(milliseconds: 150));
      
      // Should execute after delay
      expect(callCount, 1);
      
      debouncer.dispose();
    });

    test('should cancel previous call when called again', () async {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 100));
      int callCount = 0;

      // First call
      debouncer.call(() => callCount++);
      
      // Wait 50ms (less than delay)
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Second call should cancel first
      debouncer.call(() => callCount++);
      
      // Wait for delay
      await Future.delayed(const Duration(milliseconds: 150));
      
      // Should only execute once (the second call)
      expect(callCount, 1);
      
      debouncer.dispose();
    });

    test('should execute multiple times if delay expires between calls', () async {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 50));
      int callCount = 0;

      // First call
      debouncer.call(() => callCount++);
      await Future.delayed(const Duration(milliseconds: 100));
      expect(callCount, 1);

      // Second call after delay
      debouncer.call(() => callCount++);
      await Future.delayed(const Duration(milliseconds: 100));
      expect(callCount, 2);
      
      debouncer.dispose();
    });

    test('should cancel pending action when cancel is called', () async {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 100));
      int callCount = 0;

      debouncer.call(() => callCount++);
      
      // Cancel before delay expires
      await Future.delayed(const Duration(milliseconds: 50));
      debouncer.cancel();
      
      // Wait past original delay
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Should not execute
      expect(callCount, 0);
      
      debouncer.dispose();
    });

    test('should handle rapid successive calls correctly', () async {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 100));
      int callCount = 0;

      // Rapid calls
      for (int i = 0; i < 10; i++) {
        debouncer.call(() => callCount++);
        await Future.delayed(const Duration(milliseconds: 10));
      }
      
      // Wait for delay
      await Future.delayed(const Duration(milliseconds: 150));
      
      // Should only execute once (the last call)
      expect(callCount, 1);
      
      debouncer.dispose();
    });
  });

  group('Throttler Tests', () {
    test('should execute immediately on first call', () {
      final throttler = Throttler(duration: const Duration(milliseconds: 100));
      int callCount = 0;

      throttler.call(() => callCount++);
      
      // Should execute immediately
      expect(callCount, 1);
      
      throttler.dispose();
    });

    test('should ignore calls during throttle period', () async {
      final throttler = Throttler(duration: const Duration(milliseconds: 100));
      int callCount = 0;

      // First call executes
      throttler.call(() => callCount++);
      expect(callCount, 1);
      
      // Calls during throttle period are ignored
      throttler.call(() => callCount++);
      throttler.call(() => callCount++);
      expect(callCount, 1);
      
      // Wait for throttle to expire
      await Future.delayed(const Duration(milliseconds: 150));
      
      // Next call should execute
      throttler.call(() => callCount++);
      expect(callCount, 2);
      
      throttler.dispose();
    });

    test('should allow execution after throttle period expires', () async {
      final throttler = Throttler(duration: const Duration(milliseconds: 50));
      int callCount = 0;

      // First call
      throttler.call(() => callCount++);
      expect(callCount, 1);
      
      // Wait for throttle to expire
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Second call should execute
      throttler.call(() => callCount++);
      expect(callCount, 2);
      
      throttler.dispose();
    });

    test('should cancel throttle when cancel is called', () async {
      final throttler = Throttler(duration: const Duration(milliseconds: 100));
      int callCount = 0;

      throttler.call(() => callCount++);
      expect(callCount, 1);
      
      // Cancel throttle
      throttler.cancel();
      
      // Should be able to call immediately
      throttler.call(() => callCount++);
      expect(callCount, 2);
      
      throttler.dispose();
    });

    test('should handle rapid successive calls correctly', () async {
      final throttler = Throttler(duration: const Duration(milliseconds: 100));
      int callCount = 0;

      // Rapid calls
      for (int i = 0; i < 10; i++) {
        throttler.call(() => callCount++);
      }
      
      // Only first call should execute
      expect(callCount, 1);
      
      // Wait for throttle to expire
      await Future.delayed(const Duration(milliseconds: 150));
      
      // Next call should execute
      throttler.call(() => callCount++);
      expect(callCount, 2);
      
      throttler.dispose();
    });
  });

  group('TrailingThrottler Tests', () {
    test('should execute immediately on first call', () {
      final throttler = TrailingThrottler(duration: const Duration(milliseconds: 100));
      int callCount = 0;

      throttler.call(() => callCount++);
      
      // Should execute immediately
      expect(callCount, 1);
      
      throttler.dispose();
    });

    test('should execute pending action after throttle period', () async {
      final throttler = TrailingThrottler(duration: const Duration(milliseconds: 100));
      int callCount = 0;

      // First call executes immediately
      throttler.call(() => callCount++);
      expect(callCount, 1);
      
      // Call during throttle period is stored
      throttler.call(() => callCount++);
      expect(callCount, 1);
      
      // Wait for throttle to expire
      await Future.delayed(const Duration(milliseconds: 150));
      
      // Pending action should execute
      expect(callCount, 2);
      
      throttler.dispose();
    });

    test('should only keep last pending action', () async {
      final throttler = TrailingThrottler(duration: const Duration(milliseconds: 100));
      int value = 0;

      // First call
      throttler.call(() => value = 1);
      expect(value, 1);
      
      // Multiple calls during throttle - only last should be kept
      throttler.call(() => value = 2);
      throttler.call(() => value = 3);
      throttler.call(() => value = 4);
      expect(value, 1); // Still first value
      
      // Wait for throttle to expire
      await Future.delayed(const Duration(milliseconds: 150));
      
      // Should have executed last pending action
      expect(value, 4);
      
      throttler.dispose();
    });

    test('should cancel pending actions when cancel is called', () async {
      final throttler = TrailingThrottler(duration: const Duration(milliseconds: 100));
      int callCount = 0;

      throttler.call(() => callCount++);
      expect(callCount, 1);
      
      // Add pending action
      throttler.call(() => callCount++);
      
      // Cancel before throttle expires
      throttler.cancel();
      
      // Wait past throttle period
      await Future.delayed(const Duration(milliseconds: 150));
      
      // Pending action should not execute
      expect(callCount, 1);
      
      throttler.dispose();
    });
  });

  group('Integration Tests', () {
    test('debouncer should work well for search input simulation', () async {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 300));
      String searchQuery = '';
      int searchCallCount = 0;

      void performSearch(String query) {
        searchQuery = query;
        searchCallCount++;
      }

      // Simulate user typing "flutter"
      debouncer.call(() => performSearch('f'));
      await Future.delayed(const Duration(milliseconds: 50));
      debouncer.call(() => performSearch('fl'));
      await Future.delayed(const Duration(milliseconds: 50));
      debouncer.call(() => performSearch('flu'));
      await Future.delayed(const Duration(milliseconds: 50));
      debouncer.call(() => performSearch('flut'));
      await Future.delayed(const Duration(milliseconds: 50));
      debouncer.call(() => performSearch('flutt'));
      await Future.delayed(const Duration(milliseconds: 50));
      debouncer.call(() => performSearch('flutte'));
      await Future.delayed(const Duration(milliseconds: 50));
      debouncer.call(() => performSearch('flutter'));
      
      // Wait for debounce
      await Future.delayed(const Duration(milliseconds: 400));
      
      // Should only search once with final query
      expect(searchCallCount, 1);
      expect(searchQuery, 'flutter');
      
      debouncer.dispose();
    });

    test('throttler should work well for scroll event simulation', () async {
      final throttler = Throttler(duration: const Duration(milliseconds: 100));
      int scrollEventCount = 0;

      void handleScroll() {
        scrollEventCount++;
      }

      // Simulate rapid scroll events
      for (int i = 0; i < 50; i++) {
        throttler.call(handleScroll);
        await Future.delayed(const Duration(milliseconds: 10));
      }
      
      // Should have throttled most events
      // With 50 events at 10ms intervals (500ms total) and 100ms throttle,
      // we expect around 5-6 executions
      expect(scrollEventCount, lessThan(10));
      expect(scrollEventCount, greaterThan(3));
      
      throttler.dispose();
    });

    test('combined debouncer and throttler for filter changes', () async {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 200));
      final throttler = Throttler(duration: const Duration(milliseconds: 100));
      
      int debouncedFilterCount = 0;
      int throttledUpdateCount = 0;

      void applyFilter() {
        debouncedFilterCount++;
      }

      void updateUI() {
        throttledUpdateCount++;
      }

      // Simulate rapid filter changes with UI updates
      for (int i = 0; i < 10; i++) {
        debouncer.call(applyFilter);
        throttler.call(updateUI);
        await Future.delayed(const Duration(milliseconds: 30));
      }
      
      // Wait for debounce
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Filter should apply once (debounced)
      expect(debouncedFilterCount, 1);
      
      // UI should update multiple times but throttled
      expect(throttledUpdateCount, greaterThan(1));
      expect(throttledUpdateCount, lessThan(10));
      
      debouncer.dispose();
      throttler.dispose();
    });
  });
}
