package github.hunmer.memento_widgets

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** MementoWidgetsPlugin */
class MementoWidgetsPlugin :
    FlutterPlugin,
    MethodCallHandler {
    // The MethodChannel that will the communication between Flutter and native Android
    private lateinit var channel: MethodChannel

    // 用于广播事件的 MethodChannel
    private var broadcastChannel: MethodChannel? = null

    // 广播接收器
    private var widgetBroadcastReceiver: WidgetBroadcastReceiver? = null

    // 应用上下文
    private var applicationContext: Context? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "memento_widgets")
        channel.setMethodCallHandler(this)

        // 创建专门的广播 MethodChannel
        broadcastChannel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "github.hunmer.memento/widget_broadcast"
        )
        broadcastChannel!!.setMethodCallHandler(this)

        // 获取应用上下文
        applicationContext = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            "registerBroadcastReceiver" -> {
                val actions = call.argument<List<String>>("actions")
                if (actions != null) {
                    registerBroadcastReceiver(actions)
                    result.success(true)
                } else {
                    result.error("INVALID_ARGUMENTS", "Actions list is required", null)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        broadcastChannel?.setMethodCallHandler(null)
        unregisterBroadcastReceiver()
    }

    /// 注册广播接收器
    private fun registerBroadcastReceiver(actions: List<String>) {
        // 取消之前的注册
        unregisterBroadcastReceiver()

        // 创建新的广播接收器
        widgetBroadcastReceiver = WidgetBroadcastReceiver { action, intent ->
            val data = intent?.extras?.keySet()?.associateWith { key ->
                intent.extras?.get(key)
            }

            // 在主线程中调用 Flutter 方法
            Handler(Looper.getMainLooper()).post {
                broadcastChannel?.invokeMethod(
                    "onBroadcastReceived",
                    mapOf(
                        "action" to action,
                        "data" to data
                    )
                )
            }
        }

        // 创建IntentFilter
        val filter = IntentFilter()
        actions.forEach { action ->
            filter.addAction(action)
        }

        // 注册广播接收器
        try {
            val context = applicationContext
            if (context != null) {
                // Android 14+ 需要指定 RECEIVER_EXPORTED 标志
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                    context.registerReceiver(
                        widgetBroadcastReceiver,
                        filter,
                        android.content.Context.RECEIVER_EXPORTED
                    )
                } else {
                    context.registerReceiver(widgetBroadcastReceiver, filter)
                }
                android.util.Log.d("MementoWidgets", "BroadcastReceiver registered for actions: $actions")
            } else {
                android.util.Log.w("MementoWidgets", "Application context not available, broadcast receiver not registered")
            }
        } catch (e: Exception) {
            android.util.Log.e("MementoWidgets", "Failed to register BroadcastReceiver", e)
        }
    }

    /// 取消注册广播接收器
    private fun unregisterBroadcastReceiver() {
        widgetBroadcastReceiver?.let { receiver ->
            try {
                val context = applicationContext
                context?.unregisterReceiver(receiver)
                android.util.Log.d("MementoWidgets", "BroadcastReceiver unregistered")
            } catch (e: Exception) {
                android.util.Log.e("MementoWidgets", "Failed to unregister BroadcastReceiver", e)
            }
        }
        widgetBroadcastReceiver = null
    }
}

/// 小组件广播接收器
private class WidgetBroadcastReceiver(
    private val onReceive: (String, Intent?) -> Unit
) : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        if (action != null) {
            onReceive(action, intent)
        }
    }
}
