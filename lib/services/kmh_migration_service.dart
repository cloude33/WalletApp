import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/wallet.dart';
import '../models/kmh_transaction.dart';
import '../models/kmh_transaction_type.dart';
import 'data_service.dart';
import '../repositories/kmh_repository.dart';
import 'error_logger_service.dart';
import '../exceptions/kmh_exception.dart';
import '../exceptions/error_codes.dart';
class KmhMigrationService {
  static final KmhMigrationService _instance = KmhMigrationService._internal();
  factory KmhMigrationService() => _instance;
  KmhMigrationService._internal();

  final DataService _dataService = DataService();
  final KmhRepository _kmhRepository = KmhRepository();
  final ErrorLoggerService _logger = ErrorLoggerService();
  final Uuid _uuid = const Uuid();

  static const String _migrationKey = 'kmh_migration_v1_completed';
  static const String _backupKey = 'kmh_migration_v1_backup';
  static const String _migrationReportKey = 'kmh_migration_v1_report';
  static const String _migrationErrorKey = 'kmh_migration_v1_error';
  static const double _defaultInterestRate = 24.0;
  Future<bool> isMigrationCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_migrationKey) ?? false;
  }
  Future<void> markMigrationCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_migrationKey, true);
    await prefs.setString(_backupKey, DateTime.now().toIso8601String());
  }
  Future<List<Wallet>> _findKmhCandidates() async {
    final wallets = await _dataService.getWallets();
    return wallets.where((wallet) {
      return wallet.type == 'bank' && wallet.creditLimit > 0;
    }).toList();
  }
  Future<int> _migrateTransactions(Wallet wallet) async {
    int transactionsConverted = 0;

    try {
      _logger.info(
        'İşlem dönüştürme başlatılıyor: ${wallet.name}',
        context: 'KmhMigration',
      );
      final allTransactions = await _dataService.getTransactions();
      final walletTransactions = allTransactions
          .where((t) => t.walletId == wallet.id)
          .toList();

      _logger.debug(
        '${walletTransactions.length} işlem bulundu',
        context: 'KmhMigration',
      );
      for (var transaction in walletTransactions) {
        try {
          KmhTransactionType kmhType;
          if (transaction.type == 'transfer') {
            kmhType = KmhTransactionType.transfer;
          } else if (transaction.type == 'expense' || transaction.amount < 0) {
            kmhType = KmhTransactionType.withdrawal;
          } else if (transaction.type == 'income' || transaction.amount > 0) {
            kmhType = KmhTransactionType.deposit;
          } else {
            kmhType = KmhTransactionType.transfer;
          }
          final kmhTransaction = KmhTransaction(
            id: _uuid.v4(),
            walletId: wallet.id,
            type: kmhType,
            amount: transaction.amount.abs(),
            date: transaction.date,
            description: transaction.description,
            balanceAfter: 0.0,
            linkedTransactionId: transaction.id,
          );
          await _kmhRepository.addTransaction(kmhTransaction);
          transactionsConverted++;
        } catch (e, stackTrace) {
          _logger.error(
            'Tek işlem dönüştürme hatası: ${transaction.id}',
            error: e,
            stackTrace: stackTrace,
            context: 'KmhMigration',
          );
          continue;
        }
      }

      _logger.info(
        '${wallet.name} için $transactionsConverted işlem dönüştürüldü',
        context: 'KmhMigration',
      );
    } catch (e, stackTrace) {
      _logger.error(
        'İşlem dönüştürme hatası (${wallet.name})',
        error: e,
        stackTrace: stackTrace,
        context: 'KmhMigration',
      );
      rethrow;
    }

    return transactionsConverted;
  }
  Future<KmhMigrationResult> migrateKmhAccounts() async {
    final startTime = DateTime.now();
    final List<String> errors = [];
    final List<String> warnings = [];
    int accountsMigrated = 0;
    int totalTransactionsConverted = 0;
    int accountsFailed = 0;

    try {
      _logger.info('KMH migration başlatılıyor...', context: 'KmhMigration');
      if (await isMigrationCompleted()) {
        _logger.info(
          'KMH migration zaten tamamlanmış, atlanıyor',
          context: 'KmhMigration',
        );

        final report = await _generateMigrationReport(
          success: true,
          accountsMigrated: 0,
          transactionsConverted: 0,
          accountsFailed: 0,
          errors: [],
          warnings: ['Migration zaten tamamlanmış'],
          startTime: startTime,
          endTime: DateTime.now(),
        );

        return KmhMigrationResult(
          success: true,
          accountsMigrated: 0,
          transactionsConverted: 0,
          message: 'Migration zaten tamamlanmış',
          report: report,
        );
      }
      final kmhCandidates = await _findKmhCandidates();
      _logger.info(
        '${kmhCandidates.length} adet KMH hesabı adayı bulundu',
        context: 'KmhMigration',
      );

      if (kmhCandidates.isEmpty) {
        _logger.info(
          'Migrate edilecek KMH hesabı bulunamadı',
          context: 'KmhMigration',
        );

        await markMigrationCompleted();

        final report = await _generateMigrationReport(
          success: true,
          accountsMigrated: 0,
          transactionsConverted: 0,
          accountsFailed: 0,
          errors: [],
          warnings: ['Migrate edilecek KMH hesabı bulunamadı'],
          startTime: startTime,
          endTime: DateTime.now(),
        );

        return KmhMigrationResult(
          success: true,
          accountsMigrated: 0,
          transactionsConverted: 0,
          message: 'Migrate edilecek KMH hesabı bulunamadı',
          report: report,
        );
      }
      for (var wallet in kmhCandidates) {
        try {
          _logger.info(
            'Hesap migrate ediliyor: ${wallet.name} (${wallet.id})',
            context: 'KmhMigration',
          );

          bool walletNeedsUpdate = false;
          Wallet updatedWallet = wallet;
          if (wallet.interestRate == null) {
            updatedWallet = updatedWallet.copyWith(
              interestRate: _defaultInterestRate,
            );
            walletNeedsUpdate = true;
            _logger.debug(
              'Default faiz oranı atandı: $_defaultInterestRate%',
              context: 'KmhMigration',
            );
          }

          if (wallet.lastInterestDate == null) {
            updatedWallet = updatedWallet.copyWith(
              lastInterestDate: DateTime.now(),
            );
            walletNeedsUpdate = true;
          }

          if (wallet.accruedInterest == null) {
            updatedWallet = updatedWallet.copyWith(accruedInterest: 0.0);
            walletNeedsUpdate = true;
          }
          if (walletNeedsUpdate) {
            await _dataService.updateWallet(updatedWallet);
            accountsMigrated++;
            _logger.info(
              'KMH hesabı güncellendi: ${wallet.name}',
              context: 'KmhMigration',
            );
          }
          try {
            final transactionsConverted = await _migrateTransactions(
              updatedWallet,
            );
            totalTransactionsConverted += transactionsConverted;
          } catch (e, stackTrace) {
            final errorMsg = 'İşlem dönüştürme hatası (${wallet.name}): $e';
            _logger.error(
              errorMsg,
              error: e,
              stackTrace: stackTrace,
              context: 'KmhMigration',
            );
            warnings.add(errorMsg);
          }
        } catch (e, stackTrace) {
          accountsFailed++;
          final errorMsg = 'Hesap migration hatası (${wallet.name}): $e';
          _logger.error(
            errorMsg,
            error: e,
            stackTrace: stackTrace,
            context: 'KmhMigration',
          );
          errors.add(errorMsg);
          if (_isCriticalError(e)) {
            _logger.error(
              'Kritik hata tespit edildi, migration durduruluyor',
              error: e,
              context: 'KmhMigration',
            );
            throw KmhException(
              ErrorCodes.MIGRATION_FAILED,
              'Kritik migration hatası: $e',
              {'wallet': wallet.name, 'error': e.toString()},
            );
          }
        }
      }

      final endTime = DateTime.now();

      _logger.info(
        'Migration tamamlandı: $accountsMigrated hesap güncellendi, '
        '$totalTransactionsConverted işlem dönüştürüldü, '
        '$accountsFailed hesap başarısız',
        context: 'KmhMigration',
      );
      await markMigrationCompleted();
      final report = await _generateMigrationReport(
        success: true,
        accountsMigrated: accountsMigrated,
        transactionsConverted: totalTransactionsConverted,
        accountsFailed: accountsFailed,
        errors: errors,
        warnings: warnings,
        startTime: startTime,
        endTime: endTime,
      );

      _logger.info(
        'KMH migration başarıyla tamamlandı!',
        context: 'KmhMigration',
      );

      return KmhMigrationResult(
        success: true,
        accountsMigrated: accountsMigrated,
        transactionsConverted: totalTransactionsConverted,
        accountsFailed: accountsFailed,
        message: _buildSuccessMessage(
          accountsMigrated,
          totalTransactionsConverted,
          accountsFailed,
        ),
        errors: errors,
        warnings: warnings,
        report: report,
      );
    } catch (e, stackTrace) {
      final endTime = DateTime.now();

      _logger.error(
        'KMH migration kritik hatası',
        error: e,
        stackTrace: stackTrace,
        context: 'KmhMigration',
      );
      await _saveErrorInfo(e, stackTrace);
      KmhRollbackResult? rollbackResult;
      try {
        _logger.warning(
          'Migration başarısız, rollback deneniyor...',
          context: 'KmhMigration',
        );
        rollbackResult = await rollbackMigration();

        if (rollbackResult.success) {
          _logger.info(
            'Rollback başarılı: ${rollbackResult.accountsReverted} hesap geri alındı',
            context: 'KmhMigration',
          );
        } else {
          _logger.error(
            'Rollback başarısız: ${rollbackResult.message}',
            error: rollbackResult.error,
            context: 'KmhMigration',
          );
        }
      } catch (rollbackError, rollbackStackTrace) {
        _logger.error(
          'Rollback hatası',
          error: rollbackError,
          stackTrace: rollbackStackTrace,
          context: 'KmhMigration',
        );
      }
      final report = await _generateMigrationReport(
        success: false,
        accountsMigrated: accountsMigrated,
        transactionsConverted: totalTransactionsConverted,
        accountsFailed: accountsFailed,
        errors: [...errors, 'Kritik hata: $e'],
        warnings: warnings,
        startTime: startTime,
        endTime: endTime,
        rollbackResult: rollbackResult,
      );

      return KmhMigrationResult(
        success: false,
        accountsMigrated: accountsMigrated,
        transactionsConverted: totalTransactionsConverted,
        accountsFailed: accountsFailed,
        message: 'Migration hatası: $e',
        error: e,
        errors: [...errors, e.toString()],
        warnings: warnings,
        report: report,
        rollbackResult: rollbackResult,
      );
    }
  }
  bool _isCriticalError(dynamic error) {
    if (error is StateError) return true;
    if (error is ArgumentError) return true;
    if (error is KmhException) return false;
    return false;
  }
  String _buildSuccessMessage(int migrated, int converted, int failed) {
    if (failed > 0) {
      return 'Migration kısmen başarılı: $migrated hesap güncellendi, '
          '$converted işlem dönüştürüldü, $failed hesap başarısız';
    }
    return 'Migration başarıyla tamamlandı: $migrated hesap güncellendi, '
        '$converted işlem dönüştürüldü';
  }
  Future<void> _saveErrorInfo(dynamic error, StackTrace? stackTrace) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final errorInfo = {
        'timestamp': DateTime.now().toIso8601String(),
        'error': error.toString(),
        'stackTrace': stackTrace?.toString() ?? 'No stack trace',
      };
      await prefs.setString(_migrationErrorKey, errorInfo.toString());
    } catch (e) {
      _logger.error(
        'Hata bilgisi kaydedilemedi',
        error: e,
        context: 'KmhMigration',
      );
    }
  }
  Future<KmhMigrationReport> _generateMigrationReport({
    required bool success,
    required int accountsMigrated,
    required int transactionsConverted,
    required int accountsFailed,
    required List<String> errors,
    required List<String> warnings,
    required DateTime startTime,
    required DateTime endTime,
    KmhRollbackResult? rollbackResult,
  }) async {
    final duration = endTime.difference(startTime);

    final report = KmhMigrationReport(
      success: success,
      startTime: startTime,
      endTime: endTime,
      duration: duration,
      accountsMigrated: accountsMigrated,
      transactionsConverted: transactionsConverted,
      accountsFailed: accountsFailed,
      errors: errors,
      warnings: warnings,
      rollbackResult: rollbackResult,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_migrationReportKey, report.toJson());
      _logger.info('Migration raporu kaydedildi', context: 'KmhMigration');
    } catch (e) {
      _logger.error(
        'Migration raporu kaydedilemedi',
        error: e,
        context: 'KmhMigration',
      );
    }

    return report;
  }
  Future<KmhMigrationReport?> getLastMigrationReport() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportJson = prefs.getString(_migrationReportKey);

      if (reportJson == null) return null;

      return KmhMigrationReport.fromJson(reportJson);
    } catch (e) {
      _logger.error(
        'Migration raporu okunamadı',
        error: e,
        context: 'KmhMigration',
      );
      return null;
    }
  }
  Future<KmhMigrationStatus> getMigrationStatus() async {
    final isCompleted = await isMigrationCompleted();
    final prefs = await SharedPreferences.getInstance();
    final backupDate = prefs.getString(_backupKey);

    final wallets = await _dataService.getWallets();
    final kmhAccounts = wallets.where((w) => w.isKmhAccount).toList();

    int accountsWithNewFields = 0;
    int accountsWithoutNewFields = 0;

    for (var account in kmhAccounts) {
      if (account.interestRate != null &&
          account.lastInterestDate != null &&
          account.accruedInterest != null) {
        accountsWithNewFields++;
      } else {
        accountsWithoutNewFields++;
      }
    }

    return KmhMigrationStatus(
      isCompleted: isCompleted,
      migrationDate: backupDate != null ? DateTime.parse(backupDate) : null,
      totalKmhAccounts: kmhAccounts.length,
      accountsWithNewFields: accountsWithNewFields,
      accountsWithoutNewFields: accountsWithoutNewFields,
    );
  }
  Future<KmhRollbackResult> rollbackMigration() async {
    try {
      debugPrint('KMH migration geri alınıyor...');

      int accountsReverted = 0;
      int transactionsDeleted = 0;
      final wallets = await _dataService.getWallets();
      final kmhAccounts = wallets.where((w) => w.isKmhAccount).toList();

      for (var wallet in kmhAccounts) {
        bool walletNeedsUpdate = false;
        Wallet updatedWallet = wallet;
        if (wallet.interestRate != null ||
            wallet.lastInterestDate != null ||
            wallet.accruedInterest != null ||
            wallet.accountNumber != null) {
          updatedWallet = Wallet(
            id: wallet.id,
            name: wallet.name,
            balance: wallet.balance,
            type: wallet.type,
            color: wallet.color,
            icon: wallet.icon,
            cutOffDay: wallet.cutOffDay,
            paymentDay: wallet.paymentDay,
            installment: wallet.installment,
            creditLimit: wallet.creditLimit,
            interestRate: null,
            lastInterestDate: null,
            accruedInterest: null,
            accountNumber: null,
          );
          walletNeedsUpdate = true;
        }

        if (walletNeedsUpdate) {
          await _dataService.updateWallet(updatedWallet);
          accountsReverted++;
        }
        try {
          final kmhTransactions = await _kmhRepository.getTransactions(
            wallet.id,
          );
          await _kmhRepository.deleteTransactionsByWallet(wallet.id);
          transactionsDeleted += kmhTransactions.length;
        } catch (e) {
          debugPrint('KmhTransaction silme hatası (${wallet.name}): $e');
        }
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_migrationKey);
      await prefs.remove(_backupKey);

      debugPrint(
        'Rollback tamamlandı: $accountsReverted hesap geri alındı, '
        '$transactionsDeleted işlem silindi',
      );

      return KmhRollbackResult(
        success: true,
        accountsReverted: accountsReverted,
        transactionsDeleted: transactionsDeleted,
        message: 'Rollback başarıyla tamamlandı',
      );
    } catch (e, stackTrace) {
      debugPrint('Rollback hatası: $e');
      debugPrint('Stack trace: $stackTrace');
      return KmhRollbackResult(
        success: false,
        accountsReverted: 0,
        transactionsDeleted: 0,
        message: 'Rollback hatası: $e',
        error: e,
      );
    }
  }
}
class KmhMigrationResult {
  final bool success;
  final int accountsMigrated;
  final int transactionsConverted;
  final int accountsFailed;
  final String message;
  final dynamic error;
  final List<String> errors;
  final List<String> warnings;
  final KmhMigrationReport? report;
  final KmhRollbackResult? rollbackResult;

