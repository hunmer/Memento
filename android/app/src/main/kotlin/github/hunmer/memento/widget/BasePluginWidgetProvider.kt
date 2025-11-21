package github.hunmer.memento.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import github.hunmer.memento.MainActivity
import github.hunmer.memento.R
import org.json.JSONObject

/**
 * 插件小组件基类
 *
 * 提供通用的小组件功能：
 * - 从 SharedPreferences 读取数据
 * - 构建 RemoteViews
 * - 处理点击跳转
 */
abstract class BasePluginWidgetProvider : AppWidgetProvider() {

    /**
     * 插件ID，子类必须实现
     */
    abstract val pluginId: String

    /**
     * 小组件尺寸类型
     */
    enum class WidgetSize {
        SIZE_1X1,
        SIZE_2X1,
        SIZE_2X2
    }

    /**
     * 获取小组件尺寸，子类可覆盖
     */
    open val widgetSize: WidgetSize = WidgetSize.SIZE_1X1

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    /**
     * 更新单个小组件
     */
    protected open fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = when (widgetSize) {
            WidgetSize.SIZE_1X1 -> RemoteViews(context.packageName, R.layout.widget_plugin_1x1)
            WidgetSize.SIZE_2X1 -> RemoteViews(context.packageName, R.layout.widget_plugin_2x1)
            WidgetSize.SIZE_2X2 -> RemoteViews(context.packageName, R.layout.widget_plugin_2x2)
        }

        // 读取插件数据
        val data = loadWidgetData(context)

        if (data != null) {
            // 设置背景颜色
            val colorValue = data.optInt("colorValue", Color.BLUE)
            // views.setInt(R.id.widget_container, "setBackgroundColor", colorValue)

            when (widgetSize) {
                WidgetSize.SIZE_1X1 -> setup1x1Widget(views, data)
                WidgetSize.SIZE_2X1 -> setup2x1Widget(views, data)
                WidgetSize.SIZE_2X2 -> setup2x2Widget(views, data)
            }
        } else {
            // 没有数据时显示默认内容
            setupDefaultWidget(views)
        }

        // 设置点击跳转
        setupClickIntent(context, views)

        // 更新小组件
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    /**
     * 设置 1x1 小组件内容
     */
    private fun setup1x1Widget(views: RemoteViews, data: JSONObject) {
        // 设置图标
        val iconCodePoint = data.optInt("iconCodePoint", 0xE87C) // default: check_box
        val iconChar = try {
            String(Character.toChars(iconCodePoint))
        } catch (e: Exception) {
            "·"
        }
        views.setTextViewText(R.id.widget_icon, iconChar)

        // 设置统计值和标签
        val stats = data.optJSONArray("stats")
        if (stats != null && stats.length() > 0) {
            val firstStat = stats.getJSONObject(0)
            views.setTextViewText(R.id.widget_value, firstStat.optString("value", "-"))
            views.setTextViewText(R.id.widget_label, firstStat.optString("label", ""))
        } else {
            views.setTextViewText(R.id.widget_value, "-")
            views.setTextViewText(R.id.widget_label, data.optString("pluginName", pluginId))
        }
    }

    /**
     * 设置 2x1 小组件内容
     */
    private fun setup2x1Widget(views: RemoteViews, data: JSONObject) {
        // 设置图标
        val iconCodePoint = data.optInt("iconCodePoint", 0xE87C)
        val iconChar = try {
            String(Character.toChars(iconCodePoint))
        } catch (e: Exception) {
            "·"
        }
        views.setTextViewText(R.id.widget_icon, iconChar)

        // 设置标题
        views.setTextViewText(R.id.widget_title, data.optString("pluginName", pluginId))

        // 设置统计项
        val stats = data.optJSONArray("stats")
        if (stats != null) {
            for (i in 0 until minOf(stats.length(), 2)) {
                val stat = stats.getJSONObject(i)
                val itemId = if (i == 0) R.id.stat_item_1 else R.id.stat_item_2
                val valueId = if (i == 0) R.id.stat_value_1 else R.id.stat_value_2
                val labelId = if (i == 0) R.id.stat_label_1 else R.id.stat_label_2

                views.setViewVisibility(itemId, View.VISIBLE)
                views.setTextViewText(valueId, stat.optString("value", "-"))
                views.setTextViewText(labelId, stat.optString("label", ""))

                // 如果有自定义颜色
                val statColor = stat.optInt("colorValue", 0)
                if (statColor != 0) {
                    views.setTextColor(valueId, statColor)
                }
            }
        }
    }

