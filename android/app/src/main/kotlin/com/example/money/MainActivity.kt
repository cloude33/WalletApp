package com.example.money

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity() {
    
    private lateinit var biometricChannelHandler: BiometricChannelHandler
    private lateinit var securityChannelHandler: SecurityChannelHandler
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Biometric channel handler'ı register et
        biometricChannelHandler = BiometricChannelHandler(this)
        biometricChannelHandler.registerWith(flutterEngine)
        
        // Security channel handler'ı register et
        securityChannelHandler = SecurityChannelHandler(this, this)
        securityChannelHandler.configureFlutterEngine(flutterEngine)
    }
}
