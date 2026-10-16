package com.example.inslate

import android.app.Activity
import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingUnlock: MethodChannel.Result? = null
    private val unlockRequest = 10471

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Fail closed until Flutter has read the persisted privacy setting.
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "inslate/device_unlock")
            .setMethodCallHandler { call, result ->
                val keyguard = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
                when (call.method) {
                    "isAvailable" -> result.success(keyguard.isDeviceSecure)
                    "protectScreen" -> {
                        if (call.argument<Boolean>("enabled") == true) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        }
                        result.success(null)
                    }
                    "authenticate" -> {
                        if (pendingUnlock != null) {
                            result.error("AUTH_IN_PROGRESS", "Device verification is already open.", null)
                        } else if (!keyguard.isDeviceSecure) {
                            result.error("NO_DEVICE_LOCK", "Set a phone screen lock first.", null)
                        } else {
                            @Suppress("DEPRECATION")
                            val intent = keyguard.createConfirmDeviceCredentialIntent(
                                "Unlock InSlate", "Verify your phone PIN, pattern or password."
                            )
                            if (intent == null) {
                                result.error("UNAVAILABLE", "Device verification is unavailable.", null)
                            } else {
                                pendingUnlock = result
                                try {
                                    @Suppress("DEPRECATION")
                                    startActivityForResult(intent, unlockRequest)
                                } catch (error: Exception) {
                                    pendingUnlock = null
                                    result.error("UNAVAILABLE", "Unable to open device verification.", null)
                                }
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    @Deprecated("Uses the system device-credential confirmation flow")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == unlockRequest) {
            val reply = pendingUnlock
            pendingUnlock = null
            // Let onResume deliver Flutter’s foreground lifecycle event first.
            window.decorView.post { reply?.success(resultCode == Activity.RESULT_OK) }
        }
    }
}
