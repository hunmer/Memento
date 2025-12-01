package github.hunmer.memento.widgets.providers

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
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
import java.text.SimpleDateFormat
import java.util.*

/**
 * 打卡周视图小组件 Provider
 * 显示一周七天的打卡项目和打卡次数
 *
 * 特点：
 * - 7列网格布局（周一~周日）
 * - 每列显示该日期的打卡项目和次数
 * - 当天高亮显示（黄色）
 * - 未来日期不可点击
 * - 点击跳转到对应日期的打卡对话框
 */
class CheckinWeeklyListWidgetProvider : BasePluginWidgetProvider() {
    override val pluginId: String = "checkin_weekly_list"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_4X2

    companion object {
        private const val TAG = "CheckinWeeklyList"
        private const val PREF_KEY_PRIMARY_COLOR = "checkin_weekly_primary_color_"

        // 默认颜色
        private const val DEFAULT_PRIMARY_COLOR = 0xFFFBBF24.toInt()  // 黄色（当天高亮）

        // 每列最多显示的打卡项目数
        private const val MAX_ITEMS_PER_DAY = 6

        // 打卡项目颜色映射
        private val ITEM_COLORS = mapOf(
            "orange" to intArrayOf(0xFFFED7AA.toInt(), 0xFFFB923C.toInt(), 0xFF9A3412.toInt()),  // bg, badge, text
            "gray" to intArrayOf(0xFFE5E7EB.toInt(), 0xFF9CA3AF.toInt(), 0xFF1F2937.toInt()),
            "purple" to intArrayOf(0xFFE9D5FF.toInt(), 0xFFA855F7.toInt(), 0xFF6B21A8.toInt()),
            "pink" to intArrayOf(0xFFFBCFE8.toInt(), 0xFFEC4899.toInt(), 0xFF9D174D.toInt()),
            "green" to intArrayOf(0xFFD1FAE5.toInt(), 0xFF22C55E.toInt(), 0xFF166534.toInt()),
            "blue" to intArrayOf(0xFFBFDBFE.toInt(), 0xFF3B82F6.toInt(), 0xFF1E40AF.toInt()),
            "red" to intArrayOf(0xFFFECACA.toInt(), 0xFFEF4444.toInt(), 0xFF991B1B.toInt()),
            "yellow" to intArrayOf(0xFFFEF3C7.toInt(), 0xFFF59E0B.toInt(), 0xFF92400E.toInt()),
            "teal" to intArrayOf(0xFFCCFBF1.toInt(), 0xFF14B8A6.toInt(), 0xFF115E59.toInt()),
            "indigo" to intArrayOf(0xFFC7D2FE.toInt(), 0xFF6366F1.toInt(), 0xFF3730A3.toInt())
        )

        // 默认颜色组（灰色）
        private val DEFAULT_ITEM_COLORS = ITEM_COLORS["gray"]!!

        /**
         * 静态方法：刷新所有周视图小组件
         */
        fun refreshAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, CheckinWeeklyListWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)

            val intent = Intent(context, CheckinWeeklyListWidgetProvider::class.java)
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
            val views = RemoteViews(context.packageName, R.layout.widget_checkin_weekly)

            // 读取颜色和透明度配置
            val primaryColor = getConfiguredPrimaryColor(context, appWidgetId)

