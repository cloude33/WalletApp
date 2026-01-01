import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  FirebaseAuth get _auth => FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // Web client ID'yi manuel olarak belirt
    serverClientId: '195092382674-ca5q05m7idrstrqpfb5bc6e00thqiu20.apps.googleusercontent.com',
  );

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user?.updateDisplayName(displayName);
      await credential.user?.reload();

      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Sign up error: $e');
      rethrow;
    }
  }

  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Sign in error: $e');
      rethrow;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      debugPrint('🔄 Google Sign-In başlatılıyor...');

      if (kIsWeb) {
        // Web için Google Identity Services (GIS) veya signInWithPopup kullan
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope(
          'https://www.googleapis.com/auth/userinfo.profile',
        );

        debugPrint(
          '🌐 Web platformu algılandı, signInWithPopup kullanılıyor...',
        );
        final userCredential = await _auth.signInWithPopup(googleProvider);
        debugPrint('✅ Google Sign-In başarılı: ${userCredential.user?.email}');
        return userCredential;
      } else {
        // Mobil için mevcut GoogleSignIn akışını kullan
        
        // Önce mevcut oturumu temizle
        try {
          await _googleSignIn.signOut();
          await _auth.signOut();
        } catch (e) {
          debugPrint('⚠️ Sign out error (ignorable): $e');
        }
        
        debugPrint('🔄 Google Sign-In başlatılıyor...');
        
        // Google Play Services kontrolü
        final isAvailable = await _googleSignIn.isSignedIn();
        debugPrint('📱 Google Play Services durumu: $isAvailable');
        
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        
        if (googleUser == null) {
          debugPrint('❌ Google Sign-In iptal edildi');
          return null;
        }

        debugPrint('✅ Google kullanıcısı seçildi: ${googleUser.email}');

        // Google kimlik doğrulama detaylarını al
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        if (googleAuth.accessToken == null || googleAuth.idToken == null) {
          debugPrint('❌ Google auth tokens alınamadı');
          debugPrint('Access Token: ${googleAuth.accessToken != null ? 'OK' : 'NULL'}');
          debugPrint('ID Token: ${googleAuth.idToken != null ? 'OK' : 'NULL'}');
          
          // Token alınamadıysa tekrar dene
          await _googleSignIn.signOut();
          throw Exception('Google authentication tokens not available. Please try again.');
        }

        debugPrint('✅ Google auth tokens alındı');

        // Firebase credential oluştur
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        debugPrint('🔄 Firebase ile giriş yapılıyor...');
        final userCredential = await _auth.signInWithCredential(credential);

        debugPrint('✅ Google Sign-In başarılı: ${userCredential.user?.email}');
        return userCredential;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } on PlatformException catch (e) {
      debugPrint('❌ Platform Exception: ${e.code} - ${e.message}');
      debugPrint('❌ Platform Exception Details: ${e.details}');
      
      if (e.code == 'sign_in_failed') {
        if (e.message?.contains('10') == true) {
          throw 'Google Sign-In yapılandırma hatası. Lütfen:\n'
              '• Uygulamayı tamamen kapatıp açın\n'
              '• Google Play Services\'i güncelleyin\n'
              '• Cihazınızı yeniden başlatın\n'
              '• İnternet bağlantınızı kontrol edin';
        }
        throw 'Google Sign-In başarısız. Lütfen internet bağlantınızı kontrol edin ve tekrar deneyin.';
      }
      throw 'Google Sign-In hatası: ${e.message ?? e.code}';
    } catch (e) {
      debugPrint('❌ Google sign in error: $e');
      throw 'Google Sign-In sırasında beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }

  Future<void> signOut() async {
    try {
      if (kIsWeb) {
        await _auth.signOut();
      } else {
        await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
      }
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      debugPrint('Password reset error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Password reset error: $e');
      rethrow;
    }
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı oturumu açık değil');

      final email = user.email;
      if (email == null) throw Exception('E-posta adresi bulunamadı');

      // Re-authenticate
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      debugPrint('Update password error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Update password error: $e');
      rethrow;
    }
  }

  bool get isSignedIn => _auth.currentUser != null;

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Hatalı şifre girdiniz.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanımda.';
      case 'weak-password':
        return 'Şifre çok zayıf. Lütfen daha güçlü bir şifre seçin.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'user-disabled':
        return 'Bu kullanıcı hesabı devre dışı bırakılmış.';
      case 'too-many-requests':
        return 'Çok fazla başarısız deneme. Lütfen daha sonra tekrar deneyin.';
      case 'operation-not-allowed':
        return 'Bu işlem şu anda izin verilmiyor.';
      case 'invalid-credential':
        return 'Geçersiz kimlik bilgileri.';
      default:
        return e.message ?? 'Bilinmeyen bir hata oluştu.';
    }
  }
}
