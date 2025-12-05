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
import android.util.Log
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
    ActivityAware,
    NfcAdapter.ReaderCallback {
    private lateinit var channel: MethodChannel
    private var context: Context? = null
    private var activity: android.app.Activity? = null
    private var nfcAdapter: NfcAdapter? = null
    private var pendingResult: Result? = null
    private var isWriteMode = false
    private var pendingWriteData: String = ""
    private var pendingWriteFormat: String = ""
    private var timeoutHandler: Handler? = null
    private val timeoutRunnable = Runnable {
        Log.w(TAG, "NFC operation timeout")
        pendingResult?.success(hashMapOf(
            "success" to false,
            "error" to "NFC操作超时，请重试"
        ))
        stopNfcReading()
    }

    companion object {
        private const val TAG = "MementoNfcPlugin"
        private const val NFC_TIMEOUT_MS = 15000L // 15秒超时
    }

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
                isWriteMode = false
                startNfcReading(result)
            }
            "writeNfc" -> {
                val data = call.argument<String>("data") ?: ""
                val formatType = call.argument<String>("formatType") ?: "NDEF"
                isWriteMode = true
                startNfcWriting(result, data, formatType)
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

    private fun startNfcWriting(result: Result, data: String, formatType: String) {
        if (nfcAdapter == null || !nfcAdapter!!.isEnabled) {
            result.success(hashMapOf(
                "success" to false,
                "error" to "NFC未启用"
            ))
            return
        }

        pendingResult = result
        pendingWriteData = data
        pendingWriteFormat = formatType

        // 启动超时计时器
        timeoutHandler = Handler(Looper.getMainLooper())
        timeoutHandler?.postDelayed(timeoutRunnable, NFC_TIMEOUT_MS)

        // 延迟一点时间启动，让Flutter有时间显示对话框
        Handler(Looper.getMainLooper()).postDelayed({
            try {
                // 启动前台调度，添加更多 flags 和 extras
                val extras = android.os.Bundle()
                extras.putInt(NfcAdapter.EXTRA_READER_PRESENCE_CHECK_DELAY, 250)

                // 使用所有支持的 NFC 技术，并添加 NDEF 过滤
                val flags = NfcAdapter.FLAG_READER_NFC_A or
                           NfcAdapter.FLAG_READER_NFC_B or
                           NfcAdapter.FLAG_READER_NFC_F or
                           NfcAdapter.FLAG_READER_NFC_V or
                           NfcAdapter.FLAG_READER_NO_PLATFORM_SOUNDS

                nfcAdapter!!.enableReaderMode(activity, this, flags, extras)
            } catch (e: Exception) {
                // 取消超时计时器
                timeoutHandler?.removeCallbacks(timeoutRunnable)
                result.success(hashMapOf(
                    "success" to false,
                    "error" to "启动NFC写入失败: ${e.message}"
                ))
            }
        }, 200)
    }

    private fun startNfcReading(result: Result) {
        Log.d(TAG, "startNfcReading: Starting NFC reading")
        if (nfcAdapter == null || !nfcAdapter!!.isEnabled) {
            Log.e(TAG, "startNfcReading: NFC not supported or not enabled")
            result.success(hashMapOf(
                "success" to false,
                "error" to "NFC未启用"
            ))
            return
        }

        pendingResult = result
        Log.d(TAG, "startNfcReading: NFC adapter is ready, starting reader mode in 200ms")

        // 启动超时计时器
        timeoutHandler = Handler(Looper.getMainLooper())
        timeoutHandler?.postDelayed(timeoutRunnable, NFC_TIMEOUT_MS)

        // 延迟一点时间启动，让Flutter有时间显示对话框
        Handler(Looper.getMainLooper()).postDelayed({
            try {
                Log.d(TAG, "startNfcReading: Enabling reader mode")
                // 启动前台调度，添加更多 flags 和 extras
                val extras = android.os.Bundle()
                extras.putInt(NfcAdapter.EXTRA_READER_PRESENCE_CHECK_DELAY, 250)

                // 使用所有支持的 NFC 技术，并添加 NDEF 过滤
                val flags = NfcAdapter.FLAG_READER_NFC_A or
                           NfcAdapter.FLAG_READER_NFC_B or
                           NfcAdapter.FLAG_READER_NFC_F or
                           NfcAdapter.FLAG_READER_NFC_V or
                           NfcAdapter.FLAG_READER_NO_PLATFORM_SOUNDS

                nfcAdapter!!.enableReaderMode(activity, this, flags, extras)
                Log.i(TAG, "startNfcReading: Reader mode enabled successfully")
            } catch (e: Exception) {
                Log.e(TAG, "startNfcReading: Failed to enable reader mode", e)
                // 取消超时计时器
                timeoutHandler?.removeCallbacks(timeoutRunnable)
                result.success(hashMapOf(
                    "success" to false,
                    "error" to "启动NFC读取失败: ${e.message}"
                ))
            }
        }, 200)
    }

    override fun onTagDiscovered(tag: Tag?) {
        Log.d(TAG, "onTagDiscovered: Tag discovered: ${tag != null}")
        // 取消超时计时器
        timeoutHandler?.removeCallbacks(timeoutRunnable)

        if (tag == null) {
            Log.w(TAG, "onTagDiscovered: Tag is null")
            Handler(Looper.getMainLooper()).post {
                pendingResult?.success(hashMapOf(
                    "success" to false,
                    "error" to "未检测到NFC标签"
                ))
                stopNfcReading()
            }
            return
        }

        if (isWriteMode) {
            Log.i(TAG, "onTagDiscovered: Processing write operation")
            // 写入模式
            val writeResult = performWrite(tag, pendingWriteData, pendingWriteFormat)
            Handler(Looper.getMainLooper()).post {
                pendingResult?.success(writeResult)
                stopNfcReading()
            }
        } else {
            Log.i(TAG, "onTagDiscovered: Processing read operation")
            // 读取模式
            val readResult = performRead(tag)
            Handler(Looper.getMainLooper()).post {
                pendingResult?.success(readResult)
                stopNfcReading()
            }
        }
    }

    private fun stopNfcReading() {
        Log.d(TAG, "stopNfcReading: Stopping NFC reading")
        try {
            // 取消超时计时器
            timeoutHandler?.removeCallbacks(timeoutRunnable)
            timeoutHandler = null

            nfcAdapter?.disableReaderMode(activity)
        } catch (e: Exception) {
            Log.w(TAG, "stopNfcReading: Error disabling reader mode", e)
            // 忽略关闭错误
        }
        pendingResult = null
        pendingWriteData = ""
        pendingWriteFormat = ""
    }

    private fun performRead(tag: Tag): HashMap<String, Any> {
        try {

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
            result["error"] = e.message ?: "Unknown error"
            return result
        }
    }

    private fun performWrite(tag: Tag, data: String, formatType: String): HashMap<String, Any> {
        return try {
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
            result["error"] = e.message ?: "Unknown error"
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
            result["error"] = e.message ?: "Unknown error"
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
            result["error"] = e.message ?: "Unknown error"
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
        stopNfcReading()
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        stopNfcReading()
        activity = null
    }
}
