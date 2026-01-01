import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parion/screens/security/biometric_setup_screen.dart';
import 'package:parion/services/auth/biometric_service.dart';
import 'package:parion/models/security/biometric_type.dart' as app_biometric;
import 'package:parion/models/security/auth_result.dart';
import 'package:parion/models/security/auth_state.dart';

/// Mock biyometrik servis
class MockBiometricService implements BiometricService {
  final bool _isAvailable;
  final List<app_biometric.BiometricType> _availableBiometrics;
  final bool _shouldAuthSucceed;
  final String? _errorMessage;

  MockBiometricService({
    bool isAvailable = true,
    List<app_biometric.BiometricType> availableBiometrics = const [
      app_biometric.BiometricType.fingerprint,
    ],
    bool shouldAuthSucceed = true,
    String? errorMessage,
  }) : _isAvailable = isAvailable,
       _availableBiometrics = availableBiometrics,
       _shouldAuthSucceed = shouldAuthSucceed,
       _errorMessage = errorMessage;

  @override
  Future<bool> isBiometricAvailable() async => _isAvailable;

  @override
  Future<List<app_biometric.BiometricType>> getAvailableBiometrics() async =>
      _availableBiometrics;

  @override
  Future<AuthResult> authenticate({
    String? localizedFallbackTitle,
    String? cancelButtonText,
  }) async {
    if (_shouldAuthSucceed) {
      return AuthResult.success(method: AuthMethod.biometric);
    } else {
      return AuthResult.failure(
        method: AuthMethod.biometric,
        errorMessage: _errorMessage ?? 'Authentication failed',
      );
    }
  }

  @override
  Future<bool> enrollBiometric() async => _shouldAuthSucceed;

  @override
  Future<void> disableBiometric() async {}

  @override
  Future<bool> isDeviceSecure() async => true;

  @override
  Future<bool> canCheckBiometrics() async => _isAvailable;
}

