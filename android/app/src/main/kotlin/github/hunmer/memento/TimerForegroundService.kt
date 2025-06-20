package github.hunmer.memento

import android.app.Service
import android.content.Intent
import android.os.IBinder
import androidx.core.app.NotificationCompat
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
    private val NOTIFICATION_ID = 1


    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("TimerForegroundService", "onStartCommand called")
        
        // 创建默认通知以确保服务不会超时
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Memento Timer")
            .setContentText("Timer is running")
            .setSmallIcon(R.drawable.launcher_icon)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
        
        startForeground(NOTIFICATION_ID, notification)
        
        // 处理Intent动作
        intent?.action?.let { action ->
            when (action) {
                "START" -> {
                    val taskId = intent.getStringExtra("taskId")
                    val taskName = intent.getStringExtra("taskName")
                    val totalSeconds = intent.getIntExtra("totalSeconds", 0)
                    val currentSeconds = intent.getIntExtra("currentSeconds", 0)
                    startTimerService(Bundle().apply {
                        putString("taskId", taskId)
                        putString("taskName", taskName)
                        putInt("totalSeconds", totalSeconds)
                        putInt("currentSeconds", currentSeconds)
                    })
                }
                "UPDATE" -> {
                    val taskId = intent.getStringExtra("taskId")
                    val taskName = intent.getStringExtra("taskName")
                    val totalSeconds = intent.getIntExtra("totalSeconds", 0)
                    val currentSeconds = intent.getIntExtra("currentSeconds", 0)
                    startTimerService(Bundle().apply {
                        putString("taskId", taskId)
                        putString("taskName", taskName)
                        putInt("totalSeconds", totalSeconds)
                        putInt("currentSeconds", currentSeconds)
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
        
        // 保留MethodChannel处理以防其他用途
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startTimerService" -> {
                    val args = call.arguments as? Bundle
                    startTimerService(args)
                    result.success(null)
                }
                "updateTimerService" -> {
                    val args = call.arguments as? Bundle
                    updateTimerService(args)
                    result.success(null)
                }
                "stopTimerService" -> {
                    val args = call.arguments as? Bundle
                    stopTimerService(args)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        
        return START_NOT_STICKY
    }


    private fun startTimerService(args: Bundle?) {
        Log.d("TimerForegroundService", "startTimerService called2")

        args?.let {
            val taskId = it.getString("taskId")
            val taskName = it.getString("taskName")
            val totalSeconds = it.getInt("totalSeconds")
            val currentSeconds = it.getInt("currentSeconds")
            val subTimers = it.getSerializable("subTimers") as? ArrayList<*>
            val currentSubTimerIndex = it.getInt("currentSubTimerIndex", -1)

            val notificationIntent = Intent(this, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                this,
                0, notificationIntent, PendingIntent.FLAG_IMMUTABLE
            )

            // 创建进度条样式
            val progress = (currentSeconds.toFloat() / totalSeconds.toFloat() * 100).toInt()
            val progressStyle = NotificationCompat.BigTextStyle()
                .bigText(buildSubTimersText(subTimers, currentSubTimerIndex))
                .setBigContentTitle(taskName ?: "Memento Timer")
                .setSummaryText("Progress: $progress%")

            val notification = NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle(taskName ?: "Memento Timer")
                .setContentText("$currentSeconds/$totalSeconds seconds")
                .setSmallIcon(R.drawable.launcher_icon)
                .setContentIntent(pendingIntent)
                .setStyle(progressStyle)
                .setProgress(100, progress, false)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setCategory(NotificationCompat.CATEGORY_SERVICE)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setOngoing(true)
                .setOnlyAlertOnce(true)
                .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
                .build()

            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun updateTimerService(args: Bundle?) {
        Log.d("TimerForegroundService", "updateTimerService called1")
        args?.let {
            val taskName = it.getString("taskName")
            val totalSeconds = it.getInt("totalSeconds")
            val currentSeconds = it.getInt("currentSeconds")
            val subTimers = it.getSerializable("subTimers") as? ArrayList<*>
            val currentSubTimerIndex = it.getInt("currentSubTimerIndex", -1)

            // 创建进度条样式
            val progress = (currentSeconds.toFloat() / totalSeconds.toFloat() * 100).toInt()
            val progressStyle = NotificationCompat.BigTextStyle()
                .bigText(buildSubTimersText(subTimers, currentSubTimerIndex))
                .setBigContentTitle(taskName ?: "Memento Timer")
                .setSummaryText("Progress: $progress%")
            Log.d("TimerService", "Updating notification with progress: $progress%")

            val notification = NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle(taskName ?: "Memento Timer")
                .setContentText("$currentSeconds/$totalSeconds seconds")
                .setSmallIcon(R.drawable.launcher_icon)
                .setStyle(progressStyle)
                .setProgress(100, progress, false)
                .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
                .build()

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.notify(NOTIFICATION_ID, notification)
        }
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

    private fun stopTimerService(args: Bundle?) {
        Log.d("TimerForegroundService", "stopTimerService called")
        stopForeground(true)
        stopSelf()
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
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
    }
}