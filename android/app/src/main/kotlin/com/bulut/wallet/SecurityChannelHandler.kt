package com.bulut.wallet

import android.app.Activity
import android.app.KeyguardManager
import android.content.Context
import android.os.Build
import android.view.WindowManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File

/**
 * Android platform-specific security implementations
 * 
 * This handler provides Android-specific security features including:
 * - Screenshot blocking
 * - Background blur/secure flag
 * - Root detection
 * - Device security status
 */
class SecurityChannelHandler(
    private val activity: Activity,
    private val context: Context
) : MethodCallHandler {

    companion object {
        private const val CHANNEL_NAME = "com.bulut.wallet/security"
    }

    private var isScreenshotBlocked = false
    private var isBackgroundBlurEnabled = false

    fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
            .setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "enableScreenshotBlocking" -> {
                enableScreenshotBlocking(result)
            }
            "disableScreenshotBlocking" -> {
                disableScreenshotBlocking(result)
            }
            "enableBackgroundBlur" -> {
                enableBackgroundBlur(result)
            }
            "disableBackgroundBlur" -> {
                disableBackgroundBlur(result)
            }
            "isDeviceSecure" -> {
                checkDeviceSecurity(result)
            }
            "detectRoot" -> {
                detectRoot(result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    /**
     * Enables screenshot blocking by setting FLAG_SECURE
     * Requirement 9.1: Screenshot blocking
     */
    private fun enableScreenshotBlocking(result: Result) {
        try {
            activity.window.setFlags(
                WindowManager.LayoutParams.FLAG_SECURE,
                WindowManager.LayoutParams.FLAG_SECURE
            )
            isScreenshotBlocked = true
            result.success(true)
        } catch (e: Exception) {
            result.error("SCREENSHOT_BLOCKING_ERROR", "Failed to enable screenshot blocking", e.message)
        }
    }

    /**
     * Disables screenshot blocking by clearing FLAG_SECURE
     */
    private fun disableScreenshotBlocking(result: Result) {
        try {
            activity.window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
            isScreenshotBlocked = false
            result.success(true)
        } catch (e: Exception) {
            result.error("SCREENSHOT_BLOCKING_ERROR", "Failed to disable screenshot blocking", e.message)
        }
    }

    /**
     * Enables background blur by setting FLAG_SECURE (same as screenshot blocking on Android)
     * Requirement 9.2: Background blur in task switcher
     */
    private fun enableBackgroundBlur(result: Result) {
        try {
            // On Android, FLAG_SECURE also hides content in recent apps
            activity.window.setFlags(
                WindowManager.LayoutParams.FLAG_SECURE,
                WindowManager.LayoutParams.FLAG_SECURE
            )
            isBackgroundBlurEnabled = true
            result.success(true)
        } catch (e: Exception) {
            result.error("BACKGROUND_BLUR_ERROR", "Failed to enable background blur", e.message)
        }
    }

    /**
     * Disables background blur by clearing FLAG_SECURE
     */
    private fun disableBackgroundBlur(result: Result) {
        try {
            // Only clear if screenshot blocking is also disabled
            if (!isScreenshotBlocked) {
                activity.window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
            }
            isBackgroundBlurEnabled = false
            result.success(true)
        } catch (e: Exception) {
            result.error("BACKGROUND_BLUR_ERROR", "Failed to disable background blur", e.message)
        }
    }

    /**
     * Checks if device has secure lock screen
     */
    private fun checkDeviceSecurity(result: Result) {
        try {
            val keyguardManager = context.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            
            val isSecure = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                keyguardManager.isDeviceSecure
            } else {
                @Suppress("DEPRECATION")
                keyguardManager.isKeyguardSecure
            }
            
            result.success(isSecure)
        } catch (e: Exception) {
            result.error("DEVICE_SECURITY_ERROR", "Failed to check device security", e.message)
        }
    }

    /**
     * Detects if device is rooted
     * Requirement 9.4: Root detection
     */
    private fun detectRoot(result: Result) {
        try {
            val isRooted = isDeviceRooted()
            result.success(isRooted)
        } catch (e: Exception) {
            result.error("ROOT_DETECTION_ERROR", "Failed to detect root", e.message)
        }
    }

    /**
     * Comprehensive root detection using multiple methods
     */
    private fun isDeviceRooted(): Boolean {
        return checkRootMethod1() || checkRootMethod2() || checkRootMethod3() || checkRootMethod4()
    }

    /**
     * Check for common root binaries
     */
    private fun checkRootMethod1(): Boolean {
        val rootPaths = arrayOf(
            "/system/app/Superuser.apk",
            "/sbin/su",
            "/system/bin/su",
            "/system/xbin/su",
            "/data/local/xbin/su",
            "/data/local/bin/su",
            "/system/sd/xbin/su",
            "/system/bin/failsafe/su",
            "/data/local/su",
            "/su/bin/su"
        )

        for (path in rootPaths) {
            if (File(path).exists()) {
                return true
            }
        }
        return false
    }

    /**
     * Check for root management apps
     */
    private fun checkRootMethod2(): Boolean {
        val rootApps = arrayOf(
            "com.noshufou.android.su",
            "com.noshufou.android.su.elite",
            "eu.chainfire.supersu",
            "com.koushikdutta.superuser",
            "com.thirdparty.superuser",
            "com.yellowes.su",
            "com.koushikdutta.rommanager",
            "com.koushikdutta.rommanager.license",
            "com.dimonvideo.luckypatcher",
            "com.chelpus.lackypatch",
            "com.ramdroid.appquarantine",
            "com.ramdroid.appquarantinepro"
        )

        val packageManager = context.packageManager
        for (packageName in rootApps) {
            try {
                packageManager.getPackageInfo(packageName, 0)
                return true
            } catch (e: Exception) {
                // Package not found, continue checking
            }
        }
        return false
    }

    /**
     * Check for dangerous system properties
     */
    private fun checkRootMethod3(): Boolean {
        return try {
            val buildTags = Build.TAGS
            buildTags != null && buildTags.contains("test-keys")
        } catch (e: Exception) {
            false
        }
    }

    /**
     * Check for RW system partition
     */
    private fun checkRootMethod4(): Boolean {
        return try {
            val process = Runtime.getRuntime().exec(arrayOf("/system/bin/mount"))
            val inputStream = process.inputStream
            val reader = inputStream.bufferedReader()
            
            reader.useLines { lines ->
                lines.any { line ->
                    line.contains("/system") && (line.contains("rw,") || line.contains("rw "))
                }
            }
        } catch (e: Exception) {
            false
        }
    }
}
