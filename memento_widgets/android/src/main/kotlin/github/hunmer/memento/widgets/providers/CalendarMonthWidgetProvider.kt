package github.hunmer.memento.widgets.providers

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import android.graphics.Color
import android.net.Uri
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import android.widget.Toast
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

        // 配置键前缀
        private const val PREF_KEY_PRIMARY_COLOR = "calendar_widget_primary_color_"
        private const val PREF_KEY_ACCENT_COLOR = "calendar_widget_accent_color_"
        private const val PREF_KEY_OPACITY = "calendar_widget_opacity_"
        private const val PREF_KEY_DISPLAY_YEAR = "calendar_widget_display_year_"
        private const val PREF_KEY_DISPLAY_MONTH = "calendar_widget_display_month_"

        // 默认主题色 - 白色 (未配置状态)
        private const val DEFAULT_PRIMARY_COLOR = 0xFFFFFFFF.toInt()
        private const val DEFAULT_ACCENT_COLOR = 0xFF000000.toInt()  // 黑色文字
        private const val DEFAULT_OPACITY = 1.0f

        // 固定文本颜色
        private const val TEXT_COLOR_PRIMARY = 0xFF1F2937.toInt()
        private const val TEXT_COLOR_SECONDARY = 0xFF6B7280.toInt()
        private const val TEXT_COLOR_MUTED = 0xFF9CA3AF.toInt()

        // Action
        private const val ACTION_COMPLETE_EVENT = "github.hunmer.memento.widgets.COMPLETE_CALENDAR_EVENT"
        private const val ACTION_PREV_MONTH = "github.hunmer.memento.widgets.CALENDAR_PREV_MONTH"
        private const val ACTION_NEXT_MONTH = "github.hunmer.memento.widgets.CALENDAR_NEXT_MONTH"

        // 待同步的完成事件队列 key
        private const val PREF_KEY_PENDING_COMPLETE_EVENTS = "calendar_pending_complete_events"
    }

    override fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_calendar_month)

        // 检查是否已配置
        val isConfigured = isWidgetConfigured(context, appWidgetId)

        if (!isConfigured) {
            // 未配置：显示"点击配置"提示
            setupUnconfiguredWidget(context, views, appWidgetId)
        } else {
            // 已配置：正常显示
            // 读取颜色配置
            val primaryColor = getConfiguredPrimaryColor(context, appWidgetId)
            val accentColor = getConfiguredAccentColor(context, appWidgetId)
            val opacity = getConfiguredOpacity(context, appWidgetId)

            // 应用背景颜色（使用 backgroundTintList 保持圆角效果）
            val bgColor = adjustColorAlpha(primaryColor, opacity)
            views.setColorStateList(
                R.id.calendar_month_container,
                "setBackgroundTintList",
                ColorStateList.valueOf(bgColor)
            )

            // 应用标题色（强调色）
            views.setTextColor(R.id.calendar_month_name, accentColor)

            // 获取当前显示的年月（可能是用户翻页后的月份）
            val displayYear = getDisplayYear(context, appWidgetId)
            val displayMonth = getDisplayMonth(context, appWidgetId)

            // 加载原始数据
            val savedData = loadWidgetData(context)
            val savedYear = savedData?.optInt("year", -1) ?: -1
            val savedMonth = savedData?.optInt("month", -1) ?: -1

            // 判断是否需要生成不同月份的数据
            val data = if (savedYear != displayYear || savedMonth != displayMonth) {
                // 用户翻页到了其他月份，生成该月份的日历数据
                Log.d(TAG, "生成 $displayYear-$displayMonth 的日历数据")
                generateCalendarData(context, displayYear, displayMonth)
            } else if (savedData != null) {
                Log.d(TAG, "使用保存的数据: $savedData")
                savedData
            } else {
                Log.w(TAG, "无法加载小组件数据，使用默认当前月份")
                // 即使没有数据也显示当前月份的日历
                generateCalendarData(context, displayYear, displayMonth)
            }

            setupCalendarWidget(context, views, data, appWidgetId)

            // 设置整体点击事件（打开日历插件）
            setupWidgetClickIntent(context, views)
        }

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
        // 上一月按钮
        val prevIntent = Intent(context, CalendarMonthWidgetProvider::class.java).apply {
            action = ACTION_PREV_MONTH
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        }
        val prevPendingIntent = PendingIntent.getBroadcast(
            context,
            appWidgetId * 100 + 1,
            prevIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.calendar_month_prev, prevPendingIntent)

        // 下一月按钮
        val nextIntent = Intent(context, CalendarMonthWidgetProvider::class.java).apply {
            action = ACTION_NEXT_MONTH
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        }
        val nextPendingIntent = PendingIntent.getBroadcast(
            context,
            appWidgetId * 100 + 2,
            nextIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.calendar_month_next, nextPendingIntent)
    }

    /**
     * 获取当前显示的年份
     */
    private fun getDisplayYear(context: Context, appWidgetId: Int): Int {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getInt("$PREF_KEY_DISPLAY_YEAR$appWidgetId", Calendar.getInstance().get(Calendar.YEAR))
    }

    /**
     * 获取当前显示的月份
     */
    private fun getDisplayMonth(context: Context, appWidgetId: Int): Int {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getInt("$PREF_KEY_DISPLAY_MONTH$appWidgetId", Calendar.getInstance().get(Calendar.MONTH) + 1)
    }

    /**
     * 设置当前显示的年月
     */
    private fun setDisplayYearMonth(context: Context, appWidgetId: Int, year: Int, month: Int) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .putInt("$PREF_KEY_DISPLAY_YEAR$appWidgetId", year)
            .putInt("$PREF_KEY_DISPLAY_MONTH$appWidgetId", month)
            .apply()
    }

    /**
     * 计算上一月的年月
     */
    private fun getPrevMonth(year: Int, month: Int): Pair<Int, Int> {
        return if (month == 1) {
            Pair(year - 1, 12)
        } else {
            Pair(year, month - 1)
        }
    }

    /**
     * 计算下一月的年月
     */
    private fun getNextMonth(year: Int, month: Int): Pair<Int, Int> {
        return if (month == 12) {
            Pair(year + 1, 1)
        } else {
            Pair(year, month + 1)
        }
    }

    /**
     * 生成指定年月的日历数据
     */
    private fun generateCalendarData(context: Context, year: Int, month: Int): JSONObject {
        val calendar = Calendar.getInstance()
        calendar.set(year, month - 1, 1) // month 是 1-12，Calendar.MONTH 是 0-11

        // 获取本月第一天是星期几 (周一=1, 周日=7)
        var firstWeekday = calendar.get(Calendar.DAY_OF_WEEK) - 1
        if (firstWeekday == 0) firstWeekday = 7

        // 获取本月天数
        val daysInMonth = calendar.getActualMaximum(Calendar.DAY_OF_MONTH)

        // 获取今天的日期
        val now = Calendar.getInstance()
        val todayYear = now.get(Calendar.YEAR)
        val todayMonth = now.get(Calendar.MONTH) + 1
        val today = if (year == todayYear && month == todayMonth) {
            now.get(Calendar.DAY_OF_MONTH)
        } else {
            -1 // 不是当月，不高亮今天
        }

        // 尝试从保存的数据中获取事件
        val dayEventsMap = JSONObject()
        val savedData = loadWidgetData(context)
        if (savedData != null) {
            val savedYear = savedData.optInt("year", -1)
            val savedMonth = savedData.optInt("month", -1)
            if (savedYear == year && savedMonth == month) {
                val dayEvents = savedData.optJSONObject("dayEvents")
                if (dayEvents != null) {
                    val keys = dayEvents.keys()
                    while (keys.hasNext()) {
                        val key = keys.next()
                        dayEventsMap.put(key, dayEvents.getJSONArray(key))
                    }
                }
            }
        }

        return JSONObject().apply {
            put("year", year)
            put("month", month)
            put("daysInMonth", daysInMonth)
            put("firstWeekday", firstWeekday)
            put("today", today)
            put("dayEvents", dayEventsMap)
        }
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

        val appWidgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)

        when (intent.action) {
            ACTION_PREV_MONTH -> {
                if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) return
                Log.d(TAG, "切换到上一月: appWidgetId=$appWidgetId")

                // 获取当前显示的年月
                val currentYear = getDisplayYear(context, appWidgetId)
                val currentMonth = getDisplayMonth(context, appWidgetId)

                // 计算上一月
                val (newYear, newMonth) = getPrevMonth(currentYear, currentMonth)

                // 保存新的年月
                setDisplayYearMonth(context, appWidgetId, newYear, newMonth)

                // 刷新小组件
                val appWidgetManager = AppWidgetManager.getInstance(context)
                updateAppWidget(context, appWidgetManager, appWidgetId)
            }

            ACTION_NEXT_MONTH -> {
                if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) return
                Log.d(TAG, "切换到下一月: appWidgetId=$appWidgetId")

                // 获取当前显示的年月
                val currentYear = getDisplayYear(context, appWidgetId)
                val currentMonth = getDisplayMonth(context, appWidgetId)

                // 计算下一月
                val (newYear, newMonth) = getNextMonth(currentYear, currentMonth)

                // 保存新的年月
                setDisplayYearMonth(context, appWidgetId, newYear, newMonth)

                // 刷新小组件
                val appWidgetManager = AppWidgetManager.getInstance(context)
                updateAppWidget(context, appWidgetManager, appWidgetId)
            }

            ACTION_COMPLETE_EVENT -> {
                val eventId = intent.getStringExtra("eventId") ?: return
                Log.d(TAG, "完成事件: eventId=$eventId, appWidgetId=$appWidgetId")

                // 后台处理：通过广播通知 Flutter 端完成事件
                val result = completeEventInBackground(context, eventId)

                // 显示 Toast
                val message = if (result) "任务已完成" else "完成任务失败"
                Toast.makeText(context, message, Toast.LENGTH_SHORT).show()

                // 如果成功，刷新小组件
                if (result && appWidgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
                    val appWidgetManager = AppWidgetManager.getInstance(context)
                    updateAppWidget(context, appWidgetManager, appWidgetId)
                }
            }
        }
    }

    /**
     * 后台完成事件
     * 更新 SharedPreferences 中的事件状态，并将事件 ID 添加到待同步队列
     */
    private fun completeEventInBackground(context: Context, eventId: String): Boolean {
        return try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val jsonString = prefs.getString("calendar_month_widget_data", null)

            if (jsonString != null) {
                val data = JSONObject(jsonString)
                val dayEvents = data.optJSONObject("dayEvents")

                if (dayEvents != null) {
                    var found = false
                    val keys = dayEvents.keys()

                    while (keys.hasNext()) {
                        val day = keys.next()
                        val events = dayEvents.getJSONArray(day)

                        for (i in 0 until events.length()) {
                            val event = events.getJSONObject(i)
                            if (event.optString("id") == eventId) {
                                // 标记为完成
                                event.put("completed", true)
                                found = true
                                Log.d(TAG, "事件标记为完成: $eventId")
                                break
                            }
                        }

                        if (found) break
                    }

                    if (found) {
                        // 保存更新后的数据
                        prefs.edit().putString("calendar_month_widget_data", data.toString()).apply()

                        // 将事件 ID 添加到待同步队列，供 Flutter 端启动时处理
                        addToPendingCompleteEvents(context, eventId)

                        return true
                    }
                }
            }

            Log.w(TAG, "未找到事件: $eventId")
            false
        } catch (e: Exception) {
            Log.e(TAG, "后台完成事件失败", e)
            false
        }
    }

    /**
     * 将事件 ID 添加到待同步完成队列
     */
    private fun addToPendingCompleteEvents(context: Context, eventId: String) {
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val existingJson = prefs.getString(PREF_KEY_PENDING_COMPLETE_EVENTS, "[]")
            val pendingArray = JSONArray(existingJson)

            // 检查是否已存在
            var exists = false
            for (i in 0 until pendingArray.length()) {
                if (pendingArray.getString(i) == eventId) {
                    exists = true
                    break
                }
            }

            if (!exists) {
                pendingArray.put(eventId)
                prefs.edit().putString(PREF_KEY_PENDING_COMPLETE_EVENTS, pendingArray.toString()).apply()
                Log.d(TAG, "事件已添加到待同步队列: $eventId, 队列长度: ${pendingArray.length()}")
            }
        } catch (e: Exception) {
            Log.e(TAG, "添加待同步事件失败", e)
        }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        super.onDeleted(context, appWidgetIds)
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val editor = prefs.edit()
        for (appWidgetId in appWidgetIds) {
            // 清理所有相关配置
            editor.remove("$PREF_KEY_PRIMARY_COLOR$appWidgetId")
            editor.remove("$PREF_KEY_ACCENT_COLOR$appWidgetId")
            editor.remove("$PREF_KEY_OPACITY$appWidgetId")
            editor.remove("$PREF_KEY_DISPLAY_YEAR$appWidgetId")
            editor.remove("$PREF_KEY_DISPLAY_MONTH$appWidgetId")
        }
        editor.apply()
    }

    /**
     * 获取背景色（主色调）
     */
    private fun getConfiguredPrimaryColor(context: Context, appWidgetId: Int): Int {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val colorStr = prefs.getString("$PREF_KEY_PRIMARY_COLOR$appWidgetId", null)
        return colorStr?.toLongOrNull()?.toInt() ?: DEFAULT_PRIMARY_COLOR
    }

    /**
     * 获取标题色（强调色）
     */
    private fun getConfiguredAccentColor(context: Context, appWidgetId: Int): Int {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val colorStr = prefs.getString("$PREF_KEY_ACCENT_COLOR$appWidgetId", null)
        return colorStr?.toLongOrNull()?.toInt() ?: DEFAULT_ACCENT_COLOR
    }

    /**
     * 获取透明度
     */
    private fun getConfiguredOpacity(context: Context, appWidgetId: Int): Float {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val opacityStr = prefs.getString("$PREF_KEY_OPACITY$appWidgetId", null)
        return opacityStr?.toFloatOrNull() ?: DEFAULT_OPACITY
    }

    /**
     * 调整颜色的透明度
     */
    private fun adjustColorAlpha(color: Int, alphaFactor: Float): Int {
        val alpha = (alphaFactor * 255).toInt()
        val red = (color shr 16) and 0xFF
        val green = (color shr 8) and 0xFF
        val blue = color and 0xFF
        return (alpha shl 24) or (red shl 16) or (green shl 8) or blue
    }

    /**
     * 检查小组件是否已配置
     */
    private fun isWidgetConfigured(context: Context, appWidgetId: Int): Boolean {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        // 如果有保存的主色调配置，则认为已配置
        return prefs.contains("$PREF_KEY_PRIMARY_COLOR$appWidgetId")
    }

    /**
     * 设置未配置状态的小组件
     */
    private fun setupUnconfiguredWidget(
        context: Context,
        views: RemoteViews,
        appWidgetId: Int
    ) {
        // 使用默认颜色
        val bgColor = adjustColorAlpha(DEFAULT_PRIMARY_COLOR, DEFAULT_OPACITY)
        views.setColorStateList(
            R.id.calendar_month_container,
            "setBackgroundTintList",
            ColorStateList.valueOf(bgColor)
        )

        // 设置标题为"点击配置"
        views.setTextViewText(R.id.calendar_month_name, "点击配置")
        views.setTextColor(R.id.calendar_month_name, DEFAULT_ACCENT_COLOR)

        // 隐藏所有日期和事件
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

        for (id in dayTextIds) {
            views.setViewVisibility(id, View.GONE)
        }
        for (id in dayDotIds) {
            views.setViewVisibility(id, View.GONE)
        }

        // 隐藏事件列表
        views.setViewVisibility(R.id.no_events_text, View.GONE)
        val eventItemIds = listOf(R.id.event_item_1, R.id.event_item_2, R.id.event_item_3, R.id.event_item_4, R.id.event_item_5)
        for (id in eventItemIds) {
            views.setViewVisibility(id, View.GONE)
        }

        // 设置点击事件：跳转到配置页面
        val configUri = Uri.parse("memento://widget/calendar_month/config?widgetId=$appWidgetId")
        val intent = Intent(Intent.ACTION_VIEW).apply {
            data = configUri
            setPackage("github.hunmer.memento")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }

        val pendingIntent = PendingIntent.getActivity(
            context,
            appWidgetId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        views.setOnClickPendingIntent(R.id.calendar_month_container, pendingIntent)
    }
}
