package github.hunmer.memento

import android.util.Log
import android.content.Intent
import android.os.Build
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import github.hunmer.memento.TimerForegroundService

import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "github.hunmer.memento/timer_service"
    private val WIDGET_CHANNEL = "github.hunmer.memento/widget"
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

        // 初始化小组件 MethodChannel
        widgetMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL)

        // 如果有待发送的 URL，现在发送
        pendingWidgetUrl?.let { url ->
            widgetMethodChannel?.invokeMethod("onWidgetClicked", url)
            pendingWidgetUrl = null
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