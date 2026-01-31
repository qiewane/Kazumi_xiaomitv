package com.predidit.kazumi

import android.content.Intent
import android.os.Build
import android.net.Uri
import android.os.Bundle
import android.view.KeyEvent
import androidx.annotation.NonNull
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.predidit.kazumi/intent"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openWithMime" -> {
                    val url = call.argument<String>("url")
                    val mimeType = call.argument<String>("mimeType")
                    if (url != null && mimeType != null) {
                        openWithMime(url, mimeType)
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGUMENT", "URL and MIME type required", null)
                    }
                }
                "checkIfInMultiWindowMode" -> {
                    result.success(checkIfInMultiWindowMode())
                }
                "getAndroidSdkVersion" -> {
                    result.success(getAndroidSdkVersion())
                }
                "forceTVMode" -> {
                    // 强制返回 TV 模式
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // 强制 Leanback 模式（TV）
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            window.setDecorFitsSystemWindows(false)
        }
    }

    // TV 遥控器按键优化
    override fun dispatchKeyEvent(event: KeyEvent?): Boolean {
        if (event != null) {
            when (event.keyCode) {
                KeyEvent.KEYCODE_DPAD_CENTER,
                KeyEvent.KEYCODE_ENTER,
                KeyEvent.KEYCODE_DPAD_UP,
                KeyEvent.KEYCODE_DPAD_DOWN,
                KeyEvent.KEYCODE_DPAD_LEFT,
                KeyEvent.KEYCODE_DPAD_RIGHT -> {
                    // 确保遥控器事件传递
                    return super.dispatchKeyEvent(event)
                }
            }
        }
        return super.dispatchKeyEvent(event)
    }

    private fun openWithMime(url: String, mimeType: String) {
        val intent = Intent(Intent.ACTION_VIEW)
        intent.setDataAndType(Uri.parse(url), mimeType)
        startActivity(intent)
    }

    private fun checkIfInMultiWindowMode(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            this.isInMultiWindowMode 
        } else {
            false 
        }
    }

    private fun getAndroidSdkVersion(): Int {
        return Build.VERSION.SDK_INT
    }
}
