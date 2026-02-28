package com.priyanshu.dime_money

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.priyanshu.dime_money/quick_actions"
    private var launchAction: String? = null
    private var methodChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        launchAction = parseQuickAction(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getLaunchAction" -> {
                    val action = launchAction
                    launchAction = null
                    result.success(action)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val action = parseQuickAction(intent)
        if (action != null) {
            methodChannel?.invokeMethod("quickAction", action)
        }
    }

    private fun parseQuickAction(intent: Intent?): String? {
        val uri = intent?.data ?: return null
        if (uri.scheme == "dimemoney" && uri.host == "quick_action") {
            return uri.lastPathSegment
        }
        return null
    }
}