    /**
     * 设置 2x2 小组件内容
     */
    private fun setup2x2Widget(views: RemoteViews, data: JSONObject) {
        // 设置图标
        val iconCodePoint = data.optInt("iconCodePoint", 0xE87C)
        val iconChar = try {
            String(Character.toChars(iconCodePoint))
        } catch (e: Exception) {
            "·"
        }
        views.setTextViewText(R.id.widget_icon, iconChar)

        // 设置标题
        views.setTextViewText(R.id.widget_title, data.optString("pluginName", pluginId))

        // 设置统计项（最多4个）
        val stats = data.optJSONArray("stats")
        if (stats != null) {
            val statIds = listOf(
                Triple(R.id.stat_item_1, R.id.stat_value_1, R.id.stat_label_1),
                Triple(R.id.stat_item_2, R.id.stat_value_2, R.id.stat_label_2),
                Triple(R.id.stat_item_3, R.id.stat_value_3, R.id.stat_label_3),
                Triple(R.id.stat_item_4, R.id.stat_value_4, R.id.stat_label_4)
            )

            for (i in 0 until minOf(stats.length(), 4)) {
                val stat = stats.getJSONObject(i)
                val (itemId, valueId, labelId) = statIds[i]

                views.setViewVisibility(itemId, View.VISIBLE)
                views.setTextViewText(valueId, stat.optString("value", "-"))
                views.setTextViewText(labelId, stat.optString("label", ""))

                // 如果有自定义颜色
                val statColor = stat.optInt("colorValue", 0)
                if (statColor != 0) {
                    views.setTextColor(valueId, statColor)
                }
            }
        }
    }

    /**
     * 设置默认显示内容
     */
    private fun setupDefaultWidget(views: RemoteViews) {
        when (widgetSize) {
            WidgetSize.SIZE_1X1 -> {
                views.setTextViewText(R.id.widget_icon, "·")
                views.setTextViewText(R.id.widget_value, "-")
                views.setTextViewText(R.id.widget_label, pluginId)
            }
            WidgetSize.SIZE_2X1 -> {
                views.setTextViewText(R.id.widget_icon, "·")
                views.setTextViewText(R.id.widget_title, pluginId)
                views.setViewVisibility(R.id.stat_item_1, View.GONE)
                views.setViewVisibility(R.id.stat_item_2, View.GONE)
            }
            WidgetSize.SIZE_2X2 -> {
                views.setTextViewText(R.id.widget_icon, "·")
                views.setTextViewText(R.id.widget_title, pluginId)
                views.setViewVisibility(R.id.stat_item_1, View.GONE)
                views.setViewVisibility(R.id.stat_item_2, View.GONE)
                views.setViewVisibility(R.id.stat_item_3, View.GONE)
                views.setViewVisibility(R.id.stat_item_4, View.GONE)
            }
        }
    }

    /**
     * 设置点击跳转
     */
    private fun setupClickIntent(context: Context, views: RemoteViews) {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse("memento://widget/$pluginId")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }

        val pendingIntent = PendingIntent.getActivity(
            context,
            pluginId.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)
    }

    /**
     * 从 SharedPreferences 加载小组件数据
     */
    private fun loadWidgetData(context: Context): JSONObject? {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val jsonString = prefs.getString("${pluginId}_widget_data", null) ?: return null

        return try {
            JSONObject(jsonString)
        } catch (e: Exception) {
            null
        }
    }

    companion object {
        const val PREFS_NAME = "HomeWidgetPreferences"
    }
}
