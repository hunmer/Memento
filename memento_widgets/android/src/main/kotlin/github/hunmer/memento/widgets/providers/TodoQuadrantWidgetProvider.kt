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
import android.widget.Toast
import github.hunmer.memento_widgets.R
import github.hunmer.memento.widgets.BasePluginWidgetProvider
import org.json.JSONArray
import org.json.JSONObject

/**
 * 四象限任务小组件 Provider
 * 显示用户的任务四象限视图，按重要性和紧急程度分组
 *
 * 交互逻辑：
 * - 点击左上角日期范围按钮：切换时间范围（本日/本周/本月）
 * - 点击 checkbox：后台完成任务（不打开应用），显示 Toast 提示
 * - 点击标题栏：跳转到待办列表
 */
class TodoQuadrantWidgetProvider : BasePluginWidgetProvider() {
    override val pluginId: String = "todo_quadrant"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_2X2

    companion object {
        private const val TAG = "TodoQuadrantWidget"
        private const val PREF_KEY_DATE_RANGE = "todo_quadrant_date_range_"
        private const val PREF_KEY_PRIMARY_COLOR = "todo_quadrant_widget_primary_color_"
        private const val PREF_KEY_ACCENT_COLOR = "todo_quadrant_widget_accent_color_"
        private const val PREF_KEY_OPACITY = "todo_quadrant_widget_opacity_"

        // 默认颜色（蓝色系）
        private const val DEFAULT_PRIMARY_COLOR = 0xFF2196F3.toInt()
        private const val DEFAULT_ACCENT_COLOR = 0xFFFFFFFF.toInt()
        private const val DEFAULT_OPACITY = 0.95f

        // 广播 Action
        const val ACTION_TASK_CLICK = "github.hunmer.memento.widgets.TODO_QUADRANT_TASK_CLICK"
        const val ACTION_DATE_RANGE_CLICK = "github.hunmer.memento.widgets.TODO_QUADRANT_DATE_RANGE_CLICK"

        // 待同步的任务变更（应用启动时读取）
        const val PREF_KEY_PENDING_CHANGES = "todo_quadrant_pending_changes"

        // 时间范围常量
        const val RANGE_TODAY = "today"
        const val RANGE_WEEK = "week"
        const val RANGE_MONTH = "month"

        // 象限标签
        private const val QUADRANT_URGENT_IMPORTANT = "urgent_important"
        private const val QUADRANT_NOT_URGENT_IMPORTANT = "not_urgent_important"
        private const val QUADRANT_URGENT_NOT_IMPORTANT = "urgent_not_important"
        private const val QUADRANT_NOT_URGENT_NOT_IMPORTANT = "not_urgent_not_important"

        /**
         * 静态方法：刷新所有四象限小组件
         */
        fun refreshAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, TodoQuadrantWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)

