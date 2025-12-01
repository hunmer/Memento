package github.hunmer.memento.widgets.providers

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import com.example.memento_widgets.R
import github.hunmer.memento.widgets.BasePluginWidgetProvider
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

/**
 * 日历月视图小组件 Provider
 *
 * 功能:
 * - 左侧显示当前月份的日历网格 (7列 x 6行)
 * - 右侧显示选中日期（默认今天）的事件列表
 * - 有事件的日期下方显示绿色小圆点
 * - 今天日期显示绿色圆形背景
 * - 点击事件checkbox可完成任务
 * - 点击事件打开app展示详情
 */
class CalendarMonthWidgetProvider : BasePluginWidgetProvider() {
    override val pluginId: String = "calendar_month"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_4X2

    companion object {
        private const val TAG = "CalendarMonthWidget"

        // 主题色 - 绿色
        private const val PRIMARY_COLOR = 0xFF34D399.toInt()
        private const val TEXT_COLOR_PRIMARY = 0xFF1F2937.toInt()
        private const val TEXT_COLOR_SECONDARY = 0xFF6B7280.toInt()
        private const val TEXT_COLOR_MUTED = 0xFF9CA3AF.toInt()

        // Action
        private const val ACTION_COMPLETE_EVENT = "github.hunmer.memento.widgets.COMPLETE_CALENDAR_EVENT"
    }

