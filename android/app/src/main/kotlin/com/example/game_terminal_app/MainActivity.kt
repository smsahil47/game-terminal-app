package com.example.game_terminal_app

import android.media.MediaPlayer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var alarm: MediaPlayer? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "game_terminal/session_alarm")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        if (alarm == null) {
                            alarm = MediaPlayer.create(this, R.raw.alarm)?.apply {
                                isLooping = true
                                start()
                            }
                        }
                        result.success(null)
                    }
                    "stop" -> {
                        alarm?.release()
                        alarm = null
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        alarm?.release()
        alarm = null
        super.onDestroy()
    }
}
