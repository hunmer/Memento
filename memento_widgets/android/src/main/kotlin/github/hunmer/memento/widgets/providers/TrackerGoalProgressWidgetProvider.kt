package github.hunmer.memento.widgets.providers

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.res.ColorStateList
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import github.hunmer.memento_widgets.R
import org.json.JSONObject

/**
 * 目标追踪进度增减小组件 Provider（进度条样式）
 *
 * 功能:
 * 1. 显示目标名称、当前值/目标值
 * 2. 显示进度百分比和进度条
 * 3. 提供加号按钮增加进度并显示 toast
 * 4. 点击小组件主体打开目标详情页
 */
class TrackerGoalProgressWidgetProvider : TrackerGoalWidgetProvider() {
    companion object {
        private const val TAG = "TrackerGoalProgressWidget"
    }

    override fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_tracker_goal_progress)

        // 1. 读取此小组件实例的配置(用户选择的目标ID)
        val goalId = getConfiguredGoalIdPublic(context, appWidgetId)

        if (goalId == null) {
            // 未配置:显示提示,引导用户点击配置
            setupUnconfiguredWidgetProgress(views, context, appWidgetId)
        } else {
            // 已配置:读取数据并显示
            val data = loadWidgetData(context)
            if (data != null) {
                val success = setupConfiguredWidgetProgress(views, context, data, goalId, appWidgetId)
                if (!success) {
                    setupDefaultWidgetProgress(views, context, appWidgetId)
                }
            } else {
                setupDefaultWidgetProgress(views, context, appWidgetId)
            }
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    /**
     * 获取用户配置的目标ID（公开方法以便复用）
     */
    private fun getConfiguredGoalIdPublic(context: Context, appWidgetId: Int): String? {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getString("tracker_goal_id_$appWidgetId", null)
    }

    /**
     * 设置未配置的小组件（进度条样式）
     */
    private fun setupUnconfiguredWidgetProgress(
        views: RemoteViews,
        context: Context,
        appWidgetId: Int
    ) {
        views.setTextViewText(R.id.widget_goal_name, "每日目标")
        views.setViewVisibility(R.id.widget_hint_text, View.VISIBLE)
        views.setViewVisibility(R.id.widget_progress_container, View.GONE)

        // 设置点击跳转到配置界面（使用不同的路由以区分小组件类型）
        val intent = android.content.Intent(android.content.Intent.ACTION_VIEW)
        intent.data = android.net.Uri.parse("memento://widget/tracker_goal_progress/config?widgetId=$appWidgetId")
        intent.setPackage("github.hunmer.memento")
        intent.flags = android.content.Intent.FLAG_ACTIVITY_NEW_TASK or android.content.Intent.FLAG_ACTIVITY_CLEAR_TOP

        val pendingIntent = android.app.PendingIntent.getActivity(
            context,
            appWidgetId,
            intent,
            android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
        )

        views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)
    }

    /**
     * 设置已配置的小组件（进度条样式）
     */
    private fun setupConfiguredWidgetProgress(
        views: RemoteViews,
        context: Context,
        data: JSONObject,
        goalId: String,
        appWidgetId: Int
    ): Boolean {
        return try {
            // 从 data 中查找对应 ID 的目标
            val goals = data.optJSONArray("goals")
            var targetGoal: JSONObject? = null

            if (goals != null) {
                for (i in 0 until goals.length()) {
                    val goal = goals.getJSONObject(i)
                    if (goal.optString("id") == goalId) {
                        targetGoal = goal
                        break
                    }
                }
            }

            if (targetGoal == null) {
                Log.w(TAG, "Goal not found: $goalId")
                return false
            }

            // 设置目标数据
            val goalName = targetGoal.optString("name", "目标")
            val currentValue = targetGoal.optDouble("currentValue", 0.0).toInt()
            val targetValue = targetGoal.optDouble("targetValue", 100.0).toInt()

            // 计算进度百分比
            val percentage = if (targetValue > 0) {
                ((currentValue.toDouble() / targetValue.toDouble()) * 100).toInt().coerceIn(0, 100)
            } else {
                0
            }

            views.setTextViewText(R.id.widget_goal_name, goalName)
            views.setTextViewText(R.id.widget_current_value, currentValue.toString())
            views.setTextViewText(R.id.widget_target_value, "/$targetValue")
            views.setTextViewText(R.id.widget_percentage_text, "$percentage%")

            // 设置进度条进度
            views.setProgressBar(R.id.widget_progress_bar, 100, percentage, false)

            // 显示数据,隐藏提示
            views.setViewVisibility(R.id.widget_hint_text, View.GONE)
            views.setViewVisibility(R.id.widget_progress_container, View.VISIBLE)

            // 设置加号按钮点击事件（复用父类逻辑）
            setupButtonClicksProgress(views, context, appWidgetId, goalId, goalName)

            // 设置主体点击事件(跳转到目标详情页)
            setupMainClickProgress(views, context, goalId)

            Log.d(TAG, "Widget configured: $goalName ($currentValue/$targetValue, $percentage%)")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to setup configured widget", e)
            false
        }
    }

    /**
     * 设置默认小组件（进度条样式）
     */
    private fun setupDefaultWidgetProgress(
        views: RemoteViews,
        context: Context,
        appWidgetId: Int
    ) {
        views.setTextViewText(R.id.widget_goal_name, "每日目标")
        views.setTextViewText(R.id.widget_current_value, "0")
        views.setTextViewText(R.id.widget_target_value, "/0")
        views.setTextViewText(R.id.widget_percentage_text, "0%")
        views.setViewVisibility(R.id.widget_hint_text, View.GONE)
        views.setViewVisibility(R.id.widget_progress_container, View.VISIBLE)

        // 进度条设置为 0%
        views.setProgressBar(R.id.widget_progress_bar, 100, 0, false)
    }

    /**
     * 设置按钮点击事件（进度条样式）
     */
    private fun setupButtonClicksProgress(
        views: RemoteViews,
        context: Context,
        appWidgetId: Int,
        goalId: String,
        goalName: String
    ) {
        // 加号按钮（使用自己的类以便正确刷新）
        val incrementIntent = android.content.Intent(context, TrackerGoalProgressWidgetProvider::class.java)
        incrementIntent.action = "github.hunmer.memento.widgets.TRACKER_GOAL_INCREMENT"
        incrementIntent.putExtra("appWidgetId", appWidgetId)
        incrementIntent.putExtra("goalId", goalId)
        incrementIntent.putExtra("goalName", goalName)

        val incrementPendingIntent = android.app.PendingIntent.getBroadcast(
            context,
            appWidgetId * 2,
            incrementIntent,
            android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_button_increment, incrementPendingIntent)
    }

    /**
     * 设置主体点击事件(跳转到目标详情页)
     */
    private fun setupMainClickProgress(views: RemoteViews, context: Context, goalId: String) {
        val intent = android.content.Intent(android.content.Intent.ACTION_VIEW)
        intent.data = android.net.Uri.parse("memento://plugin/tracker/goal/$goalId")
        intent.setPackage("github.hunmer.memento")
        intent.flags = android.content.Intent.FLAG_ACTIVITY_NEW_TASK or android.content.Intent.FLAG_ACTIVITY_CLEAR_TOP

        val pendingIntent = android.app.PendingIntent.getActivity(
            context,
            goalId.hashCode(),
            intent,
            android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
        )

        views.setOnClickPendingIntent(R.id.widget_progress_container, pendingIntent)
    }
}
