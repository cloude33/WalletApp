# Error Handling Migration Guide

This guide explains how to migrate existing services to use the new error handling system.

## Overview

The new error handling system provides:
- Structured exception handling with `CreditCardException`
- Centralized error codes in `ErrorCodes`
- Automatic error logging with `ErrorLoggerService`
- Validation helpers in `ServiceErrorHandler`
- User-friendly error messages

## Migration Steps

### Step 1: Add Imports

Add these imports to your service file:

```dart
import '../exceptions/credit_card_exception.dart';
import '../exceptions/error_codes.dart';
import '../utils/service_error_handler.dart';
```

### Step 2: Add Service Name Constant

Add a service name constant for logging:

```dart
class MyService {
  static const String _serviceName = 'MyService';
  // ... rest of the class
}
```

### Step 3: Wrap Operations

Wrap your service methods with `ServiceErrorHandler.execute`:

**Before:**
```dart
Future<Result> myOperation(String param) async {
  if (param.isEmpty) {
    throw Exception('Parameter cannot be empty');
  }
  
  final result = await _performOperation(param);
  return result;
}
```

**After:**
```dart
Future<Result> myOperation(String param) async {
  return await ServiceErrorHandler.execute(
    operation: () async {
      ServiceErrorHandler.validateNotEmpty(
        value: param,
        fieldName: 'Parametre',
      );
      
      final result = await _performOperation(param);
      return result;
    },
    serviceName: _serviceName,
    operationName: 'myOperation',
    errorCode: ErrorCodes.OPERATION_FAILED,
    errorMessage: 'İşlem başarısız',
  );
}
```

### Step 4: Replace Validation Logic

Replace manual validation with helper methods:

**Before:**
```dart
if (amount <= 0) {
  throw Exception('Amount must be positive');
}
if (cardId.trim().isEmpty) {
  throw Exception('Card ID cannot be empty');
}
if (installmentCount < 2 || installmentCount > 36) {
  throw Exception('Installment count must be between 2 and 36');
}
```

**After:**
```dart
ServiceErrorHandler.validatePositive(
  value: amount,
  fieldName: 'Tutar',
  errorCode: ErrorCodes.INVALID_AMOUNT,
);

ServiceErrorHandler.validateNotEmpty(
  value: cardId,
  fieldName: 'Kart ID',
  errorCode: ErrorCodes.INVALID_CARD_DATA,
);

ServiceErrorHandler.validateRange(
  value: installmentCount.toDouble(),
  min: 2,
  max: 36,
  fieldName: 'Taksit sayısı',
  errorCode: ErrorCodes.INVALID_INSTALLMENT_COUNT,
);
```

### Step 5: Replace Exception Throws

Replace generic exceptions with `CreditCardException`:

**Before:**
```dart
if (balance < amount) {
  throw Exception('Insufficient balance');
}
```

**After:**
```dart
if (balance < amount) {
  throw CreditCardException(
    'Yetersiz bakiye',
    ErrorCodes.INSUFFICIENT_BALANCE,
    {'balance': balance, 'requested': amount},
  );
}
```

### Step 6: Update Documentation

Update method documentation to reflect the new exception type:

**Before:**
```dart
/// Throws [Exception] if validation fails
```

**After:**
```dart
/// Throws [CreditCardException] if validation fails
```

## Common Patterns

### Pattern 1: Simple Validation

```dart
Future<void> updateCard(String cardId, String name) async {
  return await ServiceErrorHandler.execute(
    operation: () async {
      ServiceErrorHandler.validateNotEmpty(
        value: cardId,
        fieldName: 'Kart ID',
      );
      ServiceErrorHandler.validateNotEmpty(
        value: name,
        fieldName: 'Kart adı',
      );
      
      await _repo.update(cardId, name);
    },
    serviceName: _serviceName,
    operationName: 'updateCard',
    errorCode: ErrorCodes.UPDATE_FAILED,
    errorMessage: 'Kart güncellenemedi',
  );
}
```

### Pattern 2: Business Logic Validation

```dart
Future<void> makePayment(String cardId, double amount) async {
  return await ServiceErrorHandler.execute(
    operation: () async {
      final card = await _repo.findById(cardId);
      if (card == null) {
        throw CreditCardException(
          'Kart bulunamadı',
          ErrorCodes.CARD_NOT_FOUND,
          {'cardId': cardId},
        );
      }
      
      if (amount > card.debt) {
        throw CreditCardException(
          'Ödeme tutarı borçtan fazla',
          ErrorCodes.PAYMENT_EXCEEDS_DEBT,
          {'payment': amount, 'debt': card.debt},
        );
      }
      
      await _processPayment(card, amount);
    },
    serviceName: _serviceName,
    operationName: 'makePayment',
    errorCode: ErrorCodes.OPERATION_FAILED,
    errorMessage: 'Ödeme işlemi başarısız',
  );
}
```

### Pattern 3: Multiple Validations

