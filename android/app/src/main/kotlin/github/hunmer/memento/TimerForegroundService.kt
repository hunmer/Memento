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
import kotlin.math.abs

class TimerForegroundService : Service() {
    private lateinit var methodChannel: MethodChannel

    companion object {
        const val CHANNEL_NAME = "github.hunmer.memento/timer_service"
        lateinit var flutterEngine: FlutterEngine

        // 存储所有活动计时器的通知ID
        private val activeTimerNotificationIds = mutableMapOf<String, Int>()

        // 获取或创建通知ID
        fun getOrCreateNotificationId(timerId: String): Int {
            return activeTimerNotificationIds.getOrPut(timerId) {
                abs(timerId.hashCode()) % 90000 + 10000 // 5位数字ID (10000-99999)
            }
        }
    }

    private val CHANNEL_ID = "TimerForegroundServiceChannel"
    private val TIMER_CHANNEL_ID = "TimerMultiNotificationChannel"

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("TimerForegroundService", "onStartCommand called")

        // 重新初始化MethodChannel以确保每次服务启动都能正确处理
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                // 兼容旧版本API（单个计时器）
                "startTimerService" -> {
                    val args = call.arguments as? Map<*, *>
                    val intent = Intent(this, TimerForegroundService::class.java).apply {
                        action = "START"
                        args?.let {
                            putExtra("taskId", it["taskId"] as? String ?: "default_timer")
                            putExtra("taskName", it["taskName"] as? String ?: "Memento Timer")
                            putExtra("subTimers", it["subTimers"] as? ArrayList<*>)
                            putExtra("currentSubTimerIndex", it["currentSubTimerIndex"] as? Int ?: -1)
                        }
                    }
                    startService(intent)
                    result.success(null)
                }
                "updateTimerService" -> {
                    val args = call.arguments as? Map<*, *>
                    val intent = Intent(this, TimerForegroundService::class.java).apply {
                        action = "UPDATE"
                        args?.let {
                            putExtra("taskId", it["taskId"] as? String ?: "default_timer")
                            putExtra("taskName", it["taskName"] as? String ?: "Memento Timer")
                            putExtra("subTimers", it["subTimers"] as? ArrayList<*>)
                            putExtra("currentSubTimerIndex", it["currentSubTimerIndex"] as? Int ?: -1)
                        }
                    }
                    startService(intent)
                    result.success(null)
                }
                "stopTimerService" -> {
                    val intent = Intent(this, TimerForegroundService::class.java).apply {
                        action = "STOP"
                        putExtra("taskId", "default_timer")
                    }
                    stopService(intent)
                    result.success(null)
                }

