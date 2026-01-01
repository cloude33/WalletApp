import 'package:flutter_test/flutter_test.dart';
import 'package:parion/services/kmh_service.dart';
import 'package:parion/services/data_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../property_test_utils.dart';

/// **Feature: kmh-account-management, Property 4: Hesap Güncelleme Round-Trip**
/// **Validates: Requirements 1.4**
///
/// Property: For any KMH account, when updated, the new values should be saved
/// and when read back should contain the updated values.
void main() {
  group('KMH Account Update Round-Trip Property Tests', () {
    late KmhService kmhService;
    late DataService dataService;

    setUp(() async {
      // Initialize SharedPreferences with empty data for each test
      SharedPreferences.setMockInitialValues({});

      // Initialize services
      dataService = DataService();
      await dataService.init();
      kmhService = KmhService(dataService: dataService);
    });

    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 4: KMH account update round-trip - updated values preserved',
      generator: () {
        return {
          'bankName': PropertyTest.randomString(minLength: 5, maxLength: 30),
          'creditLimit': PropertyTest.randomPositiveDouble(
            min: 1000,
            max: 100000,
          ),
          'interestRate': PropertyTest.randomPositiveDouble(min: 1, max: 50),
          'accountNumber':
              PropertyTest.randomInt(min: 100000, max: 999999).toString() +
              PropertyTest.randomInt(min: 1000, max: 9999).toString(),
          'initialBalance': PropertyTest.randomDouble(min: -50000, max: 50000),
          // New values for update
          'newCreditLimit': PropertyTest.randomPositiveDouble(
            min: 1000,
            max: 100000,
          ),
          'newInterestRate': PropertyTest.randomPositiveDouble(min: 1, max: 50),
          'newBalance': PropertyTest.randomDouble(min: -50000, max: 50000),
        };
      },
      property: (data) async {
        // Step 1: Create initial KMH account
        final initialAccount = await kmhService.createKmhAccount(
          bankName: data['bankName'],
          creditLimit: data['creditLimit'],
          interestRate: data['interestRate'],
          accountNumber: data['accountNumber'],
          initialBalance: data['initialBalance'],
        );

        // Verify initial account was created correctly
        expect(initialAccount.isKmhAccount, isTrue);
        expect(initialAccount.name, equals(data['bankName']));
        expect(initialAccount.creditLimit, equals(data['creditLimit']));
        expect(initialAccount.interestRate, equals(data['interestRate']));
        expect(initialAccount.accountNumber, equals(data['accountNumber']));
        expect(initialAccount.balance, equals(data['initialBalance']));

        // Step 2: Update the account with new values
        final updatedAccount = initialAccount.copyWith(
          creditLimit: data['newCreditLimit'],
          interestRate: data['newInterestRate'],
          balance: data['newBalance'],
        );

        // Save the updated account
        await kmhService.updateKmhAccount(updatedAccount);

        // Step 3: Read back the account from storage
        final wallets = await dataService.getWallets();
        final retrievedAccount = wallets.firstWhere(
          (w) => w.id == initialAccount.id,
        );

        // Property 1: Updated fields should have new values
        expect(
          retrievedAccount.creditLimit,
          equals(data['newCreditLimit']),
          reason: 'Credit limit should be updated',
        );
        expect(
          retrievedAccount.interestRate,
          equals(data['newInterestRate']),
          reason: 'Interest rate should be updated',
        );
        expect(
          retrievedAccount.balance,
          equals(data['newBalance']),
          reason: 'Balance should be updated',
        );

        // Property 2: Unchanged fields should remain the same
        expect(
          retrievedAccount.id,
          equals(initialAccount.id),
          reason: 'ID should not change',
        );
        expect(
          retrievedAccount.name,
          equals(data['bankName']),
          reason: 'Bank name should not change',
        );
        expect(
          retrievedAccount.accountNumber,
          equals(data['accountNumber']),
          reason: 'Account number should not change',
        );
        expect(
          retrievedAccount.type,
          equals('bank'),
          reason: 'Type should remain bank',
        );

        // Property 3: Should still be identified as KMH account
        expect(
          retrievedAccount.isKmhAccount,
          isTrue,
          reason: 'Should still be a KMH account after update',
        );

        // Property 4: Computed properties should reflect updated values
        final expectedUsedCredit = data['newBalance'] < 0
            ? (data['newBalance'] as double).abs()
            : 0.0;
        expect(
          retrievedAccount.usedCredit,
          equals(expectedUsedCredit),
          reason: 'Used credit should be calculated from new balance',
        );

        final expectedAvailableCredit =
            (data['newCreditLimit'] as double) + (data['newBalance'] as double);
        expect(
          retrievedAccount.availableCredit,
          equals(expectedAvailableCredit),
          reason: 'Available credit should be calculated from new values',
        );

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description:
          'Property 4: Multiple sequential updates preserve latest values',
      generator: () {
        return {
          'bankName': PropertyTest.randomString(minLength: 5, maxLength: 30),
          'creditLimit1': PropertyTest.randomPositiveDouble(
            min: 1000,
            max: 100000,
          ),
          'interestRate1': PropertyTest.randomPositiveDouble(min: 1, max: 50),
          'creditLimit2': PropertyTest.randomPositiveDouble(
            min: 1000,
            max: 100000,
          ),
          'interestRate2': PropertyTest.randomPositiveDouble(min: 1, max: 50),
          'creditLimit3': PropertyTest.randomPositiveDouble(
            min: 1000,
            max: 100000,
          ),
          'interestRate3': PropertyTest.randomPositiveDouble(min: 1, max: 50),
        };
      },
      property: (data) async {
        // Create initial account
        final account = await kmhService.createKmhAccount(
          bankName: data['bankName'],
          creditLimit: data['creditLimit1'],
          interestRate: data['interestRate1'],
        );

        // First update
        var updated = account.copyWith(
          creditLimit: data['creditLimit2'],
          interestRate: data['interestRate2'],
        );
        await kmhService.updateKmhAccount(updated);

        // Second update
        updated = updated.copyWith(
          creditLimit: data['creditLimit3'],
          interestRate: data['interestRate3'],
        );
        await kmhService.updateKmhAccount(updated);

        // Read back and verify latest values
        final wallets = await dataService.getWallets();
        final retrieved = wallets.firstWhere((w) => w.id == account.id);

        // Property: Should have the latest (third) values
        expect(
          retrieved.creditLimit,
          equals(data['creditLimit3']),
          reason: 'Should have latest credit limit',
        );
        expect(
          retrieved.interestRate,
          equals(data['interestRate3']),
          reason: 'Should have latest interest rate',
        );

        return true;
      },
      iterations: 100,
    );

    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 4: Update preserves KMH-specific fields',
      generator: () {
        return {
          'bankName': PropertyTest.randomString(minLength: 5, maxLength: 30),
          'creditLimit': PropertyTest.randomPositiveDouble(
            min: 1000,
            max: 100000,
          ),
          'interestRate': PropertyTest.randomPositiveDouble(min: 1, max: 50),
          'accountNumber': PropertyTest.randomInt(
            min: 100000,
            max: 999999,
          ).toString(),
          'accruedInterest': PropertyTest.randomPositiveDouble(
            min: 0,
            max: 10000,
          ),
          'lastInterestDate': PropertyTest.randomDateTime(),
          'newCreditLimit': PropertyTest.randomPositiveDouble(
            min: 1000,
            max: 100000,
          ),
        };
      },
      property: (data) async {
        // Create account with all KMH fields
        var account = await kmhService.createKmhAccount(
          bankName: data['bankName'],
          creditLimit: data['creditLimit'],
          interestRate: data['interestRate'],
          accountNumber: data['accountNumber'],
        );

        // Manually set additional fields (simulating interest accrual)
        account = account.copyWith(
          accruedInterest: data['accruedInterest'],
          lastInterestDate: data['lastInterestDate'],
        );
        await dataService.updateWallet(account);

        // Update only credit limit
        final updated = account.copyWith(creditLimit: data['newCreditLimit']);
        await kmhService.updateKmhAccount(updated);

        // Read back
        final wallets = await dataService.getWallets();
        final retrieved = wallets.firstWhere((w) => w.id == account.id);

        // Property: Credit limit should be updated
        expect(retrieved.creditLimit, equals(data['newCreditLimit']));

        // Property: Other KMH fields should be preserved
        expect(
          retrieved.accountNumber,
          equals(data['accountNumber']),
          reason: 'Account number should be preserved',
        );
        expect(
          retrieved.accruedInterest,
          equals(data['accruedInterest']),
          reason: 'Accrued interest should be preserved',
        );

        // DateTime comparison with tolerance
        if (retrieved.lastInterestDate != null &&
            data['lastInterestDate'] != null) {
          expect(
            retrieved.lastInterestDate!
                .difference(data['lastInterestDate'])
                .inMilliseconds
                .abs(),
            lessThan(1000),
            reason: 'Last interest date should be preserved',
          );
        }

        return true;
      },
      iterations: 100,
    );
  });
}