  KmhMigrationResult({
    required this.success,
    required this.accountsMigrated,
    required this.transactionsConverted,
    this.accountsFailed = 0,
    required this.message,
    this.error,
    this.errors = const [],
    this.warnings = const [],
    this.report,
    this.rollbackResult,
  });
  String get userFriendlyMessage {
    if (success) {
      if (accountsFailed > 0) {
        return 'KMH hesaplarınız kısmen güncellendi. '
            '$accountsMigrated hesap başarıyla güncellendi, '
            '$accountsFailed hesapta sorun oluştu.';
      }
      if (accountsMigrated == 0) {
        return 'Güncellenecek KMH hesabı bulunamadı.';
      }
      return 'KMH hesaplarınız başarıyla güncellendi! '
          '$accountsMigrated hesap ve $transactionsConverted işlem güncellendi.';
    } else {
      if (rollbackResult?.success == true) {
        return 'Güncelleme başarısız oldu ve değişiklikler geri alındı. '
            'Lütfen destek ekibiyle iletişime geçin.';
      }
      return 'Güncelleme başarısız oldu. Lütfen uygulamayı yeniden başlatın '
          've sorun devam ederse destek ekibiyle iletişime geçin.';
    }
  }

  @override
  String toString() {
    return 'KmhMigrationResult(success: $success, accountsMigrated: $accountsMigrated, '
        'transactionsConverted: $transactionsConverted, accountsFailed: $accountsFailed, '
        'message: $message, errors: ${errors.length}, warnings: ${warnings.length})';
  }
}
class KmhRollbackResult {
  final bool success;
  final int accountsReverted;
  final int transactionsDeleted;
  final String message;
  final dynamic error;