    override fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_calendar_month)

        // 加载数据
        val data = loadWidgetData(context)

        if (data != null) {
            Log.d(TAG, "数据加载成功: $data")
            setupCalendarWidget(context, views, data, appWidgetId)
        } else {
            Log.w(TAG, "无法加载小组件数据，使用默认当前月份")
            // 即使没有数据也显示当前月份的日历
            setupDefaultCalendar(context, views, appWidgetId)
        }

        // 设置整体点击事件（打开日历插件）
        setupWidgetClickIntent(context, views)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    /**
     * 设置日历小组件
     */
    private fun setupCalendarWidget(
        context: Context,
        views: RemoteViews,
        data: JSONObject,
        appWidgetId: Int
    ) {
        try {
            // 解析数据
            val year = data.optInt("year", Calendar.getInstance().get(Calendar.YEAR))
            val month = data.optInt("month", Calendar.getInstance().get(Calendar.MONTH) + 1)
            val daysInMonth = data.optInt("daysInMonth", 30)
            val firstWeekday = data.optInt("firstWeekday", 1) // 1=周一
            val today = data.optInt("today", Calendar.getInstance().get(Calendar.DAY_OF_MONTH))
            val selectedDay = data.optInt("selectedDay", today)
            val dayEvents = data.optJSONObject("dayEvents") ?: JSONObject()

            Log.d(TAG, "日历数据: year=$year, month=$month, days=$daysInMonth, firstWeekday=$firstWeekday, today=$today")

            // 设置月份标题
            val monthNames = arrayOf("", "一月", "二月", "三月", "四月", "五月", "六月",
                "七月", "八月", "九月", "十月", "十一月", "十二月")
            views.setTextViewText(R.id.calendar_month_name, monthNames.getOrElse(month) { "${month}月" })

            // 日期格子和点的ID列表
            val dayTextIds = listOf(
                R.id.day_1, R.id.day_2, R.id.day_3, R.id.day_4, R.id.day_5, R.id.day_6, R.id.day_7,
                R.id.day_8, R.id.day_9, R.id.day_10, R.id.day_11, R.id.day_12, R.id.day_13, R.id.day_14,
                R.id.day_15, R.id.day_16, R.id.day_17, R.id.day_18, R.id.day_19, R.id.day_20, R.id.day_21,
                R.id.day_22, R.id.day_23, R.id.day_24, R.id.day_25, R.id.day_26, R.id.day_27, R.id.day_28,
                R.id.day_29, R.id.day_30, R.id.day_31, R.id.day_32, R.id.day_33, R.id.day_34, R.id.day_35,
                R.id.day_36, R.id.day_37, R.id.day_38, R.id.day_39, R.id.day_40, R.id.day_41, R.id.day_42
            )

            val dayDotIds = listOf(
                R.id.day_dot_1, R.id.day_dot_2, R.id.day_dot_3, R.id.day_dot_4, R.id.day_dot_5, R.id.day_dot_6, R.id.day_dot_7,
                R.id.day_dot_8, R.id.day_dot_9, R.id.day_dot_10, R.id.day_dot_11, R.id.day_dot_12, R.id.day_dot_13, R.id.day_dot_14,
                R.id.day_dot_15, R.id.day_dot_16, R.id.day_dot_17, R.id.day_dot_18, R.id.day_dot_19, R.id.day_dot_20, R.id.day_dot_21,
                R.id.day_dot_22, R.id.day_dot_23, R.id.day_dot_24, R.id.day_dot_25, R.id.day_dot_26, R.id.day_dot_27, R.id.day_dot_28,
                R.id.day_dot_29, R.id.day_dot_30, R.id.day_dot_31, R.id.day_dot_32, R.id.day_dot_33, R.id.day_dot_34, R.id.day_dot_35,
                R.id.day_dot_36, R.id.day_dot_37, R.id.day_dot_38, R.id.day_dot_39, R.id.day_dot_40, R.id.day_dot_41, R.id.day_dot_42
            )

            val dayCellIds = listOf(
                R.id.day_cell_1, R.id.day_cell_2, R.id.day_cell_3, R.id.day_cell_4, R.id.day_cell_5, R.id.day_cell_6, R.id.day_cell_7,
                R.id.day_cell_8, R.id.day_cell_9, R.id.day_cell_10, R.id.day_cell_11, R.id.day_cell_12, R.id.day_cell_13, R.id.day_cell_14,
                R.id.day_cell_15, R.id.day_cell_16, R.id.day_cell_17, R.id.day_cell_18, R.id.day_cell_19, R.id.day_cell_20, R.id.day_cell_21,
                R.id.day_cell_22, R.id.day_cell_23, R.id.day_cell_24, R.id.day_cell_25, R.id.day_cell_26, R.id.day_cell_27, R.id.day_cell_28,
                R.id.day_cell_29, R.id.day_cell_30, R.id.day_cell_31, R.id.day_cell_32, R.id.day_cell_33, R.id.day_cell_34, R.id.day_cell_35,
                R.id.day_cell_36, R.id.day_cell_37, R.id.day_cell_38, R.id.day_cell_39, R.id.day_cell_40, R.id.day_cell_41, R.id.day_cell_42
            )

            // 填充日历
            for (i in dayTextIds.indices) {
                // 计算实际日期 (firstWeekday: 1=周一, 7=周日)
                val dayNumber = i + 1 - (firstWeekday - 1)

                if (dayNumber in 1..daysInMonth) {
                    // 显示日期
                    views.setViewVisibility(dayTextIds[i], View.VISIBLE)
                    views.setTextViewText(dayTextIds[i], dayNumber.toString())

                    val isToday = dayNumber == today
                    val eventCount = dayEvents.optJSONArray(dayNumber.toString())?.length() ?: 0
                    val hasEvents = eventCount > 0

                    // 设置样式
                    if (isToday) {
                        // 今天 - 绿色圆形背景，白色文字
                        views.setInt(dayTextIds[i], "setBackgroundResource", R.drawable.calendar_today_circle)
                        views.setTextColor(dayTextIds[i], Color.WHITE)
                        // 今天不显示点（已有圆形背景）
                        views.setViewVisibility(dayDotIds[i], View.GONE)
                    } else {
                        // 非今天
                        views.setInt(dayTextIds[i], "setBackgroundColor", Color.TRANSPARENT)
                        views.setTextColor(dayTextIds[i], TEXT_COLOR_PRIMARY)
                        // 有事件则显示点
                        views.setViewVisibility(dayDotIds[i], if (hasEvents) View.VISIBLE else View.GONE)
                    }

                    // 设置日期点击事件
                    setupDayClickIntent(context, views, dayCellIds[i], year, month, dayNumber, appWidgetId)
                } else {
                    // 非本月日期 - 隐藏
                    views.setTextViewText(dayTextIds[i], "")
                    views.setInt(dayTextIds[i], "setBackgroundColor", Color.TRANSPARENT)
                    views.setViewVisibility(dayDotIds[i], View.GONE)
                }
            }

            // 设置右侧事件列表（显示今天的事件）
            setupEventsList(context, views, dayEvents, today, year, month, appWidgetId)

            // 设置月份导航按钮
            setupMonthNavigationButtons(context, views, appWidgetId)

        } catch (e: Exception) {
            Log.e(TAG, "设置日历小组件失败", e)
            setupDefaultCalendar(context, views, appWidgetId)
        }
    }

    /**
     * 设置默认日历（无数据时）
     */
    private fun setupDefaultCalendar(
        context: Context,
        views: RemoteViews,
        appWidgetId: Int
    ) {
        val calendar = Calendar.getInstance()
        val year = calendar.get(Calendar.YEAR)
        val month = calendar.get(Calendar.MONTH) + 1
        val today = calendar.get(Calendar.DAY_OF_MONTH)

        // 获取本月第一天是星期几
        calendar.set(Calendar.DAY_OF_MONTH, 1)
        var firstWeekday = calendar.get(Calendar.DAY_OF_WEEK) - 1 // 转为周一=1格式
        if (firstWeekday == 0) firstWeekday = 7

        // 获取本月天数
        val daysInMonth = calendar.getActualMaximum(Calendar.DAY_OF_MONTH)

        // 构建模拟数据
        val data = JSONObject().apply {
            put("year", year)
            put("month", month)
            put("daysInMonth", daysInMonth)
            put("firstWeekday", firstWeekday)
            put("today", today)
            put("dayEvents", JSONObject())
        }

        setupCalendarWidget(context, views, data, appWidgetId)
    }

    /**
     * 设置事件列表
     */
    private fun setupEventsList(
        context: Context,
        views: RemoteViews,
        dayEvents: JSONObject,
        day: Int,
        year: Int,
        month: Int,
        appWidgetId: Int
    ) {
        val events = dayEvents.optJSONArray(day.toString()) ?: JSONArray()
        val eventCount = events.length()

        // 事件项ID
        val eventItemIds = listOf(R.id.event_item_1, R.id.event_item_2, R.id.event_item_3, R.id.event_item_4, R.id.event_item_5)
        val eventTitleIds = listOf(R.id.event_title_1, R.id.event_title_2, R.id.event_title_3, R.id.event_title_4, R.id.event_title_5)
        val eventTimeIds = listOf(R.id.event_time_1, R.id.event_time_2, R.id.event_time_3, R.id.event_time_4, R.id.event_time_5)
        val eventCheckboxIds = listOf(R.id.event_checkbox_1, R.id.event_checkbox_2, R.id.event_checkbox_3, R.id.event_checkbox_4, R.id.event_checkbox_5)

        if (eventCount == 0) {
            // 无事件 - 显示提示
            views.setViewVisibility(R.id.no_events_text, View.VISIBLE)
            for (itemId in eventItemIds) {
                views.setViewVisibility(itemId, View.GONE)
            }
        } else {
            // 有事件 - 隐藏提示
            views.setViewVisibility(R.id.no_events_text, View.GONE)

            // 显示事件（最多5个）
            for (i in 0 until minOf(eventCount, 5)) {
                val event = events.getJSONObject(i)
                val eventId = event.optString("id", "")
                val title = event.optString("title", "未命名事件")
                val startTime = event.optString("startTime", "")
                val completed = event.optBoolean("completed", false)

                // 显示事件项
                views.setViewVisibility(eventItemIds[i], View.VISIBLE)
                views.setTextViewText(eventTitleIds[i], title)

                // 格式化时间 (从 ISO 字符串提取时间部分)
                val timeDisplay = formatTimeFromISO(startTime)
                views.setTextViewText(eventTimeIds[i], timeDisplay)

                // 设置checkbox状态
                val checkboxBg = if (completed) R.drawable.ic_checkbox_checked else R.drawable.checkbox_unchecked
                views.setInt(eventCheckboxIds[i], "setBackgroundResource", checkboxBg)

                // 设置事件点击 - 打开app展示详情
                setupEventClickIntent(context, views, eventItemIds[i], eventId, appWidgetId, i)

                // 设置checkbox点击 - 完成事件
                setupCheckboxClickIntent(context, views, eventCheckboxIds[i], eventId, appWidgetId, i)
            }

            // 隐藏多余的事件项
            for (i in eventCount until 5) {
                views.setViewVisibility(eventItemIds[i], View.GONE)
            }
        }
    }

    /**
     * 从 ISO 时间字符串提取时间部分
     */
    private fun formatTimeFromISO(isoString: String): String {
        return try {
            // ISO格式: 2025-01-15T09:00:00.000Z
            val timePart = isoString.substringAfter("T").substringBefore(".")
            val parts = timePart.split(":")
            if (parts.size >= 2) {
                "${parts[0]}:${parts[1]}"
            } else {
                ""
            }
        } catch (e: Exception) {
            ""
        }
    }

    /**
     * 设置日期点击事件
     */
    private fun setupDayClickIntent(
        context: Context,
        views: RemoteViews,
        cellId: Int,
        year: Int,
        month: Int,
        day: Int,
        appWidgetId: Int
    ) {
        val dateString = String.format("%04d-%02d-%02d", year, month, day)
        val uriString = "memento://widget/calendar_month?date=$dateString"

        val intent = Intent(Intent.ACTION_VIEW).apply {
            data = Uri.parse(uriString)
            setPackage("github.hunmer.memento")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }

        val requestCode = appWidgetId * 100 + day
        val pendingIntent = PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        views.setOnClickPendingIntent(cellId, pendingIntent)
    }

    /**
     * 设置事件点击事件（打开详情）
     */
    private fun setupEventClickIntent(
        context: Context,
        views: RemoteViews,
        itemId: Int,
        eventId: String,
        appWidgetId: Int,
        index: Int
    ) {
        val uriString = "memento://widget/calendar_month/event?eventId=$eventId"

        val intent = Intent(Intent.ACTION_VIEW).apply {
            data = Uri.parse(uriString)
            setPackage("github.hunmer.memento")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }

        val requestCode = appWidgetId * 1000 + index
        val pendingIntent = PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        views.setOnClickPendingIntent(itemId, pendingIntent)
    }

    /**
     * 设置checkbox点击事件（完成任务）
     */
    private fun setupCheckboxClickIntent(
        context: Context,
        views: RemoteViews,
        checkboxId: Int,
        eventId: String,
        appWidgetId: Int,
        index: Int
    ) {
        val intent = Intent(context, CalendarMonthWidgetProvider::class.java).apply {
            action = ACTION_COMPLETE_EVENT
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            putExtra("eventId", eventId)
        }

        val requestCode = appWidgetId * 10000 + index
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        views.setOnClickPendingIntent(checkboxId, pendingIntent)
    }

    /**
     * 设置月份导航按钮
     */
    private fun setupMonthNavigationButtons(
        context: Context,
        views: RemoteViews,
        appWidgetId: Int
    ) {
        // 上一月和下一月按钮暂时不实现功能，只是UI
        // 可以在这里添加切换月份的逻辑
    }

    /**
     * 设置整体点击事件
     */
    private fun setupWidgetClickIntent(context: Context, views: RemoteViews) {
        val intent = Intent(Intent.ACTION_VIEW).apply {
            data = Uri.parse("memento://widget/calendar")
            setPackage("github.hunmer.memento")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }

        val pendingIntent = PendingIntent.getActivity(
            context,
            pluginId.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        views.setOnClickPendingIntent(R.id.calendar_month_name, pendingIntent)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        when (intent.action) {
            ACTION_COMPLETE_EVENT -> {
                val eventId = intent.getStringExtra("eventId") ?: return
                val appWidgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)

                Log.d(TAG, "完成事件: eventId=$eventId, appWidgetId=$appWidgetId")

                // 发送完成事件的深链接到app
                val completeIntent = Intent(Intent.ACTION_VIEW).apply {
                    data = Uri.parse("memento://widget/calendar_month/complete?eventId=$eventId")
                    setPackage("github.hunmer.memento")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                context.startActivity(completeIntent)
            }
        }
    }
}
