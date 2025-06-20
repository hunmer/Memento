package com.example.flutter_application_1

import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "github.hunmer.memento/timer_service"
    private val ALARM_PERMISSION_REQUEST_CODE = 1001
    private val ALARM_PERMISSIONS = arrayOf(
        "android.permission.SCHEDULE_EXACT_ALARM",
        "android.permission.USE_EXACT_ALARM",
    )
    private val NOTIFICATION_PERMISSION = "android.permission.POST_NOTIFICATIONS"
    private val NOTIFICATION_PERMISSION_REQUEST_CODE = 1002

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        checkAlarmPermissions()
        checkNotificationPermission()
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startTimerService" -> {
                    val taskId = call.argument<String>("taskId")
                    val taskName = call.argument<String>("taskName")
                    val totalSeconds = call.argument<Int>("totalSeconds")
                    val currentSeconds = call.argument<Int>("currentSeconds")
                    startTimerService(taskId, taskName, totalSeconds, currentSeconds)
                    result.success(null)
                }
                "updateTimerService" -> {
                    val taskId = call.argument<String>("taskId")
                    val taskName = call.argument<String>("taskName")
                    val totalSeconds = call.argument<Int>("totalSeconds")
                    val currentSeconds = call.argument<Int>("currentSeconds")
                    updateTimerService(taskId, taskName, totalSeconds, currentSeconds)
                    result.success(null)
                }
                "stopTimerService" -> {
                    val taskId = call.argument<String>("taskId")
                    stopTimerService(taskId)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun checkAlarmPermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val permissionsToRequest = ALARM_PERMISSIONS.filter {
                ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
            }.toTypedArray()

            if (permissionsToRequest.isNotEmpty()) {
                ActivityCompat.requestPermissions(
                    this,
                    permissionsToRequest,
                    ALARM_PERMISSION_REQUEST_CODE
                )
            }
        }
    }

    private fun checkNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, NOTIFICATION_PERMISSION) 
                != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(NOTIFICATION_PERMISSION),
                    NOTIFICATION_PERMISSION_REQUEST_CODE
                )
            }
        }
    }

    private fun startTimerService(taskId: String?, taskName: String?, totalSeconds: Int?, currentSeconds: Int?) {
        val serviceIntent = Intent(this, TimerForegroundService::class.java).apply {
            action = "START"
            putExtra("taskId", taskId)
            putExtra("taskName", taskName)
            putExtra("totalSeconds", totalSeconds ?: 0)
            putExtra("currentSeconds", currentSeconds ?: 0)
        }
        startService(serviceIntent)
    }

    private fun updateTimerService(taskId: String?, taskName: String?, totalSeconds: Int?, currentSeconds: Int?) {
        val serviceIntent = Intent(this, TimerForegroundService::class.java).apply {
            action = "UPDATE"
            putExtra("taskId", taskId)
            putExtra("taskName", taskName)
            putExtra("totalSeconds", totalSeconds ?: 0)
            putExtra("currentSeconds", currentSeconds ?: 0)
        }
        startService(serviceIntent)
    }

    private fun stopTimerService(taskId: String?) {
        val serviceIntent = Intent(this, TimerForegroundService::class.java).apply {
            action = "STOP"
            putExtra("taskId", taskId)
        }
        startService(serviceIntent)
    }
}