  KmhRollbackResult({
    required this.success,
    required this.accountsReverted,
    required this.transactionsDeleted,
    required this.message,
    this.error,
  });

  @override
  String toString() {
    return 'KmhRollbackResult(success: $success, accountsReverted: $accountsReverted, '
        'transactionsDeleted: $transactionsDeleted, message: $message)';
  }
}
class KmhMigrationStatus {
  final bool isCompleted;
  final DateTime? migrationDate;
  final int totalKmhAccounts;
  final int accountsWithNewFields;
  final int accountsWithoutNewFields;

  KmhMigrationStatus({
    required this.isCompleted,
    this.migrationDate,
    required this.totalKmhAccounts,
    required this.accountsWithNewFields,
    required this.accountsWithoutNewFields,
  });

  bool get needsMigration => !isCompleted || accountsWithoutNewFields > 0;

  @override
  String toString() {
    return 'KmhMigrationStatus(isCompleted: $isCompleted, migrationDate: $migrationDate, '
        'totalKmhAccounts: $totalKmhAccounts, accountsWithNewFields: $accountsWithNewFields, '
        'accountsWithoutNewFields: $accountsWithoutNewFields, needsMigration: $needsMigration)';
  }
}
class KmhMigrationReport {
  final bool success;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final int accountsMigrated;
  final int transactionsConverted;
  final int accountsFailed;
  final List<String> errors;
  final List<String> warnings;
  final KmhRollbackResult? rollbackResult;

