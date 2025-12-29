import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'kmh_service.dart';
import 'kmh_migration_service.dart';
import 'kmh_alert_service.dart';
import 'error_logger_service.dart';
class KmhInterestSchedulerService {
  final KmhService _kmhService;
  final KmhMigrationService _migrationService;
  final KmhAlertService _alertService;
  final ErrorLoggerService _logger;
  
  Timer? _timer;
  Timer? _retryTimer;
  
  static const String _lastInterestRunKey = 'kmh_last_interest_run';
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(minutes: 5);

  KmhInterestSchedulerService({
    KmhService? kmhService,
    KmhMigrationService? migrationService,
    KmhAlertService? alertService,
    ErrorLoggerService? logger,
  })  : _kmhService = kmhService ?? KmhService(),
        _migrationService = migrationService ?? KmhMigrationService(),
        _alertService = alertService ?? KmhAlertService(),
        _logger = logger ?? ErrorLoggerService();
  Future<void> initialize() async {
    try {
      _logger.info('KMH Interest Scheduler başlatılıyor...', context: 'KmhScheduler');
      await _runMigration();
      await _checkAndRunInterest();
      _scheduleDailyInterest();

      _logger.info('KMH Interest Scheduler başarıyla başlatıldı', context: 'KmhScheduler');
    } catch (e, stackTrace) {
      _logger.error(
        'KMH Interest Scheduler başlatma hatası',
        error: e,
        stackTrace: stackTrace,
        context: 'KmhScheduler',
      );
    }
  }
  Future<void> _runMigration() async {
    try {
      _logger.info('Migration kontrolü yapılıyor...', context: 'KmhScheduler');
      
      final result = await _migrationService.migrateKmhAccounts();
      
      if (result.success) {
        if (result.accountsMigrated > 0) {
          _logger.info(
            'Migration başarılı: ${result.accountsMigrated} hesap güncellendi',
            context: 'KmhScheduler',
          );
        } else {
          _logger.debug(
            'Migration zaten tamamlanmış veya gerekli değil',
            context: 'KmhScheduler',
          );
        }
      } else {
        _logger.warning(
          'Migration başarısız: ${result.message}',
          context: 'KmhScheduler',
        );
      }
    } catch (e, stackTrace) {
      _logger.error(
        'Migration hatası',
        error: e,
        stackTrace: stackTrace,
        context: 'KmhScheduler',
      );
    }
  }
  Future<void> _checkAndRunInterest() async {
    try {
      final lastRun = await _getLastInterestRun();
      final now = DateTime.now();
      if (lastRun != null && _isSameDay(lastRun, now)) {
        _logger.debug(
          'Faiz tahakkuku bugün zaten çalıştırılmış',
          context: 'KmhScheduler',
        );
        return;
      }

      _logger.info('Günlük faiz tahakkuku çalıştırılıyor...', context: 'KmhScheduler');
      await _runInterestAccrual();
    } catch (e, stackTrace) {
      _logger.error(
        'Faiz kontrolü hatası',
        error: e,
        stackTrace: stackTrace,
        context: 'KmhScheduler',
      );
    }
  }
  void _scheduleDailyInterest() {
    _timer?.cancel();

    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = tomorrow.difference(now);

    _logger.debug(
      'Sonraki faiz tahakkuku: ${timeUntilMidnight.inHours} saat ${timeUntilMidnight.inMinutes % 60} dakika sonra',
      context: 'KmhScheduler',
    );
    _timer = Timer(timeUntilMidnight, () async {
      await _runInterestAccrual();
      _scheduleDailyInterest();
    });
  }
  Future<void> _runInterestAccrual({int retryCount = 0}) async {
    try {
      _logger.info('Faiz tahakkuku başlatılıyor...', context: 'KmhScheduler');

      final accountsProcessed = await _kmhService.applyInterestToAllAccounts();

      _logger.info(
        'Faiz tahakkuku tamamlandı: $accountsProcessed hesap işlendi',
        context: 'KmhScheduler',
      );
      try {
        final alertsSent = await _alertService.checkAndSendAlerts();
        _logger.info(
          'Uyarı kontrolü tamamlandı: $alertsSent bildirim gönderildi',
          context: 'KmhScheduler',
        );
      } catch (e, stackTrace) {
        _logger.error(
          'Uyarı kontrolü hatası',
          error: e,
          stackTrace: stackTrace,
          context: 'KmhScheduler',
        );
      }
      await _saveLastInterestRun(DateTime.now());
      _retryTimer?.cancel();
      _retryTimer = null;
    } catch (e, stackTrace) {
      _logger.error(
        'Faiz tahakkuku hatası (deneme ${retryCount + 1}/$_maxRetries)',
        error: e,
        stackTrace: stackTrace,
        context: 'KmhScheduler',
      );
      if (retryCount < _maxRetries) {
        _logger.warning(
          'Faiz tahakkuku $_retryDelay sonra tekrar denenecek',
          context: 'KmhScheduler',
        );

        _retryTimer?.cancel();
        _retryTimer = Timer(_retryDelay, () async {
          await _runInterestAccrual(retryCount: retryCount + 1);
        });
      } else {
        _logger.error(
          'Faiz tahakkuku maksimum deneme sayısına ulaştı, vazgeçiliyor',
          error: e,
          context: 'KmhScheduler',
        );
      }
    }
  }
  Future<void> runNow() async {
    _logger.info('Manuel faiz tahakkuku tetiklendi', context: 'KmhScheduler');
    await _runInterestAccrual();
  }
  Future<DateTime?> _getLastInterestRun() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getString(_lastInterestRunKey);
      
      if (timestamp == null) return null;
      
      return DateTime.parse(timestamp);
    } catch (e) {
      _logger.error(
        'Son faiz çalıştırma zamanı okunamadı',
        error: e,
        context: 'KmhScheduler',
      );
      return null;
    }
  }
  Future<void> _saveLastInterestRun(DateTime time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastInterestRunKey, time.toIso8601String());
    } catch (e) {
      _logger.error(
        'Son faiz çalıştırma zamanı kaydedilemedi',
        error: e,
        context: 'KmhScheduler',
      );
    }
  }
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
  Future<void> cancelSchedule() async {
    _timer?.cancel();
    _timer = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    
    _logger.info('KMH Interest Scheduler durduruldu', context: 'KmhScheduler');
  }
  void dispose() {
    _timer?.cancel();
    _retryTimer?.cancel();
  }
}
