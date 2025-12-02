package github.hunmer.memento.widgets.services

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import com.example.memento_widgets.R
import github.hunmer.memento.widgets.providers.HabitTimerWidgetProvider
import org.json.JSONObject

/**
 * 习惯计时器前台服务
 *
 * 功能：
 * 1. 保持后台运行，即使屏幕关闭也能持续计时
 * 2. 每秒更新小组件显示
 * 3. 显示常驻通知栏，展示计时状态
 * 4. 支持通知栏快速控制（暂停/停止）
 */
class HabitTimerForegroundService : Service() {

    companion object {
        private const val TAG = "HabitTimerService"
        private const val CHANNEL_ID = "habit_timer_channel"
        private const val NOTIFICATION_ID = 1001

        // Intent Actions
        const val ACTION_START_TIMER = "ACTION_START_TIMER"
        const val ACTION_PAUSE_TIMER = "ACTION_PAUSE_TIMER"
        const val ACTION_STOP_TIMER = "ACTION_STOP_TIMER"
        const val ACTION_UPDATE_WIDGET = "ACTION_UPDATE_WIDGET"

        // Intent Extras
        const val EXTRA_WIDGET_ID = "EXTRA_WIDGET_ID"
        const val EXTRA_HABIT_ID = "EXTRA_HABIT_ID"
        const val EXTRA_HABIT_NAME = "EXTRA_HABIT_NAME"
        const val EXTRA_DURATION_MINUTES = "EXTRA_DURATION_MINUTES"

        private const val PREFS_NAME = "HomeWidgetPreferences"
    }

    private val handler = Handler(Looper.getMainLooper())
    private var updateRunnable: Runnable? = null
    private var isTimerRunning = false
    private var currentWidgetId: Int? = null
    private var currentHabitId: String? = null
    private var currentHabitName: String = "习惯计时"
    private var durationMinutes: Int = 25
    private var elapsedSeconds: Int = 0
    private var isCountdownMode: Boolean = true

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Service created")
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand: ${intent?.action}")

