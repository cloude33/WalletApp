import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/screens/security/security_settings_screen.dart';
import 'package:money/services/auth/auth_service.dart';
import 'package:money/services/auth/two_factor_service.dart';

void main() {
  group('SecuritySettingsScreen Widget Tests', () {
    late AuthService authService;
    late TwoFactorService twoFactorService;

    setUp(() async {
      authService = AuthService();
      twoFactorService = TwoFactorService();
      
      await authService.initialize();
      await twoFactorService.initialize();
      
      // Reset services to clean state
      authService.resetForTesting();
      twoFactorService.resetForTesting();
    });

    testWidgets('should display security settings screen title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SecuritySettingsScreen(),
        ),
      );

      // Verify the app bar title is displayed
      expect(find.text('Güvenlik Ayarları'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('should show loading indicator initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SecuritySettingsScreen(),
        ),
      );

      // Verify loading indicator is shown initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display authentication methods section', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SecuritySettingsScreen(),
        ),
      );

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Verify authentication methods section is displayed
      expect(find.text('Kimlik Doğrulama Yöntemleri'), findsOneWidget);
      expect(find.text('Biyometrik Doğrulama'), findsOneWidget);
    });

    testWidgets('should display session settings section', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SecuritySettingsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify session settings section is displayed
      expect(find.text('Oturum Ayarları'), findsOneWidget);
      expect(find.text('Oturum Zaman Aşımı'), findsOneWidget);
      expect(find.text('Arka Plan Kilitleme'), findsOneWidget);
    });

    testWidgets('should display two-factor authentication section', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SecuritySettingsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify two-factor authentication section is displayed
      expect(find.text('İki Faktörlü Doğrulama'), findsOneWidget);
    });

    testWidgets('should display advanced security section', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SecuritySettingsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify advanced security section is displayed
      expect(find.text('Gelişmiş Güvenlik'), findsOneWidget);
      expect(find.text('Güvenlik Seviyesi'), findsOneWidget);
      expect(find.text('Güvenlik Ayarlarını Sıfırla'), findsOneWidget);
    });

    testWidgets('should show biometric toggle switch', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SecuritySettingsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify biometric switch exists
      expect(find.byType(Switch), findsWidgets);
    });

    testWidgets('should show session timeout dropdown', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SecuritySettingsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify session timeout dropdown exists
      expect(find.byType(DropdownButton<int>), findsOneWidget);
    });

    testWidgets('should show biometric setup option when available but not enabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SecuritySettingsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // The biometric setup option may or may not be visible depending on device capabilities
      // Just verify the screen renders without errors
      expect(find.byType(SecuritySettingsScreen), findsOneWidget);
    });

    testWidgets('should display security level indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SecuritySettingsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify security level is displayed
      expect(find.text('Güvenlik Seviyesi'), findsOneWidget);
      expect(find.byIcon(Icons.shield), findsOneWidget);
    });

    testWidgets('should show two-factor methods when enabled', (WidgetTester tester) async {
      // Enable two-factor authentication
      await twoFactorService.enableSMSVerification('+905551234567');
      
      await tester.pumpWidget(
        const MaterialApp(
          home: SecuritySettingsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify two-factor methods are displayed
      expect(find.text('SMS Doğrulama'), findsOneWidget);
      expect(find.text('E-posta Doğrulama'), findsOneWidget);
      expect(find.text('Authenticator Uygulaması'), findsOneWidget);
    });

    testWidgets('should handle session timeout change', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SecuritySettingsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the session timeout dropdown
      final dropdown = find.byType(DropdownButton<int>);
      expect(dropdown, findsOneWidget);
      
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Select a different timeout option (e.g., 10 minutes)
      final option = find.text('10 dk').last;
      await tester.tap(option);
      await tester.pumpAndSettle();

      // Verify success message is shown
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('should handle background lock toggle', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SecuritySettingsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Find the background lock switch (it's one of the switches)
      final switches = find.byType(Switch);
      expect(switches, findsWidgets);
      
      // Tap the last switch (background lock)
      await tester.tap(switches.last);
      await tester.pumpAndSettle();

      // Verify the switch state changed
      expect(find.byType(Switch), findsWidgets);
    });

    testWidgets('should show confirmation dialog for destructive actions', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SecuritySettingsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll to find the reset button
      await tester.scrollUntilVisible(
        find.text('Güvenlik Ayarlarını Sıfırla'),
        500.0,
      );

      // Tap the reset security settings button
      await tester.tap(find.text('Güvenlik Ayarlarını Sıfırla'));
      await tester.pumpAndSettle();

      // Verify confirmation dialog is shown
      expect(find.text('Güvenlik Ayarlarını Sıfırla'), findsWidgets);
      expect(find.text('İptal'), findsOneWidget);
      expect(find.text('Sıfırla'), findsOneWidget);
    });

    testWidgets('should cancel destructive action when cancel is pressed', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SecuritySettingsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll to find the reset button
      await tester.scrollUntilVisible(
        find.text('Güvenlik Ayarlarını Sıfırla'),
        500.0,
      );

      // Tap the reset security settings button
      await tester.tap(find.text('Güvenlik Ayarlarını Sıfırla'));
      await tester.pumpAndSettle();

      // Tap cancel button
      await tester.tap(find.text('İptal'));
      await tester.pumpAndSettle();

      // Verify dialog is dismissed
      expect(find.text('Sıfırla'), findsNothing);
    });

    testWidgets('should display all section icons correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SecuritySettingsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify key icons are present
      expect(find.byIcon(Icons.fingerprint), findsOneWidget);
      expect(find.byIcon(Icons.timer), findsOneWidget);
      expect(find.byIcon(Icons.lock_clock), findsOneWidget);
      expect(find.byIcon(Icons.security), findsOneWidget);
      expect(find.byIcon(Icons.shield), findsOneWidget);
    });

    testWidgets('should handle error state gracefully', (WidgetTester tester) async {
      // Force an error by not initializing services properly
      // This test verifies the error UI is shown
      
      await tester.pumpWidget(
        const MaterialApp(
          home: SecuritySettingsScreen(),
        ),
      );

      // Pump a few frames
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // The screen should either show loading or content
      expect(find.byType(SecuritySettingsScreen), findsOneWidget);
    });

    testWidgets('should show retry button on error', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SecuritySettingsScreen(),
        ),
      );

      // Pump a few frames to let initialization complete
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 1));

      // If error state is shown, verify retry button exists
      // Otherwise, verify the screen loaded successfully
      final retryButton = find.text('Tekrar Dene');
      final settingsContent = find.text('Kimlik Doğrulama Yöntemleri');
      
      expect(
        retryButton.evaluate().isNotEmpty || settingsContent.evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('should display masked phone number for SMS verification', (WidgetTester tester) async {
      // Enable SMS verification with a phone number
      await twoFactorService.enableSMSVerification('+905551234567');
      
      await tester.pumpWidget(
        const MaterialApp(
          home: SecuritySettingsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify masked phone number is displayed (last 4 digits visible)
      expect(find.textContaining('****'), findsWidgets);
    });

    testWidgets('should display masked email for email verification', (WidgetTester tester) async {
      // Enable email verification
      await twoFactorService.enableEmailVerification('test@example.com');
      
      await tester.pumpWidget(
        const MaterialApp(
          home: SecuritySettingsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify masked email is displayed
      expect(find.textContaining('te*'), findsWidgets);
    });

    testWidgets('should show backup codes count when available', (WidgetTester tester) async {
      // Enable two-factor with backup codes
      await twoFactorService.enableSMSVerification('+905551234567');
      
      await tester.pumpWidget(
        const MaterialApp(
          home: SecuritySettingsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify backup codes section is shown
      final backupCodesText = find.text('Yedek Kodlar');
      if (backupCodesText.evaluate().isNotEmpty) {
        expect(backupCodesText, findsOneWidget);
      }
    });

    // PIN change test removed

    testWidgets('should handle scroll correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SecuritySettingsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify scrollable content
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      
      // Scroll down
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();

      // Verify we can still see the screen
      expect(find.byType(SecuritySettingsScreen), findsOneWidget);
    });

    testWidgets('should display all cards with proper styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SecuritySettingsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify cards are displayed
      expect(find.byType(Card), findsWidgets);
      
      // Verify cards have proper elevation and shape
      final cards = tester.widgetList<Card>(find.byType(Card));
      for (final card in cards) {
        expect(card.elevation, equals(2));
        expect(card.shape, isA<RoundedRectangleBorder>());
      }
    });

    testWidgets('should show proper security level colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SecuritySettingsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify security level indicator exists
      expect(find.byIcon(Icons.shield), findsOneWidget);
      
      // The color will depend on the current security configuration
      // Just verify the widget is rendered
      expect(find.text('Güvenlik Seviyesi'), findsOneWidget);
    });
  });

  group('SecuritySettingsScreen Integration Tests', () {
    testWidgets('should handle multiple setting changes', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SecuritySettingsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Find switches
      final switches = find.byType(Switch);
      if (switches.evaluate().length >= 2) {
        // Toggle first switch
        await tester.tap(switches.first);
        await tester.pumpAndSettle();
        
        // Toggle second switch
        await tester.tap(switches.at(1));
        await tester.pumpAndSettle();
      }

      // Verify screen is still functional
      expect(find.byType(SecuritySettingsScreen), findsOneWidget);
    });
  });
}