                // 新API：多计时器支持
                "startMultipleTimerService" -> {
                    val args = call.arguments as? Map<*, *>
                    val timerId = args?.get("timerId") as? String
                    val taskName = args?.get("taskName") as? String
                    val content = args?.get("content") as? String
                    val progress = args?.get("progress") as? Int ?: 0
                    val maxProgress = args?.get("maxProgress") as? Int ?: 100
                    val color = args?.get("color") as? Int ?: 0xFFFF9800.toInt()

                    if (timerId != null) {
                        startMultipleTimer(timerId, taskName ?: "Memento Timer", content ?: "", progress, maxProgress, color)
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGUMENTS", "timerId is required", null)
                    }
                }
                "updateMultipleTimerService" -> {
                    val args = call.arguments as? Map<*, *>
                    val timerId = args?.get("timerId") as? String
                    val content = args?.get("content") as? String
                    val progress = args?.get("progress") as? Int ?: 0
                    val maxProgress = args?.get("maxProgress") as? Int ?: 100

                    if (timerId != null) {
                        updateMultipleTimer(timerId, content ?: "", progress, maxProgress)
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGUMENTS", "timerId is required", null)
                    }
                }
                "stopMultipleTimerService" -> {
                    val args = call.arguments as? Map<*, *>
                    val timerId = args?.get("timerId") as? String

                    if (timerId != null) {
                        stopMultipleTimer(timerId)
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGUMENTS", "timerId is required", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // 处理Intent动作
        intent?.action?.let { action ->
            when (action) {
                "START" -> {
                    val taskId = intent.getStringExtra("taskId") ?: "default_timer"
                    val taskName = intent.getStringExtra("taskName") ?: "Memento Timer"
                    val subTimers = intent.getSerializableExtra("subTimers") as? ArrayList<*>
                    val currentSubTimerIndex = intent.getIntExtra("currentSubTimerIndex", -1)
                    startTimerService(Bundle().apply {
                        putString("taskId", taskId)
                        putString("taskName", taskName)
                        putSerializable("subTimers", subTimers)
                        putInt("currentSubTimerIndex", currentSubTimerIndex)
                    })
                }
                "UPDATE" -> {
                    val taskId = intent.getStringExtra("taskId") ?: "default_timer"
                    val taskName = intent.getStringExtra("taskName") ?: "Memento Timer"
                    val subTimers = intent.getSerializableExtra("subTimers") as? ArrayList<*>
                    val currentSubTimerIndex = intent.getIntExtra("currentSubTimerIndex", -1)
                    Log.w("TimerForegroundService", "UPDATE called with taskId: $taskId")
                    updateTimerService(Bundle().apply {
                        putString("taskId", taskId)
                        putString("taskName", taskName)
                        putSerializable("subTimers", subTimers)
                        putInt("currentSubTimerIndex", currentSubTimerIndex)
                    })
                }
                "STOP" -> {
                    val taskId = intent.getStringExtra("taskId") ?: "default_timer"
                    stopTimerService(Bundle().apply {
                        putString("taskId", taskId)
                    })
                }
            }
        }

        return START_NOT_STICKY
    }

    private fun extractTimerParams(args: Bundle?): TimerParams? {
        return args?.let {
            TimerParams(
                taskId = it.getString("taskId"),
                taskName = it.getString("taskName"),
                subTimers = it.getSerializable("subTimers") as? ArrayList<*>,
                currentSubTimerIndex = it.getInt("currentSubTimerIndex", -1)
            )
        }
    }

    private fun createTimerNotification(params: TimerParams, withPendingIntent: Boolean = false): Notification {
        val currentSubTimer = params.subTimers?.getOrNull(params.currentSubTimerIndex) as? Map<*, *>
        val currentName = currentSubTimer?.get("name") as? String ?: "Current Task"
        val duration = currentSubTimer?.get("duration") as? Int ?: 0
        val current = currentSubTimer?.get("current") as? Int ?: 0
        val progress = if (duration > 0) (current.toFloat() / duration.toFloat() * 100).toInt() else 0

        fun formatTime(seconds: Int): String {
            val minutes = seconds / 60
            val secs = seconds % 60
            return String.format("%d:%02d", minutes, secs)
        }

        val currentFormatted = formatTime(current)
        val durationFormatted = formatTime(duration)

        val progressStyle = NotificationCompat.BigTextStyle()
            .bigText(buildSubTimersText(params.subTimers, params.currentSubTimerIndex))
            .setBigContentTitle(params.taskName ?: "Memento Timer")
            .setSummaryText("$currentName: $currentFormatted/$durationFormatted")

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(params.taskName ?: "Memento Timer")
            .setContentText("$currentName: $currentFormatted/$durationFormatted")
            .setSmallIcon(R.drawable.launcher_icon)
            .setStyle(progressStyle)
            .setProgress(100, progress, false)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)

        if (withPendingIntent) {
            val notificationIntent = Intent(this, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                this,
                0, notificationIntent, PendingIntent.FLAG_IMMUTABLE
            )
            builder.setContentIntent(pendingIntent)
        }

        return builder.build()
    }

    private fun startTimerService(args: Bundle?) {
        Log.d("TimerForegroundService", "startTimerService called")
        extractTimerParams(args)?.let { params ->
            val notification = createTimerNotification(params, withPendingIntent = true)
            val notificationId = getOrCreateNotificationId(params.taskId ?: "default_timer")
            startForeground(notificationId, notification)
            Log.d("TimerForegroundService", "Started foreground notification with ID: $notificationId")
        }
    }

    private fun updateTimerService(args: Bundle?) {
        try {
            val params = extractTimerParams(args) ?: run {
                Log.e("TimerService", "Bundle missing required parameters: $args")
                return
            }

            Log.d("TimerService", "Updating notification for task: ${params.taskName}")
            val notification = createTimerNotification(params)
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                ?: throw IllegalStateException("NotificationManager not available")

            val timerId = params.taskId ?: "default_timer"
            val notificationId = getOrCreateNotificationId(timerId)
            Log.d("TimerService", "Updating notification with ID: $notificationId for timer: $timerId")
            notificationManager.notify(notificationId, notification)
            Log.d("TimerService", "Notification updated successfully")

        } catch (e: Exception) {
            Log.e("TimerService", "Error in updateTimerService", e)
        }
    }

    private data class TimerParams(
        val taskId: String?,
        val taskName: String?,
        val subTimers: ArrayList<*>?,
        val currentSubTimerIndex: Int
    )

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

    private fun stopTimerService(args: Bundle?) {
        Log.d("TimerForegroundService", "stopTimerService called")
        val taskId = args?.getString("taskId") ?: "default_timer"
        stopMultipleTimer(taskId)
    }

    // ========== 新增：多计时器支持方法 ==========

    /**
     * 启动多个计时器中的一个
     */
    private fun startMultipleTimer(
        timerId: String,
        title: String,
        content: String,
        progress: Int,
        maxProgress: Int,
        color: Int
    ) {
        Log.d("TimerForegroundService", "Starting multiple timer: $timerId")

        val notification = createMultipleTimerNotification(
            timerId = timerId,
            title = title,
            content = content,
            progress = progress,
            maxProgress = maxProgress,
            color = color
        )

        val notificationId = getOrCreateNotificationId(timerId)
        startForeground(notificationId, notification)
        activeTimerNotificationIds[timerId] = notificationId

        Log.d("TimerForegroundService", "Started timer $timerId with notification ID: $notificationId")
    }

