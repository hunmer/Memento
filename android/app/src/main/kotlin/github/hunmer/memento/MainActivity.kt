package github.hunmer.memento

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import github.hunmer.memento.TimerForegroundService

import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "github.hunmer.memento/timer_service"
    private val ENGINE_ID = "timer_engine"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        TimerForegroundService.flutterEngine = flutterEngine
        
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
                            putExtra("totalSeconds", it["totalSeconds"] as? Int ?: 0)
                            putExtra("currentSeconds", it["currentSeconds"] as? Int ?: 0)
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
                            putExtra("totalSeconds", it["totalSeconds"] as? Int ?: 0)
                            putExtra("currentSeconds", it["currentSeconds"] as? Int ?: 0)
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
                    val intent = Intent(this, TimerForegroundService::class.java)
                    stopService(intent)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}