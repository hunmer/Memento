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

class TimerForegroundService : Service() {
    private lateinit var methodChannel: MethodChannel

    companion object {
        const val CHANNEL_NAME = "github.hunmer.memento/timer_service"
        lateinit var flutterEngine: FlutterEngine
    }
    private val CHANNEL_ID = "TimerForegroundServiceChannel"
    private var currentNotificationId = 1
    private var activeNotificationId: Int? = null
    private fun getNextNotificationId(): Int {
        activeNotificationId = currentNotificationId
        return currentNotificationId++
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("TimerForegroundService", "onStartCommand called")      
        // 重新初始化MethodChannel以确保每次服务启动都能正确处理
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        methodChannel.setMethodCallHandler { call, result ->
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
                    startService(intent)
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
                    startService(intent)
                    result.success(null)
                }
                "stopTimerService" -> {
                    val intent = Intent(this, TimerForegroundService::class.java).apply {
                        action = "STOP"
                    }
                    stopService(intent)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        
        // 处理Intent动作
        intent?.action?.let { action ->
            when (action) {
                "START" -> {
                    val taskId = intent.getStringExtra("taskId")
                    val taskName = intent.getStringExtra("taskName")
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
                    val taskId = intent.getStringExtra("taskId")
                    val taskName = intent.getStringExtra("taskName")
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
                    val taskId = intent.getStringExtra("taskId")
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

        val progressStyle = NotificationCompat.BigTextStyle()
            .bigText(buildSubTimersText(params.subTimers, params.currentSubTimerIndex))
            .setBigContentTitle(params.taskName ?: "Memento Timer")
            .setSummaryText("$currentName: $current/$duration")

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(params.taskName ?: "Memento Timer")
            .setContentText("$currentName: $current/$duration")
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
        Log.d("TimerForegroundService", "startTimerService called2")
        extractTimerParams(args)?.let { params ->
            val notification = createTimerNotification(params, withPendingIntent = true)
            startForeground(getNextNotificationId(), notification)
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
            
            val notificationId = activeNotificationId ?: getNextNotificationId()
            Log.d("TimerService", "Updating notification with ID: $notificationId")
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
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        activeNotificationId?.let { id ->
            notificationManager?.cancel(id)
            activeNotificationId = null
        }
        // 保持服务运行，只关闭通知
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
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
            Log.d("TimerService", "Notification channel created")
        }
    }

    override fun onCreate() {
        super.onCreate()
        Log.d("TimerService", "Service created")
        createNotificationChannel()
    }
}