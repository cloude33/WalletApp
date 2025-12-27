package com.example.money

import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import androidx.biometric.BiometricManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Android platform-specific biyometrik işlemler için method channel handler
 */
class BiometricChannelHandler(private val context: Context) : MethodCallHandler {
    
    companion object {
        private const val CHANNEL_NAME = "biometric_service/android"
    }
    
    private val keyguardManager: KeyguardManager by lazy {
        context.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
    }
    
    private val biometricManager: BiometricManager by lazy {
        BiometricManager.from(context)
    }
    
    /**
     * Flutter engine'e method channel'ı register eder
     */
    fun registerWith(flutterEngine: FlutterEngine) {
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
    }
    
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "hasSecureLockScreen" -> {
                result.success(hasSecureLockScreen())
            }
            "openBiometricSettings" -> {
                result.success(openBiometricSettings())
            }
            "getBiometricStatus" -> {
                result.success(getBiometricStatus())
            }
            "isStrongBiometricAvailable" -> {
                result.success(isStrongBiometricAvailable())
            }
            "isWeakBiometricAvailable" -> {
                result.success(isWeakBiometricAvailable())
            }
            else -> {
                result.notImplemented()
            }
        }
    }
    
    /**
     * Cihazın güvenli lock screen'e sahip olup olmadığını kontrol eder
     */
    private fun hasSecureLockScreen(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                keyguardManager.isDeviceSecure
            } else {
                keyguardManager.isKeyguardSecure
            }
        } catch (e: Exception) {
            false
        }
    }
    
    /**
     * Android biyometrik ayarlar sayfasını açar
     */
    private fun openBiometricSettings(): Boolean {
        return try {
            val intent = when {
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.R -> {
                    // Android 11+ (API 30+) - Biometric settings
                    Intent(Settings.ACTION_BIOMETRIC_ENROLL).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                }
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.P -> {
                    // Android 9+ (API 28+) - Fingerprint settings
                    Intent(Settings.ACTION_FINGERPRINT_ENROLL).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                }
                else -> {
                    // Eski Android sürümleri - Security settings
                    Intent(Settings.ACTION_SECURITY_SETTINGS).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                }
            }
            
            context.startActivity(intent)
            true
        } catch (e: Exception) {
            // Eğer specific intent çalışmazsa, genel güvenlik ayarlarını aç
            try {
                val fallbackIntent = Intent(Settings.ACTION_SECURITY_SETTINGS).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                context.startActivity(fallbackIntent)
                true
            } catch (fallbackException: Exception) {
                false
            }
        }
    }
    
    /**
     * Biyometrik durumu hakkında detaylı bilgi döndürür
     */
    private fun getBiometricStatus(): Map<String, Any> {
        val status = mutableMapOf<String, Any>()
        
        try {
            val biometricStatus = biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_WEAK)
            
            status["canAuthenticate"] = when (biometricStatus) {
                BiometricManager.BIOMETRIC_SUCCESS -> "SUCCESS"
                BiometricManager.BIOMETRIC_ERROR_NO_HARDWARE -> "NO_HARDWARE"
                BiometricManager.BIOMETRIC_ERROR_HW_UNAVAILABLE -> "HW_UNAVAILABLE"
                BiometricManager.BIOMETRIC_ERROR_NONE_ENROLLED -> "NONE_ENROLLED"
                BiometricManager.BIOMETRIC_ERROR_SECURITY_UPDATE_REQUIRED -> "SECURITY_UPDATE_REQUIRED"
                BiometricManager.BIOMETRIC_ERROR_UNSUPPORTED -> "UNSUPPORTED"
                BiometricManager.BIOMETRIC_STATUS_UNKNOWN -> "UNKNOWN"
                else -> "UNKNOWN"
            }
            
            status["hasSecureLockScreen"] = hasSecureLockScreen()
            status["isDeviceSecure"] = keyguardManager.isDeviceSecure
            status["androidVersion"] = Build.VERSION.SDK_INT
            status["deviceModel"] = "${Build.MANUFACTURER} ${Build.MODEL}"
            
            // Strong biometric support (Android 11+)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                val strongBiometricStatus = biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG)
                status["strongBiometricStatus"] = when (strongBiometricStatus) {
                    BiometricManager.BIOMETRIC_SUCCESS -> "SUCCESS"
                    BiometricManager.BIOMETRIC_ERROR_NO_HARDWARE -> "NO_HARDWARE"
                    BiometricManager.BIOMETRIC_ERROR_HW_UNAVAILABLE -> "HW_UNAVAILABLE"
                    BiometricManager.BIOMETRIC_ERROR_NONE_ENROLLED -> "NONE_ENROLLED"
                    else -> "UNAVAILABLE"
                }
            }
            
        } catch (e: Exception) {
            status["error"] = e.message ?: "Unknown error"
        }
        
        return status
    }
    
    /**
     * Strong biometric (Class 3) desteğini kontrol eder
     */
    private fun isStrongBiometricAvailable(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG) == BiometricManager.BIOMETRIC_SUCCESS
            } else {
                // Android 11 öncesi için genel biometric kontrolü
                biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_WEAK) == BiometricManager.BIOMETRIC_SUCCESS
            }
        } catch (e: Exception) {
            false
        }
    }
    
    /**
     * Weak biometric (Class 2) desteğini kontrol eder
     */
    private fun isWeakBiometricAvailable(): Boolean {
        return try {
            biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_WEAK) == BiometricManager.BIOMETRIC_SUCCESS
        } catch (e: Exception) {
            false
        }
    }
}