            // 触发小组件更新
            val intent = Intent(context, TodoQuadrantWidgetProvider::class.java)
            intent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetIds)
            context.sendBroadcast(intent)

            Log.d(TAG, "Refreshed all TodoQuadrant widgets: ${appWidgetIds.size} widgets")
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        when (intent.action) {
            ACTION_TASK_CLICK -> handleTaskClick(context, intent)
            ACTION_DATE_RANGE_CLICK -> handleDateRangeClick(context, intent)
        }
    }

    /**
     * 处理任务点击事件
     */
    private fun handleTaskClick(context: Context, intent: Intent) {
        val taskId = intent.getStringExtra("task_id") ?: return

        Log.d(TAG, "handleTaskClick: taskId=$taskId")

        try {
            // 后台完成任务切换（不打开应用）
            val currentCompleted = intent.getBooleanExtra("task_completed", false)
            val newCompleted = !currentCompleted
            Log.d(TAG, "Toggle task in background: taskId=$taskId, newCompleted=$newCompleted")

            // 1. 更新 SharedPreferences 中的任务数据
            val taskTitle = updateTaskInPrefs(context, taskId, newCompleted)

            // 2. 记录待同步的变更（应用启动时处理）
            recordPendingChange(context, taskId, newCompleted)

            // 3. 显示 Toast 提示
            val message = if (newCompleted) {
                "✓ 已完成「$taskTitle」"
            } else {
                "↩ 已恢复「$taskTitle」"
            }
            Toast.makeText(context, message, Toast.LENGTH_SHORT).show()

            // 4. 刷新小组件
            refreshAllWidgets(context)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to handle task click", e)
        }
    }

    /**
     * 处理日期范围点击事件
     */
    private fun handleDateRangeClick(context: Context, intent: Intent) {
        val appWidgetId = intent.getIntExtra("app_widget_id", -1)
        if (appWidgetId == -1) return

        Log.d(TAG, "handleDateRangeClick: appWidgetId=$appWidgetId")

        try {
            val currentRange = getConfiguredDateRange(context, appWidgetId)
            val newRange = when (currentRange) {
                RANGE_TODAY -> RANGE_WEEK
                RANGE_WEEK -> RANGE_MONTH
                RANGE_MONTH -> RANGE_TODAY
                else -> RANGE_TODAY
            }

            // 保存新的日期范围
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit().putString("$PREF_KEY_DATE_RANGE$appWidgetId", newRange).apply()

            Log.d(TAG, "Updated date range: appWidgetId=$appWidgetId, range=$newRange")

            // 刷新小组件
            val appWidgetManager = AppWidgetManager.getInstance(context)
            updateAppWidget(context, appWidgetManager, appWidgetId)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to handle date range click", e)
        }
    }

    /**
     * 更新 SharedPreferences 中的任务完成状态
     */
    private fun updateTaskInPrefs(context: Context, taskId: String, completed: Boolean): String {
        var taskTitle = "任务"
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val jsonString = prefs.getString("todo_quadrant_widget_data", null) ?: return taskTitle

            val json = JSONObject(jsonString)

            // 遍历四个象限，查找并更新任务
            val quadrants = arrayOf(
                QUADRANT_URGENT_IMPORTANT,
                QUADRANT_NOT_URGENT_IMPORTANT,
                QUADRANT_URGENT_NOT_IMPORTANT,
                QUADRANT_NOT_URGENT_NOT_IMPORTANT
            )

            var taskFound = false
            for (quadrant in quadrants) {
                val tasksArray = json.optJSONArray(quadrant) ?: continue
                for (i in 0 until tasksArray.length()) {
                    val task = tasksArray.getJSONObject(i)
                    if (task.optString("id") == taskId) {
                        taskTitle = task.optString("title", "任务")
                        task.put("completed", completed)
                        taskFound = true
                        break
                    }
                }
                if (taskFound) break
            }

            // 如果任务完成，从象限中移除
            if (completed && taskFound) {
                for (quadrant in quadrants) {
                    val tasksArray = json.optJSONArray(quadrant) ?: continue
                    val newTasks = JSONArray()
                    for (i in 0 until tasksArray.length()) {
                        val task = tasksArray.getJSONObject(i)
                        if (task.optString("id") != taskId) {
                            newTasks.put(task)
                        }
                    }
                    json.put(quadrant, newTasks)
                }
            }

            prefs.edit().putString("todo_quadrant_widget_data", json.toString()).apply()
            Log.d(TAG, "Task updated in prefs: taskId=$taskId, completed=$completed")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to update task in prefs", e)
        }
        return taskTitle
    }

    /**
     * 记录待同步的任务变更
     */
    private fun recordPendingChange(context: Context, taskId: String, completed: Boolean) {
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val pendingJson = prefs.getString(PREF_KEY_PENDING_CHANGES, "{}") ?: "{}"
            val pending = JSONObject(pendingJson)

            pending.put(taskId, completed)
            prefs.edit().putString(PREF_KEY_PENDING_CHANGES, pending.toString()).apply()
            Log.d(TAG, "Recorded pending change: taskId=$taskId, completed=$completed")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to record pending change", e)
        }
    }

    override fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_todo_quadrant)

        // 检查是否已配置
        val dateRange = getConfiguredDateRange(context, appWidgetId)
        Log.d(TAG, "updateAppWidget: appWidgetId=$appWidgetId, dateRange=$dateRange")

        if (dateRange == null) {
            // 未配置，显示配置提示
            Log.d(TAG, "小组件未配置，显示选择提示")
            setupUnconfiguredWidget(views, context, appWidgetId)
        } else {
            // 已配置，显示四象限任务
            Log.d(TAG, "小组件已配置，dateRange=$dateRange")

            // 读取颜色和透明度配置
            val primaryColor = getConfiguredPrimaryColor(context, appWidgetId)
            val accentColor = getConfiguredAccentColor(context, appWidgetId)
            val opacity = getConfiguredOpacity(context, appWidgetId)

            setupConfiguredWidget(views, context, appWidgetId, dateRange, primaryColor, accentColor, opacity)
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    /**
     * 设置未配置状态的小组件
     */
    private fun setupUnconfiguredWidget(views: RemoteViews, context: Context, appWidgetId: Int) {
        // 设置默认标题
        views.setTextViewText(R.id.widget_title, "任务四象限")
        views.setTextViewText(R.id.date_range_button, "点击设置小组件")

        // 显示配置提示，隐藏象限
        setQuadrantsVisibility(views, View.GONE)

        // 设置点击事件，跳转到配置页面
        val configIntent = Intent(Intent.ACTION_VIEW)
        configIntent.data = Uri.parse("memento://widget/todo_quadrant/config?widgetId=$appWidgetId")
        configIntent.setPackage("github.hunmer.memento")
        configIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP

        val configPendingIntent = PendingIntent.getActivity(
            context,
            appWidgetId,
            configIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_container, configPendingIntent)
    }

    /**
     * 设置已配置状态的小组件
     */
    private fun setupConfiguredWidget(
        views: RemoteViews,
        context: Context,
        appWidgetId: Int,
        dateRange: String,
        primaryColor: Int,
        accentColor: Int,
        opacity: Float
    ) {
        // 设置标题和日期范围
        views.setTextViewText(R.id.widget_title, "任务四象限")
        views.setTextViewText(R.id.date_range_button, getDateRangeLabel(dateRange))

        // 应用颜色配置
        applyColors(views, context, appWidgetId, primaryColor, accentColor, opacity)

        // 显示象限，隐藏提示
        setQuadrantsVisibility(views, View.VISIBLE)

        // 设置日期范围按钮点击事件
        val dateRangeIntent = Intent(context, TodoQuadrantWidgetProvider::class.java)
        dateRangeIntent.action = ACTION_DATE_RANGE_CLICK
        dateRangeIntent.putExtra("app_widget_id", appWidgetId)

        val dateRangePendingIntent = PendingIntent.getBroadcast(
            context,
            appWidgetId * 1000 + 1,
            dateRangeIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.date_range_button, dateRangePendingIntent)

        // 设置标题栏点击事件（打开应用）
        val openAppIntent = Intent(Intent.ACTION_VIEW)
        openAppIntent.data = Uri.parse("memento://widget/todo")
        openAppIntent.setPackage("github.hunmer.memento")
        openAppIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP

        val openAppPendingIntent = PendingIntent.getActivity(
            context,
            appWidgetId * 1000 + 2,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_header, openAppPendingIntent)

        // 加载并显示四象限数据
        loadAndDisplayQuadrantData(views, context)
    }

    /**
     * 设置象限的可见性
     */
    private fun setQuadrantsVisibility(views: RemoteViews, visibility: Int) {
        views.setViewVisibility(R.id.quadrant_urgent_important, visibility)
        views.setViewVisibility(R.id.quadrant_not_urgent_important, visibility)
        views.setViewVisibility(R.id.quadrant_urgent_not_important, visibility)
        views.setViewVisibility(R.id.quadrant_not_urgent_not_important, visibility)
    }

    /**
     * 应用颜色配置
     */
    private fun applyColors(
        views: RemoteViews,
        context: Context,
        appWidgetId: Int,
        primaryColor: Int,
        accentColor: Int,
        opacity: Float
    ) {
        val bgColor = adjustColorAlpha(primaryColor, opacity)
        views.setColorStateList(
            R.id.widget_container,
            "setBackgroundTintList",
            ColorStateList.valueOf(bgColor)
        )

        // 设置标题颜色
        views.setTextColor(R.id.widget_title, accentColor)
        views.setTextColor(R.id.date_range_button, accentColor)

        // 设置象限标签颜色
        views.setTextColor(R.id.label_urgent_important, accentColor)
        views.setTextColor(R.id.label_not_urgent_important, accentColor)
        views.setTextColor(R.id.label_urgent_not_important, accentColor)
        views.setTextColor(R.id.label_not_urgent_not_important, accentColor)
    }

    /**
     * 加载并显示四象限数据
     */
    private fun loadAndDisplayQuadrantData(views: RemoteViews, context: Context) {
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val jsonString = prefs.getString("todo_quadrant_widget_data", null)

            if (jsonString.isNullOrEmpty()) {
                Log.d(TAG, "No quadrant data found")
                return
            }

            val json = JSONObject(jsonString)

            // 显示每个象限的任务数量
            displayQuadrantCount(views, R.id.count_urgent_important, json.optJSONArray(QUADRANT_URGENT_IMPORTANT))
            displayQuadrantCount(views, R.id.count_not_urgent_important, json.optJSONArray(QUADRANT_NOT_URGENT_IMPORTANT))
            displayQuadrantCount(views, R.id.count_urgent_not_important, json.optJSONArray(QUADRANT_URGENT_NOT_IMPORTANT))
            displayQuadrantCount(views, R.id.count_not_urgent_not_important, json.optJSONArray(QUADRANT_NOT_URGENT_NOT_IMPORTANT))

            Log.d(TAG, "Quadrant data loaded and displayed")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to load quadrant data", e)
        }
    }

    /**
     * 显示象限任务数量
     */
    private fun displayQuadrantCount(views: RemoteViews, viewId: Int, tasksArray: JSONArray?) {
        val count = tasksArray?.length() ?: 0
        views.setTextViewText(viewId, count.toString())
    }

    /**
     * 获取配置的日期范围
     */
    private fun getConfiguredDateRange(context: Context, appWidgetId: Int): String? {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getString("$PREF_KEY_DATE_RANGE$appWidgetId", null)
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

    /**
     * 获取日期范围标签
     */
    private fun getDateRangeLabel(range: String): String {
        return when (range) {
            RANGE_TODAY -> "本日"
            RANGE_WEEK -> "本周"
            RANGE_MONTH -> "本月"
            else -> "本日"
        }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        super.onDeleted(context, appWidgetIds)
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val editor = prefs.edit()
        for (appWidgetId in appWidgetIds) {
            editor.remove("$PREF_KEY_DATE_RANGE$appWidgetId")
            editor.remove("$PREF_KEY_PRIMARY_COLOR$appWidgetId")
            editor.remove("$PREF_KEY_ACCENT_COLOR$appWidgetId")
            editor.remove("$PREF_KEY_OPACITY$appWidgetId")
        }
        editor.apply()
    }
}
