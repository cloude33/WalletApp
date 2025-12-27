# Security Test Suite

Bu dizin, PIN ve biyometrik kimlik doğrulama sisteminin güvenlik testlerini içerir.

## Test Kategorileri

### 1. Penetration Test Simülasyonları (`security_penetration_test.dart`)

Güvenlik açıklarını tespit etmek için penetration test senaryolarını simüle eder.

**Test Senaryoları:**
- **PT-001**: Timing attack direnci - PIN doğrulama sabit zamanlı olmalı
- **PT-002**: SQL injection denemesi - PIN depolamada SQL injection koruması
- **PT-003**: XSS denemesi - Güvenlik olay kayıtlarında XSS koruması
- **PT-004**: Path traversal denemesi - Güvenli depolamada path traversal koruması
- **PT-005**: Buffer overflow denemesi - Çok uzun PIN girişi koruması
- **PT-006**: Race condition - Eşzamanlı PIN doğrulama güvenliği
- **PT-007**: Memory dump saldırısı - Bellekte hassas veri kalmamalı
- **PT-008**: Session fixation saldırısı önleme
- **PT-009**: Privilege escalation denemesi - PIN bypass koruması
- **PT-010**: Kriptografik zayıflık testi - PIN şifreleme güvenliği
- **PT-011**: Denial of Service - Hızlı başarısız denemeler
- **PT-012**: Screenshot blocking bypass denemesi
- **PT-013**: Root detection bypass denemesi
- **PT-014**: Clipboard veri sızıntısı denemesi
- **PT-015**: Metadata injection - Güvenlik olaylarında metadata güvenliği

**Gereksinimler:**
- 2.1: Deneme sayacı yönetimi
- 2.2: Kilitleme mekanizması
- 9.1: Ekran görüntüsü engelleme
- 9.2: Arka plan bulanıklaştırma
- 9.3: Clipboard güvenliği
- 9.4: Root/jailbreak tespiti

### 2. Brute Force Saldırı Testleri (`brute_force_attack_test.dart`)

Brute force saldırılarına karşı sistemin direncini test eder.

**Test Senaryoları:**
- **BF-001**: Sıralı brute force saldırısı - Kilitleme tetiklenmeli
- **BF-002**: Dictionary attack - Yaygın PIN'lerle saldırı
- **BF-003**: Gecikmeli dağıtık brute force - Gecikmeli denemeler
- **BF-004**: Kapsamlı 4 haneli PIN brute force - Tüm kombinasyonlar
- **BF-005**: Paralel brute force saldırısı tespiti
- **BF-006**: Artan brute force (0000-9999) - Erken durdurma
- **BF-007**: Azalan brute force (9999-0000) - Erken durdurma
- **BF-008**: Desen tabanlı brute force (1111, 2222, vb.)
- **BF-009**: Doğum günü tabanlı brute force - MMDD formatı
- **BF-010**: Kilitleme süresi artışı - Tekrarlanan saldırılar
- **BF-011**: Maksimum deneme - Uzun süreli kilitleme
- **BF-012**: Kilitleme kalıcılığı - Servis yeniden başlatma
- **BF-013**: Başarılı doğrulama - Sayaç sıfırlama
- **BF-014**: Hızlı atış brute force - Rate limiting
- **BF-015**: Geçerli format varyasyonları - Boşluk, tab, vb.

**Gereksinimler:**
- 2.1: 3 yanlış PIN girişinde hesabı geçici olarak kilitlemeli
- 2.2: Hesap kilitlendiğinde 30 saniye bekleme süresi uygulamalı
- 2.3: 5 yanlış PIN girişinde hesabı 5 dakika kilitlemeli
- 2.4: Kilitleme süresi dolduğunda deneme sayacını sıfırlamalı

### 3. Data Leak Prevention Testleri (`data_leak_prevention_test.dart`)

Hassas verilerin sızmasını önleme mekanizmalarını test eder.

**Test Senaryoları:**
- **DLP-001**: PIN düz metin olarak depolanmamalı
- **DLP-002**: Screenshot blocking - Hassas veri yakalama önleme
- **DLP-003**: Background blur - Task switcher'da içerik gizleme
- **DLP-004**: Clipboard temizleme - Hassas veri kalmamalı
- **DLP-005**: Hata mesajlarında veri sızıntısı olmamalı
- **DLP-006**: Log kayıtlarında hassas veri olmamalı
- **DLP-007**: Bellek temizleme - PIN işlemlerinden sonra
- **DLP-008**: Secure storage şifreleme - Tüm hassas veriler
- **DLP-009**: Root tespiti - Güvenliği ihlal edilmiş cihazlar
- **DLP-010**: Clipboard - Kredi kartı desenleri engelleme
- **DLP-011**: Clipboard - SSN desenleri engelleme
- **DLP-012**: Secure storage - Exception'larda veri sızıntısı yok
- **DLP-013**: PIN değiştirme - Eski PIN güvenli silme
- **DLP-014**: Güvenlik olayları - Hassas veri içermemeli
- **DLP-015**: Clipboard otomatik temizleme
- **DLP-016**: Başarısız doğrulama - Timing bilgisi sızıntısı yok
- **DLP-017**: Secure storage - Eşzamanlı erişim güvenliği
- **DLP-018**: Uygulama sonlandırma - Hassas veri kalmamalı
- **DLP-019**: Güvenlik durumu - İç detaylar açığa çıkmamalı
- **DLP-020**: Clipboard - Güvenilmeyen uygulamalara paylaşım engelleme

