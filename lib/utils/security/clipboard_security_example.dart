import 'package:flutter/material.dart';
import 'clipboard_security.dart';
import '../../services/auth/security_service.dart';

/// Clipboard güvenlik kullanım örneği
/// 
/// Bu sınıf, clipboard güvenlik özelliklerinin nasıl kullanılacağını gösterir.
class ClipboardSecurityExample {
  final ClipboardSecurity _clipboardSecurity = ClipboardSecurity();
  final SecurityService _securityService = SecurityService();

  /// Güvenli kopyalama örneği
  Future<void> demonstrateSecureCopy() async {
    // Güvenlik servisini başlat
    await _securityService.initialize();
    
    // Clipboard güvenliğini etkinleştir
    await _securityService.enableClipboardSecurity();
    
    // Hassas veri kopyalama denemesi (engellenecek)
    final sensitiveResult = await _securityService.secureCopyText('1234', source: 'PIN_Input');
    print('Hassas veri kopyalama sonucu: $sensitiveResult'); // false
    
    // Normal veri kopyalama (başarılı olacak)
    final normalResult = await _securityService.secureCopyText('Merhaba Dünya', source: 'Text_Field');
    print('Normal veri kopyalama sonucu: $normalResult'); // true
    
    // Clipboard durumunu kontrol et
    final status = await _securityService.getClipboardSecurityStatus();
    print('Engellenen deneme sayısı: ${status.blockedAttempts}');
  }

  /// Otomatik temizleme örneği
  Future<void> demonstrateAutoCleanup() async {
    await _clipboardSecurity.initialize();
    
    // 2 dakikalık otomatik temizleme ayarla
    await _clipboardSecurity.enableAutoCleanup(
      interval: const Duration(minutes: 2),
    );
    
    // Clipboard durumunu kontrol et
    final status = await _clipboardSecurity.getSecurityStatus();
    print('Otomatik temizleme aktif: ${status.isAutoCleanupEnabled}');
    print('Temizleme aralığı: ${status.cleanupInterval.inMinutes} dakika');
  }

  /// Özel hassas veri pattern'leri örneği
  Future<void> demonstrateCustomPatterns() async {
    await _clipboardSecurity.initialize();
    
    // Özel hassas veri pattern'leri tanımla
    final customPatterns = [
      // Türk kimlik numarası pattern'i
      RegExp(r'^\d{11}$'),
      // Özel hesap numarası pattern'i
      RegExp(r'^ACC\d{8}$'),
      // API key pattern'i
      RegExp(r'^[A-Za-z0-9]{32}$'),
    ];
    
    _clipboardSecurity.updateSensitivePatterns(customPatterns);
    
    // Test et
    final tcResult = await _clipboardSecurity.copyText('12345678901'); // Engellenecek
    final accountResult = await _clipboardSecurity.copyText('ACC12345678'); // Engellenecek
    final apiKeyResult = await _clipboardSecurity.copyText('abcd1234efgh5678ijkl9012mnop3456'); // Engellenecek
    final normalResult = await _clipboardSecurity.copyText('Normal metin'); // Başarılı
    
    print('TC No kopyalama: $tcResult');
    print('Hesap No kopyalama: $accountResult');
    print('API Key kopyalama: $apiKeyResult');
    print('Normal metin kopyalama: $normalResult');
  }

  /// Güvenli paylaşım örneği
  Future<void> demonstrateSecureShare() async {
    await _clipboardSecurity.initialize();
    
    // İzin verilen uygulamaları güncelle
    final allowedApps = {
      'com.whatsapp',
      'com.telegram.messenger',
      'com.google.android.gm',
    };
    _clipboardSecurity.updateAllowedApps(allowedApps);
    
    // Güvenli paylaşım dene
    final shareResult1 = await _clipboardSecurity.secureShare(
      'Bu güvenli bir mesajdır',
      targetApp: 'com.whatsapp',
    );
    
    final shareResult2 = await _clipboardSecurity.secureShare(
      '1234', // Hassas veri - engellenecek
      targetApp: 'com.whatsapp',
    );
    
    print('Normal mesaj paylaşımı: $shareResult1'); // true
    print('Hassas veri paylaşımı: $shareResult2'); // false
  }

  /// Widget entegrasyonu örneği
  Widget buildClipboardSecurityWidget() {
    return FutureBuilder<ClipboardSecurityStatus>(
      future: _clipboardSecurity.getSecurityStatus(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }
        
        final status = snapshot.data!;
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Clipboard Güvenlik Durumu',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                _buildStatusRow('Güvenlik Aktif', status.isSecurityEnabled),
                _buildStatusRow('Otomatik Temizleme', status.isAutoCleanupEnabled),
                _buildStatusRow('Hassas Veri Var', status.hasSensitiveData),
                const SizedBox(height: 8),
                Text('Engellenen Denemeler: ${status.blockedAttempts}'),
                Text('Temizleme Aralığı: ${status.cleanupInterval.inMinutes} dakika'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        await _securityService.enableClipboardSecurity();
                      },
                      child: const Text('Güvenliği Etkinleştir'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        await _securityService.clearClipboard();
                      },
                      child: const Text('Clipboard Temizle'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusRow(String label, bool status) {
    return Row(
      children: [
        Icon(
          status ? Icons.check_circle : Icons.cancel,
          color: status ? Colors.green : Colors.red,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}