
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// TOTP (Time-based One-Time Password) helper utility
/// 
/// This class provides functionality for generating and verifying TOTP codes
/// according to RFC 6238 specification. It supports standard 6-digit codes
/// with 30-second time windows.
class TOTPHelper {
  /// Default time step in seconds (30 seconds)
  static const int defaultTimeStep = 30;
  
  /// Default code length (6 digits)
  static const int defaultCodeLength = 6;
  
  /// Default time window tolerance (1 window before and after)
  static const int defaultWindowTolerance = 1;
  
  /// Base32 alphabet for encoding/decoding
  static const String _base32Alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  /// Generate a random TOTP secret
  /// 
  /// [length] - Length of the secret in bytes (default: 20)
  /// 
  /// Returns base32-encoded secret string
  static String generateSecret({int length = 20}) {
    final random = Random.secure();
    final bytes = Uint8List(length);
    
    for (int i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    
    return _base32Encode(bytes);
  }

  /// Generate TOTP code for current time
  /// 
  /// [secret] - Base32-encoded secret
  /// [timeStep] - Time step in seconds (default: 30)
  /// [codeLength] - Length of generated code (default: 6)
  /// [timestamp] - Custom timestamp (default: current time)
  /// 
  /// Returns 6-digit TOTP code
  static String generateTOTP(
    String secret, {
    int timeStep = defaultTimeStep,
    int codeLength = defaultCodeLength,
    DateTime? timestamp,
  }) {
    final time = timestamp ?? DateTime.now();
    final timeCounter = time.millisecondsSinceEpoch ~/ (timeStep * 1000);
    
    return _generateHOTP(secret, timeCounter, codeLength);
  }

  /// Verify TOTP code
  /// 
  /// [secret] - Base32-encoded secret
  /// [code] - TOTP code to verify
  /// [timeStep] - Time step in seconds (default: 30)
  /// [codeLength] - Length of the code (default: 6)
  /// [windowTolerance] - Number of time windows to check (default: 1)
  /// [timestamp] - Custom timestamp (default: current time)
  /// 
  /// Returns true if code is valid, false otherwise
  static bool verifyTOTP(
    String secret,
    String code, {
    int timeStep = defaultTimeStep,
    int codeLength = defaultCodeLength,
    int windowTolerance = defaultWindowTolerance,
    DateTime? timestamp,
  }) {
    if (code.length != codeLength) {
      return false;
    }

    final time = timestamp ?? DateTime.now();
    final timeCounter = time.millisecondsSinceEpoch ~/ (timeStep * 1000);
    
    // Check current window and tolerance windows
    for (int i = -windowTolerance; i <= windowTolerance; i++) {
      final testCounter = timeCounter + i;
      final expectedCode = _generateHOTP(secret, testCounter, codeLength);
      
      if (code == expectedCode) {
        return true;
      }
    }
    
    return false;
  }

  /// Generate QR code URL for TOTP setup
  /// 
  /// [secret] - Base32-encoded secret
  /// [accountName] - Account name (e.g., user email)
  /// [issuer] - Issuer name (e.g., app name)
  /// [algorithm] - Hash algorithm (default: SHA1)
  /// [digits] - Number of digits (default: 6)
  /// [period] - Time period in seconds (default: 30)
  /// 
  /// Returns otpauth:// URL for QR code generation
  static String generateQRCodeUrl(
    String secret,
    String accountName,
    String issuer, {
    String algorithm = 'SHA1',
    int digits = defaultCodeLength,
    int period = defaultTimeStep,
  }) {
    final encodedAccountName = Uri.encodeComponent(accountName);
    final encodedIssuer = Uri.encodeComponent(issuer);
    
    return 'otpauth://totp/$encodedIssuer:$encodedAccountName'
           '?secret=$secret'
           '&issuer=$encodedIssuer'
           '&algorithm=$algorithm'
           '&digits=$digits'
           '&period=$period';
  }

  /// Get remaining time in current TOTP window
  /// 
  /// [timeStep] - Time step in seconds (default: 30)
  /// [timestamp] - Custom timestamp (default: current time)
  /// 
  /// Returns remaining seconds in current time window
  static int getRemainingTime({
    int timeStep = defaultTimeStep,
    DateTime? timestamp,
  }) {
    final time = timestamp ?? DateTime.now();
    final secondsInCurrentWindow = (time.millisecondsSinceEpoch ~/ 1000) % timeStep;
    return timeStep - secondsInCurrentWindow;
  }

  /// Validate TOTP secret format
  /// 
  /// [secret] - Base32-encoded secret to validate
  /// 
  /// Returns true if secret is valid base32, false otherwise
  static bool isValidSecret(String secret) {
    if (secret.isEmpty) return false;
    
    // Remove padding and check characters
    final cleanSecret = secret.replaceAll('=', '');
    
    for (int i = 0; i < cleanSecret.length; i++) {
      if (!_base32Alphabet.contains(cleanSecret[i].toUpperCase())) {
        return false;
      }
    }
    
    return true;
  }

  /// Generate backup codes
  /// 
  /// [count] - Number of backup codes to generate (default: 10)
  /// [length] - Length of each backup code (default: 8)
  /// 
  /// Returns list of backup codes
  static List<String> generateBackupCodes({
    int count = 10,
    int length = 8,
  }) {
    final random = Random.secure();
    final codes = <String>[];
    
    for (int i = 0; i < count; i++) {
      String code = '';
      for (int j = 0; j < length; j++) {
        code += random.nextInt(10).toString();
      }
      codes.add(code);
    }
    
    return codes;
  }

  /// Format backup code for display
  /// 
  /// [code] - Backup code to format
  /// 
  /// Returns formatted backup code (e.g., "1234-5678")
  static String formatBackupCode(String code) {
    if (code.length <= 4) return code;
    
    final buffer = StringBuffer();
    for (int i = 0; i < code.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write('-');
      }
      buffer.write(code[i]);
    }
    
    return buffer.toString();
  }

