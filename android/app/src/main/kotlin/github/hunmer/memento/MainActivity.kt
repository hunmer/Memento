package github.hunmer.memento

import android.util.Log
import android.content.Intent
import android.os.Build
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import github.hunmer.memento.TimerForegroundService
import github.hunmer.memento.ActivityForegroundService

import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "github.hunmer.memento/timer_service"
    private val WIDGET_CHANNEL = "github.hunmer.memento/widget"
    private val ACTIVITY_CHANNEL = "github.hunmer.memento/activity_notification"
    private val ENGINE_ID = "timer_engine"

    private var widgetMethodChannel: MethodChannel? = null
    private var pendingWidgetUrl: String? = null

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        // 处理启动时的 DeepLink
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // 处理新的 DeepLink
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        // 处理活动通知Intent
        val source = intent?.getStringExtra("source")
        val action = intent?.getStringExtra("action")
        val quickAction = intent?.getStringExtra("quickAction")

        if (source == "activity_notification") {
            Log.d("MainActivity", "Received activity notification: action=$action, quickAction=$quickAction")

            // 通过小组件通道发送活动通知点击事件到Flutter
            if (widgetMethodChannel != null) {
                widgetMethodChannel?.invokeMethod("onActivityNotificationClicked", mapOf(
                    "source" to source,
                    "action" to action,
                    "quickAction" to quickAction
                ))
            } else {
                // 如果widgetMethodChannel还没初始化，这里可以保存待处理的事件
                Log.w("MainActivity", "WidgetMethodChannel not initialized, activity notification event lost")
            }
        }

        // 处理DeepLink
        val uri: Uri? = intent?.data
        uri?.let {
            Log.d("MainActivity", "Received DeepLink: $it")

            // 如果 MethodChannel 已经初始化，直接发送；否则保存待发送
            if (widgetMethodChannel != null) {
                widgetMethodChannel?.invokeMethod("onWidgetClicked", it.toString())
            } else {
                pendingWidgetUrl = it.toString()
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        TimerForegroundService.flutterEngine = flutterEngine
        ActivityForegroundService.flutterEngine = flutterEngine

        // 初始化小组件 MethodChannel
        widgetMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL)

        // 处理活动通知点击事件
        widgetMethodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "onActivityNotificationClicked" -> {
                    // 这个方法由MainActivity内部调用，不需要处理返回值
                    Log.d("MainActivity", "Activity notification click handled")
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // 如果有待发送的 URL，现在发送
        pendingWidgetUrl?.let { url ->
            widgetMethodChannel?.invokeMethod("onWidgetClicked", url)
            pendingWidgetUrl = null
        }

        // 初始化活动通知 MethodChannel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ACTIVITY_CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "startActivityNotificationService" -> {
                    Log.d("MainActivity", "Starting activity notification service")
                    val intent = Intent(this, ActivityForegroundService::class.java).apply {
                        action = "START"
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(null)
                }
                "stopActivityNotificationService" -> {
                    Log.d("MainActivity", "Stopping activity notification service")
                    val intent = Intent(this, ActivityForegroundService::class.java)
                    stopService(intent)
                    result.success(null)
                }
                "updateActivityNotification" -> {
                    Log.d("MainActivity", "Updating activity notification")
                    val args = call.arguments as? Map<*, *>
                    val title = args?.get("title") as? String
                    val content = args?.get("content") as? String

                    val intent = Intent(this, ActivityForegroundService::class.java).apply {
                        action = "UPDATE"
                        putExtra("title", title)
                        putExtra("content", content)
                    }
                    startService(intent)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "startTimerService" -> {
                    val args = call.arguments as? Map<*, *>
                    val intent = Intent(this, TimerForegroundService::class.java).apply {
                        action = "START"
                        args?.let {
                            putExtra("taskId", it["taskId"] as? String)
                            putExtra("taskName", it["taskName"] as? String)
                            putExtra("subTimers", it["subTimers"] as? ArrayList<*>)
                            putExtra("currentSubTimerIndex", it["currentSubTimerIndex"] as? Int ?: -1)
                        }
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(null)
                }
                "updateTimerService" -> {
                    val args = call.arguments as? Map<*, *>
                    val intent = Intent(this, TimerForegroundService::class.java).apply {
                        action = "UPDATE"
                        args?.let {
                            putExtra("taskId", it["taskId"] as? String)
                            putExtra("taskName", it["taskName"] as? String)
                            putExtra("subTimers", it["subTimers"] as? ArrayList<*>)
                            putExtra("currentSubTimerIndex", it["currentSubTimerIndex"] as? Int ?: -1)
                        }
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(null)
                }
                "stopTimerService" -> {
                    Log.w("stopTimerService", "Stopping timer service")
                    val intent = Intent(this, TimerForegroundService::class.java)
                    stopService(intent)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}