package github.hunmer.memento

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import org.json.JSONArray

/**
 * 频道快速发送小组件 Provider
 */
class ChatQuickWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        private const val PREFS_NAME = "HomeWidgetPreferences"
        private const val PREF_CHANNELS = "channels_json"

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.widget_chat_quick)

            // 读取频道数据
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val channelsJson = prefs.getString(PREF_CHANNELS, "[]") ?: "[]"

            try {
                val channels = JSONArray(channelsJson)
                val channelCount = minOf(channels.length(), 3)

                // 设置频道项的可见性和数据
                for (i in 0 until 3) {
                    val channelItemId = when (i) {
                        0 -> R.id.channel_item_1
                        1 -> R.id.channel_item_2
                        2 -> R.id.channel_item_3
                        else -> continue
                    }

                    val channelNameId = when (i) {
                        0 -> R.id.channel_name_1
                        1 -> R.id.channel_name_2
                        2 -> R.id.channel_name_3
                        else -> continue
                    }

                    val channelPreviewId = when (i) {
                        0 -> R.id.channel_preview_1
                        1 -> R.id.channel_preview_2
                        2 -> R.id.channel_preview_3
                        else -> continue
                    }

                    val channelIconId = when (i) {
                        0 -> R.id.channel_icon_1
                        1 -> R.id.channel_icon_2
                        2 -> R.id.channel_icon_3
                        else -> continue
                    }

                    if (i < channelCount) {
                        val channel = channels.getJSONObject(i)
                        val channelId = channel.getString("id")
                        val channelName = channel.getString("name")
                        val lastMessage = channel.optString("lastMessage", "")

                        // 显示频道项
                        views.setViewVisibility(channelItemId, android.view.View.VISIBLE)

                        // 设置频道名称
                        views.setTextViewText(channelNameId, channelName)

                        // 设置最后消息预览
                        views.setTextViewText(
                            channelPreviewId,
                            if (lastMessage.isNotEmpty()) lastMessage else "暂无消息"
                        )

                        // 设置频道图标颜色（从 colorValue 读取）
                        val colorValue = channel.optInt("colorValue", 0xFF5C6BC0.toInt())
                        // views.setInt(channelIconId, "setBackgroundColor", colorValue)

                        // 设置点击事件 - 使用 home_widget 方式跳转到 quick_send 界面
                        val intent = Intent(context, MainActivity::class.java).apply {
                            action = Intent.ACTION_VIEW
                            data = Uri.parse("memento://widget/quick_send?channelId=$channelId")
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                        }

                        val pendingIntent = PendingIntent.getActivity(
                            context,
                            channelId.hashCode(),
                            intent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )

                        views.setOnClickPendingIntent(channelItemId, pendingIntent)
                    } else {
                        // 隐藏未使用的频道项
                        views.setViewVisibility(channelItemId, android.view.View.GONE)
                    }
                }

                // 设置"选择频道"按钮点击事件 - 打开应用但不指定频道
                val newChannelIntent = Intent(context, MainActivity::class.java).apply {
                    action = Intent.ACTION_VIEW
                    data = Uri.parse("memento://widget/quick_send")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }

                val newChannelPendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    newChannelIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                views.setOnClickPendingIntent(R.id.new_channel_button, newChannelPendingIntent)

            } catch (e: Exception) {
                e.printStackTrace()
                // 发生错误时显示错误信息
                views.setTextViewText(R.id.channel_name_1, "加载失败")
                views.setTextViewText(R.id.channel_preview_1, e.message ?: "未知错误")
                views.setViewVisibility(R.id.channel_item_1, android.view.View.VISIBLE)
                views.setViewVisibility(R.id.channel_item_2, android.view.View.GONE)
                views.setViewVisibility(R.id.channel_item_3, android.view.View.GONE)
            }

            // 更新小组件
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
