# Error Handling Quick Reference

## Quick Start

### 1. Import Required Classes
```dart
import '../exceptions/credit_card_exception.dart';
import '../exceptions/error_codes.dart';
import '../utils/service_error_handler.dart';
```

### 2. Wrap Service Method
```dart
Future<Result> myMethod(String param) async {
  return await ServiceErrorHandler.execute(
    operation: () async {
      // Your code here
    },
    serviceName: 'MyService',
    operationName: 'myMethod',
    errorCode: ErrorCodes.OPERATION_FAILED,
    errorMessage: 'İşlem başarısız',
  );
}
```

## Common Validations

### Positive Number
```dart
ServiceErrorHandler.validatePositive(
  value: amount,
  fieldName: 'Tutar',
);
```

### Not Empty String
```dart
ServiceErrorHandler.validateNotEmpty(
  value: name,
  fieldName: 'İsim',
);
```

### Range Check
```dart
ServiceErrorHandler.validateRange(
  value: count,
  min: 1,
  max: 36,
  fieldName: 'Taksit sayısı',
);
```

### Enum Validation
```dart
ServiceErrorHandler.validateInList(
  value: type,
  allowedValues: ['bonus', 'miles', 'cashback'],
  fieldName: 'Puan türü',
);
```

## Throwing Exceptions

### Simple Exception
```dart
throw CreditCardException(
  'Kart bulunamadı',
  ErrorCodes.CARD_NOT_FOUND,
);
```

### With Details
```dart
throw CreditCardException(
  'Yetersiz bakiye',
  ErrorCodes.INSUFFICIENT_BALANCE,
  {'balance': balance, 'requested': amount},
);
```

## UI Error Handling

### Show Error
```dart
try {
  await service.operation();
} catch (e) {
  ErrorHandler.showError(context, e);
}
```

### Show Success
```dart
ErrorHandler.showSuccess(context, 'İşlem başarılı');
```

## Common Error Codes

| Scenario | Error Code |
|----------|------------|
| Invalid amount | `ErrorCodes.INVALID_AMOUNT` |
| Card not found | `ErrorCodes.CARD_NOT_FOUND` |
| Insufficient balance | `ErrorCodes.INSUFFICIENT_BALANCE` |
| Limit exceeded | `ErrorCodes.LIMIT_EXCEEDED` |
| Save failed | `ErrorCodes.SAVE_FAILED` |
| Update failed | `ErrorCodes.UPDATE_FAILED` |
| Invalid input | `ErrorCodes.INVALID_INPUT` |
| Calculation error | `ErrorCodes.CALCULATION_ERROR` |

## Logging

### Log Error
```dart
final logger = ErrorLoggerService();
logger.error('Operation failed', error: e, stackTrace: st);
```

### Log Info
```dart
logger.info('Operation completed', context: 'MyService');
```

## Testing

### Test Exception
```dart
test('should throw exception', () async {
  expect(
    () => service.method(),
    throwsA(isA<CreditCardException>()
      .having((e) => e.code, 'code', ErrorCodes.INVALID_AMOUNT)),
  );
});
```

## Full Example

```dart
class MyService {
  static const String _serviceName = 'MyService';

  Future<void> processPayment(String cardId, double amount) async {
    return await ServiceErrorHandler.execute(
      operation: () async {
        // Validate inputs
        ServiceErrorHandler.validateNotEmpty(
          value: cardId,
          fieldName: 'Kart ID',
        );
        ServiceErrorHandler.validatePositive(
          value: amount,
          fieldName: 'Tutar',
        );

        // Get card
        final card = await _repo.findById(cardId);
        if (card == null) {
          throw CreditCardException(
            'Kart bulunamadı',
            ErrorCodes.CARD_NOT_FOUND,
            {'cardId': cardId},
          );
        }

        // Business logic validation
        if (amount > card.debt) {
          throw CreditCardException(
            'Ödeme tutarı borçtan fazla',
            ErrorCodes.PAYMENT_EXCEEDS_DEBT,
            {'payment': amount, 'debt': card.debt},
          );
        }

        // Process payment
        await _processPayment(card, amount);
      },
      serviceName: _serviceName,
      operationName: 'processPayment',
      errorCode: ErrorCodes.OPERATION_FAILED,
      errorMessage: 'Ödeme işlemi başarısız',
    );
  }
}
```

## See Also

- Full documentation: `lib/exceptions/README.md`
- Migration guide: `docs/ERROR_HANDLING_MIGRATION_GUIDE.md`
- Implementation summary: `docs/ERROR_HANDLING_SUMMARY.md`