  KmhMigrationReport({
    required this.success,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.accountsMigrated,
    required this.transactionsConverted,
    required this.accountsFailed,
    required this.errors,
    required this.warnings,
    this.rollbackResult,
  });
  String toJson() {
    return '''
{
  "success": $success,
  "startTime": "${startTime.toIso8601String()}",
  "endTime": "${endTime.toIso8601String()}",
  "durationSeconds": ${duration.inSeconds},
  "accountsMigrated": $accountsMigrated,
  "transactionsConverted": $transactionsConverted,
  "accountsFailed": $accountsFailed,
  "errorCount": ${errors.length},
  "warningCount": ${warnings.length},
  "errors": ${_listToJson(errors)},
  "warnings": ${_listToJson(warnings)},
  "rollbackPerformed": ${rollbackResult != null},
  "rollbackSuccess": ${rollbackResult?.success ?? false}
}
''';
  }
  static KmhMigrationReport fromJson(String json) {
    final startTimeMatch = RegExp(r'"startTime":\s*"([^"]+)"').firstMatch(json);
    final endTimeMatch = RegExp(r'"endTime":\s*"([^"]+)"').firstMatch(json);
    final successMatch = RegExp(r'"success":\s*(true|false)').firstMatch(json);
    final accountsMigratedMatch = RegExp(
      r'"accountsMigrated":\s*(\d+)',
    ).firstMatch(json);
    final transactionsConvertedMatch = RegExp(
      r'"transactionsConverted":\s*(\d+)',
    ).firstMatch(json);
    final accountsFailedMatch = RegExp(
      r'"accountsFailed":\s*(\d+)',
    ).firstMatch(json);

    final startTime = startTimeMatch != null
        ? DateTime.parse(startTimeMatch.group(1)!)
        : DateTime.now();
    final endTime = endTimeMatch != null
        ? DateTime.parse(endTimeMatch.group(1)!)
        : DateTime.now();

    return KmhMigrationReport(
      success: successMatch?.group(1) == 'true',
      startTime: startTime,
      endTime: endTime,
      duration: endTime.difference(startTime),
      accountsMigrated: int.parse(accountsMigratedMatch?.group(1) ?? '0'),
      transactionsConverted: int.parse(
        transactionsConvertedMatch?.group(1) ?? '0',
      ),
      accountsFailed: int.parse(accountsFailedMatch?.group(1) ?? '0'),
      errors: [],
      warnings: [],
    );
  }

