package com.memento.foreground_service

import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Memento 前台服务插件
 *
 * 处理计时器服务和活动通知服务的 MethodChannel 调用。
 */
class MementoForegroundServicePlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    companion object {
        private const val TAG = "MementoForegroundService"
        private const val TIMER_CHANNEL = "com.memento.foreground_service/timer"
        private const val ACTIVITY_CHANNEL = "com.memento.foreground_service/activity_notification"

        // 静态引用，供 Service 使用
        var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding? = null
    }

    private lateinit var timerChannel: MethodChannel
    private lateinit var activityChannel: MethodChannel
    private var context: Context? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        flutterPluginBinding = binding
        context = binding.applicationContext

        // 计时器服务通道
        timerChannel = MethodChannel(binding.binaryMessenger, TIMER_CHANNEL)
        timerChannel.setMethodCallHandler(this)

        // 活动通知服务通道
        activityChannel = MethodChannel(binding.binaryMessenger, ACTIVITY_CHANNEL)
        activityChannel.setMethodCallHandler(this)

        // 设置服务的 FlutterEngine 引用
        TimerForegroundService.flutterPluginBinding = binding
        ActivityForegroundService.flutterPluginBinding = binding

        Log.d(TAG, "Plugin attached to engine")
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        val ctx = context
        if (ctx == null) {
            result.error("NO_CONTEXT", "Context not available", null)
            return
        }

        when (call.method) {
            // 计时器服务方法
            "startTimerService" -> handleStartTimerService(ctx, call, result)
            "updateTimerService" -> handleUpdateTimerService(ctx, call, result)
            "stopTimerService" -> handleStopTimerService(ctx, result)

            // 活动通知服务方法
            "startActivityNotificationService" -> handleStartActivityService(ctx, result)
            "stopActivityNotificationService" -> handleStopActivityService(ctx, result)
            "updateActivityNotification" -> handleUpdateActivityNotification(ctx, call, result)

            else -> result.notImplemented()
        }
    }

    // ==================== 计时器服务处理 ====================

    private fun handleStartTimerService(ctx: Context, call: MethodCall, result: Result) {
        try {
            val args = call.arguments as? Map<*, *>
            val intent = Intent(ctx, TimerForegroundService::class.java).apply {
                action = "START"
                args?.let {
                    putExtra("taskId", it["taskId"] as? String)
                    putExtra("taskName", it["taskName"] as? String)
                    putExtra("subTimers", it["subTimers"] as? ArrayList<*>)
                    putExtra("currentSubTimerIndex", it["currentSubTimerIndex"] as? Int ?: -1)
                }
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                ctx.startForegroundService(intent)
            } else {
                ctx.startService(intent)
            }

            Log.d(TAG, "Timer service started")
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "Error starting timer service", e)
            result.error("START_ERROR", e.message, null)
        }
    }

    private fun handleUpdateTimerService(ctx: Context, call: MethodCall, result: Result) {
        try {
            val args = call.arguments as? Map<*, *>
            val intent = Intent(ctx, TimerForegroundService::class.java).apply {
                action = "UPDATE"
                args?.let {
                    putExtra("taskId", it["taskId"] as? String)
                    putExtra("taskName", it["taskName"] as? String)
                    putExtra("subTimers", it["subTimers"] as? ArrayList<*>)
                    putExtra("currentSubTimerIndex", it["currentSubTimerIndex"] as? Int ?: -1)
                }
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                ctx.startForegroundService(intent)
            } else {
                ctx.startService(intent)
            }

            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "Error updating timer service", e)
            result.error("UPDATE_ERROR", e.message, null)
        }
    }

    private fun handleStopTimerService(ctx: Context, result: Result) {
        try {
            val intent = Intent(ctx, TimerForegroundService::class.java)
            ctx.stopService(intent)
            Log.d(TAG, "Timer service stopped")
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping timer service", e)
            result.error("STOP_ERROR", e.message, null)
        }
    }

    // ==================== 活动通知服务处理 ====================

    private fun handleStartActivityService(ctx: Context, result: Result) {
        try {
            val intent = Intent(ctx, ActivityForegroundService::class.java).apply {
                action = "START"
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                ctx.startForegroundService(intent)
            } else {
                ctx.startService(intent)
            }

            Log.d(TAG, "Activity notification service started")
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "Error starting activity notification service", e)
            result.error("START_ERROR", e.message, null)
        }
    }

    private fun handleStopActivityService(ctx: Context, result: Result) {
        try {
            val intent = Intent(ctx, ActivityForegroundService::class.java)
            ctx.stopService(intent)
            Log.d(TAG, "Activity notification service stopped")
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping activity notification service", e)
            result.error("STOP_ERROR", e.message, null)
        }
    }

    private fun handleUpdateActivityNotification(ctx: Context, call: MethodCall, result: Result) {
        try {
            val args = call.arguments as? Map<*, *>
            val title = args?.get("title") as? String
            val content = args?.get("content") as? String

            val intent = Intent(ctx, ActivityForegroundService::class.java).apply {
                action = "UPDATE"
                putExtra("title", title)
                putExtra("content", content)
            }
            ctx.startService(intent)

            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "Error updating activity notification", e)
            result.error("UPDATE_ERROR", e.message, null)
        }
    }

    // ==================== 生命周期方法 ====================

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        timerChannel.setMethodCallHandler(null)
        activityChannel.setMethodCallHandler(null)
        context = null
        flutterPluginBinding = null
        Log.d(TAG, "Plugin detached from engine")
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        // Activity 附加时可以获取 Activity 引用
    }

    override fun onDetachedFromActivityForConfigChanges() {}

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {}

    override fun onDetachedFromActivity() {}
}
