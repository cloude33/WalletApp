import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/models/wallet.dart';
import 'package:money/widgets/statistics/kmh_asset_card.dart';

void main() {
  group('KmhAssetCard Widget Tests', () {
    testWidgets('displays empty state when no KMH accounts', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KmhAssetCard(
              kmhAccounts: [],
            ),
          ),
        ),
      );

      expect(find.text('KMH hesabı bulunmamaktadır'), findsOneWidget);
      expect(find.byIcon(Icons.account_balance_outlined), findsOneWidget);
    });

    testWidgets('displays KMH asset analysis header', (tester) async {
      final kmhAccounts = [
        Wallet(
          id: '1',
          name: 'Test KMH',
          balance: 1000.0,
          type: 'bank',
          color: '#FF0000',
          icon: 'account_balance',
          creditLimit: 5000.0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KmhAssetCard(
              kmhAccounts: kmhAccounts,
            ),
          ),
        ),
      );

      expect(find.text('KMH Varlık Analizi'), findsOneWidget);
      expect(find.text('1 hesap'), findsOneWidget);
    });

    testWidgets('displays liquidity reserve correctly', (tester) async {
      final kmhAccounts = [
        Wallet(
          id: '1',
          name: 'Test KMH',
          balance: 1000.0,
          type: 'bank',
          color: '#FF0000',
          icon: 'account_balance',
          creditLimit: 5000.0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KmhAssetCard(
              kmhAccounts: kmhAccounts,
            ),
          ),
        ),
      );

      expect(find.text('Likidite Rezervi'), findsOneWidget);
      // Liquidity reserve = positive balance (1000) + unused limit (5000 - 1000 = 4000) = 5000
      expect(find.text('₺5.000,00'), findsAtLeastNWidgets(1));
    });

    testWidgets('displays positive balance and unused limit breakdown', (tester) async {
      final kmhAccounts = [
        Wallet(
          id: '1',
          name: 'Test KMH',
          balance: 2000.0,
          type: 'bank',
          color: '#FF0000',
          icon: 'account_balance',
          creditLimit: 10000.0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KmhAssetCard(
              kmhAccounts: kmhAccounts,
            ),
          ),
        ),
      );

      expect(find.text('Pozitif Bakiye'), findsOneWidget);
      expect(find.text('Kullanılmayan Limit'), findsAtLeastNWidgets(1));
      expect(find.text('₺2.000,00'), findsAtLeastNWidgets(1)); // Positive balance
      expect(find.text('₺8.000,00'), findsAtLeastNWidgets(1)); // Unused limit (10000 - 2000)
    });

    testWidgets('displays positive balance KMH accounts section', (tester) async {
      final kmhAccounts = [
        Wallet(
          id: '1',
          name: 'Positive KMH',
          balance: 1500.0,
          type: 'bank',
          color: '#FF0000',
          icon: 'account_balance',
          creditLimit: 5000.0,
        ),
        Wallet(
          id: '2',
          name: 'Negative KMH',
          balance: -500.0,
          type: 'bank',
          color: '#00FF00',
          icon: 'account_balance',
          creditLimit: 3000.0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KmhAssetCard(
              kmhAccounts: kmhAccounts,
            ),
          ),
        ),
      );

      expect(find.text('Pozitif Bakiyeli KMH Hesapları'), findsOneWidget);
      expect(find.text('Positive KMH'), findsOneWidget);
      // Negative KMH should not appear in positive balance section initially
      expect(find.text('Negative KMH'), findsNothing);
    });

    testWidgets('expands to show all accounts when expand button is tapped', (tester) async {
      final kmhAccounts = [
        Wallet(
          id: '1',
          name: 'Positive KMH',
          balance: 1500.0,
          type: 'bank',
          color: '#FF0000',
          icon: 'account_balance',
          creditLimit: 5000.0,
        ),
        Wallet(
          id: '2',
          name: 'Negative KMH',
          balance: -500.0,
          type: 'bank',
          color: '#00FF00',
          icon: 'account_balance',
          creditLimit: 3000.0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: KmhAssetCard(
                kmhAccounts: kmhAccounts,
              ),
            ),
          ),
        ),
      );

      // Initially, negative account should not be visible
      expect(find.text('Negative KMH'), findsNothing);

      // Tap expand button
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();

      // Now all accounts should be visible
      expect(find.text('Tüm KMH Hesapları'), findsOneWidget);
      expect(find.text('Negative KMH'), findsOneWidget);
      expect(find.byIcon(Icons.expand_less), findsOneWidget);
    });

    testWidgets('calculates unused limit correctly for positive balance', (tester) async {
      final kmhAccounts = [
        Wallet(
          id: '1',
          name: 'Test KMH',
          balance: 3000.0,
          type: 'bank',
          color: '#FF0000',
          icon: 'account_balance',
          creditLimit: 10000.0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KmhAssetCard(
              kmhAccounts: kmhAccounts,
            ),
          ),
        ),
      );

      // Unused limit should be creditLimit - balance = 10000 - 3000 = 7000
      expect(find.text('₺7.000,00'), findsAtLeastNWidgets(1));
    });

    testWidgets('calculates unused limit correctly for negative balance', (tester) async {
      final kmhAccounts = [
        Wallet(
          id: '1',
          name: 'Test KMH',
          balance: -2000.0,
          type: 'bank',
          color: '#FF0000',
          icon: 'account_balance',
          creditLimit: 10000.0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: KmhAssetCard(
                kmhAccounts: kmhAccounts,
              ),
            ),
          ),
        ),
      );

      // Tap expand to see the account details
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();

      // Unused limit should be creditLimit - abs(balance) = 10000 - 2000 = 8000
      expect(find.text('₺8.000,00'), findsAtLeastNWidgets(1));
    });

    testWidgets('displays utilization rate correctly', (tester) async {
      final kmhAccounts = [
        Wallet(
          id: '1',
          name: 'Test KMH',
          balance: 3000.0,
          type: 'bank',
          color: '#FF0000',
          icon: 'account_balance',
          creditLimit: 10000.0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KmhAssetCard(
              kmhAccounts: kmhAccounts,
            ),
          ),
        ),
      );

      // Utilization rate = (3000 / 10000) * 100 = 30%
      expect(find.text('30.0%'), findsOneWidget);
    });

    testWidgets('displays account number when available', (tester) async {
      final kmhAccounts = [
        Wallet(
          id: '1',
          name: 'Test KMH',
          balance: 1000.0,
          type: 'bank',
          color: '#FF0000',
          icon: 'account_balance',
          creditLimit: 5000.0,
          accountNumber: '******1234',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KmhAssetCard(
              kmhAccounts: kmhAccounts,
            ),
          ),
        ),
      );

      expect(find.text('******1234'), findsOneWidget);
    });

    testWidgets('handles multiple KMH accounts correctly', (tester) async {
      final kmhAccounts = [
        Wallet(
          id: '1',
          name: 'KMH 1',
          balance: 2000.0,
          type: 'bank',
          color: '#FF0000',
          icon: 'account_balance',
          creditLimit: 5000.0,
        ),
        Wallet(
          id: '2',
          name: 'KMH 2',
          balance: 1000.0,
          type: 'bank',
          color: '#00FF00',
          icon: 'account_balance',
          creditLimit: 3000.0,
        ),
        Wallet(
          id: '3',
          name: 'KMH 3',
          balance: -500.0,
          type: 'bank',
          color: '#0000FF',
          icon: 'account_balance',
          creditLimit: 2000.0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KmhAssetCard(
              kmhAccounts: kmhAccounts,
            ),
          ),
        ),
      );

      expect(find.text('3 hesap'), findsOneWidget);
      
      // Total positive balance = 2000 + 1000 = 3000
      expect(find.text('₺3.000,00'), findsAtLeastNWidgets(1));
      
      // Total unused limit = (5000-2000) + (3000-1000) + (2000-500) = 3000 + 2000 + 1500 = 6500
      expect(find.text('₺6.500,00'), findsAtLeastNWidgets(1));
      
      // Liquidity reserve = 3000 + 6500 = 9500
      expect(find.text('₺9.500,00'), findsAtLeastNWidgets(1));
    });

    testWidgets('displays info message in expanded view', (tester) async {
      final kmhAccounts = [
        Wallet(
          id: '1',
          name: 'Test KMH',
          balance: 1000.0,
          type: 'bank',
          color: '#FF0000',
          icon: 'account_balance',
          creditLimit: 5000.0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: KmhAssetCard(
                kmhAccounts: kmhAccounts,
              ),
            ),
          ),
        ),
      );

      // Tap expand button
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();

      expect(
        find.text('Pozitif bakiyeli KMH hesapları likit varlık olarak değerlendirilir ve acil durumlarda kullanılabilir.'),
        findsOneWidget,
      );
    });

    testWidgets('shows correct status labels for positive and negative balances', (tester) async {
      final kmhAccounts = [
        Wallet(
          id: '1',
          name: 'Positive KMH',
          balance: 1000.0,
          type: 'bank',
          color: '#FF0000',
          icon: 'account_balance',
          creditLimit: 5000.0,
        ),
        Wallet(
          id: '2',
          name: 'Negative KMH',
          balance: -500.0,
          type: 'bank',
          color: '#00FF00',
          icon: 'account_balance',
          creditLimit: 3000.0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: KmhAssetCard(
                kmhAccounts: kmhAccounts,
              ),
            ),
          ),
        ),
      );

      // Expand to see all accounts
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();

      // Should find "Varlık" (Asset) label for positive balance
      expect(find.text('Varlık'), findsAtLeastNWidgets(1));
      
      // Should find "Borç" (Debt) label for negative balance
      expect(find.text('Borç'), findsAtLeastNWidgets(1));
    });
  });
}
