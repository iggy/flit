package com.theiggy.flit

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Also the target of "Share via… flit" (ACTION_SEND text/plain, see the
 * manifest). The latest share is held here until Dart takes it on the
 * "flit/share" channel (lib/core/platform/share_intake.dart): `take` returns
 * {text, subject} or null and clears it; `available` tells a running app
 * that a new one is waiting. Pull-based, so a share that launched the app
 * isn't lost while Dart is still starting.
 */
class MainActivity : FlutterActivity() {
    private var pendingShare: Map<String, String>? = null
    private var shareChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        shareChannel =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "flit/share").apply {
                setMethodCallHandler { call, result ->
                    when (call.method) {
                        "take" -> {
                            result.success(pendingShare)
                            pendingShare = null
                        }
                        else -> result.notImplemented()
                    }
                }
            }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Not when restored, or relaunched from recents: that would replay
        // an old share.
        val fromHistory = (intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY) != 0
        if (savedInstanceState == null && !fromHistory) {
            capture(intent)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (capture(intent)) {
            shareChannel?.invokeMethod("available", null)
        }
    }

    override fun onDestroy() {
        shareChannel?.setMethodCallHandler(null)
        shareChannel = null
        super.onDestroy()
    }

    /** Keeps [intent]'s shared text, if it is a share. */
    private fun capture(intent: Intent?): Boolean {
        if (intent?.action != Intent.ACTION_SEND) {
            return false
        }
        val text = intent.getCharSequenceExtra(Intent.EXTRA_TEXT)?.toString().orEmpty()
        val subject = intent.getStringExtra(Intent.EXTRA_SUBJECT).orEmpty()
        if (text.isBlank() && subject.isBlank()) {
            return false
        }
        pendingShare = mapOf("text" to text, "subject" to subject)
        return true
    }
}
