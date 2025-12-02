package github.hunmer.memento.widgets.providers

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import android.net.Uri
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import com.example.memento_widgets.R
import github.hunmer.memento.widgets.BasePluginWidgetProvider
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.*

/**
 * 本周打卡列表小组件 Provider（日历网格视图）
 * 显示一周七天的打卡项目，使用彩色竖条标识
 *
 * 特点：
 * - 7列网格布局（周一~周日）
 * - 每列显示该日期的打卡项目（彩色竖条 + 项目名称）
 * - 月份标题 + 星期标题 + 日期数字行
 * - 每列最多显示6个项目，超过显示"+N"
 * - 点击打卡项跳转到打卡对话框（传入日期和项目ID）
 * - 未来日期的打卡项不可点击
 * - 支持主题配置（背景色、强调色、透明度）
 */
class CalendarTodayListWidgetProvider : BasePluginWidgetProvider() {
    override val pluginId: String = "calendar_today_list"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_4X2

    companion object {
        private const val TAG = "CalendarTodayList"
        private const val PREF_KEY_PRIMARY_COLOR = "calendar_today_primary_color_"
        private const val PREF_KEY_ACCENT_COLOR = "calendar_today_accent_color_"
        private const val PREF_KEY_OPACITY = "calendar_today_opacity_"

        // 默认颜色
        private const val DEFAULT_PRIMARY_COLOR = 0xFF374151.toInt()  // 深灰色背景
        private const val DEFAULT_ACCENT_COLOR = 0xFFFFFFFF.toInt()   // 白色文字
        private const val DEFAULT_OPACITY = 0.95f

        // 每列最多显示的打卡项目数
        private const val MAX_ITEMS_PER_DAY = 6

        // 打卡项目颜色映射（徽章颜色）
        private val ITEM_COLORS = mapOf(
            "orange" to 0xFFFB923C.toInt(),
            "gray" to 0xFF9CA3AF.toInt(),
            "purple" to 0xFFA855F7.toInt(),
            "pink" to 0xFFEC4899.toInt(),
            "green" to 0xFF22C55E.toInt(),
            "blue" to 0xFF3B82F6.toInt(),
            "red" to 0xFFEF4444.toInt(),
            "yellow" to 0xFFF59E0B.toInt(),
            "teal" to 0xFF14B8A6.toInt(),
            "indigo" to 0xFF6366F1.toInt(),
            "cyan" to 0xFF06B6D4.toInt(),
            "lime" to 0xFF84CC16.toInt()
        )

        // 默认徽章颜色（灰色）
        private const val DEFAULT_BADGE_COLOR = 0xFF9CA3AF.toInt()

        /**
         * 静态方法：刷新所有日历打卡小组件
         */
        fun refreshAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, CalendarTodayListWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)

