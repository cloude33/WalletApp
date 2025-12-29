
class FormatHelper {
  /// Telefon numarasını formatlar: 0 (507) 351 88 88
  static String formatPhoneNumber(String? phone) {
    if (phone == null || phone.trim().isEmpty) return '';
    
    // Sadece rakamları al
    String digits = phone.replaceAll(RegExp(r'\D'), '');
    
    // Eğer +90 veya 90 ile başlıyorsa temizle
    if (digits.startsWith('90')) {
      digits = digits.substring(2);
    } else if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    
    // Eğer 10 hane değilse olduğu gibi döndür (geçersiz numara)
    if (digits.length != 10) {
      // Başında 0 yoksa ekleyip döndürelim en azından
      return phone.startsWith('0') ? phone : '0$phone';
    }
    
    // Format: 0 (507) 351 88 88
    final areaCode = digits.substring(0, 3);
    final firstPart = digits.substring(3, 6);
    final secondPart = digits.substring(6, 8);
    final thirdPart = digits.substring(8, 10);
    
    return '0 ($areaCode) $firstPart $secondPart $thirdPart';
  }
}
