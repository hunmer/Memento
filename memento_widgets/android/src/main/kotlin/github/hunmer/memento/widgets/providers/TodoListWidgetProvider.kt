package github.hunmer.memento.widgets.providers

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import android.widget.Toast
import com.example.memento_widgets.R
import github.hunmer.memento.widgets.BasePluginWidgetProvider
import org.json.JSONArray
import org.json.JSONObject

/**
 * 待办列表小组件 Provider
 * 显示用户的待办任务列表，支持配置时间范围和标题
 *
 * 交互逻辑：
 * - 点击 checkbox：后台完成任务（不打开应用），显示 Toast 提示
 * - 点击任务标题：打开任务详情页
 * - 点击标题栏/添加按钮：跳转到待办列表
 */
class TodoListWidgetProvider : BasePluginWidgetProvider() {
    override val pluginId: String = "todo_list"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_2X2

    companion object {
        private const val TAG = "TodoListWidget"
        private const val PREF_KEY_PREFIX_RANGE = "todo_list_range_"
        private const val PREF_KEY_PREFIX_TITLE = "todo_list_title_"

        // 广播 Action
        const val ACTION_TASK_CLICK = "github.hunmer.memento.widgets.TODO_LIST_TASK_CLICK"

        // 待同步的任务变更（应用启动时读取）
        const val PREF_KEY_PENDING_CHANGES = "todo_list_pending_changes"

        // 时间范围常量
        const val RANGE_TODAY = "today"
        const val RANGE_WEEK = "week"
        const val RANGE_MONTH = "month"
        const val RANGE_ALL = "all"

        /**
         * 静态方法：刷新所有待办列表小组件
         */
        fun refreshAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, TodoListWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)

