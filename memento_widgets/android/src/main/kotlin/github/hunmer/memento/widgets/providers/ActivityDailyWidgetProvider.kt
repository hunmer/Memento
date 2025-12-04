package github.hunmer.memento.widgets.providers

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.app.PendingIntent
import android.view.View
import android.widget.RemoteViews
import org.json.JSONObject
import github.hunmer.memento_widgets.R
import github.hunmer.memento.widgets.services.ActivityDailyWidgetService

/**
 * 本日活动详细视图小组件Provider
 *
 * 功能：
 * - 显示24小时时间轴（上午/下午）
 * - 显示圆环进度图
 * - 显示活动列表（带emoji和时长）
 * - 显示底部统计信息
 * - 支持日期切换
 */
class ActivityDailyWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        android.util.Log.d(TAG, "onUpdate called for ${appWidgetIds.size} widgets: ${appWidgetIds.contentToString()}")
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val editor = prefs.edit()

        // 清理已删除小组件的数据
        for (appWidgetId in appWidgetIds) {
            editor.remove("activity_daily_data_$appWidgetId")
            editor.remove("activity_daily_primary_color_$appWidgetId")
            editor.remove("activity_daily_accent_color_$appWidgetId")
            editor.remove("activity_daily_opacity_$appWidgetId")
        }
        editor.apply()

        // 通知 Flutter 端清理已删除的 widgetId
        val intent = Intent("github.hunmer.memento.CLEANUP_WIDGET_IDS").apply {
            putExtra("deletedWidgetIds", appWidgetIds)
            putExtra("widgetType", "activity_daily")
        }
        context.sendBroadcast(intent)
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        android.util.Log.d(TAG, "updateAppWidget called for widgetId=$appWidgetId")

        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val dataJson = prefs.getString("activity_daily_data_$appWidgetId", null)

        android.util.Log.d(TAG, "Data from SharedPreferences: ${if (dataJson.isNullOrEmpty()) "null or empty" else "${dataJson.length} chars"}")

        val views = if (dataJson == null || dataJson.isEmpty()) {
            buildConfigPromptView(context, appWidgetId)
        } else {
            try {
                buildContentView(context, appWidgetId, dataJson)
            } catch (e: Exception) {
                android.util.Log.e(TAG, "Error building content view: $e")
                buildConfigPromptView(context, appWidgetId)
            }
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)

        // 通知 ListView 刷新数据
        appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.activity_list)
    }

    /**
     * 构建配置提示视图（首次添加时显示）
     */
    private fun buildConfigPromptView(context: Context, widgetId: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_activity_daily)

        views.setTextViewText(R.id.config_prompt, "点击配置小组件")
        views.setViewVisibility(R.id.config_prompt, View.VISIBLE)
        views.setViewVisibility(R.id.content_container, View.GONE)

        // deeplink到配置页面
        val deepLinkIntent = Intent(Intent.ACTION_VIEW).apply {
            data = Uri.parse("memento://activity_daily_config?widgetId=$widgetId")
            setPackage(context.packageName)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        val pendingIntent = PendingIntent.getActivity(
            context, widgetId, deepLinkIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

        return views
    }

    /**
     * 构建内容视图（已配置的小组件）
     */
    private fun buildContentView(context: Context, widgetId: Int, dataJson: String): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_activity_daily)
        val json = JSONObject(dataJson)

        val config = json.getJSONObject("config")
        val data = json.getJSONObject("data")

        android.util.Log.d(TAG, "Build content view for widget $widgetId")
        android.util.Log.d(TAG, "Data keys: ${data.keys().asSequence().toList()}")

        // 调试输出数据结构
        if (data.has("activities")) {
            val activities = data.getJSONArray("activities")
            android.util.Log.d(TAG, "Found activities array with ${activities.length()} items")
        } else {
            android.util.Log.w(TAG, "No 'activities' field in data")
        }

        if (data.has("timeline")) {
            val timeline = data.getJSONObject("timeline")
            android.util.Log.d(TAG, "Found timeline object with keys: ${timeline.keys().asSequence().toList()}")
        } else {
            android.util.Log.w(TAG, "No 'timeline' field in data")
        }

        views.setViewVisibility(R.id.config_prompt, View.GONE)
        views.setViewVisibility(R.id.content_container, View.VISIBLE)

        // 读取颜色配置
        val primaryColor = config.getString("backgroundColor").toLongOrNull()?.toInt()
            ?: DEFAULT_PRIMARY_COLOR
        val accentColor = config.getString("accentColor").toLongOrNull()?.toInt()
            ?: DEFAULT_ACCENT_COLOR
        val opacity = config.optDouble("opacity", 0.95).toFloat()

        android.util.Log.d(TAG, "Colors: primary=${Integer.toHexString(primaryColor)}, accent=${Integer.toHexString(accentColor)}")

        // 应用背景色（带透明度）
        val bgColor = applyOpacity(primaryColor, opacity)
        views.setInt(R.id.widget_root, "setBackgroundColor", bgColor)

        // 设置日期标题
        val dateText = data.getString("dateText")
        views.setTextViewText(R.id.date_title, dateText)
        views.setTextColor(R.id.date_title, accentColor)

        // 设置进度百分比
        val progressPercent = data.optInt("progressPercent", 0)
        views.setTextViewText(R.id.progress_percent, "$progressPercent%")
        views.setTextColor(R.id.progress_percent, accentColor)

        // 设置日期切换按钮颜色
        views.setInt(R.id.btn_prev_day, "setColorFilter", accentColor)
        views.setInt(R.id.btn_next_day, "setColorFilter", accentColor)

        // 设置时间轴数据
        setTimelineData(views, data, accentColor)

        // 设置底部统计数据（长时间活动列表）
        setLongActivitiesData(views, data)

        // 设置标签统计数据
        setTagStatsData(views, data)

        // 设置日期切换按钮点击事件
        setupDayNavigation(context, views, widgetId)

        // 设置活动列表
        val listIntent = Intent(context, ActivityDailyWidgetService::class.java).apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
            setData(Uri.parse(this.toUri(Intent.URI_INTENT_SCHEME)))
        }
        views.setRemoteAdapter(R.id.activity_list, listIntent)

        // 列表项点击事件
        val clickIntentTemplate = Intent(context, ActivityDailyWidgetProvider::class.java).apply {
            action = ACTION_ITEM_CLICK
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
        }
        val clickPendingIntent = PendingIntent.getBroadcast(
            context, widgetId, clickIntentTemplate,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        )
        views.setPendingIntentTemplate(R.id.activity_list, clickPendingIntent)

        // 空列表提示
        views.setEmptyView(R.id.activity_list, R.id.empty_view)

        // 根据是否有活动来显示/隐藏整个底部统计区域
        val hasActivities = data.optJSONArray("activities")?.length() ?: 0
        if (hasActivities > 0) {
            views.setViewVisibility(R.id.stats_container, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.stats_container, View.GONE)
        }

        return views
    }

    /**
     * 设置时间轴数据（12行，0-11点）
     */
    private fun setTimelineData(views: RemoteViews, data: JSONObject, accentColor: Int) {
        val emptyColor = Color.parseColor("#E5E7EB")

        // 获取时间轴数据
        val timeline = data.optJSONObject("timeline") ?: return
        val amBars = timeline.optJSONArray("amBars")
        val pmDots = timeline.optJSONArray("pmDots")

        android.util.Log.d(TAG, "Timeline data: amBars=${amBars?.length()}, pmDots=${pmDots?.length()}")

        // AM活动条资源ID
        val amBarIds = intArrayOf(
            R.id.am_bar_0, R.id.am_bar_1, R.id.am_bar_2, R.id.am_bar_3,
            R.id.am_bar_4, R.id.am_bar_5, R.id.am_bar_6, R.id.am_bar_7,
            R.id.am_bar_9, R.id.am_bar_10, R.id.am_bar_11
        )

        // 设置AM活动条颜色
        if (amBars != null) {
            for (i in 0 until minOf(amBars.length(), amBarIds.size)) {
                val color = amBars.optLong(i, emptyColor.toLong()).toInt()
                android.util.Log.d(TAG, "Setting AM bar $i to color: ${Integer.toHexString(color)}")
                views.setInt(amBarIds[i], "setBackgroundColor", color)
            }
        }

        // 设置PM活动点（下午12-23点）
        if (pmDots != null) {
            for (hour in 12..23) {
                val dotIndex = hour - 12
                if (dotIndex < pmDots.length()) {
                    val color = pmDots.optLong(dotIndex, 0).toInt()
                    if (color != 0) {
                        // 获取对应小时的dot ID
                        val dotId = when (hour) {
                            12 -> R.id.pm_dot_0_1
                            13 -> R.id.pm_dot_1_1
                            14 -> R.id.pm_dot_2_1
                            15 -> R.id.pm_dot_3_1
                            16 -> R.id.pm_dot_4_1
                            17 -> R.id.pm_dot_5_1
                            18 -> R.id.pm_dot_6_1
                            19 -> R.id.pm_dot_7_1
                            20 -> R.id.pm_dot_8_1
                            21 -> R.id.pm_dot_9_1
                            22 -> R.id.pm_dot_10_1
                            23 -> R.id.pm_dot_11_1
                            else -> R.id.pm_dot_0_1
                        }
                        android.util.Log.d(TAG, "Setting PM dot $hour (index $dotIndex) to color: ${Integer.toHexString(color)}")
                        views.setViewVisibility(dotId, View.VISIBLE)
                        views.setInt(dotId, "setBackgroundColor", color)
                    }
                }
            }
        }
    }

    /**
     * 设置长时间活动数据（左下角显示前几个占用时间最长的活动）
     */
    private fun setLongActivitiesData(views: RemoteViews, data: JSONObject) {
        // 从activities数组中获取前4个活动，按时长排序
        val activities = data.optJSONArray("activities")

        val statDotIds = intArrayOf(R.id.stat_dot_1, R.id.stat_dot_2, R.id.stat_dot_3, R.id.stat_dot_4)
        val statNameIds = intArrayOf(R.id.stat_name_1, R.id.stat_name_2, R.id.stat_name_3, R.id.stat_name_4)
        val statDurationIds = intArrayOf(R.id.stat_duration_1, R.id.stat_duration_2, R.id.stat_duration_3, R.id.stat_duration_4)
        val statRowIds = intArrayOf(R.id.stat_row_1, R.id.stat_row_2, R.id.stat_row_3, R.id.stat_row_4)

        // 如果没有活动数据，隐藏所有行
        if (activities == null || activities.length() == 0) {
            android.util.Log.d(TAG, "No activities found, hiding all stat rows")
            for (rowId in statRowIds) {
                views.setViewVisibility(rowId, View.GONE)
            }
            return
        }

        android.util.Log.d(TAG, "Found ${activities.length()} activities, showing top ones")

        val items = mutableListOf<Triple<String, String, Int>>()

        // 解析activities并提取名称和时长
        for (i in 0 until activities.length()) {
            val activity = activities.optJSONObject(i) ?: continue
            val name = if (activity.optString("name").isNotEmpty()) {
                activity.optString("name")
            } else {
                // 如果标题为空，显示标签（第一个标签或"活动"）
                val tags = activity.optJSONArray("tags")
                if (tags != null && tags.length() > 0) {
                    tags.optString(0)
                } else {
                    "活动"
                }
            }
            val duration = activity.optString("duration", "0h")
            val color = activity.optLong("color", 0xFF607afb.toLong()).toInt()

            items.add(Triple(name, duration, color))
        }

        // 按时长排序（从长到短）
        items.sortWith { item1, item2 ->
            val duration1 = parseDurationToMinutes(item1.second)
            val duration2 = parseDurationToMinutes(item2.second)
            duration2.compareTo(duration1)
        }

        // 取前4个
        val topItems = items.take(4)

        // 设置到UI - 显示前N个，隐藏多余的
        for (i in 0 until 4) {
            if (i < topItems.size) {
                val (name, duration, color) = topItems[i]
                views.setViewVisibility(statRowIds[i], View.VISIBLE)
                views.setTextViewText(statNameIds[i], name)
                views.setTextViewText(statDurationIds[i], duration)
                views.setInt(statDotIds[i], "setBackgroundColor", color)
                android.util.Log.d(TAG, "Setting stat row $i: $name ($duration)")
            } else {
                // 隐藏多余的空行
                views.setViewVisibility(statRowIds[i], View.GONE)
            }
        }
    }

    /**
     * 将时长字符串转换为分钟数（用于排序）
     */
    private fun parseDurationToMinutes(duration: String): Int {
        return try {
            // 处理 "02時30分" 或 "2.5h" 或 "150分" 格式
            when {
                duration.contains("時") && duration.contains("分") -> {
                    // "02時30分" 格式
                    val parts = duration.split("時", "分")
                    val hours = parts[0].toIntOrNull() ?: 0
                    val minutes = parts[1].toIntOrNull() ?: 0
                    hours * 60 + minutes
                }
                duration.contains("h") -> {
                    // "2.5h" 格式
                    val hours = duration.replace("h", "").toDoubleOrNull() ?: 0.0
                    (hours * 60).toInt()
                }
                duration.contains("分") -> {
                    // "150分" 格式
                    duration.replace("分", "").toIntOrNull() ?: 0
                }
                else -> 0
            }
        } catch (e: Exception) {
            android.util.Log.w(TAG, "Failed to parse duration: $duration")
            0
        }
    }

    /**
     * 设置标签统计数据（右上角统计信息）
     */
    private fun setTagStatsData(views: RemoteViews, data: JSONObject) {
        // 如果需要显示标签统计，可以在这里添加
        // 目前右上角主要是日期和进度，进度已经在上面设置了
        android.util.Log.d(TAG, "Tag stats data set")
    }

    /**
     * 设置日期切换按钮事件
     */
    private fun setupDayNavigation(context: Context, views: RemoteViews, widgetId: Int) {
        // 上一日按钮
        val prevIntent = Intent(context, ActivityDailyWidgetProvider::class.java).apply {
            action = ACTION_PREV_DAY
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
        }
        views.setOnClickPendingIntent(
            R.id.btn_prev_day,
            PendingIntent.getBroadcast(
                context, widgetId * 10 + 1, prevIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        )

        // 下一日按钮
        val nextIntent = Intent(context, ActivityDailyWidgetProvider::class.java).apply {
            action = ACTION_NEXT_DAY
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
        }
        views.setOnClickPendingIntent(
            R.id.btn_next_day,
            PendingIntent.getBroadcast(
                context, widgetId * 10 + 2, nextIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        )
    }

    override fun onReceive(context: Context, intent: Intent) {
        android.util.Log.d(TAG, "onReceive: action=${intent.action}")
        super.onReceive(context, intent)

        when (intent.action) {
            ACTION_PREV_DAY -> changeDay(context, intent, -1)
            ACTION_NEXT_DAY -> changeDay(context, intent, 1)
            ACTION_ITEM_CLICK -> {
                val tagName = intent.getStringExtra("tag_name")
                if (tagName != null) {
                    openTagStatistics(context, tagName)
                }
            }
        }
    }

    /**
     * 切换日期（更新dayOffset）
     */
    private fun changeDay(context: Context, intent: Intent, delta: Int) {
        val widgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, -1)
        if (widgetId == -1) return

        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val currentData = prefs.getString("activity_daily_data_$widgetId", null) ?: return

        try {
            val json = JSONObject(currentData)
            val config = json.getJSONObject("config")

            val currentOffset = config.optInt("currentDayOffset", 0)
            val newOffset = currentOffset + delta

            // 更新offset
            config.put("currentDayOffset", newOffset)
            json.put("config", config)

            prefs.edit().putString("activity_daily_data_$widgetId", json.toString()).apply()

            // 通知Flutter重新计算数据
            val refreshIntent = Intent("github.hunmer.memento.REFRESH_ACTIVITY_DAILY_WIDGET").apply {
                putExtra("widgetId", widgetId)
                putExtra("dayOffset", newOffset)
            }
            context.sendBroadcast(refreshIntent)

            android.util.Log.d(TAG, "Day changed: widgetId=$widgetId, newOffset=$newOffset")
        } catch (e: Exception) {
            android.util.Log.e(TAG, "Error changing day: $e")
        }
    }

    /**
     * 打开标签统计页面
     */
    private fun openTagStatistics(context: Context, tagName: String) {
        val intent = Intent(Intent.ACTION_VIEW).apply {
            data = Uri.parse("memento://activity/tag_statistics?tag=${Uri.encode(tagName)}")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
            setPackage(context.packageName)
        }
        context.startActivity(intent)
    }

    /**
     * 应用透明度到颜色
     */
    private fun applyOpacity(color: Int, opacity: Float): Int {
        val alpha = (255 * opacity).toInt().coerceIn(0, 255)
        return Color.argb(alpha, Color.red(color), Color.green(color), Color.blue(color))
    }

    companion object {
        private const val TAG = "ActivityDailyWidget"
        private const val PREFS_NAME = "HomeWidgetPreferences"
        private const val ACTION_PREV_DAY = "github.hunmer.memento.widget.ACTIVITY_PREV_DAY"
        private const val ACTION_NEXT_DAY = "github.hunmer.memento.widget.ACTIVITY_NEXT_DAY"
        private const val ACTION_ITEM_CLICK = "github.hunmer.memento.widget.ACTIVITY_DAILY_ITEM_CLICK"

        private const val DEFAULT_PRIMARY_COLOR = 0xFFF8F9FA.toInt()
        private const val DEFAULT_ACCENT_COLOR = 0xFF1F2937.toInt()
    }
}