            // 加载周数据
            val data = loadWidgetData(context)
            if (data != null) {
                setupWeeklyWidget(views, context, data, primaryColor)
            } else {
                setupEmptyWidget(views, context)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to update widget", e)
        }
    }

    /**
     * 设置周视图小组件内容
     */
    private fun setupWeeklyWidget(views: RemoteViews, context: Context, data: JSONObject, highlightColor: Int) {
        val weekDays = getWeekDays()
        val today = getTodayDateString()
        val items = data.optJSONArray("items") ?: JSONArray()
        val dailyCheckins = data.optJSONObject("dailyCheckins") ?: JSONObject()

        Log.d(TAG, "setupWeeklyWidget: today=$today, weekDays=$weekDays, itemCount=${items.length()}")

        // 星期标题 ID
        val weekTitleIds = listOf(
            R.id.week_title_1, R.id.week_title_2, R.id.week_title_3, R.id.week_title_4,
            R.id.week_title_5, R.id.week_title_6, R.id.week_title_7
        )

        // 日期数字 ID
        val dayNumberIds = listOf(
            R.id.day_number_1, R.id.day_number_2, R.id.day_number_3, R.id.day_number_4,
            R.id.day_number_5, R.id.day_number_6, R.id.day_number_7
        )

        // 打卡项目容器 ID
        val dayContainerIds = listOf(
            R.id.day_items_1, R.id.day_items_2, R.id.day_items_3, R.id.day_items_4,
            R.id.day_items_5, R.id.day_items_6, R.id.day_items_7
        )

        // 列点击区域 ID
        val columnClickIds = listOf(
            R.id.column_click_1, R.id.column_click_2, R.id.column_click_3, R.id.column_click_4,
            R.id.column_click_5, R.id.column_click_6, R.id.column_click_7
        )

        val weekNames = listOf("周一", "周二", "周三", "周四", "周五", "周六", "周日")

        for (i in 0 until 7) {
            val dayInfo = weekDays[i]
            val dateStr = dayInfo.first  // yyyy-MM-dd 格式
            val dayOfMonth = dayInfo.second  // 日期数字

            val isToday = dateStr == today
            val isFuture = dateStr > today

            // 设置星期标题
            views.setTextViewText(weekTitleIds[i], weekNames[i])
            views.setTextColor(weekTitleIds[i], if (isToday) highlightColor else 0xFF6B7280.toInt())

            // 设置日期数字
            views.setTextViewText(dayNumberIds[i], dayOfMonth.toString())
            views.setTextColor(dayNumberIds[i], if (isToday) highlightColor else 0xFF1F2937.toInt())

            // 设置该天的打卡项目
            setupDayItems(views, context, dayContainerIds[i], items, dailyCheckins, dateStr, isFuture)

            // 设置列点击事件
            if (!isFuture) {
                setupColumnClickIntent(context, views, columnClickIds[i], dateStr)
            }
        }
    }

    /**
     * 设置某一天的打卡项目列表
     */
    private fun setupDayItems(
        views: RemoteViews,
        context: Context,
        containerId: Int,
        items: JSONArray,
        dailyCheckins: JSONObject,
        dateStr: String,
        isFuture: Boolean
    ) {
        // 获取当天的打卡数据
        val dayData = dailyCheckins.optJSONObject(dateStr)

        // 打卡项目 item ID（每列最多6个）
        val itemIds = when (containerId) {
            R.id.day_items_1 -> listOf(R.id.day1_item_1, R.id.day1_item_2, R.id.day1_item_3, R.id.day1_item_4, R.id.day1_item_5, R.id.day1_item_6)
            R.id.day_items_2 -> listOf(R.id.day2_item_1, R.id.day2_item_2, R.id.day2_item_3, R.id.day2_item_4, R.id.day2_item_5, R.id.day2_item_6)
            R.id.day_items_3 -> listOf(R.id.day3_item_1, R.id.day3_item_2, R.id.day3_item_3, R.id.day3_item_4, R.id.day3_item_5, R.id.day3_item_6)
            R.id.day_items_4 -> listOf(R.id.day4_item_1, R.id.day4_item_2, R.id.day4_item_3, R.id.day4_item_4, R.id.day4_item_5, R.id.day4_item_6)
            R.id.day_items_5 -> listOf(R.id.day5_item_1, R.id.day5_item_2, R.id.day5_item_3, R.id.day5_item_4, R.id.day5_item_5, R.id.day5_item_6)
            R.id.day_items_6 -> listOf(R.id.day6_item_1, R.id.day6_item_2, R.id.day6_item_3, R.id.day6_item_4, R.id.day6_item_5, R.id.day6_item_6)
            R.id.day_items_7 -> listOf(R.id.day7_item_1, R.id.day7_item_2, R.id.day7_item_3, R.id.day7_item_4, R.id.day7_item_5, R.id.day7_item_6)
            else -> emptyList()
        }

        val badgeIds = when (containerId) {
            R.id.day_items_1 -> listOf(R.id.day1_badge_1, R.id.day1_badge_2, R.id.day1_badge_3, R.id.day1_badge_4, R.id.day1_badge_5, R.id.day1_badge_6)
            R.id.day_items_2 -> listOf(R.id.day2_badge_1, R.id.day2_badge_2, R.id.day2_badge_3, R.id.day2_badge_4, R.id.day2_badge_5, R.id.day2_badge_6)
            R.id.day_items_3 -> listOf(R.id.day3_badge_1, R.id.day3_badge_2, R.id.day3_badge_3, R.id.day3_badge_4, R.id.day3_badge_5, R.id.day3_badge_6)
            R.id.day_items_4 -> listOf(R.id.day4_badge_1, R.id.day4_badge_2, R.id.day4_badge_3, R.id.day4_badge_4, R.id.day4_badge_5, R.id.day4_badge_6)
            R.id.day_items_5 -> listOf(R.id.day5_badge_1, R.id.day5_badge_2, R.id.day5_badge_3, R.id.day5_badge_4, R.id.day5_badge_5, R.id.day5_badge_6)
            R.id.day_items_6 -> listOf(R.id.day6_badge_1, R.id.day6_badge_2, R.id.day6_badge_3, R.id.day6_badge_4, R.id.day6_badge_5, R.id.day6_badge_6)
            R.id.day_items_7 -> listOf(R.id.day7_badge_1, R.id.day7_badge_2, R.id.day7_badge_3, R.id.day7_badge_4, R.id.day7_badge_5, R.id.day7_badge_6)
            else -> emptyList()
        }

        val nameIds = when (containerId) {
            R.id.day_items_1 -> listOf(R.id.day1_name_1, R.id.day1_name_2, R.id.day1_name_3, R.id.day1_name_4, R.id.day1_name_5, R.id.day1_name_6)
            R.id.day_items_2 -> listOf(R.id.day2_name_1, R.id.day2_name_2, R.id.day2_name_3, R.id.day2_name_4, R.id.day2_name_5, R.id.day2_name_6)
            R.id.day_items_3 -> listOf(R.id.day3_name_1, R.id.day3_name_2, R.id.day3_name_3, R.id.day3_name_4, R.id.day3_name_5, R.id.day3_name_6)
            R.id.day_items_4 -> listOf(R.id.day4_name_1, R.id.day4_name_2, R.id.day4_name_3, R.id.day4_name_4, R.id.day4_name_5, R.id.day4_name_6)
            R.id.day_items_5 -> listOf(R.id.day5_name_1, R.id.day5_name_2, R.id.day5_name_3, R.id.day5_name_4, R.id.day5_name_5, R.id.day5_name_6)
            R.id.day_items_6 -> listOf(R.id.day6_name_1, R.id.day6_name_2, R.id.day6_name_3, R.id.day6_name_4, R.id.day6_name_5, R.id.day6_name_6)
            R.id.day_items_7 -> listOf(R.id.day7_name_1, R.id.day7_name_2, R.id.day7_name_3, R.id.day7_name_4, R.id.day7_name_5, R.id.day7_name_6)
            else -> emptyList()
        }

        // 遍历所有打卡项目
        for (i in 0 until minOf(items.length(), MAX_ITEMS_PER_DAY)) {
            val item = items.getJSONObject(i)
            val itemId = item.optString("id", "")
            val itemName = item.optString("name", "")
            val colorName = item.optString("color", "gray")

            // 获取该打卡项目在当天的打卡次数
            val count = dayData?.optInt(itemId, 0) ?: 0

            // 获取颜色组
            val colors = ITEM_COLORS[colorName] ?: DEFAULT_ITEM_COLORS

            // 显示该项目
            views.setViewVisibility(itemIds[i], View.VISIBLE)

            // 设置背景色 (使用 setInt 兼容旧版本)
            views.setInt(itemIds[i], "setBackgroundColor", colors[0])

            // 设置徽章（次数）
            views.setTextViewText(badgeIds[i], count.toString())
            views.setTextColor(badgeIds[i], Color.WHITE)
            views.setInt(badgeIds[i], "setBackgroundColor", colors[1])

            // 设置名称
            views.setTextViewText(nameIds[i], itemName)
            views.setTextColor(nameIds[i], colors[2])

            // 未来日期降低透明度
            if (isFuture) {
                views.setFloat(itemIds[i], "setAlpha", 0.5f)
            } else {
                views.setFloat(itemIds[i], "setAlpha", 1.0f)
            }

            // 设置单个项目点击事件
            if (!isFuture) {
                setupItemClickIntent(context, views, itemIds[i], itemId, dateStr)
            }
        }

        // 隐藏多余的项目槽位
        for (i in items.length() until MAX_ITEMS_PER_DAY) {
            if (i < itemIds.size) {
                views.setViewVisibility(itemIds[i], View.GONE)
            }
        }
    }

    /**
     * 设置空白状态
     */
    private fun setupEmptyWidget(views: RemoteViews, context: Context) {
        views.setViewVisibility(R.id.weekly_empty_hint, View.VISIBLE)
        views.setViewVisibility(R.id.weekly_content, View.GONE)

        // 设置点击跳转到打卡插件
        val intent = Intent(Intent.ACTION_VIEW)
        intent.data = Uri.parse("memento://widget/checkin")
        intent.setPackage("github.hunmer.memento")
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP

        val pendingIntent = PendingIntent.getActivity(
            context,
            "checkin_weekly".hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.weekly_widget_container, pendingIntent)
    }

    /**
     * 设置列点击事件（跳转到该日期的打卡页面）
     */
    private fun setupColumnClickIntent(context: Context, views: RemoteViews, viewId: Int, dateStr: String) {
        val intent = Intent(Intent.ACTION_VIEW)
        intent.data = Uri.parse("memento://widget/checkin/date?date=$dateStr")
        intent.setPackage("github.hunmer.memento")
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP

        val pendingIntent = PendingIntent.getActivity(
            context,
            "checkin_column_$dateStr".hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(viewId, pendingIntent)
    }

    /**
     * 设置单个打卡项目点击事件（打开该项目的打卡对话框）
     */
    private fun setupItemClickIntent(context: Context, views: RemoteViews, viewId: Int, itemId: String, dateStr: String) {
        val intent = Intent(Intent.ACTION_VIEW)
        intent.data = Uri.parse("memento://widget/checkin_item/record?itemId=$itemId&date=$dateStr")
        intent.setPackage("github.hunmer.memento")
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP

        val pendingIntent = PendingIntent.getActivity(
            context,
            "checkin_item_${itemId}_$dateStr".hashCode(),
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
     * 获取今天的日期字符串
     */
    private fun getTodayDateString(): String {
        val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
        return dateFormat.format(Date())
    }

    /**
     * 获取配置的高亮色（主色调）
     */
    private fun getConfiguredPrimaryColor(context: Context, appWidgetId: Int): Int {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val colorStr = prefs.getString("$PREF_KEY_PRIMARY_COLOR$appWidgetId", null)
        return colorStr?.toLongOrNull()?.toInt() ?: DEFAULT_PRIMARY_COLOR
    }

    /**
     * 加载周视图数据
     */
    override fun loadWidgetData(context: Context): JSONObject? {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val jsonString = prefs.getString("checkin_weekly_list_widget_data", null) ?: return null

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
        }
        editor.apply()
    }
}
