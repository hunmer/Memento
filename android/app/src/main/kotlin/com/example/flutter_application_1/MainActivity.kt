package github.hunmer.memento

import android.content.Intent
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "github.hunmer.memento/timer_service"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startTimerService" -> {
                    val taskName = call.argument<String>("taskName")
                    val totalSeconds = call.argument<Int>("totalSeconds")
                    val currentSeconds = call.argument<Int>("currentSeconds")
                    startTimerService(taskName, totalSeconds, currentSeconds)
                    result.success(null)
                }
                "updateTimerService" -> {
                    val taskName = call.argument<String>("taskName")
                    val totalSeconds = call.argument<Int>("totalSeconds")
                    val currentSeconds = call.argument<Int>("currentSeconds")
                    updateTimerService(taskName, totalSeconds, currentSeconds)
                    result.success(null)
                }
                "stopTimerService" -> {
                    stopTimerService()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startTimerService(taskName: String?, totalSeconds: Int?, currentSeconds: Int?) {
        val serviceIntent = Intent(this, TimerForegroundService::class.java).apply {
            action = "START"
            putExtra("taskName", taskName)
            putExtra("totalSeconds", totalSeconds ?: 0)
            putExtra("currentSeconds", currentSeconds ?: 0)
        }
        startService(serviceIntent)
    }

    private fun updateTimerService(taskName: String?, totalSeconds: Int?, currentSeconds: Int?) {
        val serviceIntent = Intent(this, TimerForegroundService::class.java).apply {
            action = "UPDATE"
            putExtra("taskName", taskName)
            putExtra("totalSeconds", totalSeconds ?: 0)
            putExtra("currentSeconds", currentSeconds ?: 0)
        }
        startService(serviceIntent)
    }

    private fun stopTimerService() {
        val serviceIntent = Intent(this, TimerForegroundService::class.java).apply {
            action = "STOP"
        }
        startService(serviceIntent)
    }
}
