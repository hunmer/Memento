package com.example.flutter_application_1

import android.app.*
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import android.content.Context
import android.content.pm.ServiceInfo

class TimerForegroundService : Service() {
    private val CHANNEL_ID = "timer_service_channel"
    private val NOTIFICATION_ID_BASE = 1000
    private val activeTimers = mutableMapOf<String, Int>()

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            "START" -> {
                val taskId = intent.getStringExtra("taskId") ?: return START_NOT_STICKY
                val taskName = intent.getStringExtra("taskName") ?: "Timer"
                val totalSeconds = intent.getIntExtra("totalSeconds", 0)
                val currentSeconds = intent.getIntExtra("currentSeconds", 0)
                startTimer(taskId, taskName, totalSeconds, currentSeconds)
            }
            "UPDATE" -> {
                val taskId = intent.getStringExtra("taskId") ?: return START_NOT_STICKY
                val taskName = intent.getStringExtra("taskName") ?: "Timer"
                val totalSeconds = intent.getIntExtra("totalSeconds", 0)
                val currentSeconds = intent.getIntExtra("currentSeconds", 0)
                updateTimer(taskId, taskName, totalSeconds, currentSeconds)
            }
            "STOP" -> {
                val taskId = intent.getStringExtra("taskId") ?: return START_NOT_STICKY
                stopTimer(taskId)
            }
        }
        return START_NOT_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Timer Service Channel",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows timer progress"
                setSound(null, null)
            }
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun startTimer(taskId: String, taskName: String, totalSeconds: Int, currentSeconds: Int) {
        val notificationId = NOTIFICATION_ID_BASE + activeTimers.size
        activeTimers[taskId] = notificationId
        val notification = createNotification(taskName, totalSeconds, currentSeconds)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(notificationId, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
        } else {
            startForeground(notificationId, notification)
        }
    }

    private fun updateTimer(taskId: String, taskName: String, totalSeconds: Int, currentSeconds: Int) {
        val notificationId = activeTimers[taskId] ?: return
        val notification = createNotification(taskName, totalSeconds, currentSeconds)
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(notificationId, notification)
    }

    private fun stopTimer(taskId: String) {
        val notificationId = activeTimers.remove(taskId) ?: return
        stopForeground(STOP_FOREGROUND_REMOVE)
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(notificationId)
        if (activeTimers.isEmpty()) {
            stopSelf()
        }
    }

    private fun createNotification(taskName: String, totalSeconds: Int, currentSeconds: Int): Notification {
        val progress = if (totalSeconds > 0) ((currentSeconds.toFloat() / totalSeconds.toFloat()) * 100).toInt() else 0
        
        val timeLeft = formatTime(totalSeconds - currentSeconds)
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(taskName)
            .setContentText("Time remaining: $timeLeft")
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setProgress(100, progress, false)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun formatTime(seconds: Int): String {
        val hours = seconds / 3600
        val minutes = (seconds % 3600) / 60
        val secs = seconds % 60
        return when {
            hours > 0 -> String.format("%d:%02d:%02d", hours, minutes, secs)
            else -> String.format("%02d:%02d", minutes, secs)
        }
    }

    private fun stopAllTimers() {
        for (notificationId in activeTimers.values) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.cancel(notificationId)
        }
        activeTimers.clear()
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}