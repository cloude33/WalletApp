import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:parion/models/wallet.dart';
import 'package:parion/models/kmh_transaction.dart';
import 'package:parion/models/kmh_transaction_type.dart';
import 'package:parion/screens/kmh_statement_screen.dart';
import 'package:parion/services/kmh_box_service.dart';
import 'package:parion/services/data_service.dart';
import '../test_setup.dart';

void main() {
  group('KmhStatementScreen', () {
    setUpAll(() async {
      await TestSetup.initializeTestEnvironment();
      await initializeDateFormatting('tr_TR', null);
    });

    setUp(() async {
      await TestSetup.setupTest();
    });

    tearDown(() async {
      await TestSetup.tearDownTest();
    });

    tearDownAll(() async {
      await TestSetup.cleanupTestEnvironment();
    });

    testWidgets('should display statement screen with date range selector', (
      WidgetTester tester,
    ) async {
      // Create a test KMH account
      final testAccount = Wallet(
        id: 'test-wallet-1',
        name: 'Test KMH Account',
        balance: -5000.0,
        type: 'bank',
        color: '0xFF2196F3',
        icon: 'account_balance',
        creditLimit: 10000.0,
        interestRate: 24.0,
        lastInterestDate: DateTime.now(),
        accruedInterest: 100.0,
        accountNumber: '1234567890',
      );

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: KmhStatementScreen(account: testAccount),
          locale: const Locale('tr', 'TR'),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify the screen title
      expect(find.text('KMH Ekstresi'), findsOneWidget);

      // Verify date range selector is present
      expect(find.text('Tarih Aralığı'), findsOneWidget);

      // Verify predefined date range buttons
      expect(find.text('Son 7 Gün'), findsOneWidget);
      expect(find.text('Son 30 Gün'), findsOneWidget);
      expect(find.text('Son 3 Ay'), findsOneWidget);

      // Verify show statement button
      expect(find.text('Ekstreyi Göster'), findsOneWidget);

      // Verify export button in app bar
      expect(find.byIcon(Icons.file_download), findsOneWidget);
    });

    testWidgets('should display empty state when no transactions', (
      WidgetTester tester,
    ) async {
      final testAccount = Wallet(
        id: 'test-wallet-2',
        name: 'Empty KMH Account',
        balance: 0.0,
        type: 'bank',
        color: '0xFF2196F3',
        icon: 'account_balance',
        creditLimit: 10000.0,
        interestRate: 24.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: KmhStatementScreen(account: testAccount),
          locale: const Locale('tr', 'TR'),
        ),
      );

      // Wait for initial load
      await tester.pumpAndSettle();

      // Tap the show statement button
      await tester.tap(find.text('Ekstreyi Göster'));
      await tester.pumpAndSettle();

      // Should show empty state or "no transactions" message
      // The exact message depends on whether there are transactions
      expect(find.text('Ekstre bulunamadı'), findsOneWidget);
    });

    testWidgets('should display statement with transactions', (
      WidgetTester tester,
    ) async {
      final testAccount = Wallet(
        id: 'test-wallet-3',
        name: 'KMH with Transactions',
        balance: -3000.0,
        type: 'bank',
        color: '0xFF2196F3',
        icon: 'account_balance',
        creditLimit: 10000.0,
        interestRate: 24.0,
      );

      print('Test: Adding wallet');
      await DataService().addWallet(testAccount);

      // Add some test transactions
      final transaction1 = KmhTransaction(
        id: 'trans-1',
        walletId: testAccount.id,
        type: KmhTransactionType.withdrawal,
        amount: 2000.0,
        date: DateTime.now().subtract(const Duration(days: 5)),
        description: 'Test Withdrawal',
        balanceAfter: -2000.0,
      );

      final transaction2 = KmhTransaction(
        id: 'trans-2',
        walletId: testAccount.id,
        type: KmhTransactionType.deposit,
        amount: 1000.0,
        date: DateTime.now().subtract(const Duration(days: 3)),
        description: 'Test Deposit',
        balanceAfter: -1000.0,
      );

      final transaction3 = KmhTransaction(
        id: 'trans-3',
        walletId: testAccount.id,
        type: KmhTransactionType.interest,
        amount: 50.0,
        date: DateTime.now().subtract(const Duration(days: 1)),
        description: 'Günlük faiz tahakkuku',
        balanceAfter: -1050.0,
        interestAmount: 50.0,
      );

      print('Test: Adding transactions');
      await KmhBoxService.transactionsBox.put(transaction1.id, transaction1);
      await KmhBoxService.transactionsBox.put(transaction2.id, transaction2);
      await KmhBoxService.transactionsBox.put(transaction3.id, transaction3);

      print('Test: Pumping widget');
      await tester.pumpWidget(
        MaterialApp(
          home: KmhStatementScreen(account: testAccount),
          locale: const Locale('tr', 'TR'),
        ),
      );

      print('Test: Pump and settle');
      await tester.pumpAndSettle();

      // Tap the show statement button
      print('Test: Tapping button');
      await tester.tap(find.text('Ekstreyi Göster'));

      // Wait for async operations manually instead of pumpAndSettle to avoid timeouts
      // if there are ongoing animations
      print('Test: Manual pumps');
      await tester.pump(); // Start animation
      await tester.pump(const Duration(milliseconds: 100)); // Allow microtasks
      await tester.pump(
        const Duration(seconds: 1),
      ); // Wait for loading simulation
      await tester.pump(); // Final rebuild
      print('Test: Verification');

      // Verify statement header
      expect(find.text('Özet'), findsOneWidget);

      // Verify summary sections
      expect(find.text('Dönem Başı Bakiye'), findsOneWidget);
      expect(find.text('Dönem Sonu Bakiye'), findsOneWidget);
      expect(find.text('Toplam Para Yatırma'), findsOneWidget);
      expect(find.text('Toplam Para Çekme'), findsOneWidget);
      expect(find.text('Toplam Faiz'), findsOneWidget);

      // Verify transaction list
      expect(find.text('İşlem Detayları'), findsOneWidget);
      expect(find.text('Test Withdrawal'), findsOneWidget);
      expect(find.text('Test Deposit'), findsOneWidget);
      expect(find.text('Günlük faiz tahakkuku'), findsOneWidget);
    });

    testWidgets('should show export options when export button tapped', (
      WidgetTester tester,
    ) async {
      final testAccount = Wallet(
        id: 'test-wallet-4',
        name: 'Test Export',
        balance: -1000.0,
        type: 'bank',
        color: '0xFF2196F3',
        icon: 'account_balance',
        creditLimit: 10000.0,
        interestRate: 24.0,
      );

      // Add a transaction so statement is not null
      final transaction = KmhTransaction(
        id: 'trans-export',
        walletId: testAccount.id,
        type: KmhTransactionType.withdrawal,
        amount: 1000.0,
        date: DateTime.now(),
        description: 'Test',
        balanceAfter: -1000.0,
      );

      await KmhBoxService.transactionsBox.put(transaction.id, transaction);

      await tester.pumpWidget(
        MaterialApp(
          home: KmhStatementScreen(account: testAccount),
          locale: const Locale('tr', 'TR'),
        ),
      );

      await tester.pumpAndSettle();

      // Load the statement first
      await tester.tap(find.text('Ekstreyi Göster'));
      await tester.pumpAndSettle();

      // Tap export button
      await tester.tap(find.byIcon(Icons.file_download));
      await tester.pumpAndSettle();

      // Verify export options are shown
      expect(find.text('PDF olarak dışa aktar'), findsOneWidget);
      expect(find.text('Excel olarak dışa aktar'), findsOneWidget);
      expect(find.text('Paylaş'), findsOneWidget);
    });

    testWidgets('should allow date range selection', (
      WidgetTester tester,
    ) async {
      final testAccount = Wallet(
        id: 'test-wallet-5',
        name: 'Test Date Range',
        balance: 0.0,
        type: 'bank',
        color: '0xFF2196F3',
        icon: 'account_balance',
        creditLimit: 10000.0,
        interestRate: 24.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: KmhStatementScreen(account: testAccount),
          locale: const Locale('tr', 'TR'),
        ),
      );

      await tester.pumpAndSettle();

      // Verify predefined date range chips
      expect(find.byType(ChoiceChip), findsWidgets);

      // Tap on "Son 7 Gün" preset
      await tester.tap(find.text('Son 7 Gün'));
      await tester.pumpAndSettle();

      // The statement should be loaded automatically
      // Verify loading indicator or statement content
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('should display interest calculations when interest exists', (
      WidgetTester tester,
    ) async {
      final testAccount = Wallet(
        id: 'test-wallet-6',
        name: 'Test Interest',
        balance: -5000.0,
        type: 'bank',
        color: '0xFF2196F3',
        icon: 'account_balance',
        creditLimit: 10000.0,
        interestRate: 24.0,
      );

      // Add interest transactions
      final interest1 = KmhTransaction(
        id: 'interest-1',
        walletId: testAccount.id,
        type: KmhTransactionType.interest,
        amount: 30.0,
        date: DateTime.now().subtract(const Duration(days: 2)),
        description: 'Günlük faiz tahakkuku',
        balanceAfter: -5030.0,
        interestAmount: 30.0,
      );

      final interest2 = KmhTransaction(
        id: 'interest-2',
        walletId: testAccount.id,
        type: KmhTransactionType.interest,
        amount: 30.0,
        date: DateTime.now().subtract(const Duration(days: 1)),
        description: 'Günlük faiz tahakkuku',
        balanceAfter: -5060.0,
        interestAmount: 30.0,
      );

      await KmhBoxService.transactionsBox.put(interest1.id, interest1);
      await KmhBoxService.transactionsBox.put(interest2.id, interest2);

      await tester.pumpWidget(
        MaterialApp(
          home: KmhStatementScreen(account: testAccount),
          locale: const Locale('tr', 'TR'),
        ),
      );

      await tester.pumpAndSettle();

      // Load statement
      await tester.tap(find.text('Ekstreyi Göster'));
      await tester.pumpAndSettle();

      // Verify interest calculations section
      expect(find.text('Faiz Hesaplamaları'), findsOneWidget);
      expect(find.text('Dönem Toplam Faiz'), findsOneWidget);
      expect(find.text('Ortalama Günlük Faiz'), findsOneWidget);
      expect(find.text('Dönem Süresi'), findsOneWidget);
    });
  });
}
