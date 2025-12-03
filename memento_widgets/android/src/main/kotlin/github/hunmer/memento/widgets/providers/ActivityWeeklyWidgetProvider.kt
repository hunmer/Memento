package github.hunmer.memento.widgets.providers

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Color
import android.net.Uri
import android.app.PendingIntent
import android.view.View
import android.widget.RemoteViews
import org.json.JSONObject
import com.example.memento_widgets.R
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

        // 渲染热力图
        val heatmapData = data.getJSONObject("heatmap")
        val heatmap = parseHeatmap(heatmapData)
        val heatmapBitmap = generateHeatmapBitmap(heatmap, accentColor)
        views.setImageViewBitmap(R.id.heatmap_image, heatmapBitmap)

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
     * 生成热力图Bitmap（7天×24小时）
     */
    private fun generateHeatmapBitmap(heatmap: List<List<Int>>, accentColor: Int): Bitmap {
        val maxCount = heatmap.flatten().maxOrNull() ?: 1
        val bitmap = Bitmap.createBitmap(24, 7, Bitmap.Config.ARGB_8888)

        for (day in 0..6) {
            for (hour in 0..23) {
                val count = if (day < heatmap.size && hour < heatmap[day].size) {
                    heatmap[day][hour]
                } else {
                    0
                }

                val intensity = if (maxCount > 0) count.toFloat() / maxCount else 0f
                val color = interpolateColor(Color.WHITE, accentColor, intensity)
                bitmap.setPixel(hour, day, color)
            }
        }

        return bitmap
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
        return List(7) { day ->
            val dayArray = heatmapArray.getJSONArray(day)
            List(24) { hour -> dayArray.optInt(hour, 0) }
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
