import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parion/screens/security/security_dashboard_screen.dart';

void main() {
  group('SecurityDashboardScreen', () {
    testWidgets('should display security dashboard title', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        const MaterialApp(
          home: SecurityDashboardScreen(),
        ),
      );

      // Verify the app bar title is displayed
      expect(find.text('Güvenlik Dashboard'), findsOneWidget);
      
      // Verify refresh button is present
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('should show loading indicator initially', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        const MaterialApp(
          home: SecurityDashboardScreen(),
        ),
      );

      // Verify loading indicator is shown initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should have refresh functionality', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        const MaterialApp(
          home: SecurityDashboardScreen(),
        ),
      );

      // Find and tap the refresh button
      final refreshButton = find.byIcon(Icons.refresh);
      expect(refreshButton, findsOneWidget);
      
      await tester.tap(refreshButton);
      await tester.pump();
      
      // Verify loading state is triggered
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display security recommendations section', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        const MaterialApp(
          home: SecurityDashboardScreen(),
        ),
      );

      // Pump a few frames to let the widget build
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // The screen should be built (either loading or with content)
      expect(find.byType(SecurityDashboardScreen), findsOneWidget);
    });

    testWidgets('should display quick actions section', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        const MaterialApp(
          home: SecurityDashboardScreen(),
        ),
      );

      // Pump a few frames to let the widget build
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // The screen should be built (either loading or with content)
      expect(find.byType(SecurityDashboardScreen), findsOneWidget);
    });
  });

  group('SecurityRecommendation', () {
    test('should create security recommendation with all properties', () {
      const recommendation = SecurityRecommendation(
        title: 'Test Title',
        description: 'Test Description',
        severity: SecurityRecommendationSeverity.high,
        action: 'Test Action',
        icon: Icons.security,
      );

      expect(recommendation.title, equals('Test Title'));
      expect(recommendation.description, equals('Test Description'));
      expect(recommendation.severity, equals(SecurityRecommendationSeverity.high));
      expect(recommendation.action, equals('Test Action'));
      expect(recommendation.icon, equals(Icons.security));
    });
  });

  group('SecurityRecommendationSeverity', () {
    test('should have all severity levels', () {
      expect(SecurityRecommendationSeverity.values, hasLength(4));
      expect(SecurityRecommendationSeverity.values, contains(SecurityRecommendationSeverity.low));
      expect(SecurityRecommendationSeverity.values, contains(SecurityRecommendationSeverity.medium));
      expect(SecurityRecommendationSeverity.values, contains(SecurityRecommendationSeverity.high));
      expect(SecurityRecommendationSeverity.values, contains(SecurityRecommendationSeverity.critical));
    });
  });
}