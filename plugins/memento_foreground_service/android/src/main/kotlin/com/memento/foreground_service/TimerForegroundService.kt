package com.memento.foreground_service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin

/**
 * 计时器前台服务
 *
 * 显示计时器进度通知，支持子任务进度管理。
 */
class TimerForegroundService : Service() {
    companion object {
        private const val TAG = "TimerForegroundService"
        private const val CHANNEL_ID = "TimerForegroundServiceChannel"
        private const val NOTIFICATION_ID_BASE = 1000

        // FlutterPluginBinding 引用
        var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding? = null
    }

    private var currentNotificationId = NOTIFICATION_ID_BASE
    private var activeNotificationId: Int? = null

    private fun getNextNotificationId(): Int {
        activeNotificationId = currentNotificationId
        return currentNotificationId++
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Service created")
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand called with action: ${intent?.action}")

        intent?.action?.let { action ->
            when (action) {
                "START" -> {
                    val params = extractTimerParams(intent)
                    startTimerService(params)
                }
                "UPDATE" -> {
                    val params = extractTimerParams(intent)
                    updateTimerService(params)
                }
                "STOP" -> {
                    stopTimerService()
                }
            }
        }

        return START_NOT_STICKY
    }

    private fun extractTimerParams(intent: Intent): TimerParams {
        return TimerParams(
            taskId = intent.getStringExtra("taskId"),
            taskName = intent.getStringExtra("taskName"),
            subTimers = intent.getSerializableExtra("subTimers") as? ArrayList<*>,
            currentSubTimerIndex = intent.getIntExtra("currentSubTimerIndex", -1)
        )
    }

    private fun startTimerService(params: TimerParams) {
        Log.d(TAG, "Starting timer service for task: ${params.taskName}")
        val notification = createTimerNotification(params, withPendingIntent = true)
        startForeground(getNextNotificationId(), notification)
    }

    private fun updateTimerService(params: TimerParams) {
        try {
            Log.d(TAG, "Updating notification for task: ${params.taskName}")
            val notification = createTimerNotification(params)
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                ?: throw IllegalStateException("NotificationManager not available")

            val notificationId = activeNotificationId ?: getNextNotificationId()
            notificationManager.notify(notificationId, notification)
            Log.d(TAG, "Notification updated successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Error updating timer service", e)
        }
    }

    private fun stopTimerService() {
        Log.d(TAG, "Stopping timer service")
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        activeNotificationId?.let { id ->
            notificationManager?.cancel(id)
            activeNotificationId = null
        }
    }

    private fun createTimerNotification(params: TimerParams, withPendingIntent: Boolean = false): Notification {
        val currentSubTimer = params.subTimers?.getOrNull(params.currentSubTimerIndex) as? Map<*, *>
        val currentName = currentSubTimer?.get("name") as? String ?: "Current Task"
        val duration = currentSubTimer?.get("duration") as? Int ?: 0
        val current = currentSubTimer?.get("current") as? Int ?: 0
        val progress = if (duration > 0) (current.toFloat() / duration.toFloat() * 100).toInt() else 0

        val currentFormatted = formatTime(current)
        val durationFormatted = formatTime(duration)

        val progressStyle = NotificationCompat.BigTextStyle()
            .bigText(buildSubTimersText(params.subTimers, params.currentSubTimerIndex))
            .setBigContentTitle(params.taskName ?: "Memento Timer")
            .setSummaryText("$currentName: $currentFormatted/$durationFormatted")

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(params.taskName ?: "Memento Timer")
            .setContentText("$currentName: $currentFormatted/$durationFormatted")
            .setSmallIcon(getNotificationIcon())
            .setStyle(progressStyle)
            .setProgress(100, progress, false)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)

        if (withPendingIntent) {
            // 获取主应用的启动 Intent
            val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
            launchIntent?.let {
                val pendingIntent = PendingIntent.getActivity(
                    this,
                    0,
                    it,
                    PendingIntent.FLAG_IMMUTABLE
                )
                builder.setContentIntent(pendingIntent)
            }
        }

        return builder.build()
    }

    private fun getNotificationIcon(): Int {
        // 尝试从 meta-data 获取图标资源
        try {
            val appInfo = packageManager.getApplicationInfo(
                packageName,
                android.content.pm.PackageManager.GET_META_DATA
            )
            val iconResId = appInfo.metaData?.getInt("com.memento.foreground_service.NOTIFICATION_ICON", 0) ?: 0
            if (iconResId != 0) return iconResId
        } catch (e: Exception) {
            Log.w(TAG, "Failed to get notification icon from meta-data", e)
        }

        // 尝试获取应用图标
        return try {
            applicationInfo.icon
        } catch (e: Exception) {
            android.R.drawable.ic_notification_overlay
        }
    }

    private fun formatTime(seconds: Int): String {
        val minutes = seconds / 60
        val secs = seconds % 60
        return String.format("%d:%02d", minutes, secs)
    }

    private fun buildSubTimersText(subTimers: ArrayList<*>?, currentIndex: Int): String {
        if (subTimers == null || subTimers.isEmpty()) return "No sub-timers"

        val builder = StringBuilder()
        for (i in subTimers.indices) {
            val timer = subTimers[i] as? HashMap<*, *>
            val name = timer?.get("name") as? String ?: "Unknown"
            val completed = timer?.get("completed") as? Boolean ?: false

            builder.append(if (i == currentIndex) "➤ " else "  ")
            builder.append(if (completed) "✓ " else "○ ")
            builder.append(name)

            if (i < subTimers.size - 1) {
                builder.append("\n")
            }
        }
        return builder.toString()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "Timer Foreground Service Channel",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Channel for timer notifications"
                enableLights(true)
                enableVibration(true)
                setShowBadge(true)
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(serviceChannel)
            Log.d(TAG, "Notification channel created")
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "Service destroyed")
    }

    private data class TimerParams(
        val taskId: String?,
        val taskName: String?,
        val subTimers: ArrayList<*>?,
        val currentSubTimerIndex: Int
    )
}
