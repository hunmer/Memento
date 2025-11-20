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
 * AI 语音快捷小组件 Provider
 */
class AgentVoiceWidgetProvider : AppWidgetProvider() {

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
        private const val PREF_CONVERSATIONS = "conversations_json"

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.widget_agent_voice)

            // 读取对话数据
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val conversationsJson = prefs.getString(PREF_CONVERSATIONS, "[]") ?: "[]"

            try {
                val conversations = JSONArray(conversationsJson)
                val conversationCount = minOf(conversations.length(), 3)

                // 设置对话项的可见性和数据
                for (i in 0 until 3) {
                    val conversationItemId = when (i) {
                        0 -> R.id.conversation_item_1
                        1 -> R.id.conversation_item_2
                        2 -> R.id.conversation_item_3
                        else -> continue
                    }

                    val conversationTitleId = when (i) {
                        0 -> R.id.conversation_title_1
                        1 -> R.id.conversation_title_2
                        2 -> R.id.conversation_title_3
                        else -> continue
                    }

                    val conversationPreviewId = when (i) {
                        0 -> R.id.conversation_preview_1
                        1 -> R.id.conversation_preview_2
                        2 -> R.id.conversation_preview_3
                        else -> continue
                    }

                    if (i < conversationCount) {
                        val conversation = conversations.getJSONObject(i)
                        val conversationId = conversation.getString("id")
                        val conversationTitle = conversation.getString("title")
                        val lastMessage = conversation.optString("lastMessage", "")

                        // 显示对话项
                        views.setViewVisibility(conversationItemId, android.view.View.VISIBLE)

                        // 设置对话标题
                        views.setTextViewText(conversationTitleId, conversationTitle)

                        // 设置最后消息预览
                        views.setTextViewText(
                            conversationPreviewId,
                            if (lastMessage.isNotEmpty()) lastMessage else "暂无消息"
                        )

                        // 设置点击事件 - 跳转到 voice_quick 界面并自动打开语音输入
                        val intent = Intent(Intent.ACTION_VIEW).apply {
                            data = Uri.parse("memento://widget/voice_quick?conversationId=$conversationId")
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                        }

                        val pendingIntent = PendingIntent.getActivity(
                            context,
                            conversationId.hashCode(),
                            intent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )

                        views.setOnClickPendingIntent(conversationItemId, pendingIntent)
                    } else {
                        // 隐藏未使用的对话项
                        views.setViewVisibility(conversationItemId, android.view.View.GONE)
                    }
                }

                // 设置"选择对话"按钮点击事件 - 打开应用但不指定对话
                val newConversationIntent = Intent(Intent.ACTION_VIEW).apply {
                    data = Uri.parse("memento://widget/voice_quick")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }

                val newConversationPendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    newConversationIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                views.setOnClickPendingIntent(R.id.new_conversation_button, newConversationPendingIntent)

            } catch (e: Exception) {
                e.printStackTrace()
                // 发生错误时显示错误信息
                views.setTextViewText(R.id.conversation_title_1, "加载失败")
                views.setTextViewText(R.id.conversation_preview_1, e.message ?: "未知错误")
                views.setViewVisibility(R.id.conversation_item_1, android.view.View.VISIBLE)
                views.setViewVisibility(R.id.conversation_item_2, android.view.View.GONE)
                views.setViewVisibility(R.id.conversation_item_3, android.view.View.GONE)
            }

            // 更新小组件
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