  // Private helper methods

  /// Generate HOTP code
  /// 
  /// [secret] - Base32-encoded secret
  /// [counter] - Counter value
  /// [codeLength] - Length of generated code
  /// 
  /// Returns HOTP code
  static String _generateHOTP(String secret, int counter, int codeLength) {
    final secretBytes = _base32Decode(secret);
    final counterBytes = _intToBytes(counter);
    
    // HMAC-SHA1
    final hmac = Hmac(sha1, secretBytes);
    final hash = hmac.convert(counterBytes).bytes;
    
    // Dynamic truncation
    final offset = hash[hash.length - 1] & 0x0F;
    final truncatedHash = (hash[offset] & 0x7F) << 24 |
                         (hash[offset + 1] & 0xFF) << 16 |
                         (hash[offset + 2] & 0xFF) << 8 |
                         (hash[offset + 3] & 0xFF);
    
    final code = truncatedHash % pow(10, codeLength).toInt();
    return code.toString().padLeft(codeLength, '0');
  }

  /// Convert integer to 8-byte array (big-endian)
  /// 
  /// [value] - Integer value to convert
  /// 
  /// Returns byte array
  static Uint8List _intToBytes(int value) {
    final bytes = Uint8List(8);
    for (int i = 7; i >= 0; i--) {
      bytes[i] = value & 0xFF;
      value >>= 8;
    }
    return bytes;
  }

  /// Encode bytes to base32
  /// 
  /// [bytes] - Bytes to encode
  /// 
  /// Returns base32-encoded string
  static String _base32Encode(Uint8List bytes) {
    if (bytes.isEmpty) return '';
    
    final buffer = StringBuffer();
    int bits = 0;
    int value = 0;
    
    for (final byte in bytes) {
      value = (value << 8) | byte;
      bits += 8;
      
      while (bits >= 5) {
        buffer.write(_base32Alphabet[(value >> (bits - 5)) & 0x1F]);
        bits -= 5;
      }
    }
    
    if (bits > 0) {
      buffer.write(_base32Alphabet[(value << (5 - bits)) & 0x1F]);
    }
    
    // Add padding
    while (buffer.length % 8 != 0) {
      buffer.write('=');
    }
    
    return buffer.toString();
  }

  /// Decode base32 to bytes
  /// 
  /// [base32] - Base32-encoded string
  /// 
  /// Returns decoded bytes
  static Uint8List _base32Decode(String base32) {
    if (base32.isEmpty) return Uint8List(0);
    
    // Remove padding and convert to uppercase
    final cleanBase32 = base32.replaceAll('=', '').toUpperCase();
    
    final bytes = <int>[];
    int bits = 0;
    int value = 0;
    
    for (final char in cleanBase32.split('')) {
      final index = _base32Alphabet.indexOf(char);
      if (index == -1) {
        throw ArgumentError('Invalid base32 character: $char');
      }
      
      value = (value << 5) | index;
      bits += 5;
      
      if (bits >= 8) {
        bytes.add((value >> (bits - 8)) & 0xFF);
        bits -= 8;
      }
    }
    
    return Uint8List.fromList(bytes);
  }
}