  String _listToJson(List<String> list) {
    if (list.isEmpty) return '[]';
    final escaped = list.map((s) => '"${s.replaceAll('"', '\\"')}"').join(', ');
    return '[$escaped]';
  }
  String toUserFriendlyReport() {
    final buffer = StringBuffer();
    buffer.writeln('=== KMH Güncelleme Raporu ===');
    buffer.writeln('');
    buffer.writeln('Durum: ${success ? "✓ Başarılı" : "✗ Başarısız"}');
    buffer.writeln('Başlangıç: ${_formatDateTime(startTime)}');
    buffer.writeln('Bitiş: ${_formatDateTime(endTime)}');
    buffer.writeln('Süre: ${duration.inSeconds} saniye');
    buffer.writeln('');
    buffer.writeln('Sonuçlar:');
    buffer.writeln('  • Güncellenen hesap: $accountsMigrated');
    buffer.writeln('  • Dönüştürülen işlem: $transactionsConverted');
    if (accountsFailed > 0) {
      buffer.writeln('  • Başarısız hesap: $accountsFailed');
    }

    if (warnings.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('Uyarılar (${warnings.length}):');
      for (var i = 0; i < warnings.length && i < 5; i++) {
        buffer.writeln('  ${i + 1}. ${warnings[i]}');
      }
      if (warnings.length > 5) {
        buffer.writeln('  ... ve ${warnings.length - 5} uyarı daha');
      }
    }

    if (errors.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('Hatalar (${errors.length}):');
      for (var i = 0; i < errors.length && i < 5; i++) {
        buffer.writeln('  ${i + 1}. ${errors[i]}');
      }
      if (errors.length > 5) {
        buffer.writeln('  ... ve ${errors.length - 5} hata daha');
      }
    }

    if (rollbackResult != null) {
      buffer.writeln('');
      buffer.writeln('Geri Alma İşlemi:');
      buffer.writeln(
        '  Durum: ${rollbackResult!.success ? "✓ Başarılı" : "✗ Başarısız"}',
      );
      buffer.writeln(
        '  Geri alınan hesap: ${rollbackResult!.accountsReverted}',
      );
      buffer.writeln('  Silinen işlem: ${rollbackResult!.transactionsDeleted}');
    }

    buffer.writeln('');
    buffer.writeln('============================');

    return buffer.toString();
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.'
        '${dt.month.toString().padLeft(2, '0')}.'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'KmhMigrationReport(success: $success, duration: ${duration.inSeconds}s, '
        'accountsMigrated: $accountsMigrated, transactionsConverted: $transactionsConverted, '
        'accountsFailed: $accountsFailed, errors: ${errors.length}, warnings: ${warnings.length})';
  }
}