        when (intent?.action) {
            ACTION_START_TIMER -> {
                currentWidgetId = intent.getIntExtra(EXTRA_WIDGET_ID, -1)
                currentHabitId = intent.getStringExtra(EXTRA_HABIT_ID)
                currentHabitName = intent.getStringExtra(EXTRA_HABIT_NAME) ?: "习惯计时"
                durationMinutes = intent.getIntExtra(EXTRA_DURATION_MINUTES, 25)

                // 从SharedPreferences读取已有的计时状态
                loadTimerState()

                startTimer()
            }
            ACTION_PAUSE_TIMER -> {
                pauseTimer()
            }
            ACTION_STOP_TIMER -> {
                stopTimer()
            }
            ACTION_UPDATE_WIDGET -> {
                updateWidget()
            }
        }

        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "习惯计时器",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "显示习惯计时器的运行状态"
                setShowBadge(false)
            }

            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun startTimer() {
        if (isTimerRunning) {
            Log.d(TAG, "Timer already running")
            return
        }

        isTimerRunning = true
        Log.d(TAG, "Starting timer: $currentHabitName, duration: $durationMinutes min")

        // 启动前台服务
        startForeground(NOTIFICATION_ID, createNotification())

        // 启动定时更新
        updateRunnable = object : Runnable {
            override fun run() {
                if (isTimerRunning) {
                    elapsedSeconds++

                    // 检查是否到时间
                    val totalSeconds = durationMinutes * 60
                    if (isCountdownMode && elapsedSeconds >= totalSeconds) {
                        // 倒计时结束
                        completeTimer()
                        return
                    }

                    // 保存状态
                    saveTimerState()

                    // 更新通知
                    val notificationManager = getSystemService(NotificationManager::class.java)
                    notificationManager.notify(NOTIFICATION_ID, createNotification())

                    // 更新小组件
                    updateWidget()

                    // 继续下一秒
                    handler.postDelayed(this, 1000)
                }
            }
        }
        handler.post(updateRunnable!!)
    }

    private fun pauseTimer() {
        if (!isTimerRunning) return

        isTimerRunning = false
        Log.d(TAG, "Timer paused")

        // 停止定时更新
        updateRunnable?.let { handler.removeCallbacks(it) }

        // 保存状态
        saveTimerState()

        // 更新通知为暂停状态
        val notificationManager = getSystemService(NotificationManager::class.java)
        notificationManager.notify(NOTIFICATION_ID, createNotification())

        // 更新小组件
        updateWidget()
    }

    private fun stopTimer() {
        Log.d(TAG, "Timer stopped")

        isTimerRunning = false
        updateRunnable?.let { handler.removeCallbacks(it) }

        // 清除计时状态
        clearTimerState()

        // 停止前台服务
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun completeTimer() {
        Log.d(TAG, "Timer completed")

        isTimerRunning = false
        updateRunnable?.let { handler.removeCallbacks(it) }

        // 记录完成（这里可以通过广播通知Flutter端保存记录）
        val intent = Intent("github.hunmer.memento.widgets.HABIT_TIMER_COMPLETED")
        intent.putExtra("habitId", currentHabitId)
        intent.putExtra("durationSeconds", elapsedSeconds)
        sendBroadcast(intent)

        // 清除状态
        clearTimerState()

        // 更新小组件显示完成状态
        updateWidget()

        // 停止服务
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun createNotification(): Notification {
        val timeString = formatTime(elapsedSeconds, isCountdownMode, durationMinutes)
        val statusText = if (isTimerRunning) "计时中" else "已暂停"

        // 点击通知打开应用
        val openAppIntent = Intent(Intent.ACTION_VIEW).apply {
            data = android.net.Uri.parse("memento://habit_timer/open?habitId=$currentHabitId")
            setPackage("github.hunmer.memento")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openPendingIntent = PendingIntent.getActivity(
            this,
            0,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // 暂停/继续按钮
        val toggleAction = if (isTimerRunning) {
            val pauseIntent = Intent(this, HabitTimerForegroundService::class.java).apply {
                action = ACTION_PAUSE_TIMER
            }
            val pausePendingIntent = PendingIntent.getService(
                this,
                1,
                pauseIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            NotificationCompat.Action(
                android.R.drawable.ic_media_pause,
                "暂停",
                pausePendingIntent
            )
        } else {
            val resumeIntent = Intent(this, HabitTimerForegroundService::class.java).apply {
                action = ACTION_START_TIMER
                putExtra(EXTRA_WIDGET_ID, currentWidgetId ?: -1)
                putExtra(EXTRA_HABIT_ID, currentHabitId)
                putExtra(EXTRA_HABIT_NAME, currentHabitName)
                putExtra(EXTRA_DURATION_MINUTES, durationMinutes)
            }
            val resumePendingIntent = PendingIntent.getService(
                this,
                1,
                resumeIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            NotificationCompat.Action(
                android.R.drawable.ic_media_play,
                "继续",
                resumePendingIntent
            )
        }

        // 停止按钮
        val stopIntent = Intent(this, HabitTimerForegroundService::class.java).apply {
            action = ACTION_STOP_TIMER
        }
        val stopPendingIntent = PendingIntent.getService(
            this,
            2,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val stopAction = NotificationCompat.Action(
            android.R.drawable.ic_delete,
            "停止",
            stopPendingIntent
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("$currentHabitName - $statusText")
            .setContentText(timeString)
            .setSmallIcon(R.drawable.ic_timer_notification)
            .setOngoing(true)
            .setContentIntent(openPendingIntent)
            .addAction(toggleAction)
            .addAction(stopAction)
            .build()
    }

    private fun updateWidget() {
        if (currentWidgetId == null || currentWidgetId!! < 0) return

        try {
            val appWidgetManager = AppWidgetManager.getInstance(this)
            val componentName = ComponentName(this, HabitTimerWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)

            // 更新所有小组件（会自动过滤只更新当前计时的小组件）
            if (appWidgetIds.isNotEmpty()) {
                val intent = Intent(this, HabitTimerWidgetProvider::class.java)
                intent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetIds)
                sendBroadcast(intent)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to update widget", e)
        }
    }

    private fun loadTimerState() {
        if (currentWidgetId == null || currentWidgetId!! < 0) return

        try {
            val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val stateKey = "habit_timer_state_${currentWidgetId}"
            val stateJson = prefs.getString(stateKey, null)

            if (stateJson != null) {
                val state = JSONObject(stateJson)
                elapsedSeconds = state.optInt("elapsedSeconds", 0)
                isCountdownMode = state.optBoolean("isCountdown", true)
                isTimerRunning = state.optBoolean("isRunning", false)
                Log.d(TAG, "Loaded timer state: elapsed=$elapsedSeconds, countdown=$isCountdownMode, running=$isTimerRunning")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to load timer state", e)
        }
    }

    private fun saveTimerState() {
        if (currentWidgetId == null || currentWidgetId!! < 0) return

        try {
            val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val stateKey = "habit_timer_state_${currentWidgetId}"

            val state = JSONObject()
            state.put("elapsedSeconds", elapsedSeconds)
            state.put("isCountdown", isCountdownMode)
            state.put("isRunning", isTimerRunning)
            state.put("timestamp", System.currentTimeMillis())

            prefs.edit().putString(stateKey, state.toString()).apply()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to save timer state", e)
        }
    }

    private fun clearTimerState() {
        if (currentWidgetId == null || currentWidgetId!! < 0) return

        try {
            val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val stateKey = "habit_timer_state_${currentWidgetId}"
            prefs.edit().remove(stateKey).apply()

            // 同时清除待处理变更
            val pendingKey = "habit_timer_pending_changes"
            val pendingJson = prefs.getString(pendingKey, "{}")
            if (pendingJson != null && pendingJson != "{}") {
                val pending = JSONObject(pendingJson)
                if (currentHabitId != null && pending.has(currentHabitId!!)) {
                    pending.remove(currentHabitId!!)
                    prefs.edit().putString(pendingKey, pending.toString()).apply()
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to clear timer state", e)
        }
    }

    private fun formatTime(seconds: Int, isCountdown: Boolean, durationMinutes: Int): String {
        val displaySeconds = if (isCountdown) {
            (durationMinutes * 60 - seconds).coerceAtLeast(0)
        } else {
            seconds
        }

        val hours = displaySeconds / 3600
        val minutes = (displaySeconds % 3600) / 60
        val secs = displaySeconds % 60

        return if (hours > 0) {
            String.format("%d:%02d:%02d", hours, minutes, secs)
        } else {
            String.format("%02d:%02d", minutes, secs)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "Service destroyed")
        isTimerRunning = false
        updateRunnable?.let { handler.removeCallbacks(it) }
    }
}
