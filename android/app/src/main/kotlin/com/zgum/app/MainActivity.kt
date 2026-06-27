package com.zgum.app

import android.content.ContentValues
import android.graphics.Rect
import android.os.Build
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    private val gestureChannel = "com.zgum.app/gesture"
    private val photoSaveChannel = "com.zgum.app/photo_save"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, gestureChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setExclusionRects" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
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
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            window.decorView.post {
                                window.decorView.systemGestureExclusionRects = emptyList()
                            }
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, photoSaveChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveImage" -> {
                        val bytes = call.argument<ByteArray>("bytes")
                        val fileName = call.argument<String>("fileName") ?: "zgum_photo.jpg"
                        val mimeType = call.argument<String>("mimeType") ?: "image/jpeg"
                        if (bytes == null || bytes.isEmpty()) {
                            result.error("EMPTY_IMAGE", "Image bytes are empty", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val values = ContentValues().apply {
                                put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
                                put(MediaStore.Images.Media.MIME_TYPE, mimeType)
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                    put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/ZGUM")
                                    put(MediaStore.Images.Media.IS_PENDING, 1)
                                }
                            }
                            val resolver = applicationContext.contentResolver
                            val uri = resolver.insert(
                                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                                values
                            ) ?: throw IllegalStateException("MediaStore insert failed")
                            resolver.openOutputStream(uri)?.use { stream ->
                                stream.write(bytes)
                            } ?: throw IllegalStateException("Output stream open failed")
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                values.clear()
                                values.put(MediaStore.Images.Media.IS_PENDING, 0)
                                resolver.update(uri, values, null, null)
                            }
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SAVE_FAILED", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
