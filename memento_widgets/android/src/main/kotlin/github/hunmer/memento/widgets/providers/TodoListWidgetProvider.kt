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
import com.example.memento_widgets.R
import github.hunmer.memento.widgets.BasePluginWidgetProvider
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

/**
 * 待办列表小组件 Provider
 * 显示用户的待办任务列表，支持配置时间范围和标题
 *
 * 交互逻辑：
 * - 点击 checkbox：广播完成任务（不打开应用）
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

            // 通知数据已更改
            appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetIds, R.id.task_list_view)
        }
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
                // 切换任务完成状态 - 启动应用处理
                val completed = intent.getBooleanExtra("task_completed", false)
                Log.d(TAG, "Toggle task: taskId=$taskId, currentCompleted=$completed")

                // 启动主应用处理任务切换
                val toggleIntent = Intent(Intent.ACTION_VIEW)
                toggleIntent.data = Uri.parse("memento://widget/todo_list/toggle?taskId=$taskId&completed=${!completed}")
                toggleIntent.setPackage("github.hunmer.memento")
                toggleIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                context.startActivity(toggleIntent)
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

        // 设置 ListView 项目点击的 PendingIntent 模板
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
     * 获取任务数量
     */
    private fun getTaskCount(context: Context, timeRange: String): Int {
        return try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val jsonString = prefs.getString("todo_list_widget_data", null) ?: return 0
            val json = JSONObject(jsonString)
            val tasks = json.optJSONArray("tasks") ?: return 0

            // 这里简单返回总数，实际过滤在 Factory 中完成
            // 但为了准确显示数量，我们需要在这里也做过滤
            var count = 0
            for (i in 0 until tasks.length()) {
                val task = tasks.getJSONObject(i)
                if (!task.optBoolean("completed", false)) {
                    count++
                }
            }
            count
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get task count", e)
            0
        }
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