            // 触发小组件更新
            val intent = Intent(context, TodoListWidgetProvider::class.java)
            intent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetIds)
            context.sendBroadcast(intent)

            // 通知列表数据已更改
            appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetIds, R.id.task_list_view)
        }
    }

    /**
     * 重写 onUpdate 方法，确保 ListView 数据也被刷新
     */
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // 调用父类方法更新小组件 UI
        super.onUpdate(context, appWidgetManager, appWidgetIds)

        // 通知 ListView 数据已更改，触发 RemoteViewsFactory.onDataSetChanged()
        appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetIds, R.id.task_list_view)

        Log.d(TAG, "onUpdate: notified ListView data changed for ${appWidgetIds.size} widgets")
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        when (intent.action) {
            ACTION_TASK_CLICK -> handleTaskClick(context, intent)
        }
    }

    /**
     * 处理任务点击事件
     */
    private fun handleTaskClick(context: Context, intent: Intent) {
        val action = intent.getStringExtra("action") ?: return
        val taskId = intent.getStringExtra("task_id") ?: return

        Log.d(TAG, "handleTaskClick: action=$action, taskId=$taskId")

        when (action) {
            "toggle_task" -> {
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
            }
            "open_detail" -> {
                // 打开任务详情页
                Log.d(TAG, "Open task detail: taskId=$taskId")
                val detailIntent = Intent(Intent.ACTION_VIEW)
                detailIntent.data = Uri.parse("memento://widget/todo_list/detail?taskId=$taskId")
                detailIntent.setPackage("github.hunmer.memento")
                detailIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                context.startActivity(detailIntent)
            }
        }
    }

    /**
     * 更新 SharedPreferences 中的任务完成状态
     * @return 任务标题（用于 Toast 显示）
     */
    private fun updateTaskInPrefs(context: Context, taskId: String, completed: Boolean): String {
        var taskTitle = "任务"
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val jsonString = prefs.getString("todo_list_widget_data", null) ?: return taskTitle

            val json = JSONObject(jsonString)
            val tasks = json.optJSONArray("tasks") ?: return taskTitle

            // 查找并更新任务
            val newTasks = JSONArray()
            var totalCount = 0

            for (i in 0 until tasks.length()) {
                val task = tasks.getJSONObject(i)
                if (task.optString("id") == taskId) {
                    taskTitle = task.optString("title", "任务")
                    task.put("completed", completed)
                }
                // 只保留未完成的任务在列表中（已完成的从小组件列表移除）
                if (!task.optBoolean("completed", false)) {
                    newTasks.put(task)
                    totalCount++
                }
            }

            // 保存更新后的数据
            json.put("tasks", newTasks)
            json.put("total", totalCount)
            prefs.edit().putString("todo_list_widget_data", json.toString()).apply()

            Log.d(TAG, "Task updated in prefs: taskId=$taskId, completed=$completed, remaining=$totalCount")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to update task in prefs", e)
        }
        return taskTitle
    }

    /**
     * 记录待同步的任务变更
     * 应用启动时会读取并同步这些变更到实际的任务数据
     */
    private fun recordPendingChange(context: Context, taskId: String, completed: Boolean) {
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val pendingJson = prefs.getString(PREF_KEY_PENDING_CHANGES, "{}") ?: "{}"
            val pending = JSONObject(pendingJson)

            // 记录变更：taskId -> completed
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
        val views = RemoteViews(context.packageName, R.layout.widget_todo_list)

        // 检查是否已配置
        val timeRange = getConfiguredTimeRange(context, appWidgetId)
        Log.d(TAG, "updateAppWidget: appWidgetId=$appWidgetId, timeRange=$timeRange")

        if (timeRange == null) {
            // 未配置，显示配置提示
            Log.d(TAG, "小组件未配置，显示选择提示")
            setupUnconfiguredWidget(views, context, appWidgetId)
        } else {
            // 已配置，显示任务列表
            Log.d(TAG, "小组件已配置，timeRange=$timeRange")
            setupConfiguredWidget(views, context, appWidgetId, timeRange)
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    /**
     * 设置未配置状态的小组件
     */
    private fun setupUnconfiguredWidget(views: RemoteViews, context: Context, appWidgetId: Int) {
        // 设置默认标题
        views.setTextViewText(R.id.widget_title, "待办")
        views.setTextViewText(R.id.widget_count, "")

        // 隐藏任务列表，显示配置提示
        views.setViewVisibility(R.id.widget_hint_text, View.VISIBLE)
        views.setViewVisibility(R.id.task_list_view, View.GONE)
        views.setViewVisibility(R.id.widget_empty_text, View.GONE)

        // 设置点击事件：打开配置页面
        val intent = Intent(Intent.ACTION_VIEW)
        intent.data = Uri.parse("memento://widget/todo_list/config?widgetId=$appWidgetId")
        intent.setPackage("github.hunmer.memento")
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP

        val pendingIntent = PendingIntent.getActivity(
            context,
            appWidgetId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)
    }

    /**
     * 设置已配置状态的小组件
     */
    private fun setupConfiguredWidget(
        views: RemoteViews,
        context: Context,
        appWidgetId: Int,
        timeRange: String
    ) {
        // 获取配置的标题
        val customTitle = getConfiguredTitle(context, appWidgetId)
        val defaultTitle = when (timeRange) {
            RANGE_TODAY -> "今天"
            RANGE_WEEK -> "本周"
            RANGE_MONTH -> "本月"
            RANGE_ALL -> "全部"
            else -> "待办"
        }
        val title = if (customTitle.isNullOrEmpty()) defaultTitle else customTitle

        views.setTextViewText(R.id.widget_title, title)

        // 隐藏配置提示
        views.setViewVisibility(R.id.widget_hint_text, View.GONE)

        // 获取任务数量
        val taskCount = getTaskCount(context, timeRange)
        views.setTextViewText(R.id.widget_count, taskCount.toString())

        if (taskCount > 0) {
            views.setViewVisibility(R.id.task_list_view, View.VISIBLE)
            views.setViewVisibility(R.id.widget_empty_text, View.GONE)
        } else {
            views.setViewVisibility(R.id.task_list_view, View.GONE)
            views.setViewVisibility(R.id.widget_empty_text, View.VISIBLE)
        }

        // 设置 ListView 的 RemoteViewsService
        val serviceIntent = Intent(context, TodoListWidgetService::class.java).apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            putExtra("time_range", timeRange)
            data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
        }
        views.setRemoteAdapter(R.id.task_list_view, serviceIntent)
        views.setEmptyView(R.id.task_list_view, R.id.widget_empty_text)

        // 设置 ListView 项目点击的 PendingIntent 模板（广播，不是 Activity）
        val clickIntent = Intent(context, TodoListWidgetProvider::class.java).apply {
            action = ACTION_TASK_CLICK
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        }
        val clickPendingIntent = PendingIntent.getBroadcast(
            context,
            appWidgetId,
            clickIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        )
        views.setPendingIntentTemplate(R.id.task_list_view, clickPendingIntent)

        // 设置标题栏点击 - 跳转到待办列表
        setupHeaderClickIntent(context, views)

        // 设置添加按钮点击 - 跳转到添加任务
        setupAddButtonClickIntent(context, views)
    }

    /**
     * 获取任务数量（按时间范围过滤）
     */
    private fun getTaskCount(context: Context, timeRange: String): Int {
        return try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val jsonString = prefs.getString("todo_list_widget_data", null) ?: return 0
            val json = JSONObject(jsonString)
            val tasks = json.optJSONArray("tasks") ?: return 0

            var count = 0
            for (i in 0 until tasks.length()) {
                val task = tasks.getJSONObject(i)
                if (!task.optBoolean("completed", false)) {
                    // 按时间范围过滤（与 TodoListRemoteViewsFactory 保持一致）
                    if (shouldIncludeTask(task, timeRange)) {
                        count++
                    }
                }
            }
            count
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get task count", e)
            0
        }
    }

    /**
     * 根据时间范围判断是否包含任务（与 TodoListRemoteViewsFactory 保持一致）
     */
    private fun shouldIncludeTask(task: JSONObject, timeRange: String): Boolean {
        // 如果是"全部"范围，包含所有任务
        if (timeRange == RANGE_ALL) return true

        val startDateStr = task.optString("startDate", null)
        val dueDateStr = task.optString("dueDate", null)

        // 如果任务没有日期，默认包含
        if (startDateStr.isNullOrEmpty() && dueDateStr.isNullOrEmpty()) return true

        val todayStart = getTodayStart()
        val todayEnd = todayStart + 24 * 60 * 60 * 1000

        val taskStart = parseDate(startDateStr)
        val taskDue = parseDate(dueDateStr)

        return when (timeRange) {
            RANGE_TODAY -> {
                // 今天的任务：开始日期<=今天 且 截止日期>=今天
                val startOk = taskStart == null || taskStart <= todayEnd
                val dueOk = taskDue == null || taskDue >= todayStart
                startOk && dueOk
            }
            RANGE_WEEK -> {
                // 本周的任务
                val weekStart = getWeekStart()
                val weekEnd = weekStart + 7 * 24 * 60 * 60 * 1000
                val startOk = taskStart == null || taskStart <= weekEnd
                val dueOk = taskDue == null || taskDue >= weekStart
                startOk && dueOk
            }
            RANGE_MONTH -> {
                // 本月的任务
                val monthStart = getMonthStart()
                val monthEnd = getMonthEnd()
                val startOk = taskStart == null || taskStart <= monthEnd
                val dueOk = taskDue == null || taskDue >= monthStart
                startOk && dueOk
            }
            else -> true
        }
    }

    private fun parseDate(dateStr: String?): Long? {
        if (dateStr.isNullOrEmpty()) return null
        return try {
            java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", java.util.Locale.getDefault())
                .parse(dateStr)?.time
        } catch (e: Exception) {
            null
        }
    }

    private fun getTodayStart(): Long {
        val cal = java.util.Calendar.getInstance()
        cal.set(java.util.Calendar.HOUR_OF_DAY, 0)
        cal.set(java.util.Calendar.MINUTE, 0)
        cal.set(java.util.Calendar.SECOND, 0)
        cal.set(java.util.Calendar.MILLISECOND, 0)
        return cal.timeInMillis
    }

    private fun getWeekStart(): Long {
        val cal = java.util.Calendar.getInstance()
        cal.set(java.util.Calendar.DAY_OF_WEEK, cal.firstDayOfWeek)
        cal.set(java.util.Calendar.HOUR_OF_DAY, 0)
        cal.set(java.util.Calendar.MINUTE, 0)
        cal.set(java.util.Calendar.SECOND, 0)
        cal.set(java.util.Calendar.MILLISECOND, 0)
        return cal.timeInMillis
    }

    private fun getMonthStart(): Long {
        val cal = java.util.Calendar.getInstance()
        cal.set(java.util.Calendar.DAY_OF_MONTH, 1)
        cal.set(java.util.Calendar.HOUR_OF_DAY, 0)
        cal.set(java.util.Calendar.MINUTE, 0)
        cal.set(java.util.Calendar.SECOND, 0)
        cal.set(java.util.Calendar.MILLISECOND, 0)
        return cal.timeInMillis
    }

    private fun getMonthEnd(): Long {
        val cal = java.util.Calendar.getInstance()
        cal.set(java.util.Calendar.DAY_OF_MONTH, cal.getActualMaximum(java.util.Calendar.DAY_OF_MONTH))
        cal.set(java.util.Calendar.HOUR_OF_DAY, 23)
        cal.set(java.util.Calendar.MINUTE, 59)
        cal.set(java.util.Calendar.SECOND, 59)
        cal.set(java.util.Calendar.MILLISECOND, 999)
        return cal.timeInMillis
    }

    /**
     * 设置标题栏点击事件 - 跳转到待办列表
     */
    private fun setupHeaderClickIntent(context: Context, views: RemoteViews) {
        val intent = Intent(Intent.ACTION_VIEW)
        intent.data = Uri.parse("memento://widget/todo")
        intent.setPackage("github.hunmer.memento")
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP

        val pendingIntent = PendingIntent.getActivity(
            context,
            "todo_header".hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        views.setOnClickPendingIntent(R.id.widget_header, pendingIntent)
    }

    /**
     * 设置添加按钮点击事件 - 跳转到添加任务
     */
    private fun setupAddButtonClickIntent(context: Context, views: RemoteViews) {
        val intent = Intent(Intent.ACTION_VIEW)
        intent.data = Uri.parse("memento://widget/todo/add")
        intent.setPackage("github.hunmer.memento")
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP

        val pendingIntent = PendingIntent.getActivity(
            context,
            "todo_add".hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        views.setOnClickPendingIntent(R.id.widget_add_button, pendingIntent)
    }

    /**
     * 获取配置的时间范围
     */
    private fun getConfiguredTimeRange(context: Context, appWidgetId: Int): String? {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getString("$PREF_KEY_PREFIX_RANGE$appWidgetId", null)
    }

    /**
     * 获取配置的标题
     */
    private fun getConfiguredTitle(context: Context, appWidgetId: Int): String? {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getString("$PREF_KEY_PREFIX_TITLE$appWidgetId", null)
    }

    /**
     * 删除配置
     */
    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        super.onDeleted(context, appWidgetIds)
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val editor = prefs.edit()
        for (appWidgetId in appWidgetIds) {
            editor.remove("$PREF_KEY_PREFIX_RANGE$appWidgetId")
            editor.remove("$PREF_KEY_PREFIX_TITLE$appWidgetId")
        }
        editor.apply()
    }
}
