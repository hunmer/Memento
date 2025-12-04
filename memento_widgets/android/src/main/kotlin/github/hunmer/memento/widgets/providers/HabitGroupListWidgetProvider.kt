package github.hunmer.memento.widgets.providers

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import android.widget.Toast
import github.hunmer.memento_widgets.R
import github.hunmer.memento.widgets.BasePluginWidgetProvider
import github.hunmer.memento.widgets.services.HabitGroupListRemoteViewsFactory
import github.hunmer.memento.widgets.services.HabitGroupListWidgetService
import org.json.JSONArray
import org.json.JSONObject

/**
 * 习惯分组列表小组件 Provider
 * 显示习惯分组列表，支持配置时间范围和标题
 *
 * 交互逻辑：
 * - 点击分组：切换显示该分组下的习惯
 * - 点击习惯：跳转到习惯计时器界面
 */
class HabitGroupListWidgetProvider : BasePluginWidgetProvider() {
    override val pluginId: String = "habit_group_list"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_4X2

    companion object {
        private const val TAG = "HabitGroupListWidget"

        // SharedPreferences key 前缀
        private const val PREF_KEY_CONFIGURED = "habit_group_list_configured_"
        private const val PREF_KEY_SELECTED_GROUP = "habit_group_list_selected_group_"
        private const val PREF_KEY_PRIMARY_COLOR = "habit_group_list_primary_color_"
        private const val PREF_KEY_ACCENT_COLOR = "habit_group_list_accent_color_"
        private const val PREF_KEY_OPACITY = "habit_group_list_opacity_"

        // 默认颜色
        private const val DEFAULT_PRIMARY_COLOR = 0xFF6366F1.toInt() // Indigo
        private const val DEFAULT_ACCENT_COLOR = 0xFF818CF8.toInt()
        private const val DEFAULT_OPACITY = 1.0f

        // 广播 Action
        const val ACTION_GROUP_CLICK = "github.hunmer.memento.widgets.HABIT_GROUP_LIST_GROUP_CLICK"
        const val ACTION_HABIT_CLICK = "github.hunmer.memento.widgets.HABIT_GROUP_LIST_HABIT_CLICK"

        // 特殊分组 ID
        const val GROUP_ALL = "__all__"
        const val GROUP_UNGROUPED = "__ungrouped__"

        /**
         * 静态方法：刷新所有习惯分组列表小组件
         */
        fun refreshAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, HabitGroupListWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)

            if (appWidgetIds.isEmpty()) {
                Log.d(TAG, "refreshAllWidgets: no widgets found")
                return
            }