            val intent = Intent(context, CalendarTodayListWidgetProvider::class.java)
            intent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetIds)
            context.sendBroadcast(intent)
        }
    }

    override fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        try {
            val views = RemoteViews(context.packageName, R.layout.widget_calendar_today_list)

            // 读取颜色和透明度配置
            val primaryColor = getConfiguredPrimaryColor(context, appWidgetId)
            val accentColor = getConfiguredAccentColor(context, appWidgetId)
            val opacity = getConfiguredOpacity(context, appWidgetId)

            // 应用背景色和透明度
            val bgColor = adjustColorAlpha(primaryColor, opacity)
            views.setColorStateList(
                R.id.calendar_today_widget_container,
                "setBackgroundTintList",
                ColorStateList.valueOf(bgColor)
            )

            // 加载周数据
            val data = loadWidgetData(context)
            if (data != null) {
                setupCalendarWidget(views, context, data, accentColor)
            } else {
                setupEmptyWidget(views, context)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to update widget", e)
        }
    }

    /**
     * 设置日历小组件内容
     */
    private fun setupCalendarWidget(
        views: RemoteViews,
        context: Context,
        data: JSONObject,
        accentColor: Int
    ) {
        val weekDays = getWeekDays()
        val today = getTodayDateString()
        val items = data.optJSONArray("items") ?: JSONArray()

        Log.d(TAG, "setupCalendarWidget: today=$today, weekDays=$weekDays, itemCount=${items.length()}")

        // 设置月份标题
        val monthName = getMonthName(weekDays[0].first)
        views.setTextViewText(R.id.calendar_month_title, monthName)
        views.setTextColor(R.id.calendar_month_title, accentColor)

        // 星期标题 ID
        val weekHeaderIds = listOf(
            R.id.week_header_1, R.id.week_header_2, R.id.week_header_3, R.id.week_header_4,
            R.id.week_header_5, R.id.week_header_6, R.id.week_header_7
        )

        // 日期数字 ID
        val dayNumberIds = listOf(
            R.id.day_number_1, R.id.day_number_2, R.id.day_number_3, R.id.day_number_4,
            R.id.day_number_5, R.id.day_number_6, R.id.day_number_7
        )

        // 日期列 ID
        val dayColumnIds = listOf(
            R.id.day_column_1, R.id.day_column_2, R.id.day_column_3, R.id.day_column_4,
            R.id.day_column_5, R.id.day_column_6, R.id.day_column_7
        )

        val weekNames = listOf("一", "二", "三", "四", "五", "六", "日")

        for (i in 0 until 7) {
            val dayInfo = weekDays[i]
            val dateStr = dayInfo.first  // yyyy-MM-dd 格式
            val dayOfMonth = dayInfo.second  // 日期数字

            val isToday = dateStr == today
            val isFuture = dateStr > today

            // 设置星期标题（使用强调色）
            views.setTextViewText(weekHeaderIds[i], weekNames[i])
            views.setTextColor(weekHeaderIds[i], accentColor)

            // 设置日期数字（使用强调色）
            views.setTextViewText(dayNumberIds[i], dayOfMonth.toString())
            views.setTextColor(dayNumberIds[i], accentColor)

            // 设置该天的打卡项目
            setupDayCheckins(views, context, dayColumnIds[i], items, dateStr, isFuture, accentColor)
        }

        // 显示主内容，隐藏空状态
        views.setViewVisibility(R.id.calendar_today_content, View.VISIBLE)
        views.setViewVisibility(R.id.calendar_today_empty_hint, View.GONE)
    }

    /**
     * 设置某一天的打卡项目列表
     */
    private fun setupDayCheckins(
        views: RemoteViews,
        context: Context,
        columnId: Int,
        items: JSONArray,
        dateStr: String,
        isFuture: Boolean,
        accentColor: Int
    ) {
        // 获取该列的所有打卡项目 ID
        val checkinIds = when (columnId) {
            R.id.day_column_1 -> listOf(
                R.id.day1_checkin_1, R.id.day1_checkin_2, R.id.day1_checkin_3,
                R.id.day1_checkin_4, R.id.day1_checkin_5, R.id.day1_checkin_6
            )
            R.id.day_column_2 -> listOf(
                R.id.day2_checkin_1, R.id.day2_checkin_2, R.id.day2_checkin_3,
                R.id.day2_checkin_4, R.id.day2_checkin_5, R.id.day2_checkin_6
            )
            R.id.day_column_3 -> listOf(
                R.id.day3_checkin_1, R.id.day3_checkin_2, R.id.day3_checkin_3,
                R.id.day3_checkin_4, R.id.day3_checkin_5, R.id.day3_checkin_6
            )
            R.id.day_column_4 -> listOf(
                R.id.day4_checkin_1, R.id.day4_checkin_2, R.id.day4_checkin_3,
                R.id.day4_checkin_4, R.id.day4_checkin_5, R.id.day4_checkin_6
            )
            R.id.day_column_5 -> listOf(
                R.id.day5_checkin_1, R.id.day5_checkin_2, R.id.day5_checkin_3,
                R.id.day5_checkin_4, R.id.day5_checkin_5, R.id.day5_checkin_6
            )
            R.id.day_column_6 -> listOf(
                R.id.day6_checkin_1, R.id.day6_checkin_2, R.id.day6_checkin_3,
                R.id.day6_checkin_4, R.id.day6_checkin_5, R.id.day6_checkin_6
            )
            R.id.day_column_7 -> listOf(
                R.id.day7_checkin_1, R.id.day7_checkin_2, R.id.day7_checkin_3,
                R.id.day7_checkin_4, R.id.day7_checkin_5, R.id.day7_checkin_6
            )
            else -> emptyList()
        }

        val badgeIds = when (columnId) {
            R.id.day_column_1 -> listOf(
                R.id.day1_badge_1, R.id.day1_badge_2, R.id.day1_badge_3,
                R.id.day1_badge_4, R.id.day1_badge_5, R.id.day1_badge_6
            )
            R.id.day_column_2 -> listOf(
                R.id.day2_badge_1, R.id.day2_badge_2, R.id.day2_badge_3,
                R.id.day2_badge_4, R.id.day2_badge_5, R.id.day2_badge_6
            )
            R.id.day_column_3 -> listOf(
                R.id.day3_badge_1, R.id.day3_badge_2, R.id.day3_badge_3,
                R.id.day3_badge_4, R.id.day3_badge_5, R.id.day3_badge_6
            )
            R.id.day_column_4 -> listOf(
                R.id.day4_badge_1, R.id.day4_badge_2, R.id.day4_badge_3,
                R.id.day4_badge_4, R.id.day4_badge_5, R.id.day4_badge_6
            )
            R.id.day_column_5 -> listOf(
                R.id.day5_badge_1, R.id.day5_badge_2, R.id.day5_badge_3,
                R.id.day5_badge_4, R.id.day5_badge_5, R.id.day5_badge_6
            )
            R.id.day_column_6 -> listOf(
                R.id.day6_badge_1, R.id.day6_badge_2, R.id.day6_badge_3,
                R.id.day6_badge_4, R.id.day6_badge_5, R.id.day6_badge_6
            )
            R.id.day_column_7 -> listOf(
                R.id.day7_badge_1, R.id.day7_badge_2, R.id.day7_badge_3,
                R.id.day7_badge_4, R.id.day7_badge_5, R.id.day7_badge_6
            )
            else -> emptyList()
        }

        val nameIds = when (columnId) {
            R.id.day_column_1 -> listOf(
                R.id.day1_name_1, R.id.day1_name_2, R.id.day1_name_3,
                R.id.day1_name_4, R.id.day1_name_5, R.id.day1_name_6
            )
            R.id.day_column_2 -> listOf(
                R.id.day2_name_1, R.id.day2_name_2, R.id.day2_name_3,
                R.id.day2_name_4, R.id.day2_name_5, R.id.day2_name_6
            )
            R.id.day_column_3 -> listOf(
                R.id.day3_name_1, R.id.day3_name_2, R.id.day3_name_3,
                R.id.day3_name_4, R.id.day3_name_5, R.id.day3_name_6
            )
            R.id.day_column_4 -> listOf(
                R.id.day4_name_1, R.id.day4_name_2, R.id.day4_name_3,
                R.id.day4_name_4, R.id.day4_name_5, R.id.day4_name_6
            )
            R.id.day_column_5 -> listOf(
                R.id.day5_name_1, R.id.day5_name_2, R.id.day5_name_3,
                R.id.day5_name_4, R.id.day5_name_5, R.id.day5_name_6
            )
            R.id.day_column_6 -> listOf(
                R.id.day6_name_1, R.id.day6_name_2, R.id.day6_name_3,
                R.id.day6_name_4, R.id.day6_name_5, R.id.day6_name_6
            )
            R.id.day_column_7 -> listOf(
                R.id.day7_name_1, R.id.day7_name_2, R.id.day7_name_3,
                R.id.day7_name_4, R.id.day7_name_5, R.id.day7_name_6
            )
            else -> emptyList()
        }

        val moreCountId = when (columnId) {
            R.id.day_column_1 -> R.id.day1_more_count
            R.id.day_column_2 -> R.id.day2_more_count
            R.id.day_column_3 -> R.id.day3_more_count
            R.id.day_column_4 -> R.id.day4_more_count
            R.id.day_column_5 -> R.id.day5_more_count
            R.id.day_column_6 -> R.id.day6_more_count
            R.id.day_column_7 -> R.id.day7_more_count
            else -> 0
        }

        // 遍历打卡项目，显示前6个
        val displayCount = minOf(items.length(), MAX_ITEMS_PER_DAY)
        for (i in 0 until displayCount) {
            val item = items.getJSONObject(i)
            val itemId = item.optString("id", "")
            val itemName = item.optString("name", "")
            val colorName = item.optString("color", "gray")

            // 获取徽章颜色
            val badgeColor = ITEM_COLORS[colorName] ?: DEFAULT_BADGE_COLOR

            // 显示打卡项目
            views.setViewVisibility(checkinIds[i], View.VISIBLE)

            // 设置彩色竖条徽章
            views.setColorStateList(
                badgeIds[i],
                "setBackgroundTintList",
                ColorStateList.valueOf(badgeColor)
            )

            // 设置项目名称（使用强调色）
            views.setTextViewText(nameIds[i], itemName)
            views.setTextColor(nameIds[i], accentColor)

            // 未来日期降低透明度
            if (isFuture) {
                views.setFloat(checkinIds[i], "setAlpha", 0.5f)
            } else {
                views.setFloat(checkinIds[i], "setAlpha", 1.0f)
                // 设置点击事件（只对非未来日期）
                setupItemClickIntent(context, views, checkinIds[i], itemId, dateStr)
            }
        }

        // 隐藏多余的项目槽位
        for (i in displayCount until MAX_ITEMS_PER_DAY) {
            if (i < checkinIds.size) {
                views.setViewVisibility(checkinIds[i], View.GONE)
            }
        }

        // 显示更多项目数量提示
        if (items.length() > MAX_ITEMS_PER_DAY) {
            val moreCount = items.length() - MAX_ITEMS_PER_DAY
            views.setTextViewText(moreCountId, "+$moreCount")
            views.setTextColor(moreCountId, accentColor)
            views.setViewVisibility(moreCountId, View.VISIBLE)
        } else {
            views.setViewVisibility(moreCountId, View.GONE)
        }
    }

    /**
     * 设置空白状态
     */
    private fun setupEmptyWidget(views: RemoteViews, context: Context) {
        views.setViewVisibility(R.id.calendar_today_empty_hint, View.VISIBLE)
        views.setViewVisibility(R.id.calendar_today_content, View.GONE)

        // 设置点击跳转到打卡插件
        val intent = Intent(Intent.ACTION_VIEW)
        intent.data = Uri.parse("memento://widget/checkin")
        intent.setPackage("github.hunmer.memento")
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP

        val pendingIntent = PendingIntent.getActivity(
            context,
            "calendar_today_list".hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.calendar_today_widget_container, pendingIntent)
    }

    /**
     * 设置单个打卡项目点击事件（打开该项目的打卡对话框，传入日期）
     */
    private fun setupItemClickIntent(
        context: Context,
        views: RemoteViews,
        viewId: Int,
        itemId: String,
        dateStr: String
    ) {
        val intent = Intent(Intent.ACTION_VIEW)
        intent.data = Uri.parse("memento://widget/checkin_item/record?itemId=$itemId&date=$dateStr")
        intent.setPackage("github.hunmer.memento")
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP

        val pendingIntent = PendingIntent.getActivity(
            context,
            "calendar_item_${itemId}_$dateStr".hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(viewId, pendingIntent)
    }

    /**
     * 获取本周的日期列表（周一到周日）
     * @return List of Pair(dateString, dayOfMonth)
     */
    private fun getWeekDays(): List<Pair<String, Int>> {
        val result = mutableListOf<Pair<String, Int>>()
        val cal = Calendar.getInstance()
        val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())

        // 调整到本周一
        val dayOfWeek = cal.get(Calendar.DAY_OF_WEEK)
        val daysFromMonday = if (dayOfWeek == Calendar.SUNDAY) 6 else dayOfWeek - Calendar.MONDAY
        cal.add(Calendar.DAY_OF_MONTH, -daysFromMonday)

        for (i in 0 until 7) {
            val dateStr = dateFormat.format(cal.time)
            val dayOfMonth = cal.get(Calendar.DAY_OF_MONTH)
            result.add(Pair(dateStr, dayOfMonth))
            cal.add(Calendar.DAY_OF_MONTH, 1)
        }

        return result
    }

    /**
     * 获取月份名称（中文）
     */
    private fun getMonthName(dateStr: String): String {
        return try {
            val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
            val date = dateFormat.parse(dateStr)
            val cal = Calendar.getInstance()
            if (date != null) {
                cal.time = date
            }
            val month = cal.get(Calendar.MONTH) + 1
            "${month}月"
        } catch (e: Exception) {
            "五月"
        }
    }

    /**
     * 获取今天的日期字符串
     */
    private fun getTodayDateString(): String {
        val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
        return dateFormat.format(Date())
    }

    /**
     * 获取配置的背景色（主色调）
     */
    private fun getConfiguredPrimaryColor(context: Context, appWidgetId: Int): Int {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val colorStr = prefs.getString("$PREF_KEY_PRIMARY_COLOR$appWidgetId", null)
        return colorStr?.toLongOrNull()?.toInt() ?: DEFAULT_PRIMARY_COLOR
    }

    /**
     * 获取配置的强调色（标题色）
     */
    private fun getConfiguredAccentColor(context: Context, appWidgetId: Int): Int {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val colorStr = prefs.getString("$PREF_KEY_ACCENT_COLOR$appWidgetId", null)
        return colorStr?.toLongOrNull()?.toInt() ?: DEFAULT_ACCENT_COLOR
    }

    /**
     * 获取配置的透明度
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
     * 加载小组件数据
     */
    override fun loadWidgetData(context: Context): JSONObject? {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val jsonString = prefs.getString("calendar_today_list_widget_data", null) ?: return null

        return try {
            JSONObject(jsonString)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to parse widget data", e)
            null
        }
    }

    /**
     * 删除配置
     */
    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        super.onDeleted(context, appWidgetIds)
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val editor = prefs.edit()
        for (appWidgetId in appWidgetIds) {
            editor.remove("$PREF_KEY_PRIMARY_COLOR$appWidgetId")
            editor.remove("$PREF_KEY_ACCENT_COLOR$appWidgetId")
            editor.remove("$PREF_KEY_OPACITY$appWidgetId")
        }
        editor.apply()
    }
}
