import 'package:get_it/get_it.dart';
import '../../services/auth_service.dart';
import '../../services/backup_service.dart';
import '../utils/app_logger.dart';

/// Global service locator instance
final GetIt getIt = GetIt.instance;

/// Setup dependency injection
Future<void> setupDependencyInjection() async {
  // Core services
  getIt.registerLazySingleton<AppLogger>(() => AppLogger());
  
  // Auth services
  getIt.registerLazySingleton<AuthService>(() => AuthService());
  
  // Backup services
  getIt.registerLazySingleton<BackupService>(() => BackupService());
  
  // Initialize services that need async initialization
  getIt<AppLogger>().init();
  await getIt<AuthService>().init();
  
  getIt<AppLogger>().info('Dependency injection setup completed');
}

/// Reset all dependencies (for testing)
Future<void> resetDependencies() async {
  await getIt.reset();
}

/// Extension methods for easy access
extension GetItExtensions on GetIt {
  /// Get AuthService instance
  AuthService get authService => get<AuthService>();
  
  /// Get BackupService instance
  BackupService get backupService => get<BackupService>();
  
  /// Get AppLogger instance
  AppLogger get logger => get<AppLogger>();
}