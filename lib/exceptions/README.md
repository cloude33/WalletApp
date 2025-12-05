# Error Management System

This directory contains the error management system for the credit card tracking application.

## Components

### 1. CreditCardException (`credit_card_exception.dart`)

Custom exception class for credit card related errors.

**Usage:**
```dart
throw CreditCardException(
  'Yetersiz puan bakiyesi',
  ErrorCodes.INSUFFICIENT_POINTS,
  {'balance': 100, 'requested': 150},
);
```

### 2. ErrorCodes (`error_codes.dart`)

Centralized error codes and user-friendly messages.

**Categories:**
- Validation Errors (INVALID_*)
- Business Logic Errors (LIMIT_EXCEEDED, INSUFFICIENT_*)
- Not Found Errors (*_NOT_FOUND)
- Calculation Errors (*_CALCULATION_ERROR)
- Database Errors (DATABASE_ERROR, *_FAILED)
- Permission Errors (*_PERMISSION_DENIED)
- Parsing Errors (*_PARSE_ERROR)
- Notification Errors (NOTIFICATION_*)
- General Errors (UNKNOWN_ERROR, NETWORK_ERROR)

**Usage:**
```dart
throw CreditCardException(
  'Kart bulunamadı',
  ErrorCodes.CARD_NOT_FOUND,
  {'cardId': cardId},
);
```

### 3. ErrorLoggerService (`../services/error_logger_service.dart`)

Service for logging errors and debugging information.

**Usage:**
```dart
final logger = ErrorLoggerService();

// Log an error
logger.error('Operation failed', error: e, stackTrace: st);

// Log a warning
logger.warning('Unusual condition detected');

// Log info
logger.info('Operation completed successfully');

// Log debug
logger.debug('Processing item', details: {'id': itemId});

// Log exception
logger.logException(creditCardException);
```

### 4. ServiceErrorHandler (`../utils/service_error_handler.dart`)

Utility for wrapping service operations with error handling.

**Usage:**

#### Execute async operation:
```dart
return await ServiceErrorHandler.execute(
  operation: () async {
    // Your operation code
    return result;
  },
  serviceName: 'MyService',
  operationName: 'myOperation',
  errorCode: ErrorCodes.OPERATION_FAILED,
  errorMessage: 'Operation failed',
);
```

#### Validation helpers:
```dart
// Validate positive number
ServiceErrorHandler.validatePositive(
  value: amount,
  fieldName: 'Tutar',
  errorCode: ErrorCodes.INVALID_AMOUNT,
);

// Validate not empty
ServiceErrorHandler.validateNotEmpty(
  value: cardName,
  fieldName: 'Kart adı',
);

// Validate in list
ServiceErrorHandler.validateInList(
  value: rewardType,
  allowedValues: ['bonus', 'miles', 'cashback'],
  fieldName: 'Puan türü',
);

// Validate range
ServiceErrorHandler.validateRange(
  value: percentage,
  min: 0,
  max: 100,
  fieldName: 'Yüzde',
);
```

### 5. ErrorHandler (`../utils/error_handler.dart`)

UI error handler for displaying errors to users.

**Usage:**
```dart
try {
  await service.performOperation();
} catch (e) {
  ErrorHandler.showError(context, e);
}

// Show success message
ErrorHandler.showSuccess(context, 'İşlem başarılı');

// Show info message
ErrorHandler.showInfo(context, 'Bilgi mesajı');
```

## Best Practices

### 1. Service Implementation

Always wrap service operations with error handling:

```dart
class MyService {
  static const String _serviceName = 'MyService';

  Future<Result> myOperation(String param) async {
    return await ServiceErrorHandler.execute(
      operation: () async {
        // Validate inputs
        ServiceErrorHandler.validateNotEmpty(
          value: param,
          fieldName: 'Parametre',
        );

        // Perform operation
        final result = await _performOperation(param);
        
        return result;
      },
      serviceName: _serviceName,
      operationName: 'myOperation',
      errorCode: ErrorCodes.OPERATION_FAILED,
      errorMessage: 'İşlem başarısız',
    );
  }
}
```

### 2. UI Error Handling

Always catch and display errors in UI:

```dart
Future<void> _handleButtonPress() async {
  try {
    await _service.performOperation();
    ErrorHandler.showSuccess(context, 'İşlem başarılı');
  } catch (e) {
    ErrorHandler.showError(context, e);
  }
}
```

### 3. Custom Validation

For complex validation, throw CreditCardException directly:

```dart
if (payment > debt) {
  throw CreditCardException(
    'Ödeme tutarı borçtan fazla olamaz',
    ErrorCodes.PAYMENT_EXCEEDS_DEBT,
    {'payment': payment, 'debt': debt},
  );
}
```

### 4. Logging

Log important operations and errors:

```dart
final logger = ErrorLoggerService();

// Log operation start
logger.debug('Starting operation', context: 'MyService');

// Log operation success
logger.info('Operation completed', context: 'MyService');

// Log validation error
logger.logValidationError(
  'Invalid input',
  field: 'amount',
  value: amount,
);

// Log exception
try {
  // operation
} catch (e, st) {
  logger.error('Operation failed', error: e, stackTrace: st);
  rethrow;
}
```

## Error Code Naming Convention

- Use UPPER_SNAKE_CASE
- Be descriptive and specific
- Group by category (prefix)
- Examples:
  - `INVALID_AMOUNT` - validation error
  - `CARD_NOT_FOUND` - not found error
  - `LIMIT_EXCEEDED` - business logic error
  - `DATABASE_ERROR` - database error

## User Message Guidelines

- Use Turkish language
- Be clear and concise
- Provide actionable information
- Avoid technical jargon
- Examples:
  - ✅ "Kart limiti aşıldı. Lütfen limitinizi kontrol edin."
  - ❌ "LIMIT_EXCEEDED: Card limit validation failed"

## Testing Error Handling

Test error scenarios in your tests:

```dart
test('should throw INSUFFICIENT_POINTS when balance is low', () async {
  final service = RewardPointsService();
  
  expect(
    () => service.spendPoints('card-1', 1000, 'Test'),
    throwsA(isA<CreditCardException>()
      .having((e) => e.code, 'code', ErrorCodes.INSUFFICIENT_POINTS)),
  );
});
```
