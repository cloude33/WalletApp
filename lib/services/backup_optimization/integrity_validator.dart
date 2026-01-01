import '../../models/backup_optimization/backup_results.dart';

/// Validator for backup data structure and integrity
class IntegrityValidator {
  /// Validates the overall structure of backup data
  Future<bool> validateStructure(Map<String, dynamic> backupData) async {
    try {
      // Check for required top-level keys
      final requiredKeys = [
        'metadata',
        'transactions',
        'wallets',
      ];

      for (final key in requiredKeys) {
        if (!backupData.containsKey(key)) {
          return false;
        }
      }

      // Validate metadata structure
      final metadata = backupData['metadata'];
      if (metadata is! Map<String, dynamic>) {
        return false;
      }

      if (!_validateMetadataStructure(metadata)) {
        return false;
      }

      // Validate transactions structure
      final transactions = backupData['transactions'];
      if (transactions is! List) {
        return false;
      }

      // Validate wallets structure
      final wallets = backupData['wallets'];
      if (wallets is! List) {
        return false;
      }

      // Validate optional sections if present
      if (backupData.containsKey('creditCards')) {
        final creditCards = backupData['creditCards'];
        if (creditCards is! List) {
          return false;
        }
      }

      if (backupData.containsKey('goals')) {
        final goals = backupData['goals'];
        if (goals is! List) {
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Validates data types within backup data
  Future<bool> validateDataTypes(Map<String, dynamic> backupData) async {
    try {
      // Validate metadata data types
      final metadata = backupData['metadata'] as Map<String, dynamic>;
      if (!_validateMetadataDataTypes(metadata)) {
        return false;
      }

      // Validate transactions data types
      final transactions = backupData['transactions'] as List;
      for (final transaction in transactions) {
        if (transaction is! Map<String, dynamic>) {
          return false;
        }
        if (!_validateTransactionDataTypes(transaction)) {
          return false;
        }
      }

      // Validate wallets data types
      final wallets = backupData['wallets'] as List;
      for (final wallet in wallets) {
        if (wallet is! Map<String, dynamic>) {
          return false;
        }
        if (!_validateWalletDataTypes(wallet)) {
          return false;
        }
      }

      // Validate optional sections
      if (backupData.containsKey('creditCards')) {
        final creditCards = backupData['creditCards'] as List;
        for (final card in creditCards) {
          if (card is! Map<String, dynamic>) {
            return false;
          }
          if (!_validateCreditCardDataTypes(card)) {
            return false;
          }
        }
      }

      if (backupData.containsKey('goals')) {
        final goals = backupData['goals'] as List;
        for (final goal in goals) {
          if (goal is! Map<String, dynamic>) {
            return false;
          }
          if (!_validateGoalDataTypes(goal)) {
            return false;
          }
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Finds inconsistencies in backup data
  Future<List<ValidationError>> findInconsistencies(Map<String, dynamic> backupData) async {
    final errors = <ValidationError>[];

    try {
      // Check metadata consistency
      final metadata = backupData['metadata'] as Map<String, dynamic>;
      final metadataErrors = await _validateMetadataConsistency(metadata, backupData);
      errors.addAll(metadataErrors);

      // Check transaction consistency
      final transactions = backupData['transactions'] as List;
      final transactionErrors = await _validateTransactionConsistency(transactions, backupData);
      errors.addAll(transactionErrors);

      // Check wallet consistency
      final wallets = backupData['wallets'] as List;
      final walletErrors = await _validateWalletConsistency(wallets, backupData);
      errors.addAll(walletErrors);

      // Check referential integrity
      final referentialErrors = await _validateReferentialIntegrity(backupData);
      errors.addAll(referentialErrors);

      // Check data ranges and constraints
      final constraintErrors = await _validateDataConstraints(backupData);
      errors.addAll(constraintErrors);

    } catch (e) {
      errors.add(ValidationError(
        field: 'general',
        message: 'Error during inconsistency check: ${e.toString()}',
        severity: 'error',
      ));
    }

    return errors;
  }

  /// Validates metadata structure
  bool _validateMetadataStructure(Map<String, dynamic> metadata) {
    final requiredFields = [
      'version',
      'createdAt',
      'transactionCount',
      'walletCount',
    ];

    for (final field in requiredFields) {
      if (!metadata.containsKey(field)) {
        return false;
      }
    }

    return true;
  }

  /// Validates metadata data types
  bool _validateMetadataDataTypes(Map<String, dynamic> metadata) {
    // Check version is string
    if (metadata['version'] is! String) {
      return false;
    }

    // Check createdAt is valid date string
    try {
      DateTime.parse(metadata['createdAt']);
    } catch (e) {
      return false;
    }

    // Check counts are integers
    if (metadata['transactionCount'] is! int) {
      return false;
    }

    if (metadata['walletCount'] is! int) {
      return false;
    }

    return true;
  }

  /// Validates transaction data types
  bool _validateTransactionDataTypes(Map<String, dynamic> transaction) {
    // Check required fields exist and have correct types
    if (transaction['id'] is! String) {
      return false;
    }

    if (transaction['amount'] is! num) {
      return false;
    }

    if (transaction['description'] is! String) {
      return false;
    }

    // Check date field
    try {
      DateTime.parse(transaction['date']);
    } catch (e) {
      return false;
    }

    return true;
  }

  /// Validates wallet data types
  bool _validateWalletDataTypes(Map<String, dynamic> wallet) {
    // Check required fields
    if (wallet['id'] is! String) {
      return false;
    }

    if (wallet['name'] is! String) {
      return false;
    }

    if (wallet['balance'] is! num) {
      return false;
    }

    return true;
  }

  /// Validates credit card data types
  bool _validateCreditCardDataTypes(Map<String, dynamic> card) {
    if (card['id'] is! String) {
      return false;
    }

    if (card['name'] is! String) {
      return false;
    }

    if (card.containsKey('limit') && card['limit'] is! num) {
      return false;
    }

    return true;
  }

  /// Validates goal data types
  bool _validateGoalDataTypes(Map<String, dynamic> goal) {
    if (goal['id'] is! String) {
      return false;
    }

    if (goal['name'] is! String) {
      return false;
    }

    if (goal['targetAmount'] is! num) {
      return false;
    }

    return true;
  }

  /// Validates metadata consistency with actual data
  Future<List<ValidationError>> _validateMetadataConsistency(
    Map<String, dynamic> metadata,
    Map<String, dynamic> backupData,
  ) async {
    final errors = <ValidationError>[];

    // Check transaction count
    final actualTransactionCount = (backupData['transactions'] as List).length;
    final metadataTransactionCount = metadata['transactionCount'] as int;

    if (actualTransactionCount != metadataTransactionCount) {
      errors.add(ValidationError(
        field: 'metadata.transactionCount',
        message: 'Transaction count mismatch',
        expectedValue: actualTransactionCount.toString(),
        actualValue: metadataTransactionCount.toString(),
      ));
    }

    // Check wallet count
    final actualWalletCount = (backupData['wallets'] as List).length;
    final metadataWalletCount = metadata['walletCount'] as int;

    if (actualWalletCount != metadataWalletCount) {
      errors.add(ValidationError(
        field: 'metadata.walletCount',
        message: 'Wallet count mismatch',
        expectedValue: actualWalletCount.toString(),
        actualValue: metadataWalletCount.toString(),
      ));
    }

    return errors;
  }

  /// Validates transaction consistency
  Future<List<ValidationError>> _validateTransactionConsistency(
    List transactions,
    Map<String, dynamic> backupData,
  ) async {
    final errors = <ValidationError>[];
    final transactionIds = <String>{};

    for (int i = 0; i < transactions.length; i++) {
      final transaction = transactions[i] as Map<String, dynamic>;
      final id = transaction['id'] as String;

      // Check for duplicate IDs
      if (transactionIds.contains(id)) {
        errors.add(ValidationError(
          field: 'transactions[$i].id',
          message: 'Duplicate transaction ID',
          actualValue: id,
        ));
      } else {
        transactionIds.add(id);
      }

      // Check amount is not zero (unless it's a valid zero transaction)
      final amount = transaction['amount'] as num;
      if (amount == 0 && !_isValidZeroTransaction(transaction)) {
        errors.add(ValidationError(
          field: 'transactions[$i].amount',
          message: 'Invalid zero amount transaction',
          actualValue: amount.toString(),
          severity: 'warning',
        ));
      }
    }

    return errors;
  }

  /// Validates wallet consistency
  Future<List<ValidationError>> _validateWalletConsistency(
    List wallets,
    Map<String, dynamic> backupData,
  ) async {
    final errors = <ValidationError>[];
    final walletIds = <String>{};

    for (int i = 0; i < wallets.length; i++) {
      final wallet = wallets[i] as Map<String, dynamic>;
      final id = wallet['id'] as String;

      // Check for duplicate IDs
      if (walletIds.contains(id)) {
        errors.add(ValidationError(
          field: 'wallets[$i].id',
          message: 'Duplicate wallet ID',
          actualValue: id,
        ));
      } else {
        walletIds.add(id);
      }

      // Check balance is reasonable
      final balance = wallet['balance'] as num;
      if (balance < -1000000 || balance > 1000000000) {
        errors.add(ValidationError(
          field: 'wallets[$i].balance',
          message: 'Wallet balance out of reasonable range',
          actualValue: balance.toString(),
          severity: 'warning',
        ));
      }
    }

    return errors;
  }

  /// Validates referential integrity between entities
  Future<List<ValidationError>> _validateReferentialIntegrity(
    Map<String, dynamic> backupData,
  ) async {
    final errors = <ValidationError>[];

    // Get all wallet IDs
    final wallets = backupData['wallets'] as List;
    final walletIds = wallets
        .map((w) => (w as Map<String, dynamic>)['id'] as String)
        .toSet();

    // Check transaction wallet references
    final transactions = backupData['transactions'] as List;
    for (int i = 0; i < transactions.length; i++) {
      final transaction = transactions[i] as Map<String, dynamic>;
      
      if (transaction.containsKey('walletId')) {
        final walletId = transaction['walletId'] as String?;
        if (walletId != null && !walletIds.contains(walletId)) {
          errors.add(ValidationError(
            field: 'transactions[$i].walletId',
            message: 'Transaction references non-existent wallet',
            actualValue: walletId,
          ));
        }
      }
    }

    return errors;
  }

  /// Validates data constraints and business rules
  Future<List<ValidationError>> _validateDataConstraints(
    Map<String, dynamic> backupData,
  ) async {
    final errors = <ValidationError>[];

    // Check backup creation date is not in the future
    final metadata = backupData['metadata'] as Map<String, dynamic>;
    final createdAt = DateTime.parse(metadata['createdAt']);
    
    if (createdAt.isAfter(DateTime.now().add(Duration(minutes: 5)))) {
      errors.add(ValidationError(
        field: 'metadata.createdAt',
        message: 'Backup creation date is in the future',
        actualValue: createdAt.toIso8601String(),
        severity: 'warning',
      ));
    }

    // Check transaction dates are reasonable
    final transactions = backupData['transactions'] as List;
    for (int i = 0; i < transactions.length; i++) {
      final transaction = transactions[i] as Map<String, dynamic>;
      final date = DateTime.parse(transaction['date']);
      
      // Check if transaction date is too far in the future
      if (date.isAfter(DateTime.now().add(Duration(days: 30)))) {
        errors.add(ValidationError(
          field: 'transactions[$i].date',
          message: 'Transaction date is too far in the future',
          actualValue: date.toIso8601String(),
          severity: 'warning',
        ));
      }

      // Check if transaction date is too far in the past (more than 10 years)
      if (date.isBefore(DateTime.now().subtract(Duration(days: 3650)))) {
        errors.add(ValidationError(
          field: 'transactions[$i].date',
          message: 'Transaction date is very old',
          actualValue: date.toIso8601String(),
          severity: 'info',
        ));
      }
    }

    return errors;
  }

  /// Checks if a zero amount transaction is valid
  bool _isValidZeroTransaction(Map<String, dynamic> transaction) {
    // Zero transactions might be valid for certain types like transfers
    final type = transaction['type'] as String?;
    return type == 'transfer' || type == 'adjustment';
  }
}