package com.songbuddy.app

import android.content.Intent
import android.net.Uri
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "songbuddy/oauth"
    private val EVENT_CHANNEL = "songbuddy/oauth"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Create notification channel for background sync
        NotificationChannelHelper.createNotificationChannel(this)
        
        // Set up event channel for OAuth deep links
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    // Store the event sink for later use
                    oauthEventSink = events
                    // Flush any pending deep link captured before Dart listener attached
                    pendingUri?.let {
                        oauthEventSink?.success(it)
                        pendingUri = null
                    }
                }

                override fun onCancel(arguments: Any?) {
                    oauthEventSink = null
                }
            }
        )
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        Log.d("MainActivity", "handleIntent called with: ${intent?.data}")
        if (intent?.data != null) {
            val uri = intent.data
            Log.d("MainActivity", "Received URI: $uri")
            if (uri?.scheme == "songbuddy" && uri.host == "callback") {
                Log.d("MainActivity", "Sending Spotify callback to Flutter: $uri")
                val url = uri.toString()
                if (oauthEventSink != null) {
                    oauthEventSink?.success(url)
                } else {
                    // Buffer until listener attaches
                    pendingUri = url
                }
            } else {
                Log.d("MainActivity", "Ignoring non-Spotify deep link: ${uri?.scheme}://${uri?.host}")
            }
        }
    }

    companion object {
        private var oauthEventSink: EventChannel.EventSink? = null
        private var pendingUri: String? = null
    }
}
