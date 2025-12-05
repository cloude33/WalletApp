import 'package:flutter_test/flutter_test.dart';
import 'package:money/services/sms_parser_service.dart';
import '../property_test_utils.dart';

/// Property-based tests for SMSParserService
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SMSParserService Property Tests', () {
    late SMSParserService service;

    setUp(() {
      service = SMSParserService();
    });

    /// **Feature: enhanced-credit-card-tracking, Property 41: SMS Okuma ve Analiz**
    /// **Validates: Requirements 12.1**
    /// 
    /// Property: For any SMS permission request, the system should read and analyze
    /// bank SMS messages when permission is granted.
    test('Property 41: SMS permission should be requestable', () async {
      // Property 1: Permission request should return a boolean
      final hasPermission = await service.requestSMSPermission();
      expect(hasPermission, isA<bool>());

      // Property 2: Reading SMS should return a list
      final messages = await service.readBankSMS();
      expect(messages, isA<List<String>>());

      // Property 3: Bank patterns should be available
      final patterns = service.getBankSMSPatterns();
      expect(patterns, isNotEmpty);
      expect(patterns, isA<Map<String, RegExp>>());

      // Property 4: All major Turkish banks should have patterns
      final expectedBanks = [
        'garanti',
        'isbank',
        'akbank',
        'yapikredi',
        'ziraat',
        'halkbank',
        'vakifbank',
        'teb',
        'denizbank',
        'finansbank',
      ];

      for (final bank in expectedBanks) {
        expect(patterns.containsKey(bank), isTrue,
            reason: 'Pattern for $bank should exist');
      }
    });

    test('Property 41: Bank detection should work for all supported banks', () {
      final testCases = {
        'garanti': 'GARANTI BBVA 1234.56 TL harcama yapildi',
        'isbank': 'ISBANK kartinizdan 2345.67 TL harcama',
        'akbank': 'AKBANK kredi kartinizla 3456.78 TL harcama',
        'yapikredi': 'YAPIKREDI kartinizdan 4567.89 TL harcama',
        'ziraat': 'ZIRAAT Bankasi 5678.90 TL harcama',
        'halkbank': 'HALKBANK 6789.01 TL harcama yapildi',
        'vakifbank': 'VAKIFBANK 7890.12 TL harcama',
        'teb': 'TEB 8901.23 TL harcama yapildi',
        'denizbank': 'DENIZBANK 9012.34 TL harcama',
        'finansbank': 'QNB Finansbank 1234.56 TL harcama',
      };

      for (final entry in testCases.entries) {
        final detectedBank = service.detectBank(entry.value);
        expect(detectedBank, equals(entry.key),
            reason: 'Should detect ${entry.key} from SMS: ${entry.value}');
      }
    });

    test('Property 41: Non-bank SMS should not be detected', () {
      final nonBankMessages = [
        'Hello, this is a regular message',
        'Your OTP is 123456',
        'Meeting at 3pm tomorrow',
        'Random text without bank info',
      ];

      for (final message in nonBankMessages) {
        final detectedBank = service.detectBank(message);
        expect(detectedBank, isNull,
            reason: 'Should not detect bank from: $message');
      }
    });

    /// **Feature: enhanced-credit-card-tracking, Property 42: SMS Parse Etme**
    /// **Validates: Requirements 12.2**
    /// 
    /// Property: For any bank SMS, the system should extract amount, date,
    /// and transaction type correctly.
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 42: SMS parsing should extract transaction details correctly',
      generator: () {
        final banks = [
          'GARANTI',
          'ISBANK',
          'AKBANK',
          'YAPIKREDI',
          'ZIRAAT',
          'HALKBANK',
          'VAKIFBANK',
          'TEB',
          'DENIZBANK',
          'FINANSBANK'
        ];
        final bank = banks[PropertyTest.randomInt(min: 0, max: banks.length - 1)];
        final amount = PropertyTest.randomPositiveDouble(min: 0.01, max: 100000);
        final isPayment = PropertyTest.randomBool();
        final transactionType = isPayment ? 'odeme' : 'harcama';
        
        // Generate date
        final date = PropertyTest.randomDateTime(
          start: DateTime(2023, 1, 1),
          end: DateTime(2024, 12, 31),
        );
        final dateStr = '${date.day}/${date.month}/${date.year}';
        
        // Generate SMS with amount in Turkish format (comma as decimal separator)
        final amountStr = amount.toStringAsFixed(2).replaceAll('.', ',');
        final sms = '$bank $amountStr TL $transactionType $dateStr';
        
        return {
          'sms': sms,
          'expectedAmount': amount,
          'expectedType': isPayment ? 'payment' : 'purchase',
          'expectedDate': DateTime(date.year, date.month, date.day),
        };
      },
      property: (data) async {
        final sms = data['sms'] as String;
        final expectedAmount = data['expectedAmount'] as double;
        final expectedType = data['expectedType'] as String;
        final expectedDate = data['expectedDate'] as DateTime;

        // Parse SMS
        final parsed = await service.parseBankSMS(sms);

        // Property 1: Parsing should succeed for valid bank SMS
        expect(parsed, isNotNull, reason: 'Should parse SMS: $sms');

        if (parsed != null) {
          // Property 2: Amount should be extracted correctly
          final parsedAmount = parsed['amount'] as double;
          expect((parsedAmount - expectedAmount).abs(), lessThan(0.01),
              reason: 'Amount should match: expected $expectedAmount, got $parsedAmount');

          // Property 3: Transaction type should be detected correctly
          expect(parsed['transactionType'], equals(expectedType),
              reason: 'Transaction type should be $expectedType');

          // Property 4: Date should be extracted correctly
          final parsedDate = parsed['date'] as DateTime;
          expect(parsedDate.year, equals(expectedDate.year));
          expect(parsedDate.month, equals(expectedDate.month));
          expect(parsedDate.day, equals(expectedDate.day));

          // Property 5: Bank should be detected
          expect(parsed['bank'], isNotNull);
          expect(parsed['bank'], isA<String>());

          // Property 6: Raw SMS should be preserved
          expect(parsed['rawSMS'], equals(sms));

          // Property 7: Installments should default to 1 if not specified
          expect(parsed['installments'], greaterThanOrEqualTo(1));
        }

        return true;
      },
      iterations: 100,
    );

    test('Property 42: SMS with installments should be parsed correctly', () async {
      final testCases = [
        {
          'sms': 'GARANTI 1000.00 TL harcama 3 taksit',
          'expectedAmount': 1000.0,
          'expectedInstallments': 3,
        },
        {
          'sms': 'AKBANK 2500.50 TL harcama 6 taksit',
          'expectedAmount': 2500.5,
          'expectedInstallments': 6,
        },
        {
          'sms': 'ISBANK 5000.00 TL harcama 12 taksit',
          'expectedAmount': 5000.0,
          'expectedInstallments': 12,
        },
      ];

      for (final testCase in testCases) {
        final parsed = await service.parseBankSMS(testCase['sms'] as String);
        expect(parsed, isNotNull);
        expect(parsed!['amount'], equals(testCase['expectedAmount']));
        expect(parsed['installments'], equals(testCase['expectedInstallments']));
      }
    });

    test('Property 42: SMS with different decimal separators should be parsed', () async {
      final testCases = [
        'GARANTI 1234.56 TL harcama', // Dot separator
        'GARANTI 1234,56 TL harcama', // Comma separator
      ];

      for (final sms in testCases) {
        final parsed = await service.parseBankSMS(sms);
        expect(parsed, isNotNull);
        expect(parsed!['amount'], equals(1234.56));
      }
    });

    test('Property 42: Invalid SMS should return null', () async {
      final invalidMessages = [
        'Hello world',
        'Random text',
        'No bank or amount here',
      ];

      for (final message in invalidMessages) {
        final parsed = await service.parseBankSMS(message);
        expect(parsed, isNull, reason: 'Should not parse: $message');
      }
    });

    test('Property 42: Payment vs purchase should be distinguished', () async {
      final purchaseSMS = 'GARANTI 1000.00 TL harcama';
      final paymentSMS = 'GARANTI 1000.00 TL odeme';

      final parsedPurchase = await service.parseBankSMS(purchaseSMS);
      final parsedPayment = await service.parseBankSMS(paymentSMS);

      expect(parsedPurchase!['transactionType'], equals('purchase'));
      expect(parsedPayment!['transactionType'], equals('payment'));
    });

    /// **Feature: enhanced-credit-card-tracking, Property 43: SMS'ten İşlem Önerisi**
    /// **Validates: Requirements 12.3**
    /// 
    /// Property: For any parsed SMS, the system should create an automatic
    /// transaction suggestion.
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 43: Transaction suggestions should be created from SMS',
      generator: () {
        final banks = ['GARANTI', 'ISBANK', 'AKBANK', 'YAPIKREDI'];
        final bank = banks[PropertyTest.randomInt(min: 0, max: banks.length - 1)];
        final amount = PropertyTest.randomPositiveDouble(min: 0.01, max: 100000);
        final amountStr = amount.toStringAsFixed(2).replaceAll('.', ',');
        final sms = '$bank $amountStr TL harcama';
        
        return {
          'sms': sms,
          'expectedAmount': amount,
        };
      },
      property: (data) async {
        final sms = data['sms'] as String;
        final expectedAmount = data['expectedAmount'] as double;

        // Create transaction from SMS
        final transaction = await service.createTransactionFromSMS(sms);

        // Property 1: Transaction should be created for purchase SMS
        expect(transaction, isNotNull, reason: 'Should create transaction from: $sms');

        if (transaction != null) {
          // Property 2: Amount should match
          expect((transaction.amount - expectedAmount).abs(), lessThan(0.01));

          // Property 3: Transaction should have required fields
          expect(transaction.id, isNotEmpty);
          expect(transaction.description, isNotEmpty);
          expect(transaction.category, isNotEmpty);
          expect(transaction.transactionDate, isNotNull);
          expect(transaction.createdAt, isNotNull);

          // Property 4: Transaction should not be cash advance by default
          expect(transaction.isCashAdvance, isFalse);

          // Property 5: Installment count should be at least 1
          expect(transaction.installmentCount, greaterThanOrEqualTo(1));

          // Property 6: Transaction should be added to suggestions
          final suggestions = await service.getSuggestedTransactions();
          expect(suggestions.any((s) => 
            (s['transaction'] as dynamic).id == transaction.id), isTrue);
        }

        return true;
      },
      iterations: 100,
    );

    test('Property 43: Payment SMS should not create transaction suggestion', () async {
      final paymentSMS = 'GARANTI 1000.00 TL odeme';
      
      final transaction = await service.createTransactionFromSMS(paymentSMS);
      
      // Payments should not create transaction suggestions
      expect(transaction, isNull);
    });

    test('Property 43: Suggestions should be retrievable', () async {
      final sms1 = 'GARANTI 1000.00 TL harcama';
      final sms2 = 'AKBANK 2000.00 TL harcama';

      await service.createTransactionFromSMS(sms1);
      await service.createTransactionFromSMS(sms2);

      final suggestions = await service.getSuggestedTransactions();
      expect(suggestions.length, greaterThanOrEqualTo(2));
    });

    test('Property 43: Unconfirmed count should be accurate', () async {
      await service.clearSuggestions();

      final sms1 = 'GARANTI 1000.00 TL harcama';
      final sms2 = 'AKBANK 2000.00 TL harcama';

      await service.createTransactionFromSMS(sms1);
      await service.createTransactionFromSMS(sms2);

      expect(service.getUnconfirmedCount(), equals(2));
    });

    /// **Feature: enhanced-credit-card-tracking, Property 44: Öneri Onaylama**
    /// **Validates: Requirements 12.4**
    /// 
    /// Property: For any suggestion confirmation, the system should add the
    /// transaction to the specified card.
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 44: Suggestions should be confirmable and assigned to cards',
      generator: () {
        final banks = ['GARANTI', 'ISBANK', 'AKBANK'];
        final bank = banks[PropertyTest.randomInt(min: 0, max: banks.length - 1)];
        final amount = PropertyTest.randomPositiveDouble(min: 0.01, max: 10000);
        final amountStr = amount.toStringAsFixed(2).replaceAll('.', ',');
        final sms = '$bank $amountStr TL harcama';
        final cardId = 'card-${PropertyTest.randomString(minLength: 5, maxLength: 10)}';
        
        return {
          'sms': sms,
          'cardId': cardId,
        };
      },
      property: (data) async {
        final sms = data['sms'] as String;
        final cardId = data['cardId'] as String;

        // Create suggestion
        final transaction = await service.createTransactionFromSMS(sms);
        expect(transaction, isNotNull);

        if (transaction != null) {
          // Property 1: Transaction should initially have empty cardId
          expect(transaction.cardId, isEmpty);

          // Property 2: Confirm suggestion with card ID
          final confirmed = await service.confirmSuggestion(
            transaction.id,
            cardId,
          );

          expect(confirmed, isNotNull);

          if (confirmed != null) {
            // Property 3: Confirmed transaction should have the card ID
            expect(confirmed.cardId, equals(cardId));

            // Property 4: Transaction ID should remain the same
            expect(confirmed.id, equals(transaction.id));

            // Property 5: Other properties should be preserved
            expect(confirmed.amount, equals(transaction.amount));
            expect(confirmed.description, equals(transaction.description));
            expect(confirmed.installmentCount, equals(transaction.installmentCount));

            // Property 6: Suggestion should be marked as confirmed
            final suggestions = await service.getSuggestedTransactions();
            final suggestion = suggestions.firstWhere(
              (s) => (s['transaction'] as dynamic).id == transaction.id,
            );
            expect(suggestion['isConfirmed'], isTrue);
          }
        }

        return true;
      },
      iterations: 100,
    );

    test('Property 44: Confirming non-existent suggestion should return null', () async {
      final result = await service.confirmSuggestion('non-existent-id', 'card-123');
      expect(result, isNull);
    });

    test('Property 44: Suggestions can be removed', () async {
      await service.clearSuggestions();

      final sms = 'GARANTI 1000.00 TL harcama';
      final transaction = await service.createTransactionFromSMS(sms);
      expect(transaction, isNotNull);

      final beforeRemove = await service.getSuggestedTransactions();
      expect(beforeRemove.length, equals(1));

      await service.removeSuggestion(transaction!.id);

      final afterRemove = await service.getSuggestedTransactions();
      expect(afterRemove.length, equals(0));
    });

    test('Property 44: All suggestions can be cleared', () async {
      await service.clearSuggestions();

      // Create multiple suggestions
      await service.createTransactionFromSMS('GARANTI 1000.00 TL harcama');
      await service.createTransactionFromSMS('AKBANK 2000.00 TL harcama');
      await service.createTransactionFromSMS('ISBANK 3000.00 TL harcama');

      final before = await service.getSuggestedTransactions();
      expect(before.length, equals(3));

      await service.clearSuggestions();

      final after = await service.getSuggestedTransactions();
      expect(after.length, equals(0));
    });

    test('Property 44: Confirmed suggestions should reduce unconfirmed count', () async {
      await service.clearSuggestions();

      final sms1 = 'GARANTI 1000.00 TL harcama';
      final sms2 = 'AKBANK 2000.00 TL harcama';

      final t1 = await service.createTransactionFromSMS(sms1);
      final t2 = await service.createTransactionFromSMS(sms2);

      expect(service.getUnconfirmedCount(), equals(2));

      await service.confirmSuggestion(t1!.id, 'card-1');

      expect(service.getUnconfirmedCount(), equals(1));

      await service.confirmSuggestion(t2!.id, 'card-2');

      expect(service.getUnconfirmedCount(), equals(0));
    });
  });
}
