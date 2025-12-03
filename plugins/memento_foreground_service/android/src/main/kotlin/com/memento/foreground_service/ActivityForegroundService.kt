package com.memento.foreground_service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel

/**
 * 活动通知前台服务
 *
 * 显示活动提醒通知，支持快速记录活动。
 */
class ActivityForegroundService : Service() {
    companion object {
        private const val TAG = "ActivityForegroundService"
        private const val CHANNEL_ID = "ActivityForegroundServiceChannel"
        private const val NOTIFICATION_ID = 2001

        // FlutterPluginBinding 引用
        var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding? = null

        // 当前通知数据
        private var lastActivityTitle: String? = null
        private var lastActivityContent: String? = null
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
                "START" -> startActivityNotificationService()
                "STOP" -> stopActivityNotificationService()
                "UPDATE" -> {
                    val title = intent.getStringExtra("title")
                    val content = intent.getStringExtra("content")
                    updateActivityNotification(title, content)
                }
            }
        }

        return START_STICKY // 保持服务运行
    }

    private fun startActivityNotificationService() {
        Log.d(TAG, "Starting activity notification service")

        try {
            val notification = createActivityNotification(
                title = "活动记录提醒",
                content = "正在监控活动记录时间...",
                showPendingIntent = true
            )

            startForeground(NOTIFICATION_ID, notification)
            Log.d(TAG, "Foreground service started")
        } catch (e: Exception) {
            Log.e(TAG, "Error starting foreground service", e)
        }
    }

    private fun stopActivityNotificationService() {
        Log.d(TAG, "Stopping activity notification service")

        try {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            notificationManager?.cancel(NOTIFICATION_ID)

            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()

            Log.d(TAG, "Foreground service stopped")
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping foreground service", e)
        }
    }

    private fun updateActivityNotification(title: String?, content: String?) {
        try {
            lastActivityTitle = title
            lastActivityContent = content

            Log.d(TAG, "Updating notification: title=$title, content=$content")

            val notification = createActivityNotification(
                title = title ?: "活动记录提醒",
                content = content ?: "正在监控活动记录时间...",
                showPendingIntent = true
            )

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                ?: throw IllegalStateException("NotificationManager not available")

            notificationManager.notify(NOTIFICATION_ID, notification)
            Log.d(TAG, "Notification updated successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Error updating notification", e)
        }
    }

    private fun createActivityNotification(
        title: String,
        content: String,
        showPendingIntent: Boolean = false
    ): Notification {
        val style = NotificationCompat.BigTextStyle()
            .bigText(content)
            .setBigContentTitle(title)
            .setSummaryText("点击快速记录活动")

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(content)
            .setSmallIcon(getNotificationIcon())
            .setStyle(style)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .setAutoCancel(false)
            .setShowWhen(false)

        if (showPendingIntent) {
            // 获取主应用的启动 Intent
            val launchIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("source", "activity_notification")
                putExtra("action", "open_activity_form")
            }

            launchIntent?.let {
                val pendingIntent = PendingIntent.getActivity(
                    this,
                    0,
                    it,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                builder.setContentIntent(pendingIntent)
            }

            // 添加快速操作按钮
            val openFormIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("source", "activity_notification")
                putExtra("action", "open_activity_form")
                putExtra("quick_action", "record")
            }

            openFormIntent?.let {
                val openFormPendingIntent = PendingIntent.getActivity(
                    this,
                    1,
                    it,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                builder.addAction(
                    getNotificationIcon(),
                    "记录活动",
                    openFormPendingIntent
                )
            }

            // 添加忽略按钮
            val dismissIntent = Intent(this, ActivityForegroundService::class.java).apply {
                action = "STOP"
            }

            val dismissPendingIntent = PendingIntent.getService(
                this,
                2,
                dismissIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            builder.addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                "忽略",
                dismissPendingIntent
            )
        }

        return builder.build()
    }

    private fun getNotificationIcon(): Int {
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

        return try {
            applicationInfo.icon
        } catch (e: Exception) {
            android.R.drawable.ic_notification_overlay
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "活动提醒服务",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "显示距离上次活动的时间和快速记录入口"
                enableLights(false)
                enableVibration(false)
                setShowBadge(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
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

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        notificationManager?.cancel(NOTIFICATION_ID)
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        Log.d(TAG, "Task removed")
        stopSelf()
    }
}
