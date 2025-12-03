package github.hunmer.memento.widgets.services

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONObject
import github.hunmer.memento_widgets.R

/**
 * 活动周视图小组件数据工厂
 *
 * 为ListView提供活动标签列表数据（每行两个标签）
 */
class ActivityWeeklyRemoteViewsFactory(
    private val context: Context,
    intent: Intent
) : RemoteViewsService.RemoteViewsFactory {

    private val widgetId: Int = intent.getIntExtra(
        AppWidgetManager.EXTRA_APPWIDGET_ID,
        AppWidgetManager.INVALID_APPWIDGET_ID
    )

    // 成对的标签项（每行两个）
    private var tagPairs: List<TagPair> = emptyList()
    private var accentColor: Int = DEFAULT_ACCENT_COLOR

    data class TagItem(
        val name: String,
        val duration: String,
        val count: Int,
        val color: Int  // 标签自身颜色
    )

    data class TagPair(
        val left: TagItem,
        val right: TagItem?  // 右侧可能为空（奇数个标签时）
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
        tagPairs = emptyList()
    }

    override fun getCount(): Int = tagPairs.size

    override fun getViewAt(position: Int): RemoteViews {
        if (position >= tagPairs.size) {
            return getLoadingView()
        }

        val pair = tagPairs[position]
        val views = RemoteViews(context.packageName, R.layout.widget_activity_weekly_item)

        // 设置左侧标签
        views.setTextViewText(R.id.left_tag_name, pair.left.name)
        views.setTextViewText(R.id.left_tag_duration, pair.left.duration)
        views.setInt(R.id.left_color_block, "setBackgroundColor", pair.left.color)
        views.setViewVisibility(R.id.left_item, View.VISIBLE)

        // 设置左侧点击事件
        val leftFillIntent = Intent().apply {
            putExtra("tag_name", pair.left.name)
        }
        views.setOnClickFillInIntent(R.id.left_item, leftFillIntent)

        // 设置右侧标签（如果存在）
        if (pair.right != null) {
            views.setTextViewText(R.id.right_tag_name, pair.right.name)
            views.setTextViewText(R.id.right_tag_duration, pair.right.duration)
            views.setInt(R.id.right_color_block, "setBackgroundColor", pair.right.color)
            views.setViewVisibility(R.id.right_item, View.VISIBLE)

            // 设置右侧点击事件
            val rightFillIntent = Intent().apply {
                putExtra("tag_name", pair.right.name)
            }
            views.setOnClickFillInIntent(R.id.right_item, rightFillIntent)
        } else {
            // 隐藏右侧
            views.setViewVisibility(R.id.right_item, View.INVISIBLE)
        }

        return views
    }

    override fun getLoadingView(): RemoteViews {
        return RemoteViews(context.packageName, R.layout.widget_activity_weekly_item).apply {
            setTextViewText(R.id.left_tag_name, "加载中...")
            setTextViewText(R.id.left_tag_duration, "")
            setViewVisibility(R.id.right_item, View.GONE)
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
                tagPairs = emptyList()
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
            val tagItems = mutableListOf<TagItem>()

            for (index in 0 until topTags.length()) {
                val tagJson = topTags.getJSONObject(index)
                val name = tagJson.getString("name")
                val durationSeconds = tagJson.getInt("duration")
                val count = tagJson.getInt("count")
                // 读取标签颜色，如果没有则使用默认强调色
                val color = tagJson.optLong("color", accentColor.toLong()).toInt()

                tagItems.add(TagItem(
                    name = name,
                    duration = formatDuration(durationSeconds),
                    count = count,
                    color = color
                ))
            }

            // 将标签成对分组
            tagPairs = tagItems.chunked(2).map { chunk ->
                TagPair(
                    left = chunk[0],
                    right = chunk.getOrNull(1)
                )
            }

            android.util.Log.d(TAG, "Loaded ${tagItems.size} tag items (${tagPairs.size} pairs) for widget $widgetId")
        } catch (e: Exception) {
            android.util.Log.e(TAG, "Error loading data: $e")
            tagPairs = emptyList()
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