            // 触发小组件更新
            val intent = Intent(context, HabitGroupListWidgetProvider::class.java)
            intent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetIds)
            context.sendBroadcast(intent)

            // 延迟通知数据变化，给Flutter端时间完成数据同步
            Handler(Looper.getMainLooper()).postDelayed({
                for (appWidgetId in appWidgetIds) {
                    // 检查数据是否存在
                    val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                    val widgetData = prefs.getString("habit_group_list_widget_data", null)

                    if (!widgetData.isNullOrEmpty()) {
                        // 数据已准备好，通知更新
                        appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.group_list_view)
                        appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.habit_grid_view)
                        Log.d(TAG, "refreshAllWidgets: notified data changed for widget $appWidgetId")
                    } else {
                        Log.d(TAG, "refreshAllWidgets: widget data not ready for $appWidgetId, skipping notification")
                    }
                }
            }, 500) // 延迟500ms通知

            Log.d(TAG, "refreshAllWidgets: scheduled data notification for ${appWidgetIds.size} widgets")
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        super.onUpdate(context, appWidgetManager, appWidgetIds)

        // 延迟通知数据变化，给Flutter端时间完成数据同步
        Handler(Looper.getMainLooper()).postDelayed({
            for (appWidgetId in appWidgetIds) {
                // 检查数据是否存在
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val widgetData = prefs.getString("habit_group_list_widget_data", null)

                if (!widgetData.isNullOrEmpty()) {
                    // 数据已准备好，通知更新
                    appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.group_list_view)
                    appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.habit_grid_view)
                    Log.d(TAG, "onUpdate: notified data changed for widget $appWidgetId")
                } else {
                    Log.d(TAG, "onUpdate: widget data not ready for $appWidgetId, skipping notification")
                }
            }
        }, 500) // 延迟500ms通知

        Log.d(TAG, "onUpdate: scheduled data notification for ${appWidgetIds.size} widgets")
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        when (intent.action) {
            ACTION_GROUP_CLICK -> handleGroupClick(context, intent)
            ACTION_HABIT_CLICK -> handleHabitClick(context, intent)
        }
    }

    /**
     * 处理分组点击事件
     */
    private fun handleGroupClick(context: Context, intent: Intent) {
        val groupId = intent.getStringExtra("group_id") ?: return
        val widgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)

        if (widgetId == AppWidgetManager.INVALID_APPWIDGET_ID) return

        Log.d(TAG, "handleGroupClick: groupId=$groupId, widgetId=$widgetId")

        // 保存选中的分组
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putString("$PREF_KEY_SELECTED_GROUP$widgetId", groupId).apply()

        // 刷新小组件
        val appWidgetManager = AppWidgetManager.getInstance(context)
        updateAppWidget(context, appWidgetManager, widgetId)
        appWidgetManager.notifyAppWidgetViewDataChanged(widgetId, R.id.habit_grid_view)
    }

    /**
     * 处理习惯点击事件
     */
    private fun handleHabitClick(context: Context, intent: Intent) {
        val action = intent.getStringExtra("action") ?: return
        val habitId = intent.getStringExtra("habit_id") ?: return

        Log.d(TAG, "handleHabitClick: action=$action, habitId=$habitId")

        when (action) {
            "open_timer" -> {
                // 打开习惯计时器界面
                Log.d(TAG, "Open habit timer: habitId=$habitId")
                val timerIntent = Intent(Intent.ACTION_VIEW)
                timerIntent.data = Uri.parse("memento://habits/timer?habitId=$habitId")
                timerIntent.setPackage("github.hunmer.memento")
                timerIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                context.startActivity(timerIntent)
            }
        }
    }

    override fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_habit_group_list)

        // 检查是否已配置
        val isConfigured = isWidgetConfigured(context, appWidgetId)
        Log.d(TAG, "updateAppWidget: appWidgetId=$appWidgetId, isConfigured=$isConfigured")

        if (!isConfigured) {
            // 未配置，显示配置提示
            Log.d(TAG, "小组件未配置，显示选择提示")
            setupUnconfiguredWidget(views, context, appWidgetId)
        } else {
            // 已配置，显示分组和习惯列表
            Log.d(TAG, "小组件已配置")

            // 读取颜色和透明度配置
            val primaryColor = getConfiguredPrimaryColor(context, appWidgetId)
            val accentColor = getConfiguredAccentColor(context, appWidgetId)
            val opacity = getConfiguredOpacity(context, appWidgetId)

            setupConfiguredWidget(views, context, appWidgetId, primaryColor, accentColor, opacity)
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    /**
     * 设置未配置状态的小组件
     */
    private fun setupUnconfiguredWidget(views: RemoteViews, context: Context, appWidgetId: Int) {
        // 隐藏列表，显示配置提示
        views.setViewVisibility(R.id.group_list_container, View.GONE)
        views.setViewVisibility(R.id.habit_list_container, View.GONE)
        views.setViewVisibility(R.id.widget_hint_text, View.VISIBLE)

        // 设置点击事件：打开配置页面
        val intent = Intent(Intent.ACTION_VIEW)
        intent.data = Uri.parse("memento://widget/habit_group_list/config?widgetId=$appWidgetId")
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
        primaryColor: Int,
        accentColor: Int,
        opacity: Float
    ) {
        // 显示列表，隐藏配置提示
        views.setViewVisibility(R.id.group_list_container, View.VISIBLE)
        views.setViewVisibility(R.id.habit_list_container, View.VISIBLE)
        views.setViewVisibility(R.id.widget_hint_text, View.GONE)

        // 应用颜色
        views.setTextColor(R.id.group_list_title, primaryColor)
        views.setTextColor(R.id.habit_list_title, primaryColor)

        // 设置分组列表的 RemoteViewsService
        val groupServiceIntent = Intent(context, HabitGroupListWidgetService::class.java).apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            putExtra("list_type", "groups")
            setData(Uri.parse(this.toUri(Intent.URI_INTENT_SCHEME)))
        }
        views.setRemoteAdapter(R.id.group_list_view, groupServiceIntent)

        // 设置习惯列表的 RemoteViewsService
        val habitServiceIntent = Intent(context, HabitGroupListWidgetService::class.java).apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            putExtra("list_type", "habits")
            setData(Uri.parse(this.toUri(Intent.URI_INTENT_SCHEME)))
        }
        views.setRemoteAdapter(R.id.habit_grid_view, habitServiceIntent)
        views.setEmptyView(R.id.habit_grid_view, R.id.habit_empty_text)

        // 设置分组点击的 PendingIntent 模板
        val groupClickIntent = Intent(context, HabitGroupListWidgetProvider::class.java).apply {
            action = ACTION_GROUP_CLICK
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        }
        val groupClickPendingIntent = PendingIntent.getBroadcast(
            context,
            appWidgetId * 1000 + 1,
            groupClickIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        )
        views.setPendingIntentTemplate(R.id.group_list_view, groupClickPendingIntent)

        // 设置习惯点击的 PendingIntent 模板
        val habitClickIntent = Intent(context, HabitGroupListWidgetProvider::class.java).apply {
            action = ACTION_HABIT_CLICK
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        }
        val habitClickPendingIntent = PendingIntent.getBroadcast(
            context,
            appWidgetId * 1000 + 2,
            habitClickIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        )
        views.setPendingIntentTemplate(R.id.habit_grid_view, habitClickPendingIntent)

        // 设置标题栏点击 - 跳转到习惯插件
        setupHeaderClickIntent(context, views)
    }

    /**
     * 设置标题栏点击事件 - 跳转到习惯插件
     */
    private fun setupHeaderClickIntent(context: Context, views: RemoteViews) {
        val intent = Intent(Intent.ACTION_VIEW)
        intent.data = Uri.parse("memento://widget/habits")
        intent.setPackage("github.hunmer.memento")
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP

        val pendingIntent = PendingIntent.getActivity(
            context,
            "habits_header".hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        views.setOnClickPendingIntent(R.id.group_list_title, pendingIntent)
        views.setOnClickPendingIntent(R.id.habit_list_title, pendingIntent)
    }

    /**
     * 检查小组件是否已配置
     */
    private fun isWidgetConfigured(context: Context, appWidgetId: Int): Boolean {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getBoolean("$PREF_KEY_CONFIGURED$appWidgetId", false)
    }

    /**
     * 获取配置的主色调
     */
    private fun getConfiguredPrimaryColor(context: Context, appWidgetId: Int): Int {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val colorStr = prefs.getString("$PREF_KEY_PRIMARY_COLOR$appWidgetId", null)
        return colorStr?.toLongOrNull()?.toInt() ?: DEFAULT_PRIMARY_COLOR
    }

    /**
     * 获取配置的强调色
     */
    private fun getConfiguredAccentColor(context: Context, appWidgetId: Int): Int {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val colorStr = prefs.getString("$PREF_KEY_ACCENT_COLOR$appWidgetId", null)
        return colorStr?.toLongOrNull()?.toInt() ?: DEFAULT_ACCENT_COLOR
    }

    /**
     * 获取配置的透明度
     */
    private fun getConfiguredOpacity(context: Context, appWidgetId: Int): Float {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val opacityStr = prefs.getString("$PREF_KEY_OPACITY$appWidgetId", null)
        return opacityStr?.toFloatOrNull() ?: DEFAULT_OPACITY
    }

    /**
     * 删除配置
     */
    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        super.onDeleted(context, appWidgetIds)
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val editor = prefs.edit()
        for (appWidgetId in appWidgetIds) {
            editor.remove("$PREF_KEY_CONFIGURED$appWidgetId")
            editor.remove("$PREF_KEY_SELECTED_GROUP$appWidgetId")
            editor.remove("$PREF_KEY_PRIMARY_COLOR$appWidgetId")
            editor.remove("$PREF_KEY_ACCENT_COLOR$appWidgetId")
            editor.remove("$PREF_KEY_OPACITY$appWidgetId")
        }
        editor.apply()
    }
}
