package github.hunmer.memento.widgets.providers

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import android.net.Uri
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import github.hunmer.memento_widgets.R
import github.hunmer.memento.widgets.BasePluginWidgetProvider
import org.json.JSONObject

class CalendarAlbumWeeklyWidgetProvider : BasePluginWidgetProvider() {
    override val pluginId: String = "calendar_album_weekly"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_2X2

    companion object {
        private const val PREF_KEY_PRIMARY_COLOR = "calendar_album_weekly_primary_color_"
        private const val PREF_KEY_ACCENT_COLOR = "calendar_album_weekly_accent_color_"
        private const val PREF_KEY_OPACITY = "calendar_album_weekly_opacity_"

        // 默认颜色
        private const val DEFAULT_PRIMARY_COLOR = 0xFF5A9E9A.toInt()  // 绿色背景
        private const val DEFAULT_ACCENT_COLOR = 0xFFFFFFFF.toInt()   // 白色标题
        private const val DEFAULT_OPACITY = 0.95f

        // 点击事件的 action
        private const val ACTION_DAY_CLICKED = "github.hunmer.memento.ACTION_CALENDAR_ALBUM_WEEKLY_DAY_CLICKED"
        private const val EXTRA_DAY_INDEX = "day_index"
    }

    override fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_calendar_album_weekly)

        // 读取颜色和透明度配置
        val primaryColor = getConfiguredPrimaryColor(context, appWidgetId)
        val accentColor = getConfiguredAccentColor(context, appWidgetId)
        val opacity = getConfiguredOpacity(context, appWidgetId)

        // 应用背景颜色（带透明度）- 使用 backgroundTintList 保持圆角效果
        val bgColor = adjustColorAlpha(primaryColor, opacity)
        views.setColorStateList(R.id.weekly_container, "setBackgroundTintList", ColorStateList.valueOf(bgColor))

        // 应用标题色（强调色）
        views.setTextColor(R.id.weekly_title, accentColor)
        views.setTextColor(R.id.weekly_week_info, accentColor)

        Log.d("CalendarAlbumWeeklyWidget", "应用颜色: bg=${Integer.toHexString(primaryColor)}, accent=${Integer.toHexString(accentColor)}, opacity=$opacity")

        // 加载并显示数据
        val data = loadWidgetData(context)
        if (data != null) {
            setupCustomWidget(views, data, context, appWidgetId)
        } else {
            setupDefaultWidget(views, context, appWidgetId)
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    /**
     * 设置自定义小组件
     */
    private fun setupCustomWidget(views: RemoteViews, data: JSONObject, context: Context, appWidgetId: Int) {
        try {
            // 解析周信息
            val weekInfo = data.optJSONObject("weekInfo")
            val weekNumber = weekInfo?.optInt("weekNumber") ?: 0
            val startDateStr = weekInfo?.optString("startDateStr") ?: ""
            val endDateStr = weekInfo?.optString("endDateStr") ?: ""

            // 设置标题
            views.setTextViewText(R.id.weekly_title, "一日一拍")
            views.setTextViewText(R.id.weekly_week_info, "第 $weekNumber 周・$startDateStr - $endDateStr")

            // 解析每日数据
            val days = data.optJSONArray("days")
            if (days != null) {
                for (i in 0 until days.length()) {
                    val day = days.getJSONObject(i)
                    val dayIndex = day.optInt("dayIndex", i)
                    val dayName = day.optString("dayName", "")
                    val hasEntry = day.optBoolean("hasEntry", false)

                    // 设置星期名称
                    val dayNameResId = getDayNameResId(i)
                    if (dayNameResId != 0) {
                        views.setTextViewText(dayNameResId, dayName)
                    }

                    // 设置星期点击事件
                    setupDayClickIntent(views, context, appWidgetId, i)
                }
            }
        } catch (e: Exception) {
            Log.e("CalendarAlbumWeeklyWidget", "Failed to setup custom widget", e)
            setupDefaultWidget(views, context, appWidgetId)
        }
    }

    /**
     * 设置默认小组件（无数据时显示）
     */
    private fun setupDefaultWidget(views: RemoteViews, context: Context, appWidgetId: Int) {
        views.setTextViewText(R.id.weekly_title, "一日一拍")
        views.setTextViewText(R.id.weekly_week_info, "点击设置小组件")

        // 设置星期名称
        val dayNames = arrayOf("一", "二", "三", "四", "五", "六", "日")
        for (i in 0 until 7) {
            val dayNameResId = getDayNameResId(i)
            if (dayNameResId != 0) {
                views.setTextViewText(dayNameResId, dayNames[i])
            }
        }

        // 点击整个小组件打开配置页面
        val intent = Intent(Intent.ACTION_VIEW)
        intent.data = Uri.parse("memento://widget/calendar_album_weekly/config?widgetId=$appWidgetId")
        intent.setPackage("github.hunmer.memento")
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP

        val pendingIntent = PendingIntent.getActivity(
            context,
            appWidgetId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        views.setOnClickPendingIntent(R.id.weekly_container, pendingIntent)
    }

    /**
     * 设置星期点击事件
     */
    private fun setupDayClickIntent(views: RemoteViews, context: Context, appWidgetId: Int, dayIndex: Int) {
        val intent = Intent(ACTION_DAY_CLICKED)
        intent.putExtra(EXTRA_DAY_INDEX, dayIndex)
        intent.putExtra("widgetId", appWidgetId)
        intent.setPackage("github.hunmer.memento")

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            appWidgetId * 10 + dayIndex,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val dayContainerResId = getDayContainerResId(dayIndex)
        if (dayContainerResId != 0) {
            views.setOnClickPendingIntent(dayContainerResId, pendingIntent)
        }
    }

    /**
     * 获取星期名称的资源 ID
     */
    private fun getDayNameResId(dayIndex: Int): Int {
        return when (dayIndex) {
            0 -> R.id.weekly_day_1_name
            1 -> R.id.weekly_day_2_name
            2 -> R.id.weekly_day_3_name
            3 -> R.id.weekly_day_4_name
            4 -> R.id.weekly_day_5_name
            5 -> R.id.weekly_day_6_name
            6 -> R.id.weekly_day_7_name
            else -> 0
        }
    }

    /**
     * 获取星期容器的资源 ID
     */
    private fun getDayContainerResId(dayIndex: Int): Int {
        return when (dayIndex) {
            0 -> R.id.weekly_day_1_container
            1 -> R.id.weekly_day_2_container
            2 -> R.id.weekly_day_3_container
            3 -> R.id.weekly_day_4_container
            4 -> R.id.weekly_day_5_container
            5 -> R.id.weekly_day_6_container
            6 -> R.id.weekly_day_7_container
            else -> 0
        }
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
