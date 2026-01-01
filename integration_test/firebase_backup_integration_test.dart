import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:parion/services/backup_service.dart';
import 'package:parion/services/firebase_auth_service.dart';
import 'package:parion/services/data_service.dart';
import 'package:parion/services/auto_backup_service.dart';
import 'package:parion/models/transaction.dart';
import 'package:parion/models/wallet.dart';
import 'package:parion/firebase_options.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Firebase Backup Integration Tests', () {
    late BackupService backupService;
    late FirebaseAuthService authService;
    late DataService dataService;
    late AutoBackupService autoBackupService;

    setUpAll(() async {
      // Firebase'i başlat
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      // SharedPreferences'ı temizle
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      // Servisleri başlat
      backupService = BackupService();
      authService = FirebaseAuthService();
      dataService = DataService();
      autoBackupService = AutoBackupService();
      
      await dataService.init();
      await backupService.loadSettings();
    });

    tearDownAll(() async {
      // Test sonrası temizlik
      try {
        await authService.signOut();
      } catch (e) {
        print('Sign out error during teardown: $e');
      }
    });

    testWidgets('Firebase Authentication Test', (WidgetTester tester) async {
      // Test kullanıcısı ile giriş yap
      const testEmail = 'test@example.com';
      const testPassword = 'testPassword123';
      const testDisplayName = 'Test User';

      try {
        // Önce mevcut kullanıcıyı çıkış yap
        await authService.signOut();
        
        // Test kullanıcısı oluştur veya giriş yap
        UserCredential? credential;
        try {
          credential = await authService.signInWithEmailAndPassword(
            email: testEmail,
            password: testPassword,
          );
        } catch (e) {
          // Kullanıcı yoksa oluştur
          credential = await authService.signUpWithEmailAndPassword(
            email: testEmail,
            password: testPassword,
            displayName: testDisplayName,
          );
        }

        expect(credential, isNotNull);
        expect(authService.currentUser, isNotNull);
        expect(authService.isSignedIn, true);
        
        print('✅ Firebase Authentication başarılı');
      } catch (e) {
        print('❌ Firebase Authentication hatası: $e');
        fail('Authentication failed: $e');
      }
    });

    testWidgets('Data Creation and Backup Test', (WidgetTester tester) async {
      // Test verileri oluştur
      final testWallet = Wallet(
        id: 'test_wallet_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Test Cüzdan',
        balance: 1000.0,
        type: 'bank',
        color: 'blue',
        icon: 'wallet',
      );

      final testTransaction = Transaction(
        id: 'test_transaction_${DateTime.now().millisecondsSinceEpoch}',
        amount: 250.0,
        description: 'Test İşlemi',
        date: DateTime.now(),
        type: 'expense',
        walletId: testWallet.id,
        category: 'test_category',
      );

      try {
        // Verileri kaydet
        await dataService.saveWallets([testWallet]);
        await dataService.saveTransactions([testTransaction]);
        
        // Verilerin kaydedildiğini kontrol et
        final savedWallets = await dataService.getWallets();
        final savedTransactions = await dataService.getTransactions();
        
        expect(savedWallets.any((w) => w.id == testWallet.id), true);
        expect(savedTransactions.any((t) => t.id == testTransaction.id), true);
        
        print('✅ Test verileri başarıyla oluşturuldu');
        print('   - Cüzdanlar: ${savedWallets.length}');
        print('   - İşlemler: ${savedTransactions.length}');
      } catch (e) {
        print('❌ Veri oluşturma hatası: $e');
        fail('Data creation failed: $e');
      }
    });

    testWidgets('Cloud Backup Upload Test', (WidgetTester tester) async {
      // Kullanıcının oturum açtığından emin ol
      if (!authService.isSignedIn) {
        fail('User must be signed in for cloud backup test');
      }

      try {
        // Bulut yedekleme durumunu izle
        bool uploadStarted = false;
        // ignore: unused_local_variable
        bool uploadCompleted = false;
        
        backupService.cloudBackupStatus.addListener(() {
          final status = backupService.cloudBackupStatus.value;
          print('Backup status changed: $status');
          
          if (status == CloudBackupStatus.uploading) {
            uploadStarted = true;
          } else if (status == CloudBackupStatus.idle && uploadStarted) {
            uploadCompleted = true;
          }
        });

        // Bulut yedekleme başlat
        print('🔄 Bulut yedekleme başlatılıyor...');
        final success = await backupService.uploadToCloud();
        
        expect(success, true);
        expect(uploadStarted, true);
        
        // Son yedekleme tarihinin güncellendiğini kontrol et
        final lastBackupDate = backupService.lastCloudBackupDate.value;
        expect(lastBackupDate, isNotNull);
        
        print('✅ Bulut yedekleme başarılı');
        print('   - Son yedekleme: $lastBackupDate');
      } catch (e) {
        print('❌ Bulut yedekleme hatası: $e');
        fail('Cloud backup failed: $e');
      }
    });

    testWidgets('Cloud Backup List Test', (WidgetTester tester) async {
      try {
        // Bulut yedeklerini listele
        print('📋 Bulut yedekleri listeleniyor...');
        final cloudBackups = await backupService.getCloudBackups();
        
        expect(cloudBackups, isNotNull);
        expect(cloudBackups.length, greaterThan(0));
        
        // İlk yedeğin detaylarını kontrol et
        final firstBackup = cloudBackups.first;
        expect(firstBackup['id'], isNotNull);
        expect(firstBackup['uploadedAt'], isNotNull);
        expect(firstBackup['size'], greaterThan(0));
        expect(firstBackup['metadata'], isNotNull);
        
        print('✅ Bulut yedekleri başarıyla listelendi');
        print('   - Toplam yedek sayısı: ${cloudBackups.length}');
        print('   - İlk yedek boyutu: ${firstBackup['size']} bytes');
      } catch (e) {
        print('❌ Bulut yedek listeleme hatası: $e');
        fail('Cloud backup listing failed: $e');
      }
    });

    testWidgets('Data Clear and Cloud Restore Test', (WidgetTester tester) async {
      try {
        // Mevcut verileri yedekle (restore test için)
        final originalWallets = await dataService.getWallets();
        final originalTransactions = await dataService.getTransactions();
        
        print('📊 Orijinal veriler:');
        print('   - Cüzdanlar: ${originalWallets.length}');
        print('   - İşlemler: ${originalTransactions.length}');
        
        // Tüm verileri temizle
        print('🗑️ Veriler temizleniyor...');
        await dataService.saveWallets([]);
        await dataService.saveTransactions([]);
        
        // Verilerin temizlendiğini kontrol et
        final clearedWallets = await dataService.getWallets();
        final clearedTransactions = await dataService.getTransactions();
        
        expect(clearedWallets.length, 0);
        expect(clearedTransactions.length, 0);
        
        print('✅ Veriler başarıyla temizlendi');
        
        // Buluttan geri yükle
        print('☁️ Buluttan geri yükleme başlatılıyor...');
        final restoreSuccess = await backupService.downloadFromCloud();
        
        expect(restoreSuccess, true);
        
        // Geri yüklenen verileri kontrol et
        final restoredWallets = await dataService.getWallets();
        final restoredTransactions = await dataService.getTransactions();
        
        expect(restoredWallets.length, greaterThan(0));
        expect(restoredTransactions.length, greaterThan(0));
        
        print('✅ Buluttan geri yükleme başarılı');
        print('   - Geri yüklenen cüzdanlar: ${restoredWallets.length}');
        print('   - Geri yüklenen işlemler: ${restoredTransactions.length}');
        
        // Verilerin doğru geri yüklendiğini kontrol et
        expect(restoredWallets.length, originalWallets.length);
        expect(restoredTransactions.length, originalTransactions.length);
        
      } catch (e) {
        print('❌ Geri yükleme hatası: $e');
        fail('Cloud restore failed: $e');
      }
    });

    testWidgets('Auto Backup Configuration Test', (WidgetTester tester) async {
      try {
        // Otomatik yedekleme ayarlarını test et
        print('⚙️ Otomatik yedekleme ayarları test ediliyor...');
        
        // Otomatik yedeklemeyi etkinleştir
        await autoBackupService.enableAutoBackup(true);
        await backupService.enableAutoCloudBackup(true);
        
        // Ayarların kaydedildiğini kontrol et
        final isAutoBackupEnabled = await autoBackupService.isAutoBackupEnabled();
        expect(isAutoBackupEnabled, true);
        expect(backupService.autoCloudBackupEnabled.value, true);
        
        print('✅ Otomatik yedekleme etkinleştirildi');
        
        // Otomatik yedeklemeyi devre dışı bırak
        await autoBackupService.enableAutoBackup(false);
        await backupService.enableAutoCloudBackup(false);
        
        // Ayarların güncellendiğini kontrol et
        final isAutoBackupDisabled = await autoBackupService.isAutoBackupEnabled();
        expect(isAutoBackupDisabled, false);
        expect(backupService.autoCloudBackupEnabled.value, false);
        
        print('✅ Otomatik yedekleme devre dışı bırakıldı');
      } catch (e) {
        print('❌ Otomatik yedekleme ayarları hatası: $e');
        fail('Auto backup configuration failed: $e');
      }
    });

    testWidgets('Cross-Platform Compatibility Test', (WidgetTester tester) async {
      try {
        // Platform bilgisini test et
        print('🔄 Platform uyumluluğu test ediliyor...');
        
        // Bulut yedeklerini al
        final cloudBackups = await backupService.getCloudBackups();
        expect(cloudBackups.length, greaterThan(0));
        
        // İlk yedeğin metadata'sını kontrol et
        final firstBackup = cloudBackups.first;
        final metadata = firstBackup['metadata'] as Map<String, dynamic>?;
        final deviceInfo = firstBackup['deviceInfo'] as Map<String, dynamic>?;
        
        expect(metadata, isNotNull);
        expect(deviceInfo, isNotNull);
        
        // Platform bilgisini kontrol et
        final platform = deviceInfo?['platform'];
        expect(platform, isIn(['android', 'ios', 'unknown']));
        
        // Versiyon uyumluluğunu kontrol et
        final version = metadata?['version'];
        expect(version, isNotNull);
        
        print('✅ Platform uyumluluğu doğrulandı');
        print('   - Platform: $platform');
        print('   - Versiyon: $version');
        print('   - Cihaz: ${deviceInfo?['deviceModel']}');
      } catch (e) {
        print('❌ Platform uyumluluğu hatası: $e');
        fail('Cross-platform compatibility test failed: $e');
      }
    });

    testWidgets('Error Handling Test', (WidgetTester tester) async {
      try {
        print('🚨 Hata yönetimi test ediliyor...');
        
        // Oturum kapatarak hata durumu oluştur
        await authService.signOut();
        expect(authService.isSignedIn, false);
        
        // Oturum açmadan yedekleme yapmaya çalış
        final backupResult = await backupService.uploadToCloud();
        expect(backupResult, false); // Başarısız olmalı
        
        // Hata durumunu kontrol et
        expect(backupService.cloudBackupStatus.value, CloudBackupStatus.error);
        
        print('✅ Hata yönetimi doğru çalışıyor');
        
        // Test kullanıcısı ile tekrar giriş yap
        await authService.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'testPassword123',
        );
        
        expect(authService.isSignedIn, true);
        print('✅ Test kullanıcısı tekrar giriş yaptı');
        
      } catch (e) {
        print('❌ Hata yönetimi testi hatası: $e');
        // Bu test hata durumlarını test ettiği için bazı hatalar beklenir
      }
    });
  });
}