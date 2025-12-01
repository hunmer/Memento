package github.hunmer.memento.widgets.providers

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import com.example.memento_widgets.R
import github.hunmer.memento.widgets.BasePluginWidgetProvider
import org.json.JSONArray
import org.json.JSONObject

/**
 * 待办列表的 RemoteViewsFactory
 * 负责创建和管理列表项
 */
class TodoListRemoteViewsFactory(
    private val context: Context,
    private val intent: Intent
) : RemoteViewsService.RemoteViewsFactory {

    companion object {
        private const val TAG = "TodoListFactory"
    }

    private var tasks: List<TaskItem> = emptyList()
    private val appWidgetId: Int = intent.getIntExtra(
        AppWidgetManager.EXTRA_APPWIDGET_ID,
        AppWidgetManager.INVALID_APPWIDGET_ID
    )
    private val timeRange: String = intent.getStringExtra("time_range") ?: "today"

    data class TaskItem(
        val id: String,
        val title: String,
        val completed: Boolean,
        val startDate: String?,
        val dueDate: String?
    )

    override fun onCreate() {
        Log.d(TAG, "onCreate: appWidgetId=$appWidgetId, timeRange=$timeRange")
    }

    override fun onDataSetChanged() {
        Log.d(TAG, "onDataSetChanged: Loading tasks for timeRange=$timeRange")
        tasks = loadTasks()
        Log.d(TAG, "Loaded ${tasks.size} tasks")
    }

    override fun onDestroy() {
        tasks = emptyList()
    }

    override fun getCount(): Int = tasks.size

    override fun getViewAt(position: Int): RemoteViews {
        if (position < 0 || position >= tasks.size) {
            return RemoteViews(context.packageName, R.layout.widget_todo_list_item)
        }

        val task = tasks[position]
        val views = RemoteViews(context.packageName, R.layout.widget_todo_list_item)

        // 设置任务标题
        views.setTextViewText(R.id.task_title, task.title)

        // 设置复选框状态
        if (task.completed) {
            views.setImageViewResource(R.id.task_checkbox, R.drawable.ic_checkbox_checked)
            // 已完成任务标题添加删除线效果（通过颜色变淡表示）
            views.setTextColor(R.id.task_title, 0xFF9CA3AF.toInt())
        } else {
            views.setImageViewResource(R.id.task_checkbox, R.drawable.ic_checkbox_unchecked)
            views.setTextColor(R.id.task_title, 0xFF1F2937.toInt())
        }

        // 设置复选框点击 - 填充 Intent
        val checkboxFillIntent = Intent().apply {
            putExtra("action", "toggle_task")
            putExtra("task_id", task.id)
            putExtra("task_completed", task.completed)
        }
        views.setOnClickFillInIntent(R.id.task_checkbox, checkboxFillIntent)

        // 设置任务标题点击 - 打开任务详情
        val detailFillIntent = Intent().apply {
            putExtra("action", "open_detail")
            putExtra("task_id", task.id)
        }
        views.setOnClickFillInIntent(R.id.task_title_container, detailFillIntent)

        return views
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = true

    /**
     * 从 SharedPreferences 加载任务数据
     */
    private fun loadTasks(): List<TaskItem> {
        return try {
            val prefs = context.getSharedPreferences(
                BasePluginWidgetProvider.PREFS_NAME,
                Context.MODE_PRIVATE
            )
            val jsonString = prefs.getString("todo_list_widget_data", null)

            if (jsonString.isNullOrEmpty()) {
                Log.w(TAG, "No task data found")
                return emptyList()
            }

            val json = JSONObject(jsonString)
            val tasksArray = json.optJSONArray("tasks") ?: return emptyList()

            val result = mutableListOf<TaskItem>()

            // 根据时间范围过滤任务
            for (i in 0 until tasksArray.length()) {
                val taskJson = tasksArray.getJSONObject(i)
                val task = TaskItem(
                    id = taskJson.optString("id", ""),
                    title = taskJson.optString("title", ""),
                    completed = taskJson.optBoolean("completed", false),
                    startDate = taskJson.optString("startDate", null),
                    dueDate = taskJson.optString("dueDate", null)
                )

                // 过滤已完成的任务
                if (!task.completed && shouldIncludeTask(task)) {
                    result.add(task)
                }
            }

            result
        } catch (e: Exception) {
            Log.e(TAG, "Failed to load tasks", e)
            emptyList()
        }
    }

    /**
     * 根据时间范围判断是否包含任务
     */
    private fun shouldIncludeTask(task: TaskItem): Boolean {
        // 如果是"全部"范围，包含所有任务
        if (timeRange == "all") return true

        // 如果任务没有日期，默认包含
        if (task.startDate == null && task.dueDate == null) return true

        val now = System.currentTimeMillis()
        val todayStart = getTodayStart()
        val todayEnd = todayStart + 24 * 60 * 60 * 1000

        val taskStart = parseDate(task.startDate)
        val taskDue = parseDate(task.dueDate)

        return when (timeRange) {
            "today" -> {
                // 今天的任务：开始日期<=今天 且 截止日期>=今天
                val startOk = taskStart == null || taskStart <= todayEnd
                val dueOk = taskDue == null || taskDue >= todayStart
                startOk && dueOk
            }
            "week" -> {
                // 本周的任务
                val weekStart = getWeekStart()
                val weekEnd = weekStart + 7 * 24 * 60 * 60 * 1000
                val startOk = taskStart == null || taskStart <= weekEnd
                val dueOk = taskDue == null || taskDue >= weekStart
                startOk && dueOk
            }
            "month" -> {
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
}
