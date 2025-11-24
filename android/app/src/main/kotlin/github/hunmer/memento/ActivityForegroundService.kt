package github.hunmer.memento

import android.app.Service
import android.content.Intent
import android.os.IBinder
import androidx.core.app.NotificationCompat
import android.app.Notification
import android.app.NotificationManager
import android.app.NotificationChannel
import android.os.Build
import android.app.PendingIntent
import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Bundle
import android.util.Log
import github.hunmer.memento.R

class ActivityForegroundService : Service() {
    private lateinit var methodChannel: MethodChannel

    companion object {
        const val CHANNEL_NAME = "github.hunmer.memento/activity_service"
        lateinit var flutterEngine: FlutterEngine
        private const val CHANNEL_ID = "ActivityForegroundServiceChannel"
        private const val NOTIFICATION_ID = 2001

        // 当前通知数据
        private var lastActivityTitle: String? = null
        private var lastActivityContent: String? = null
        private var timeSinceLastActivity: String? = null
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("ActivityForegroundService", "onStartCommand called")

        // 重新初始化MethodChannel以确保每次服务启动都能正确处理
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startActivityNotificationService" -> {
                    startActivityNotificationService()
                    result.success(null)
                }
                "stopActivityNotificationService" -> {
                    stopActivityNotificationService()
                    result.success(null)
                }
                "updateActivityNotification" -> {
                    val args = call.arguments as? Map<*, *>
                    val title = args?.get("title") as? String
                    val content = args?.get("content") as? String
                    updateActivityNotification(title, content)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // 处理Intent动作
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
        Log.d("ActivityForegroundService", "Starting activity notification service")

        try {
            // 创建基础通知
            val notification = createActivityNotification(
                title = "活动记录提醒",
                content = "正在监控活动记录时间...",
                showPendingIntent = true
            )

            // 启动前台服务
            startForeground(NOTIFICATION_ID, notification)
            Log.d("ActivityForegroundService", "Foreground service started")

        } catch (e: Exception) {
            Log.e("ActivityForegroundService", "Error starting foreground service", e)
        }
    }

    private fun stopActivityNotificationService() {
        Log.d("ActivityForegroundService", "Stopping activity notification service")

        try {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            notificationManager?.cancel(NOTIFICATION_ID)

            // 停止前台服务
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()

            Log.d("ActivityForegroundService", "Foreground service stopped")
        } catch (e: Exception) {
            Log.e("ActivityForegroundService", "Error stopping foreground service", e)
        }
    }

    private fun updateActivityNotification(title: String?, content: String?) {
        try {
            // 更新内部状态
            lastActivityTitle = title
            lastActivityContent = content
            timeSinceLastActivity = content // 简化处理，实际可以解析具体时间

            Log.d("ActivityForegroundService", "Updating notification: title=$title, content=$content")

            val notification = createActivityNotification(
                title = title ?: "活动记录提醒",
                content = content ?: "正在监控活动记录时间...",
                showPendingIntent = true
            )

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                ?: throw IllegalStateException("NotificationManager not available")

            notificationManager.notify(NOTIFICATION_ID, notification)
            Log.d("ActivityForegroundService", "Notification updated successfully")

        } catch (e: Exception) {
            Log.e("ActivityForegroundService", "Error updating notification", e)
        }
    }

    private fun createActivityNotification(
        title: String,
        content: String,
        showPendingIntent: Boolean = false
    ): Notification {
        // 创建通知样式
        val style = NotificationCompat.BigTextStyle()
            .bigText(content)
            .setBigContentTitle(title)
            .setSummaryText("点击快速记录活动")

        // 构建通知
        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(content)
            .setSmallIcon(R.drawable.launcher_icon)
            .setStyle(style)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true) // 常驻通知
            .setOnlyAlertOnce(true) // 只提醒一次
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .setAutoCancel(false) // 不自动消失
            .setShowWhen(false) // 不显示时间

        // 添加点击跳转意图
        if (showPendingIntent) {
            // 创建打开MainActivity的意图，并带上活动通知参数
            val notificationIntent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("source", "activity_notification")
                putExtra("action", "open_activity_form")
            }

            val pendingIntent = PendingIntent.getActivity(
                this,
                0,
                notificationIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            builder.setContentIntent(pendingIntent)

            // 添加快速操作按钮
            val openFormIntent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("source", "activity_notification")
                putExtra("action", "open_activity_form")
                putExtra("quick_action", "record")
            }

            val openFormPendingIntent = PendingIntent.getActivity(
                this,
                1,
                openFormIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

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
                R.drawable.launcher_icon,
                "记录活动",
                openFormPendingIntent
            ).addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                "忽略",
                dismissPendingIntent
            )
        }

        return builder.build()
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
            Log.d("ActivityForegroundService", "Notification channel created")
        }
    }

    override fun onCreate() {
        super.onCreate()
        Log.d("ActivityForegroundService", "Service created")
        createNotificationChannel()
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d("ActivityForegroundService", "Service destroyed")

        // 清理通知
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        notificationManager?.cancel(NOTIFICATION_ID)
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        Log.d("ActivityForegroundService", "Task removed")

        // 当任务被移除时，可以选择重启服务或清理
        // 这里我们选择清理，因为通知服务应该由Flutter层管理生命周期
        stopSelf()
    }
}