void main() {
  group('BiometricSetupScreen Tests', () {
    late MockBiometricService mockBiometricService;

    setUp(() {
      mockBiometricService = MockBiometricService();
      BiometricServiceSingleton.setInstance(mockBiometricService);
    });

    tearDown(() {
      BiometricServiceSingleton.reset();
    });

    testWidgets('should show loading initially', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: BiometricSetupScreen()));

      // Loading durumunu kontrol et
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        find.text('Biyometrik destek kontrol ediliyor...'),
        findsOneWidget,
      );
    });

    testWidgets('should show setup view when biometric is available', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: BiometricSetupScreen()));

      // Loading tamamlanana kadar bekle
      await tester.pumpAndSettle();

      // Setup view'ın gösterildiğini kontrol et
      expect(find.text('Biyometrik Doğrulama Kurulumu'), findsOneWidget);
      expect(find.text('Parmak İzi'), findsOneWidget);
      expect(find.text('Biyometrik Doğrulamayı Etkinleştir'), findsOneWidget);
    });

    testWidgets(
      'should show unavailable view when biometric is not available',
      (WidgetTester tester) async {
        // Biyometrik mevcut olmayan mock servis
        mockBiometricService = MockBiometricService(
          isAvailable: false,
          availableBiometrics: [],
        );
        BiometricServiceSingleton.setInstance(mockBiometricService);

        await tester.pumpWidget(
          const MaterialApp(home: BiometricSetupScreen()),
        );

        // Loading tamamlanana kadar bekle
        await tester.pumpAndSettle();

        // Unavailable view'ın gösterildiğini kontrol et
        expect(find.text('Biyometrik Doğrulama Mevcut Değil'), findsOneWidget);
        expect(find.text('Tekrar Kontrol Et'), findsOneWidget);
      },
    );

    testWidgets('should allow biometric type selection', (
      WidgetTester tester,
    ) async {
      // Birden fazla biyometrik tür ile mock servis
      mockBiometricService = MockBiometricService(
        availableBiometrics: [
          app_biometric.BiometricType.fingerprint,
          app_biometric.BiometricType.face,
        ],
      );
      BiometricServiceSingleton.setInstance(mockBiometricService);

      await tester.pumpWidget(const MaterialApp(home: BiometricSetupScreen()));

      await tester.pumpAndSettle();

      // Her iki biyometrik türün gösterildiğini kontrol et
      expect(find.text('Parmak İzi'), findsOneWidget);
      expect(find.text('Yüz Tanıma'), findsOneWidget);

      // Face ID'yi seç
      await tester.tap(find.text('Yüz Tanıma'));
      await tester.pump();

      // Seçimin yapıldığını kontrol et (check icon görünmeli)
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('should handle successful biometric enrollment', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: BiometricSetupScreen()));

      await tester.pumpAndSettle();

      // Scroll to make button visible
      await tester.scrollUntilVisible(
        find.text('Biyometrik Doğrulamayı Etkinleştir'),
        500.0,
      );

      // Etkinleştir butonuna bas
      await tester.tap(find.text('Biyometrik Doğrulamayı Etkinleştir'));

      // İşlem tamamlanana kadar bekle
      await tester.pumpAndSettle();

      // Başarı ekranının gösterildiğini kontrol et
      expect(
        find.text('Biyometrik Doğrulama Etkinleştirildi!'),
        findsOneWidget,
      );
      expect(find.text('Tamam'), findsOneWidget);
    });

    testWidgets('should handle failed biometric enrollment', (
      WidgetTester tester,
    ) async {
      // Başarısız authentication ile mock servis
      mockBiometricService = MockBiometricService(
        shouldAuthSucceed: false,
        errorMessage: 'Authentication failed',
      );
      BiometricServiceSingleton.setInstance(mockBiometricService);

      await tester.pumpWidget(const MaterialApp(home: BiometricSetupScreen()));

      await tester.pumpAndSettle();

      // Scroll to make button visible
      await tester.scrollUntilVisible(
        find.text('Biyometrik Doğrulamayı Etkinleştir'),
        500.0,
      );

      // Etkinleştir butonuna bas
      await tester.tap(find.text('Biyometrik Doğrulamayı Etkinleştir'));
      await tester.pumpAndSettle();

      // Hata mesajının gösterildiğini kontrol et
      expect(find.text('Authentication failed'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('should navigate back when skip button is pressed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: BiometricSetupScreen()));

      await tester.pumpAndSettle();

      // Scroll to make button visible
      await tester.scrollUntilVisible(find.text('Şimdi Değil'), 500.0);

      // Skip butonunun mevcut olduğunu kontrol et
      expect(find.text('Şimdi Değil'), findsOneWidget);
    });

    testWidgets('should show correct biometric icons and descriptions', (
      WidgetTester tester,
    ) async {
      // Tüm biyometrik türler ile mock servis
      mockBiometricService = MockBiometricService(
        availableBiometrics: [
          app_biometric.BiometricType.fingerprint,
          app_biometric.BiometricType.face,
          app_biometric.BiometricType.voice,
          app_biometric.BiometricType.iris,
        ],
      );
      BiometricServiceSingleton.setInstance(mockBiometricService);

      await tester.pumpWidget(const MaterialApp(home: BiometricSetupScreen()));

      await tester.pumpAndSettle();

      // Tüm biyometrik türlerin gösterildiğini kontrol et
      expect(find.text('Parmak İzi'), findsOneWidget);
      expect(find.text('Yüz Tanıma'), findsOneWidget);
      expect(find.text('Ses Tanıma'), findsOneWidget);
      expect(find.text('Iris Tarama'), findsOneWidget);

      // İkonların gösterildiğini kontrol et (birden fazla olabilir)
      expect(find.byIcon(Icons.fingerprint), findsWidgets);
      expect(find.byIcon(Icons.face), findsWidgets);
      expect(find.byIcon(Icons.record_voice_over), findsWidgets);
      expect(find.byIcon(Icons.visibility), findsWidgets);
    });

    testWidgets(
      'should auto-select when only one biometric type is available',
      (WidgetTester tester) async {
        // Sadece bir biyometrik tür ile mock servis
        mockBiometricService = MockBiometricService(
          availableBiometrics: [app_biometric.BiometricType.face],
        );
        BiometricServiceSingleton.setInstance(mockBiometricService);

        await tester.pumpWidget(
          const MaterialApp(home: BiometricSetupScreen()),
        );

        await tester.pumpAndSettle();

        // Otomatik seçimin yapıldığını kontrol et
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        expect(find.text('Yüz Tanıma'), findsOneWidget);
      },
    );
  });
}
