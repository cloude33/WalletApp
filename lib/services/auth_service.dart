import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  final LocalAuthentication _localAuth = LocalAuthentication();
  late final GoogleSignIn _googleSignIn;

  AuthService._internal() {
    if (kIsWeb) {
      // For web, we need to provide a clientId
      // In a real app, you would use your actual Google Client ID
      _googleSignIn = GoogleSignIn(
        clientId: '', // Add your web client ID here
      );
    } else {
      _googleSignIn = GoogleSignIn();
    }
  }

  SharedPreferences? _prefs;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // PIN Code
  Future<void> savePinCode(String pin) async {
    await _secureStorage.write(key: 'pin_code', value: pin);
  }

  Future<String?> getPinCode() async {
    return await _secureStorage.read(key: 'pin_code');
  }

  Future<bool> verifyPinCode(String pin) async {
    final savedPin = await getPinCode();
    return savedPin == pin;
  }

  Future<bool> hasPinCode() async {
    final pin = await getPinCode();
    return pin != null && pin.isNotEmpty;
  }

  // Biometric (Fingerprint/Face ID)
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheckBiometrics && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  Future<bool> authenticateWithBiometric() async {
    try {
      // Önce PIN kodunun olup olmadığını kontrol et
      final hasPin = await hasPinCode();
      if (!hasPin) {
        throw PlatformException(
          code: 'NoPin',
          message: 'PIN kodu bulunamadı',
        );
      }

      // Biyometrik özelliğin mevcut olup olmadığını kontrol et
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        throw PlatformException(
          code: 'NotAvailable',
          message: 'Biyometrik özellik kullanılamıyor',
        );
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Uygulamaya giriş yapmak için kimliğinizi doğrulayın',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      print('Biometric authentication error: ${e.code} - ${e.message}');
      // PlatformException'ı yeniden fırlat ki çağıran kod hata kodunu görebilsin
      rethrow;
    } catch (e) {
      print('Unexpected error in biometric authentication: $e');
      throw PlatformException(
        code: 'Unknown',
        message: 'Beklenmeyen bir hata oluştu',
      );
    }
  }

  // Google Sign In
  Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account != null) {
        // Save user info
        await _prefs?.setString('google_email', account.email);
        await _prefs?.setString('google_name', account.displayName ?? '');
        await _prefs?.setString('google_photo', account.photoUrl ?? '');
      }
      return account;
    } catch (e) {
      print('Google Sign-In error: $e');
      return null;
    }
  }

  Future<void> signOutGoogle() async {
    await _googleSignIn.signOut();
    await _prefs?.remove('google_email');
    await _prefs?.remove('google_name');
    await _prefs?.remove('google_photo');
  }

  // Facebook Sign In
  Future<Map<String, dynamic>?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        final userData = await FacebookAuth.instance.getUserData();
        // Save user info
        await _prefs?.setString('facebook_email', userData['email'] ?? '');
        await _prefs?.setString('facebook_name', userData['name'] ?? '');
        await _prefs?.setString(
          'facebook_photo',
          userData['picture']?['data']?['url'] ?? '',
        );
        return userData;
      }
      return null;
    } catch (e) {
      print('Facebook Sign-In error: $e');
      return null;
    }
  }

  Future<void> signOutFacebook() async {
    await FacebookAuth.instance.logOut();
    await _prefs?.remove('facebook_email');
    await _prefs?.remove('facebook_name');
    await _prefs?.remove('facebook_photo');
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final googleEmail = _prefs?.getString('google_email');
    final facebookEmail = _prefs?.getString('facebook_email');
    final hasPin = await hasPinCode();

    return googleEmail != null || facebookEmail != null || hasPin;
  }

  // Get current auth method
  Future<String?> getCurrentAuthMethod() async {
    if (_prefs?.getString('google_email') != null) return 'google';
    if (_prefs?.getString('facebook_email') != null) return 'facebook';
    if (await hasPinCode()) return 'pin';
    return null;
  }

  // Logout all
  Future<void> logoutAll() async {
    await signOutGoogle();
    await signOutFacebook();
    await _secureStorage.delete(key: 'pin_code');
  }

  // Biometric settings
  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(
      key: 'biometric_enabled',
      value: enabled ? 'true' : 'false',
    );
  }

  Future<bool> isBiometricEnabled() async {
    final value = await _secureStorage.read(key: 'biometric_enabled');
    return value == 'true';
  }
}
