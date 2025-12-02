package github.hunmer.memento.widgets.services

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONObject
import github.hunmer.memento.R

/**
 * 活动周视图小组件数据工厂
 *
 * 为ListView提供活动标签列表数据
 */
class ActivityWeeklyRemoteViewsFactory(
    private val context: Context,
    intent: Intent
) : RemoteViewsService.RemoteViewsFactory {

    private val widgetId: Int = intent.getIntExtra(
        AppWidgetManager.EXTRA_APPWIDGET_ID,
        AppWidgetManager.INVALID_APPWIDGET_ID
    )

    private var tagItems: List<TagItem> = emptyList()
    private var accentColor: Int = DEFAULT_ACCENT_COLOR

    data class TagItem(
        val name: String,
        val duration: String,
        val count: Int
    )

    override fun onCreate() {
        // 初始化时加载数据
        loadData()
    }

    override fun onDataSetChanged() {
        // 数据变化时重新加载
        loadData()
    }

    override fun onDestroy() {
        tagItems = emptyList()
    }

    override fun getCount(): Int = tagItems.size

    override fun getViewAt(position: Int): RemoteViews {
        if (position >= tagItems.size) {
            return getLoadingView()
        }

        val item = tagItems[position]
        val views = RemoteViews(context.packageName, R.layout.widget_activity_weekly_item)

        // 设置checkbox（仅UI装饰）
        views.setInt(R.id.item_checkbox, "setColorFilter", accentColor)

        // 设置标签名称
        views.setTextViewText(R.id.tag_name, item.name)
        views.setTextColor(R.id.tag_name, accentColor)

        // 设置时长
        views.setTextViewText(R.id.tag_duration, item.duration)
        views.setTextColor(R.id.tag_duration, applyAlpha(accentColor, 0.8f))

        // 设置点击事件的填充Intent
        val fillIntent = Intent().apply {
            putExtra("tag_name", item.name)
        }
        views.setOnClickFillInIntent(R.id.item_root, fillIntent)

        return views
    }

    override fun getLoadingView(): RemoteViews {
        return RemoteViews(context.packageName, R.layout.widget_activity_weekly_item).apply {
            setTextViewText(R.id.tag_name, "加载中...")
            setTextViewText(R.id.tag_duration, "")
        }
    }

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = true

    /**
     * 从SharedPreferences加载数据
     */
    private fun loadData() {
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val dataJson = prefs.getString("activity_weekly_data_$widgetId", null)

            if (dataJson.isNullOrEmpty()) {
                tagItems = emptyList()
                return
            }

            val json = JSONObject(dataJson)
            val config = json.getJSONObject("config")
            val data = json.getJSONObject("data")

            // 读取强调色
            accentColor = config.getString("accentColor").toLongOrNull()?.toInt()
                ?: DEFAULT_ACCENT_COLOR

            // 解析标签列表
            val topTags = data.getJSONArray("topTags")
            tagItems = List(topTags.length()) { index ->
                val tagJson = topTags.getJSONObject(index)
                val name = tagJson.getString("name")
                val durationSeconds = tagJson.getInt("duration")
                val count = tagJson.getInt("count")

                TagItem(
                    name = name,
                    duration = formatDuration(durationSeconds),
                    count = count
                )
            }

            android.util.Log.d(TAG, "Loaded ${tagItems.size} tag items for widget $widgetId")
        } catch (e: Exception) {
            android.util.Log.e(TAG, "Error loading data: $e")
            tagItems = emptyList()
        }
    }

    /**
     * 格式化时长（秒 -> HH時MM分）
     */
    private fun formatDuration(seconds: Int): String {
        val hours = seconds / 3600
        val minutes = (seconds % 3600) / 60
        return String.format("%02d時%02d分", hours, minutes)
    }

    /**
     * 为颜色应用透明度
     */
    private fun applyAlpha(color: Int, alpha: Float): Int {
        val a = (255 * alpha).toInt().coerceIn(0, 255)
        return Color.argb(a, Color.red(color), Color.green(color), Color.blue(color))
    }

    companion object {
        private const val TAG = "ActivityWeeklyFactory"
        private const val PREFS_NAME = "HomeWidgetPreferences"
        private const val DEFAULT_ACCENT_COLOR = 0xFF607afb.toInt()
    }
}
