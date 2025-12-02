package github.hunmer.memento.widgets.services

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONObject
import github.hunmer.memento.R
import android.graphics.drawable.ColorDrawable

/**
 * 习惯周视图小组件数据工厂
 *
 * 为ListView提供习惯列表数据
 */
class HabitsWeeklyRemoteViewsFactory(
    private val context: Context,
    intent: Intent
) : RemoteViewsService.RemoteViewsFactory {

    private val widgetId: Int = intent.getIntExtra(
        AppWidgetManager.EXTRA_APPWIDGET_ID,
        AppWidgetManager.INVALID_APPWIDGET_ID
    )

    private var habitItems: List<HabitItem> = emptyList()
    private var accentColor: Int = DEFAULT_ACCENT_COLOR

    data class HabitItem(
        val habitId: String,
        val habitTitle: String,
        val habitIcon: String,
        val dailyMinutes: List<Int>, // 7天的时长(分钟) [周一-周日]
        val colorValue: Int
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
        habitItems = emptyList()
    }

    override fun getCount(): Int = habitItems.size

    override fun getViewAt(position: Int): RemoteViews {
        if (position >= habitItems.size) {
            return getLoadingView()
        }

        val item = habitItems[position]
        val views = RemoteViews(context.packageName, R.layout.widget_habits_weekly_item)

        // 设置checkbox（仅UI装饰）
        views.setInt(R.id.item_checkbox, "setColorFilter", accentColor)

        // 设置习惯名称
        views.setTextViewText(R.id.habit_name, item.habitTitle)
        views.setTextColor(R.id.habit_name, accentColor)

        // 设置7天的时长格子
        val dayContainerIds = listOf(
            R.id.day_0_container, R.id.day_1_container, R.id.day_2_container,
            R.id.day_3_container, R.id.day_4_container, R.id.day_5_container,
            R.id.day_6_container
        )
        val dayBgIds = listOf(
            R.id.day_0_bg, R.id.day_1_bg, R.id.day_2_bg,
            R.id.day_3_bg, R.id.day_4_bg, R.id.day_5_bg,
            R.id.day_6_bg
        )
        val dayTextIds = listOf(
            R.id.day_0_text, R.id.day_1_text, R.id.day_2_text,
            R.id.day_3_text, R.id.day_4_text, R.id.day_5_text,
            R.id.day_6_text
        )

        for (i in 0 until 7) {
            val minutes = item.dailyMinutes.getOrElse(i) { 0 }

            if (minutes > 0) {
                // 有时长:显示分钟数,背景色为习惯颜色
                views.setTextViewText(dayTextIds[i], minutes.toString())
                views.setInt(dayBgIds[i], "setBackgroundColor", item.colorValue)
            } else {
                // 无时长:清空文本,背景透明
                views.setTextViewText(dayTextIds[i], "")
                views.setInt(dayBgIds[i], "setBackgroundColor", Color.TRANSPARENT)
            }
        }

        // 设置点击事件的填充Intent(点击习惯打开计时器对话框)
        val fillIntent = Intent().apply {
            putExtra("habit_id", item.habitId)
        }
        views.setOnClickFillInIntent(R.id.item_root, fillIntent)

        return views
    }

    override fun getLoadingView(): RemoteViews {
        return RemoteViews(context.packageName, R.layout.widget_habits_weekly_item).apply {
            setTextViewText(R.id.habit_name, "加载中...")
            // 清空所有时长格子
            val dayTextIds = listOf(
                R.id.day_0_text, R.id.day_1_text, R.id.day_2_text,
                R.id.day_3_text, R.id.day_4_text, R.id.day_5_text,
                R.id.day_6_text
            )
            dayTextIds.forEach { id ->
                setTextViewText(id, "")
            }
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
            val dataJson = prefs.getString("flutter.habits_weekly_data_$widgetId", null)

            if (dataJson.isNullOrEmpty()) {
                habitItems = emptyList()
                return
            }

            val json = JSONObject(dataJson)
            val config = json.getJSONObject("config")
            val data = json.getJSONObject("data")

            // 读取强调色
            accentColor = config.getString("accentColor").toLongOrNull()?.toInt()
                ?: DEFAULT_ACCENT_COLOR

            // 解析习惯列表
            val habitItemsJson = data.getJSONArray("habitItems")
            habitItems = List(habitItemsJson.length()) { index ->
                val habitJson = habitItemsJson.getJSONObject(index)

                val habitId = habitJson.getString("habitId")
                val habitTitle = habitJson.getString("habitTitle")
                val habitIcon = habitJson.getString("habitIcon")
                val colorValue = habitJson.getInt("colorValue")

                // 解析dailyMinutes数组
                val dailyMinutesJson = habitJson.getJSONArray("dailyMinutes")
                val dailyMinutes = List(dailyMinutesJson.length()) { i ->
                    dailyMinutesJson.getInt(i)
                }

                HabitItem(
                    habitId = habitId,
                    habitTitle = habitTitle,
                    habitIcon = habitIcon,
                    dailyMinutes = dailyMinutes,
                    colorValue = colorValue
                )
            }

            android.util.Log.d(TAG, "Loaded ${habitItems.size} habit items for widget $widgetId")
        } catch (e: Exception) {
            android.util.Log.e(TAG, "Error loading data: $e")
            e.printStackTrace()
            habitItems = emptyList()
        }
    }

    companion object {
        private const val TAG = "HabitsWeeklyFactory"
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val DEFAULT_ACCENT_COLOR = 0xFF607AFB.toInt()
    }
}