```dart
Future<Transaction> createTransaction({
  required String cardId,
  required double amount,
  required String description,
  required int installmentCount,
}) async {
  return await ServiceErrorHandler.execute(
    operation: () async {
      // Validate all inputs
      ServiceErrorHandler.validateNotEmpty(
        value: cardId,
        fieldName: 'Kart ID',
      );
      ServiceErrorHandler.validatePositive(
        value: amount,
        fieldName: 'Tutar',
      );
      ServiceErrorHandler.validateNotEmpty(
        value: description,
        fieldName: 'Açıklama',
      );
      ServiceErrorHandler.validateRange(
        value: installmentCount.toDouble(),
        min: 1,
        max: 36,
        fieldName: 'Taksit sayısı',
      );
      
      // Create and save transaction
      final transaction = Transaction(/* ... */);
      await _repo.save(transaction);
      return transaction;
    },
    serviceName: _serviceName,
    operationName: 'createTransaction',
    errorCode: ErrorCodes.SAVE_FAILED,
    errorMessage: 'İşlem oluşturulamadı',
  );
}
```

### Pattern 4: Calculation with Error Handling

```dart
Future<double> calculateInterest(String cardId) async {
  return await ServiceErrorHandler.execute(
    operation: () async {
      final card = await _repo.findById(cardId);
      if (card == null) {
        throw CreditCardException(
          'Kart bulunamadı',
          ErrorCodes.CARD_NOT_FOUND,
          {'cardId': cardId},
        );
      }
      
      try {
        final interest = card.debt * card.interestRate / 100;
        return interest;
      } catch (e) {
        throw CreditCardException(
          'Faiz hesaplanamadı',
          ErrorCodes.INTEREST_CALCULATION_ERROR,
          {'cardId': cardId, 'error': e.toString()},
        );
      }
    },
    serviceName: _serviceName,
    operationName: 'calculateInterest',
    errorCode: ErrorCodes.CALCULATION_ERROR,
    errorMessage: 'Faiz hesaplama başarısız',
  );
}
```

## Validation Helper Reference

### validatePositive
Validates that a number is greater than zero.
```dart
ServiceErrorHandler.validatePositive(
  value: amount,
  fieldName: 'Tutar',
  errorCode: ErrorCodes.INVALID_AMOUNT, // optional
);
```

### validateNonNegative
Validates that a number is greater than or equal to zero.
```dart
ServiceErrorHandler.validateNonNegative(
  value: balance,
  fieldName: 'Bakiye',
);
```

### validateNotEmpty
Validates that a string is not empty.
```dart
ServiceErrorHandler.validateNotEmpty(
  value: name,
  fieldName: 'İsim',
);
```

### validateRange
Validates that a number is within a range.
```dart
ServiceErrorHandler.validateRange(
  value: percentage,
  min: 0,
  max: 100,
  fieldName: 'Yüzde',
);
```

### validateInList
Validates that a value is in a list of allowed values.
```dart
ServiceErrorHandler.validateInList(
  value: type,
  allowedValues: ['bonus', 'miles', 'cashback'],
  fieldName: 'Puan türü',
);
```

### validateNotNull
Validates that a value is not null.
```dart
final card = ServiceErrorHandler.validateNotNull(
  value: await _repo.findById(cardId),
  message: 'Kart bulunamadı',
  errorCode: ErrorCodes.CARD_NOT_FOUND,
);
```

### validateFutureDate
Validates that a date is in the future.
```dart
ServiceErrorHandler.validateFutureDate(
  date: dueDate,
  fieldName: 'Son ödeme tarihi',
);
```

## Error Code Selection Guide

Choose the appropriate error code based on the error type:

| Error Type | Error Code | Example |
|------------|------------|---------|
| Invalid input | `INVALID_INPUT` | Empty string, null value |
| Invalid amount | `INVALID_AMOUNT` | Negative or zero amount |
| Invalid date | `INVALID_DATE` | Past date when future required |
| Not found | `*_NOT_FOUND` | Card, transaction, etc. not found |
| Insufficient | `INSUFFICIENT_*` | Insufficient balance, points, limit |
| Limit exceeded | `LIMIT_EXCEEDED` | Card limit exceeded |
| Already exists | `ALREADY_EXISTS` | Duplicate entry |
| Calculation error | `*_CALCULATION_ERROR` | Math operation failed |
| Database error | `*_FAILED` | Save, update, delete failed |

## Testing Error Handling

Test error scenarios in your tests:

```dart
test('should throw INSUFFICIENT_BALANCE when balance is low', () async {
  final service = MyService();
  
  expect(
    () => service.withdraw(1000),
    throwsA(isA<CreditCardException>()
      .having((e) => e.code, 'code', ErrorCodes.INSUFFICIENT_BALANCE)),
  );
});

test('should throw INVALID_AMOUNT for negative amount', () async {
  final service = MyService();
  
  expect(
    () => service.deposit(-100),
    throwsA(isA<CreditCardException>()
      .having((e) => e.code, 'code', ErrorCodes.INVALID_AMOUNT)),
  );
});
```

## Checklist

Use this checklist when migrating a service:

- [ ] Add imports for exception classes
- [ ] Add service name constant
- [ ] Wrap all public methods with `ServiceErrorHandler.execute`
- [ ] Replace manual validation with helper methods
- [ ] Replace `Exception` with `CreditCardException`
- [ ] Choose appropriate error codes
- [ ] Update method documentation
- [ ] Add error handling tests
- [ ] Test error messages in UI

## Examples

See these files for complete examples:
- `lib/services/reward_points_service.dart` - Fully migrated
- `lib/services/deferred_installment_service.dart` - Fully migrated
- `lib/exceptions/README.md` - Complete documentation