    /**
     * 更新多个计时器中的一个
     */
    private fun updateMultipleTimer(
        timerId: String,
        content: String,
        progress: Int,
        maxProgress: Int
    ) {
        try {
            Log.d("TimerForegroundService", "Updating timer: $timerId")

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                ?: throw IllegalStateException("NotificationManager not available")

            val notificationId = getOrCreateNotificationId(timerId)
            val timerState = getTimerState(timerId) ?: run {
                Log.w("TimerForegroundService", "Timer $timerId not found, ignoring update")
                return
            }

            val notification = createMultipleTimerNotification(
                timerId = timerId,
                title = timerState.title,
                content = content,
                progress = progress,
                maxProgress = maxProgress,
                color = timerState.color
            )

            notificationManager.notify(notificationId, notification)
            Log.d("TimerForegroundService", "Updated timer $timerId with notification ID: $notificationId")

        } catch (e: Exception) {
            Log.e("TimerForegroundService", "Error updating timer $timerId", e)
        }
    }

    /**
     * 停止多个计时器中的一个
     */
    private fun stopMultipleTimer(timerId: String) {
        Log.d("TimerForegroundService", "Stopping timer: $timerId")

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        val notificationId = activeTimerNotificationIds[timerId]

        if (notificationId != null) {
            notificationManager?.cancel(notificationId)
            activeTimerNotificationIds.remove(timerId)
            removeTimerState(timerId)
            Log.d("TimerForegroundService", "Stopped timer $timerId, notification ID: $notificationId")
        }

        // 如果没有活动计时器了，可以选择停止服务
        if (activeTimerNotificationIds.isEmpty()) {
            Log.d("TimerForegroundService", "No active timers remaining")
            // 注意：这里不直接stopSelf()，因为服务可能被其他组件需要
        }
    }

    /**
     * 创建多计时器通知
     */
    private fun createMultipleTimerNotification(
        timerId: String,
        title: String,
        content: String,
        progress: Int,
        maxProgress: Int,
        color: Int
    ): Notification {
        val progressPercent = if (maxProgress > 0) (progress * 100 / maxProgress) else 0

        // 创建大文本样式
        val bigTextStyle = NotificationCompat.BigTextStyle()
            .bigText(content)
            .setBigContentTitle(title)
            .setSummaryText("$progress / $maxProgress")

        val builder = NotificationCompat.Builder(this, TIMER_CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(content)
            .setSmallIcon(R.drawable.launcher_icon)
            .setStyle(bigTextStyle)
            .setProgress(maxProgress, progress, false)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .setColor(color)

        // 添加点击事件，点击通知打开应用
        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            getOrCreateNotificationId(timerId),
            notificationIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        builder.setContentIntent(pendingIntent)

        return builder.build()
    }

    // 简单的内存缓存，存储计时器状态
    private val timerStates = mutableMapOf<String, TimerState>()

    private data class TimerState(
        val title: String,
        val color: Int
    )

    private fun getTimerState(timerId: String): TimerState? = timerStates[timerId]

    private fun putTimerState(timerId: String, state: TimerState) {
        timerStates[timerId] = state
    }

    private fun removeTimerState(timerId: String) {
        timerStates.remove(timerId)
    }

    // 修改startMultipleTimer方法以保存状态
    private fun startMultipleTimer(
        timerId: String,
        title: String,
        content: String,
        progress: Int,
        maxProgress: Int,
        color: Int
    ) {
        Log.d("TimerForegroundService", "Starting multiple timer: $timerId")

        // 保存计时器状态
        putTimerState(timerId, TimerState(title = title, color = color))

        val notification = createMultipleTimerNotification(
            timerId = timerId,
            title = title,
            content = content,
            progress = progress,
            maxProgress = maxProgress,
            color = color
        )

        val notificationId = getOrCreateNotificationId(timerId)
        startForeground(notificationId, notification)
        activeTimerNotificationIds[timerId] = notificationId

        Log.d("TimerForegroundService", "Started timer $timerId with notification ID: $notificationId")
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // 原频道（兼容旧版本）
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "Timer Foreground Service Channel",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Channel for single timer notifications"
                enableLights(true)
                enableVibration(true)
                setShowBadge(true)
            }

            // 新频道（多计时器支持）
            val timerChannel = NotificationChannel(
                TIMER_CHANNEL_ID,
                "Multi Timer Notifications",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Channel for multiple timer notifications"
                enableLights(true)
                enableVibration(false) // 多通知栏时振动会很烦人
                setShowBadge(true)
                setSound(null, null) // 禁用声音
            }

            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(serviceChannel)
            manager.createNotificationChannel(timerChannel)
            Log.d("TimerService", "Notification channels created")
        }
    }

    override fun onCreate() {
        super.onCreate()
        Log.d("TimerService", "Service created")
        createNotificationChannel()
    }
}
