package com.example.memento_nfc

import android.content.Context
import android.content.Intent
import android.nfc.NdefMessage
import android.nfc.NdefRecord
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.nfc.tech.Ndef
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import org.json.JSONObject
import java.nio.charset.Charset

/** MementoNfcPlugin */
class MementoNfcPlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware {
    private lateinit var channel: MethodChannel
    private var context: Context? = null
    private var activity: android.app.Activity? = null
    private var nfcAdapter: NfcAdapter? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "memento_nfc")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        nfcAdapter = NfcAdapter.getDefaultAdapter(context)
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            "isNfcSupported" -> {
                result.success(nfcAdapter != null)
            }
            "isNfcEnabled" -> {
                result.success(nfcAdapter?.isEnabled ?: false)
            }
            "readNfc" -> {
                val mapResult = readNfc()
                result.success(mapResult)
            }
            "writeNfc" -> {
                val data = call.argument<String>("data") ?: ""
                val formatType = call.argument<String>("formatType") ?: "NDEF"
                val mapResult = writeNfc(data, formatType)
                result.success(mapResult)
            }
            "writeNdefUrl" -> {
                val url = call.argument<String>("url") ?: ""
                val mapResult = writeNdefUrl(url)
                result.success(mapResult)
            }
            "writeNdefText" -> {
                val text = call.argument<String>("text") ?: ""
                val mapResult = writeNdefText(text)
                result.success(mapResult)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun readNfc(): HashMap<String, Any> {
        try {
            val tag = activity?.intent?.getParcelableExtra<Tag>(NfcAdapter.EXTRA_TAG)
            if (tag == null) {
                val result = HashMap<String, Any>()
                result["success"] = false
                result["error"] = "No NFC tag detected"
                return result
            }

            val ndef = Ndef.get(tag)
            if (ndef == null) {
                val result = HashMap<String, Any>()
                result["success"] = false
                result["error"] = "Tag does not support NDEF"
                return result
            }

            ndef.connect()
            val ndefMessage = ndef.ndefMessage
            ndef.close()

            val records = ndefMessage.records
            if (records.isEmpty()) {
                val result = HashMap<String, Any>()
                result["success"] = false
                result["error"] = "No NDEF records found"
                return result
            }

            val data = StringBuilder()
            for (record in records) {
                val payload = record.payload
                if (payload != null) {
                    val text = String(payload, Charset.forName("UTF-8"))
                    data.append(text).append("\n")
                }
            }

            val result = HashMap<String, Any>()
            result["success"] = true
            result["data"] = data.toString().trim()
            return result
        } catch (e: Exception) {
            val result = HashMap<String, Any>()
            result["success"] = false
            result["error"] = e.message
            return result
        }
    }

    private fun writeNfc(data: String, formatType: String): HashMap<String, Any> {
        return try {
            val tag = activity?.intent?.getParcelableExtra<Tag>(NfcAdapter.EXTRA_TAG)
            if (tag == null) {
                val result = HashMap<String, Any>()
                result["success"] = false
                result["error"] = "No NFC tag detected"
                return result
            }

            val ndef = Ndef.get(tag)
            if (ndef == null) {
                val result = HashMap<String, Any>()
                result["success"] = false
                result["error"] = "Tag does not support NDEF"
                return result
            }

            ndef.connect()

            val textRecord = NdefRecord(
                NdefRecord.TNF_MIME_MEDIA,
                "text/plain".toByteArray(),
                byteArrayOf(),
                data.toByteArray()
            )

            val message = NdefMessage(arrayOf(textRecord))
            ndef.writeNdefMessage(message)
            ndef.close()

            val result = HashMap<String, Any>()
            result["success"] = true
            return result
        } catch (e: Exception) {
            val result = HashMap<String, Any>()
            result["success"] = false
            result["error"] = e.message
            return result
        }
    }

    private fun writeNdefUrl(url: String): HashMap<String, Any> {
        return try {
            val tag = activity?.intent?.getParcelableExtra<Tag>(NfcAdapter.EXTRA_TAG)
            if (tag == null) {
                val result = HashMap<String, Any>()
                result["success"] = false
                result["error"] = "No NFC tag detected"
                return result
            }

            val ndef = Ndef.get(tag)
            if (ndef == null) {
                val result = HashMap<String, Any>()
                result["success"] = false
                result["error"] = "Tag does not support NDEF"
                return result
            }

            ndef.connect()

            val uriField = url.toByteArray()
            val payload = ByteArray(uriField.size + 1)
            payload[0] = 0x00
            System.arraycopy(uriField, 0, payload, 1, uriField.size)

            val uriRecord = NdefRecord(
                NdefRecord.TNF_WELL_KNOWN,
                NdefRecord.RTD_URI,
                byteArrayOf(),
                payload
            )

            val message = NdefMessage(arrayOf(uriRecord))
            ndef.writeNdefMessage(message)
            ndef.close()

            val result = HashMap<String, Any>()
            result["success"] = true
            return result
        } catch (e: Exception) {
            val result = HashMap<String, Any>()
            result["success"] = false
            result["error"] = e.message
            return result
        }
    }

    private fun writeNdefText(text: String): HashMap<String, Any> {
        return try {
            val tag = activity?.intent?.getParcelableExtra<Tag>(NfcAdapter.EXTRA_TAG)
            if (tag == null) {
                val result = HashMap<String, Any>()
                result["success"] = false
                result["error"] = "No NFC tag detected"
                return result
            }

            val ndef = Ndef.get(tag)
            if (ndef == null) {
                val result = HashMap<String, Any>()
                result["success"] = false
                result["error"] = "Tag does not support NDEF"
                return result
            }

            ndef.connect()

            val lang = "en"
            val textBytes = text.toByteArray()
            val langBytes = lang.toByteArray()
            val payload = ByteArray(1 + langBytes.size + textBytes.size)

            payload[0] = langBytes.size.toByte()
            System.arraycopy(langBytes, 0, payload, 1, langBytes.size)
            System.arraycopy(textBytes, 0, payload, 1 + langBytes.size, textBytes.size)

            val textRecord = NdefRecord(
                NdefRecord.TNF_WELL_KNOWN,
                NdefRecord.RTD_TEXT,
                byteArrayOf(),
                payload
            )

            val message = NdefMessage(arrayOf(textRecord))
            ndef.writeNdefMessage(message)
            ndef.close()

            val result = HashMap<String, Any>()
            result["success"] = true
            return result
        } catch (e: Exception) {
            val result = HashMap<String, Any>()
            result["success"] = false
            result["error"] = e.message
            return result
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }
}
