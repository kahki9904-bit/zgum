package com.example.zgum

import android.graphics.Rect
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channel = "com.example.zgum/gesture"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setExclusionRects" -> {
                        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
                            @Suppress("UNCHECKED_CAST")
                            val raw = call.argument<List<Map<String, Int>>>("rects") ?: emptyList()
                            val rects = raw.map { r ->
                                Rect(r["left"]!!, r["top"]!!, r["right"]!!, r["bottom"]!!)
                            }
                            window.decorView.post {
                                window.decorView.systemGestureExclusionRects = rects
                            }
                        }
                        result.success(null)
                    }
                    "clearExclusionRects" -> {
                        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
                            window.decorView.post {
                                window.decorView.systemGestureExclusionRects = emptyList()
                            }
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