**Gereksinimler:**
- 1.2: PIN'i AES-256 şifreleme ile depolamalı
- 9.1: Ekran görüntüsü engelleme
- 9.2: Arka plan bulanıklaştırma
- 9.3: Clipboard güvenliği
- 9.4: Root/jailbreak tespiti

## Testleri Çalıştırma

### Tüm güvenlik testlerini çalıştır:
```bash
flutter test test/security/
```

### Belirli bir test dosyasını çalıştır:
```bash
flutter test test/security/security_penetration_test.dart
flutter test test/security/brute_force_attack_test.dart
flutter test test/security/data_leak_prevention_test.dart
```

### Verbose modda çalıştır:
```bash
flutter test test/security/ --verbose
```

### Coverage raporu ile çalıştır:
```bash
flutter test test/security/ --coverage
```

## Test Sonuçları

### Beklenen Sonuçlar

Tüm testler başarılı olmalıdır. Başarısız testler, güvenlik açıklarını gösterir ve düzeltilmelidir.

### Test Coverage

Bu test suite'i aşağıdaki güvenlik alanlarını kapsar:
- ✅ PIN doğrulama güvenliği
- ✅ Brute force saldırı koruması
- ✅ Timing attack koruması
- ✅ Injection attack koruması (SQL, XSS, Path Traversal)
- ✅ Buffer overflow koruması
- ✅ Race condition koruması
- ✅ Memory dump koruması
- ✅ Session güvenliği
- ✅ Privilege escalation koruması
- ✅ Kriptografik güvenlik
- ✅ DoS koruması
- ✅ Screenshot blocking
- ✅ Root/jailbreak tespiti
- ✅ Clipboard güvenliği
- ✅ Data leak prevention
- ✅ Secure storage güvenliği

## Güvenlik Best Practices

### 1. PIN Güvenliği
- PIN'ler asla düz metin olarak depolanmamalı
- AES-256-GCM şifreleme kullanılmalı
- Her şifreleme için benzersiz IV kullanılmalı
- Güvenli anahtar türetme (PBKDF2) kullanılmalı

### 2. Brute Force Koruması
- 3 başarısız denemeden sonra 30 saniye kilitleme
- 5 başarısız denemeden sonra 5 dakika kilitleme
- 10 başarısız denemeden sonra 30 dakika kilitleme
- Kilitleme durumu kalıcı olmalı

### 3. Data Leak Prevention
- Ekran görüntüsü engelleme etkin olmalı
- Arka plan bulanıklaştırma etkin olmalı
- Clipboard güvenliği etkin olmalı
- Hassas veriler log'lara yazılmamalı
- Hata mesajları hassas veri içermemeli

### 4. Root/Jailbreak Tespiti
- Root/jailbreak tespit edildiğinde güvenli mod
- Kritik güvenlik seviyesi uyarısı
- Tüm güvenlik katmanları etkinleştirilmeli

## Sorun Giderme

### Test Başarısız Olursa

1. **Timing Attack Testleri**: Timing testleri bazen CI/CD ortamlarında başarısız olabilir. Tolerans değerlerini artırın.

2. **Concurrent Tests**: Eşzamanlı testler bazen race condition'lar nedeniyle başarısız olabilir. Test isolation'ı kontrol edin.

3. **Platform-Specific Tests**: Platform-specific testler mock'ların doğru yapılandırıldığından emin olun.

### Mock Konfigürasyonu

Testler aşağıdaki mock'ları kullanır:
- `SharedPreferences`: Test verileri için
- `MethodChannel` (security): Platform güvenlik özellikleri için
- `MethodChannel` (flutter_secure_storage): Güvenli depolama için

## Katkıda Bulunma

Yeni güvenlik testleri eklerken:
1. Test senaryosunu açıkça belgeleyin
2. Hangi gereksinimi test ettiğini belirtin
3. Beklenen sonucu açıklayın
4. Edge case'leri düşünün
5. README'yi güncelleyin

## Referanslar

- [OWASP Mobile Security Testing Guide](https://owasp.org/www-project-mobile-security-testing-guide/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [CWE Top 25 Most Dangerous Software Weaknesses](https://cwe.mitre.org/top25/)
