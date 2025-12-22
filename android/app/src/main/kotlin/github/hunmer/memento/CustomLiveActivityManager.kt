package github.hunmer.memento

import android.app.Notification
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.widget.RemoteViews
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.net.HttpURLConnection
import java.net.URL
import com.example.live_activities.LiveActivityManager

class CustomLiveActivityManager(context: Context) :
    LiveActivityManager(context) {
    private val context: Context = context.applicationContext
    private val pendingIntent = PendingIntent.getActivity(
        context, 200, Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
        }, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )

    private val remoteViews = RemoteViews(
        context.packageName, R.layout.live_activity
    )

    /**
     * 从URL加载图片并调整为64dp
     */
    suspend fun loadImageBitmap(imageUrl: String?): Bitmap? {
        val dp = context.resources.displayMetrics.density.toInt()

        return withContext(Dispatchers.IO) {
            if (imageUrl.isNullOrEmpty()) return@withContext null
            try {
                val url = URL(imageUrl)
                val connection = url.openConnection() as HttpURLConnection
                connection.doInput = true
                connection.connectTimeout = 3000
                connection.readTimeout = 3000
                connection.connect()
                connection.inputStream.use { inputStream ->
                    val originalBitmap = BitmapFactory.decodeStream(inputStream)
                    originalBitmap?.let {
                        val targetSize = 64 * dp
                        val aspectRatio =
                            it.width.toFloat() / it.height.toFloat()
                        val (targetWidth, targetHeight) = if (aspectRatio > 1) {
                            targetSize to (targetSize / aspectRatio).toInt()
                        } else {
                            (targetSize * aspectRatio).toInt() to targetSize
                        }
                        Bitmap.createScaledBitmap(
                            it,
                            targetWidth,
                            targetHeight,
                            true
                        )
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
                null
            }
        }
    }

    /**
     * 更新RemoteViews中的数据
     */
    private suspend fun updateRemoteViews(
        title: String,
        subtitle: String,
        progress: Double,
        status: String,
        iconUrl: String?,
        timestamp: Long
    ) {
        remoteViews.setTextViewText(R.id.title, title)
        remoteViews.setTextViewText(R.id.subtitle, subtitle)
        remoteViews.setTextViewText(R.id.status, status)
        remoteViews.setProgressBar(R.id.progress, 100, progress.toInt(), false)

        val elapsedRealtime = android.os.SystemClock.elapsedRealtime()
        val currentTimeMillis = System.currentTimeMillis()
        val base = elapsedRealtime - (currentTimeMillis - timestamp)

        remoteViews.setChronometer(R.id.timer, base, null, true)

        iconUrl?.let { url ->
            val bitmap = loadImageBitmap(url)
            bitmap?.let { image ->
                remoteViews.setImageViewBitmap(R.id.icon, image)
            }
        }
    }

    /**
     * 构建通知 - 由插件调用
     */
    override suspend fun buildNotification(
        notification: Notification.Builder,
        event: String,
        data: Map<String, Any>
    ): Notification {
        val title = data["title"] as String
        val subtitle = data["subtitle"] as String
        val progress = (data["progress"] as? Number)?.toDouble() ?: 0.0
        val status = data["status"] as String
        val timestamp = data["timestamp"] as Long
        val iconUrl = data["iconUrl"] as? String

        // 如果是"update"事件，跳过图片加载
        val finalIconUrl = if (event == "update") null else iconUrl

        updateRemoteViews(
            title,
            subtitle,
            progress,
            status,
            finalIconUrl,
            timestamp
        )

        return notification
            .setSmallIcon(R.drawable.ic_notification)
            .setOngoing(true)
            .setContentTitle(title)
            .setContentIntent(pendingIntent)
            .setContentText(subtitle)
            .setStyle(Notification.DecoratedCustomViewStyle())
            .setCustomContentView(remoteViews)
            .setCustomBigContentView(remoteViews)
            .setPriority(Notification.PRIORITY_LOW)
            .setCategory(Notification.CATEGORY_EVENT)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .build()
    }
}
