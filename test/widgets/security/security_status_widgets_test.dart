import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/models/security/security_status.dart';
import 'package:money/models/security/auth_state.dart';
import 'package:money/widgets/security/security_status_widgets.dart';

void main() {
  group('SecurityLevelIndicator', () {
    testWidgets('displays high security level correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SecurityLevelIndicator(
              level: SecurityLevel.high,
            ),
          ),
        ),
      );

      expect(find.text('Güvenli'), findsOneWidget);
      expect(find.text('Yüksek güvenlik seviyesi'), findsOneWidget);
      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
    });

    testWidgets('displays critical security level correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SecurityLevelIndicator(
              level: SecurityLevel.critical,
            ),
          ),
        ),
      );

      expect(find.text('Kritik Risk'), findsOneWidget);
      expect(find.text('Kritik güvenlik riski'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('displays medium security level correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SecurityLevelIndicator(
              level: SecurityLevel.medium,
            ),
          ),
        ),
      );

      expect(find.text('Orta Seviye'), findsOneWidget);
      expect(find.byIcon(Icons.shield), findsOneWidget);
    });

    testWidgets('displays low security level correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SecurityLevelIndicator(
              level: SecurityLevel.low,
            ),
          ),
        ),
      );

      expect(find.text('Düşük Seviye'), findsOneWidget);
      expect(find.byIcon(Icons.warning_outlined), findsOneWidget);
    });

    testWidgets('hides description when showDescription is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SecurityLevelIndicator(
              level: SecurityLevel.high,
              showDescription: false,
            ),
          ),
        ),
      );

      expect(find.text('Güvenli'), findsNothing);
      expect(find.text('Yüksek güvenlik seviyesi'), findsNothing);
      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
    });

    testWidgets('respects custom size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SecurityLevelIndicator(
              level: SecurityLevel.high,
              size: 100.0,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(SecurityLevelIndicator),
          matching: find.byType(Container).first,
        ),
      );

      expect(container.constraints?.maxWidth, 100.0);
      expect(container.constraints?.maxHeight, 100.0);
    });
  });

  group('LockStatusWidget', () {
    testWidgets('shows nothing when not locked and no failed attempts', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LockStatusWidget(
              isLocked: false,
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsNothing);
    });

    testWidgets('displays locked status correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LockStatusWidget(
              isLocked: true,
              remainingDuration: Duration(minutes: 5, seconds: 30),
              failedAttempts: 5,
              maxAttempts: 5,
            ),
          ),
        ),
      );

      expect(find.text('Hesap Kilitli'), findsOneWidget);
      expect(find.text('Kalan Süre: 5 dakika 30 saniye'), findsOneWidget);
      expect(find.text('Başarısız Deneme: 5 / 5'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('displays warning when failed attempts exist but not locked', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LockStatusWidget(
              isLocked: false,
              failedAttempts: 3,
              maxAttempts: 5,
            ),
          ),
        ),
      );

      expect(find.text('Güvenlik Uyarısı'), findsOneWidget);
      expect(find.text('Başarısız Deneme: 3 / 5'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
    });

    testWidgets('formats duration correctly for seconds only', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LockStatusWidget(
              isLocked: true,
              remainingDuration: Duration(seconds: 45),
            ),
          ),
        ),
      );

      expect(find.text('Kalan Süre: 45 saniye'), findsOneWidget);
    });
  });

  group('SecurityWarningWidget', () {
    testWidgets('displays critical warning correctly', (tester) async {
      final warning = SecurityWarning(
        type: SecurityWarningType.rootDetected,
        severity: SecurityWarningSeverity.critical,
        message: 'Root tespit edildi',
        description: 'Cihazınızda root erişimi tespit edildi',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecurityWarningWidget(warning: warning),
          ),
        ),
      );

      expect(find.text('Root tespit edildi'), findsOneWidget);
      expect(find.text('Cihazınızda root erişimi tespit edildi'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('displays high severity warning correctly', (tester) async {
      final warning = SecurityWarning(
        type: SecurityWarningType.suspiciousActivity,
        severity: SecurityWarningSeverity.high,
        message: 'Şüpheli aktivite',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecurityWarningWidget(warning: warning),
          ),
        ),
      );

      expect(find.text('Şüpheli aktivite'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
    });

    testWidgets('calls onDismiss when close button pressed', (tester) async {
      bool dismissed = false;
      final warning = SecurityWarning(
        type: SecurityWarningType.weakSecurity,
        severity: SecurityWarningSeverity.medium,
        message: 'Zayıf güvenlik',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecurityWarningWidget(
              warning: warning,
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(dismissed, true);
    });

    testWidgets('calls onShowDetails when details button pressed', (tester) async {
      bool detailsShown = false;
      final warning = SecurityWarning(
        type: SecurityWarningType.weakSecurity,
        severity: SecurityWarningSeverity.medium,
        message: 'Zayıf güvenlik',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecurityWarningWidget(
              warning: warning,
              onShowDetails: () => detailsShown = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Detayları Gör'));
      await tester.pump();

      expect(detailsShown, true);
    });

    testWidgets('does not show description when null', (tester) async {
      final warning = SecurityWarning(
        type: SecurityWarningType.weakSecurity,
        severity: SecurityWarningSeverity.low,
        message: 'Bilgi mesajı',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecurityWarningWidget(warning: warning),
          ),
        ),
      );

      expect(find.text('Bilgi mesajı'), findsOneWidget);
      // Description should not be present
      expect(find.byType(Text), findsNWidgets(1)); // Only message text
    });
  });

  group('SecurityWarningsList', () {
    testWidgets('shows nothing when warnings list is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SecurityWarningsList(warnings: []),
          ),
        ),
      );

      expect(find.byType(SecurityWarningWidget), findsNothing);
    });

    testWidgets('displays all warnings when count is below max', (tester) async {
      final warnings = [
        SecurityWarning(
          type: SecurityWarningType.rootDetected,
          severity: SecurityWarningSeverity.critical,
          message: 'Warning 1',
        ),
        SecurityWarning(
          type: SecurityWarningType.suspiciousActivity,
          severity: SecurityWarningSeverity.high,
          message: 'Warning 2',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecurityWarningsList(warnings: warnings),
          ),
        ),
      );

      expect(find.text('Güvenlik Uyarıları (2)'), findsOneWidget);
      expect(find.byType(SecurityWarningWidget), findsNWidgets(2));
      expect(find.text('Warning 1'), findsOneWidget);
      expect(find.text('Warning 2'), findsOneWidget);
    });

    testWidgets('limits displayed warnings when maxWarnings is set', (tester) async {
      final warnings = List.generate(
        5,
        (i) => SecurityWarning(
          type: SecurityWarningType.weakSecurity,
          severity: SecurityWarningSeverity.medium,
          message: 'Warning ${i + 1}',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecurityWarningsList(
              warnings: warnings,
              maxWarnings: 3,
            ),
          ),
        ),
      );

      expect(find.text('Güvenlik Uyarıları (5)'), findsOneWidget);
      expect(find.byType(SecurityWarningWidget), findsNWidgets(3));
      expect(find.text('2 uyarı daha göster'), findsOneWidget);
    });

    testWidgets('calls onDismissWarning callback', (tester) async {
      SecurityWarning? dismissedWarning;
      final warnings = [
        SecurityWarning(
          type: SecurityWarningType.weakSecurity,
          severity: SecurityWarningSeverity.medium,
          message: 'Test Warning',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecurityWarningsList(
              warnings: warnings,
              onDismissWarning: (warning) => dismissedWarning = warning,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(dismissedWarning, warnings[0]);
    });
  });

  group('SecurityStatusCard', () {
    testWidgets('displays security status correctly', (tester) async {
      final status = SecurityStatus(
        isDeviceSecure: true,
        isRootDetected: false,
        isScreenshotBlocked: true,
        isBackgroundBlurEnabled: true,
        isClipboardSecurityEnabled: true,
        securityLevel: SecurityLevel.high,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecurityStatusCard(status: status),
          ),
        ),
      );

      expect(find.text('Güvenlik Durumu'), findsOneWidget);
      expect(find.text('Cihaz Güvenliği'), findsOneWidget);
      expect(find.text('Ekran Görüntüsü Koruması'), findsOneWidget);
      expect(find.text('Arka Plan Bulanıklaştırma'), findsOneWidget);
      expect(find.text('Clipboard Güvenliği'), findsOneWidget);
      expect(find.byType(SecurityLevelIndicator), findsOneWidget);
    });

    testWidgets('shows root detection warning', (tester) async {
      final status = SecurityStatus(
        isDeviceSecure: false,
        isRootDetected: true,
        isScreenshotBlocked: false,
        isBackgroundBlurEnabled: false,
        isClipboardSecurityEnabled: false,
        securityLevel: SecurityLevel.critical,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecurityStatusCard(status: status),
          ),
        ),
      );

      expect(find.text('Root/Jailbreak tespit edildi!'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('displays auth state when authenticated', (tester) async {
      final status = SecurityStatus(
        isDeviceSecure: true,
        isRootDetected: false,
        isScreenshotBlocked: true,
        isBackgroundBlurEnabled: true,
        isClipboardSecurityEnabled: true,
        securityLevel: SecurityLevel.high,
      );

      final authState = AuthState.authenticated(
        sessionId: 'test-session',
        authMethod: AuthMethod.biometric,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecurityStatusCard(
              status: status,
              authState: authState,
            ),
          ),
        ),
      );

      expect(find.text('Oturum Aktif'), findsOneWidget);
      expect(find.text('Yöntem: Biyometrik'), findsOneWidget);
      expect(find.byIcon(Icons.verified_user), findsOneWidget);
    });

    testWidgets('calls onShowDetails when button pressed', (tester) async {
      bool detailsShown = false;
      final status = SecurityStatus(
        isDeviceSecure: true,
        isRootDetected: false,
        isScreenshotBlocked: true,
        isBackgroundBlurEnabled: true,
        isClipboardSecurityEnabled: true,
        securityLevel: SecurityLevel.high,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecurityStatusCard(
              status: status,
              onShowDetails: () => detailsShown = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Detaylı Bilgi'));
      await tester.pump();

      expect(detailsShown, true);
    });

    testWidgets('shows disabled features correctly', (tester) async {
      final status = SecurityStatus(
        isDeviceSecure: true,
        isRootDetected: false,
        isScreenshotBlocked: false,
        isBackgroundBlurEnabled: false,
        isClipboardSecurityEnabled: false,
        securityLevel: SecurityLevel.medium,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecurityStatusCard(status: status),
          ),
        ),
      );

      // Check for cancel icons (disabled features)
      expect(
        find.descendant(
          of: find.byType(SecurityStatusCard),
          matching: find.byIcon(Icons.cancel),
        ),
        findsNWidgets(3), // 3 disabled features
      );

      // Check for check_circle icon (enabled feature - device security)
      expect(
        find.descendant(
          of: find.byType(SecurityStatusCard),
          matching: find.byIcon(Icons.check_circle),
        ),
        findsOneWidget,
      );
    });

    testWidgets('formats recent time correctly', (tester) async {
      final status = SecurityStatus(
        isDeviceSecure: true,
        isRootDetected: false,
        isScreenshotBlocked: true,
        isBackgroundBlurEnabled: true,
        isClipboardSecurityEnabled: true,
        securityLevel: SecurityLevel.high,
        lastSecurityCheck: DateTime.now().subtract(const Duration(seconds: 30)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecurityStatusCard(status: status),
          ),
        ),
      );

      expect(find.textContaining('Az önce'), findsOneWidget);
    });
  });

  group('Widget Integration', () {
    testWidgets('SecurityStatusCard integrates with SecurityLevelIndicator', (tester) async {
      final status = SecurityStatus(
        isDeviceSecure: true,
        isRootDetected: false,
        isScreenshotBlocked: true,
        isBackgroundBlurEnabled: true,
        isClipboardSecurityEnabled: true,
        securityLevel: SecurityLevel.high,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecurityStatusCard(status: status),
          ),
        ),
      );

      // Verify SecurityLevelIndicator is present and configured correctly
      final indicator = tester.widget<SecurityLevelIndicator>(
        find.byType(SecurityLevelIndicator),
      );

      expect(indicator.level, SecurityLevel.high);
      expect(indicator.size, 60);
      expect(indicator.showDescription, false);
    });

    testWidgets('SecurityWarningsList integrates with SecurityWarningWidget', (tester) async {
      final warnings = [
        SecurityWarning(
          type: SecurityWarningType.rootDetected,
          severity: SecurityWarningSeverity.critical,
          message: 'Critical Warning',
        ),
        SecurityWarning(
          type: SecurityWarningType.suspiciousActivity,
          severity: SecurityWarningSeverity.high,
          message: 'High Warning',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecurityWarningsList(warnings: warnings),
          ),
        ),
      );

      // Verify all SecurityWarningWidgets are present
      expect(find.byType(SecurityWarningWidget), findsNWidgets(2));
      
      // Verify each warning is displayed
      expect(find.text('Critical Warning'), findsOneWidget);
      expect(find.text('High Warning'), findsOneWidget);
    });
  });
}
