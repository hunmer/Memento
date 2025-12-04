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
import github.hunmer.memento.widgets.services.ActivityWeeklyWidgetService

/**
 * 活动周视图小组件Provider
 *
 * 功能：
 * - 显示7天×24小时热力图
 * - 显示周标题和导航按钮
 * - 显示前20个活动标签列表（可滚动）
 * - 支持周切换
 * - 支持点击标签打开统计页面
 */
class ActivityWeeklyWidgetProvider : AppWidgetProvider() {

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
            editor.remove("activity_weekly_data_$appWidgetId")
            editor.remove("activity_weekly_primary_color_$appWidgetId")
            editor.remove("activity_weekly_accent_color_$appWidgetId")
            editor.remove("activity_weekly_opacity_$appWidgetId")
        }
        editor.apply()

        // 通知 Flutter 端清理已删除的 widgetId
        val intent = Intent("github.hunmer.memento.CLEANUP_WIDGET_IDS").apply {
            putExtra("deletedWidgetIds", appWidgetIds)
            putExtra("widgetType", "activity_weekly")
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
        val dataJson = prefs.getString("activity_weekly_data_$appWidgetId", null)

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

        // 通知 ListView 刷新数据（RemoteViewsFactory.onDataSetChanged 会被调用）
        appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.activity_list)
    }

    /**
     * 构建配置提示视图（首次添加时显示）
     */
    private fun buildConfigPromptView(context: Context, widgetId: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_activity_weekly)

        views.setTextViewText(R.id.config_prompt, "点击设置小组件")
        views.setViewVisibility(R.id.config_prompt, View.VISIBLE)
        views.setViewVisibility(R.id.content_container, View.GONE)

        // deeplink到配置页面
        val deepLinkIntent = Intent(Intent.ACTION_VIEW).apply {
            data = Uri.parse("memento://activity_weekly_config?widgetId=$widgetId")
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
        val views = RemoteViews(context.packageName, R.layout.widget_activity_weekly)
        val json = JSONObject(dataJson)

        val config = json.getJSONObject("config")
        val data = json.getJSONObject("data")

        views.setViewVisibility(R.id.config_prompt, View.GONE)
        views.setViewVisibility(R.id.content_container, View.VISIBLE)

        // 读取颜色配置
        val primaryColor = config.getString("backgroundColor").toLongOrNull()?.toInt()
            ?: DEFAULT_PRIMARY_COLOR
        val accentColor = config.getString("accentColor").toLongOrNull()?.toInt()
            ?: DEFAULT_ACCENT_COLOR
        val opacity = config.optDouble("opacity", 0.95).toFloat()

        // 应用背景色（带透明度）
        val bgColor = applyOpacity(primaryColor, opacity)
        views.setInt(R.id.widget_root, "setBackgroundColor", bgColor)

        // 渲染热力图网格（168个格子）
        val heatmapData = data.getJSONObject("heatmap")
        val heatmap = parseHeatmap(heatmapData)
        setHeatmapGridColors(views, R.id.heatmap_container, heatmap, accentColor)

        // 设置周标题
        val weekRangeText = data.getString("weekRangeText")
        views.setTextViewText(R.id.week_title, weekRangeText)
        views.setTextColor(R.id.week_title, accentColor)

        // 设置周切换按钮颜色
        views.setInt(R.id.btn_prev_week, "setColorFilter", accentColor)
        views.setInt(R.id.btn_next_week, "setColorFilter", accentColor)

        // 设置周切换按钮点击事件
        setupWeekNavigation(context, views, widgetId)

        // 设置活动列表
        val listIntent = Intent(context, ActivityWeeklyWidgetService::class.java).apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
            setData(Uri.parse(this.toUri(Intent.URI_INTENT_SCHEME)))
        }
        views.setRemoteAdapter(R.id.activity_list, listIntent)

        // 列表项点击事件（使用模板PendingIntent）
        val clickIntentTemplate = Intent(context, ActivityWeeklyWidgetProvider::class.java).apply {
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

        return views
    }

    /**
     * 设置热力图网格颜色（24行7列 = 168个格子）
     * 直接设置预定义View的背景色
     *
     * 布局：24行（每小时），每行7列（每天）
     * 索引：index = hour * 7 + day
     *
     * 数据格式：heatmap[hour][day] = 颜色值（0 表示无活动）
     */
    private fun setHeatmapGridColors(
        views: RemoteViews,
        containerId: Int,
        heatmap: List<List<Int>>,
        accentColor: Int
    ) {
        // 无活动时的背景色（浅灰色）
        val emptyColor = Color.parseColor("#F5F5F5")

        // 168个格子的资源ID数组（Android资源ID不是连续的，必须显式列出）
        val cellIds = intArrayOf(
            // 第0行 - 0点 (周一到周日)
            R.id.heatmap_cell_0, R.id.heatmap_cell_1, R.id.heatmap_cell_2, R.id.heatmap_cell_3, R.id.heatmap_cell_4, R.id.heatmap_cell_5, R.id.heatmap_cell_6,
            // 第1行 - 1点
            R.id.heatmap_cell_7, R.id.heatmap_cell_8, R.id.heatmap_cell_9, R.id.heatmap_cell_10, R.id.heatmap_cell_11, R.id.heatmap_cell_12, R.id.heatmap_cell_13,
            // 第2行 - 2点
            R.id.heatmap_cell_14, R.id.heatmap_cell_15, R.id.heatmap_cell_16, R.id.heatmap_cell_17, R.id.heatmap_cell_18, R.id.heatmap_cell_19, R.id.heatmap_cell_20,
            // 第3行 - 3点
            R.id.heatmap_cell_21, R.id.heatmap_cell_22, R.id.heatmap_cell_23, R.id.heatmap_cell_24, R.id.heatmap_cell_25, R.id.heatmap_cell_26, R.id.heatmap_cell_27,
            // 第4行 - 4点
            R.id.heatmap_cell_28, R.id.heatmap_cell_29, R.id.heatmap_cell_30, R.id.heatmap_cell_31, R.id.heatmap_cell_32, R.id.heatmap_cell_33, R.id.heatmap_cell_34,
            // 第5行 - 5点
            R.id.heatmap_cell_35, R.id.heatmap_cell_36, R.id.heatmap_cell_37, R.id.heatmap_cell_38, R.id.heatmap_cell_39, R.id.heatmap_cell_40, R.id.heatmap_cell_41,
            // 第6行 - 6点
            R.id.heatmap_cell_42, R.id.heatmap_cell_43, R.id.heatmap_cell_44, R.id.heatmap_cell_45, R.id.heatmap_cell_46, R.id.heatmap_cell_47, R.id.heatmap_cell_48,
            // 第7行 - 7点
            R.id.heatmap_cell_49, R.id.heatmap_cell_50, R.id.heatmap_cell_51, R.id.heatmap_cell_52, R.id.heatmap_cell_53, R.id.heatmap_cell_54, R.id.heatmap_cell_55,
            // 第8行 - 8点
            R.id.heatmap_cell_56, R.id.heatmap_cell_57, R.id.heatmap_cell_58, R.id.heatmap_cell_59, R.id.heatmap_cell_60, R.id.heatmap_cell_61, R.id.heatmap_cell_62,
            // 第9行 - 9点
            R.id.heatmap_cell_63, R.id.heatmap_cell_64, R.id.heatmap_cell_65, R.id.heatmap_cell_66, R.id.heatmap_cell_67, R.id.heatmap_cell_68, R.id.heatmap_cell_69,
            // 第10行 - 10点
            R.id.heatmap_cell_70, R.id.heatmap_cell_71, R.id.heatmap_cell_72, R.id.heatmap_cell_73, R.id.heatmap_cell_74, R.id.heatmap_cell_75, R.id.heatmap_cell_76,
            // 第11行 - 11点
            R.id.heatmap_cell_77, R.id.heatmap_cell_78, R.id.heatmap_cell_79, R.id.heatmap_cell_80, R.id.heatmap_cell_81, R.id.heatmap_cell_82, R.id.heatmap_cell_83,
            // 第12行 - 12点
            R.id.heatmap_cell_84, R.id.heatmap_cell_85, R.id.heatmap_cell_86, R.id.heatmap_cell_87, R.id.heatmap_cell_88, R.id.heatmap_cell_89, R.id.heatmap_cell_90,
            // 第13行 - 13点
            R.id.heatmap_cell_91, R.id.heatmap_cell_92, R.id.heatmap_cell_93, R.id.heatmap_cell_94, R.id.heatmap_cell_95, R.id.heatmap_cell_96, R.id.heatmap_cell_97,
            // 第14行 - 14点
            R.id.heatmap_cell_98, R.id.heatmap_cell_99, R.id.heatmap_cell_100, R.id.heatmap_cell_101, R.id.heatmap_cell_102, R.id.heatmap_cell_103, R.id.heatmap_cell_104,
            // 第15行 - 15点
            R.id.heatmap_cell_105, R.id.heatmap_cell_106, R.id.heatmap_cell_107, R.id.heatmap_cell_108, R.id.heatmap_cell_109, R.id.heatmap_cell_110, R.id.heatmap_cell_111,
            // 第16行 - 16点
            R.id.heatmap_cell_112, R.id.heatmap_cell_113, R.id.heatmap_cell_114, R.id.heatmap_cell_115, R.id.heatmap_cell_116, R.id.heatmap_cell_117, R.id.heatmap_cell_118,
            // 第17行 - 17点
            R.id.heatmap_cell_119, R.id.heatmap_cell_120, R.id.heatmap_cell_121, R.id.heatmap_cell_122, R.id.heatmap_cell_123, R.id.heatmap_cell_124, R.id.heatmap_cell_125,
            // 第18行 - 18点
            R.id.heatmap_cell_126, R.id.heatmap_cell_127, R.id.heatmap_cell_128, R.id.heatmap_cell_129, R.id.heatmap_cell_130, R.id.heatmap_cell_131, R.id.heatmap_cell_132,
            // 第19行 - 19点
            R.id.heatmap_cell_133, R.id.heatmap_cell_134, R.id.heatmap_cell_135, R.id.heatmap_cell_136, R.id.heatmap_cell_137, R.id.heatmap_cell_138, R.id.heatmap_cell_139,
            // 第20行 - 20点
            R.id.heatmap_cell_140, R.id.heatmap_cell_141, R.id.heatmap_cell_142, R.id.heatmap_cell_143, R.id.heatmap_cell_144, R.id.heatmap_cell_145, R.id.heatmap_cell_146,
            // 第21行 - 21点
            R.id.heatmap_cell_147, R.id.heatmap_cell_148, R.id.heatmap_cell_149, R.id.heatmap_cell_150, R.id.heatmap_cell_151, R.id.heatmap_cell_152, R.id.heatmap_cell_153,
            // 第22行 - 22点
            R.id.heatmap_cell_154, R.id.heatmap_cell_155, R.id.heatmap_cell_156, R.id.heatmap_cell_157, R.id.heatmap_cell_158, R.id.heatmap_cell_159, R.id.heatmap_cell_160,
            // 第23行 - 23点
            R.id.heatmap_cell_161, R.id.heatmap_cell_162, R.id.heatmap_cell_163, R.id.heatmap_cell_164, R.id.heatmap_cell_165, R.id.heatmap_cell_166, R.id.heatmap_cell_167
        )

        // 循环设置168个格子的颜色（24小时×7天）
        for (hour in 0..23) {
            for (day in 0..6) {
                // 计算格子索引：24行7列布局
                val index = hour * 7 + day
                val cellId = cellIds[index]

                // 获取热力图数据：heatmap[hour][day] = 颜色值
                val colorValue = if (hour < heatmap.size && day < heatmap[hour].size) {
                    heatmap[hour][day]
                } else {
                    0
                }

                // 如果颜色值为0（无活动），使用空白色；否则直接使用活动颜色
                val color = if (colorValue == 0) emptyColor else colorValue

                // 设置每个格子的背景色
                views.setInt(cellId, "setBackgroundColor", color)
            }
        }
    }

    /**
     * 设置周切换按钮事件
     */
    private fun setupWeekNavigation(context: Context, views: RemoteViews, widgetId: Int) {
        // 上一周按钮
        val prevIntent = Intent(context, ActivityWeeklyWidgetProvider::class.java).apply {
            action = ACTION_PREV_WEEK
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
        }
        views.setOnClickPendingIntent(
            R.id.btn_prev_week,
            PendingIntent.getBroadcast(
                context, widgetId * 10 + 1, prevIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        )

        // 下一周按钮
        val nextIntent = Intent(context, ActivityWeeklyWidgetProvider::class.java).apply {
            action = ACTION_NEXT_WEEK
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
        }
        views.setOnClickPendingIntent(
            R.id.btn_next_week,
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
            ACTION_PREV_WEEK -> changeWeek(context, intent, -1)
            ACTION_NEXT_WEEK -> changeWeek(context, intent, 1)
            ACTION_ITEM_CLICK -> {
                val tagName = intent.getStringExtra("tag_name")
                if (tagName != null) {
                    openTagStatistics(context, tagName)
                }
            }
        }
    }

    /**
     * 切换周（更新weekOffset）
     */
    private fun changeWeek(context: Context, intent: Intent, delta: Int) {
        val widgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, -1)
        if (widgetId == -1) return

        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val currentData = prefs.getString("activity_weekly_data_$widgetId", null) ?: return

        try {
            val json = JSONObject(currentData)
            val config = json.getJSONObject("config")

            val currentOffset = config.optInt("currentWeekOffset", 0)
            val newOffset = currentOffset + delta

            // 更新offset
            config.put("currentWeekOffset", newOffset)
            json.put("config", config)

            prefs.edit().putString("activity_weekly_data_$widgetId", json.toString()).apply()

            // 通知Flutter重新计算数据
            val refreshIntent = Intent("github.hunmer.memento.REFRESH_ACTIVITY_WEEKLY_WIDGET").apply {
                putExtra("widgetId", widgetId)
                putExtra("weekOffset", newOffset)
            }
            context.sendBroadcast(refreshIntent)

            android.util.Log.d(TAG, "Week changed: widgetId=$widgetId, newOffset=$newOffset")
        } catch (e: Exception) {
            android.util.Log.e(TAG, "Error changing week: $e")
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

    // ==================== 工具方法 ====================

    /**
     * 应用透明度到颜色
     */
    private fun applyOpacity(color: Int, opacity: Float): Int {
        val alpha = (255 * opacity).toInt().coerceIn(0, 255)
        return Color.argb(alpha, Color.red(color), Color.green(color), Color.blue(color))
    }

    /**
     * 颜色插值（用于热力图）
     */
    private fun interpolateColor(startColor: Int, endColor: Int, fraction: Float): Int {
        val clampedFraction = fraction.coerceIn(0f, 1f)

        val startA = Color.alpha(startColor)
        val startR = Color.red(startColor)
        val startG = Color.green(startColor)
        val startB = Color.blue(startColor)

        val endA = Color.alpha(endColor)
        val endR = Color.red(endColor)
        val endG = Color.green(endColor)
        val endB = Color.blue(endColor)

        return Color.argb(
            (startA + (endA - startA) * clampedFraction).toInt(),
            (startR + (endR - startR) * clampedFraction).toInt(),
            (startG + (endG - startG) * clampedFraction).toInt(),
            (startB + (endB - startB) * clampedFraction).toInt()
        )
    }

    /**
     * 解析热力图JSON数据
     */
    private fun parseHeatmap(heatmapJson: JSONObject): List<List<Int>> {
        val heatmapArray = heatmapJson.getJSONArray("heatmap")
        return List(24) { hour ->
            val hourArray = heatmapArray.getJSONArray(hour)
            List(7) { day -> hourArray.optInt(day, 0) }
        }
    }

    companion object {
        private const val TAG = "ActivityWeeklyWidget"
        private const val PREFS_NAME = "HomeWidgetPreferences"
        private const val ACTION_PREV_WEEK = "github.hunmer.memento.widget.ACTIVITY_PREV_WEEK"
        private const val ACTION_NEXT_WEEK = "github.hunmer.memento.widget.ACTIVITY_NEXT_WEEK"
        private const val ACTION_ITEM_CLICK = "github.hunmer.memento.widget.ACTIVITY_ITEM_CLICK"

        private const val DEFAULT_PRIMARY_COLOR = 0xFFEFF7F0.toInt()
        private const val DEFAULT_ACCENT_COLOR = 0xFF607afb.toInt()
    }
}
