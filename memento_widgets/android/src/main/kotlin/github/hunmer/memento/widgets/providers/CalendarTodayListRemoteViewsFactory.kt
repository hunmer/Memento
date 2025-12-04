package github.hunmer.memento.widgets.providers

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.util.Log
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import github.hunmer.memento_widgets.R
import github.hunmer.memento.widgets.BasePluginWidgetProvider
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

/**
 * 今日事件列表的 RemoteViewsFactory
 * 负责创建和管理事件列表项
 */
class CalendarTodayListRemoteViewsFactory(
    private val context: Context,
    private val intent: Intent
) : RemoteViewsService.RemoteViewsFactory {

    companion object {
        private const val TAG = "CalendarTodayFactory"
    }

    private var events: List<EventItem> = emptyList()
    private val appWidgetId: Int = intent.getIntExtra(
        AppWidgetManager.EXTRA_APPWIDGET_ID,
        AppWidgetManager.INVALID_APPWIDGET_ID
    )

    data class EventItem(
        val id: String,
        val title: String,
        val detail: String,
        val time: String,
        val color: String,
        val completed: Boolean
    )

    override fun onCreate() {
        Log.d(TAG, "onCreate: appWidgetId=$appWidgetId")
    }

    override fun onDataSetChanged() {
        Log.d(TAG, "onDataSetChanged: Loading today's events")
        events = loadTodayEvents()
        Log.d(TAG, "Loaded ${events.size} events for today")
    }

    override fun onDestroy() {
        events = emptyList()
    }

    override fun getCount(): Int = events.size

    override fun getViewAt(position: Int): RemoteViews {
        if (position < 0 || position >= events.size) {
            return RemoteViews(context.packageName, R.layout.widget_calendar_today_list_item)
        }

        val event = events[position]
        val views = RemoteViews(context.packageName, R.layout.widget_calendar_today_list_item)

        // 设置事件标题
        views.setTextViewText(R.id.event_title, event.title)

        // 设置事件详情
        views.setTextViewText(R.id.event_detail, event.detail)

        // 设置时间标签
        views.setTextViewText(R.id.event_time, event.time)

        // 设置彩色竖条颜色
        val colorInt = try {
            Color.parseColor(event.color)
        } catch (e: Exception) {
            Color.parseColor("#34D399") // 默认绿色
        }
        views.setInt(R.id.event_color_bar, "setBackgroundColor", colorInt)

        // 设置复选框状态
        if (event.completed) {
            views.setImageViewResource(R.id.event_checkbox, R.drawable.ic_checkbox_checked)
            // 已完成事件标题变淡
            views.setTextColor(R.id.event_title, 0xFF9CA3AF.toInt())
        } else {
            views.setImageViewResource(R.id.event_checkbox, R.drawable.checkbox_unchecked)
            views.setTextColor(R.id.event_title, 0xFF1F2937.toInt())
        }

        // 设置复选框点击 - 填充 Intent
        val checkboxFillIntent = Intent().apply {
            putExtra("action", "toggle_event")
            putExtra("event_id", event.id)
            putExtra("event_completed", event.completed)
        }
        views.setOnClickFillInIntent(R.id.event_checkbox_container, checkboxFillIntent)

        // 设置事件内容点击 - 打开事件详情
        val detailFillIntent = Intent().apply {
            putExtra("action", "open_detail")
            putExtra("event_id", event.id)
        }
        views.setOnClickFillInIntent(R.id.event_content_container, detailFillIntent)

        return views
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = true

    /**
     * 从 SharedPreferences 加载今日事件数据
     */
    private fun loadTodayEvents(): List<EventItem> {
        return try {
            val prefs = context.getSharedPreferences(
                BasePluginWidgetProvider.PREFS_NAME,
                Context.MODE_PRIVATE
            )
            val jsonString = prefs.getString("calendar_month_widget_data", null)

            if (jsonString.isNullOrEmpty()) {
                Log.w(TAG, "No calendar data found")
                return emptyList()
            }

            val json = JSONObject(jsonString)
            val dayEvents = json.optJSONObject("dayEvents") ?: return emptyList()

            // 获取今天的日期号
            val today = Calendar.getInstance().get(Calendar.DAY_OF_MONTH).toString()
            val todayEventsArray = dayEvents.optJSONArray(today) ?: return emptyList()

            val result = mutableListOf<EventItem>()

            // 解析今日事件
            for (i in 0 until todayEventsArray.length()) {
                val eventJson = todayEventsArray.getJSONObject(i)

                // 解析事件数据
                val id = eventJson.optString("id", "")
                val title = eventJson.optString("title", "无标题")
                val startTime = eventJson.optString("startTime", "")
                val color = eventJson.optString("color", "#34D399")
                val completed = eventJson.optBoolean("completed", false)
                val source = eventJson.optString("source", "")

                // 格式化时间标签
                val timeLabel = formatTimeLabel(startTime)

                // 构造详情信息 (例如: "Lizi:2024-04-09T19:00")
                val detail = if (source.isNotEmpty()) {
                    "$source:$startTime"
                } else {
                    startTime.ifEmpty { "无时间" }
                }

                val event = EventItem(
                    id = id,
                    title = title,
                    detail = detail,
                    time = timeLabel,
                    color = color,
                    completed = completed
                )

                // 只显示未完成的事件
                if (!completed) {
                    result.add(event)
                }
            }

            // 按时间排序（全天事件优先，然后按时间早晚）
            result.sortedWith(compareBy(
                { if (it.time == "全天") 0 else 1 },
                { it.time }
            ))
        } catch (e: Exception) {
            Log.e(TAG, "Failed to load today's events", e)
            emptyList()
        }
    }

    /**
     * 格式化时间标签
     * 输入: "2024-04-09T19:00:00" 或 "09:00"
     * 输出: "全天" 或 "9:00" 或 "19:00"
     */
    private fun formatTimeLabel(timeStr: String): String {
        if (timeStr.isEmpty()) {
            return "全天"
        }

        return try {
            // 尝试解析完整的 ISO 格式
            if (timeStr.contains("T")) {
                val dateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.getDefault())
                val date = dateFormat.parse(timeStr)
                val timeFormat = SimpleDateFormat("H:mm", Locale.getDefault())
                timeFormat.format(date!!)
            } else if (timeStr.contains(":")) {
                // 已经是 HH:mm 格式
                val parts = timeStr.split(":")
                val hour = parts[0].toIntOrNull() ?: 0
                val minute = parts.getOrNull(1)?.toIntOrNull() ?: 0
                "$hour:${minute.toString().padStart(2, '0')}"
            } else {
                "全天"
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to format time: $timeStr", e)
            "全天"
        }
    }
}
