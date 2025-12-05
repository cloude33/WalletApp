# Credit Card Migration Service

## Overview

The `CreditCardMigrationService` handles the migration of existing credit card data to support the new enhanced tracking features. This service automatically runs on app startup and updates existing data with default values for new fields.

## What Gets Migrated

### Credit Card Fields
The service adds the following new fields to existing credit cards:

- **rewardType**: Default value is `'bonus'` (can be 'bonus', 'worldpuan', 'miles', 'cashback')
- **pointsConversionRate**: Default value is `0.01` (1 puan = 0.01 TL)
- **cashAdvanceRate**: Default value is `monthlyInterestRate * 1.5` (typically 50% higher than regular rate)
- **cashAdvanceLimit**: Default value is `creditLimit * 0.4` (40% of credit limit)

### Credit Card Transaction Fields
The service adds the following new fields to existing transactions:

- **pointsEarned**: Calculated as the transaction amount (for non-cash advance transactions)
- **installmentStartDate**: Set to transaction date for regular installments, or calculated based on `deferredMonths` for deferred installments

### Reward Points
The service creates a `RewardPoints` record for each credit card with:

- Initial balance of 0.0
- Reward type matching the card's reward type
- Conversion rate matching the card's conversion rate

## How It Works

### Automatic Migration

The migration runs automatically on app startup (in `main.dart`):

```dart
try {
  final creditCardMigrationService = CreditCardMigrationService();
  final result = await creditCardMigrationService.migrateCreditCards();
  debugPrint('Credit card migration: ${result.message}');
} catch (e) {
  debugPrint('Credit card migration error: $e');
}
```

### Migration Process

1. **Check if already migrated**: The service checks if migration has already been completed using SharedPreferences
2. **Skip if completed**: If migration was already done, it skips the process
3. **Process each card**: For each credit card:
   - Add default values for missing fields
   - Create RewardPoints record if it doesn't exist
   - Update all transactions with missing fields
4. **Mark as complete**: Set migration flag in SharedPreferences

### Idempotency

The migration is idempotent - it can be run multiple times safely:
- Already migrated data is not modified
- Only missing fields are filled with defaults
- Migration flag prevents unnecessary re-processing

## Manual Usage

### Check Migration Status

```dart
final migrationService = CreditCardMigrationService();
final status = await migrationService.getMigrationStatus();

print('Migration completed: ${status.isCompleted}');
print('Total cards: ${status.totalCards}');
print('Cards with new fields: ${status.cardsWithNewFields}');
print('Cards needing migration: ${status.cardsWithoutNewFields}');
print('Needs migration: ${status.needsMigration}');
```

### Run Migration Manually

```dart
final migrationService = CreditCardMigrationService();
final result = await migrationService.migrateCreditCards();

if (result.success) {
  print('Migration successful!');
  print('Cards updated: ${result.cardsUpdated}');
  print('Transactions updated: ${result.transactionsUpdated}');
  print('Reward points created: ${result.rewardPointsCreated}');
} else {
  print('Migration failed: ${result.message}');
}
```

### Rollback Migration (Testing Only)

⚠️ **WARNING**: Rollback should only be used for testing purposes!

```dart
final migrationService = CreditCardMigrationService();
final result = await migrationService.rollbackMigration();

if (result.success) {
  print('Rollback successful!');
  print('Cards reverted: ${result.cardsReverted}');
  print('Transactions reverted: ${result.transactionsReverted}');
  print('Reward points deleted: ${result.rewardPointsDeleted}');
}
```

## Default Values Rationale

### Reward Type: 'bonus'
Bonus is the most common reward program in Turkey, used by many banks.

### Points Conversion Rate: 0.01 (1 puan = 0.01 TL)
This is a conservative default. Most programs offer 1 puan = 0.01-0.02 TL.

### Cash Advance Rate: monthlyInterestRate * 1.5
Cash advance rates are typically 50% higher than regular purchase rates.

### Cash Advance Limit: creditLimit * 0.4
Most banks set cash advance limits at 30-50% of the credit limit. We use 40% as a middle ground.

## Testing

The migration service includes comprehensive tests covering:

- Empty database handling
- Single and multiple card migration
- Transaction migration with deferred installments
- Cash advance transaction handling
- Rollback functionality
- Migration status reporting
- Idempotency verification

Run tests with:
```bash
flutter test test/services/credit_card_migration_service_test.dart
```

## Error Handling

The migration service includes robust error handling:

- All errors are caught and logged
- Failed migrations return a `MigrationResult` with error details
- The app continues to function even if migration fails
- Migration can be retried by clearing the migration flag

## Migration Flag

The migration status is stored in SharedPreferences with the key:
- `credit_card_migration_v1_completed`: Boolean flag indicating completion
- `credit_card_migration_v1_backup`: Timestamp of when migration was completed

## Future Migrations

If additional migrations are needed in the future:

1. Create a new migration key (e.g., `credit_card_migration_v2_completed`)
2. Add new migration logic to the service
3. Update the version number in the key
4. Existing v1 migration will remain completed

## Troubleshooting

### Migration Not Running

If migration doesn't seem to run:
1. Check app logs for migration messages
2. Verify SharedPreferences is working
3. Check if migration flag is set: `credit_card_migration_v1_completed`

### Migration Fails

If migration fails:
1. Check error logs for specific error messages
2. Verify Hive boxes are properly initialized
3. Ensure all adapters are registered
4. Check for data corruption in existing records

### Reset Migration

To force migration to run again (for testing):
```dart
final prefs = await SharedPreferences.getInstance();
await prefs.remove('credit_card_migration_v1_completed');
await prefs.remove('credit_card_migration_v1_backup');
```

## Performance

The migration is designed to be fast:
- Processes cards and transactions in batches
- Only updates records that need changes
- Uses efficient Hive operations
- Typically completes in < 1 second for most users

## Data Safety

The migration is safe:
- No data is deleted
- Only adds new fields with default values
- Existing data remains unchanged
- Can be rolled back if needed (for testing)
- Idempotent - safe to run multiple times
