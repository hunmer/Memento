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
import android.widget.Toast
import github.hunmer.memento.widgets.BasePluginWidgetProvider
import com.example.memento_widgets.R
import org.json.JSONObject

/**
 * 目标追踪进度增减小组件 Provider
 *
 * 功能:
 * 1. 显示目标名称、当前值/目标值
 * 2. 提供加减按钮,后台增减进度并显示 toast
 * 3. 点击小组件主体打开目标详情页
 * 4. 支持颜色配置(背景色、强调色、透明度)
 */
open class TrackerGoalWidgetProvider : BasePluginWidgetProvider() {
    override val pluginId: String = "tracker_goal"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_2X2

    companion object {
        private const val TAG = "TrackerGoalWidget"
        private const val PREF_KEY_PREFIX = "tracker_goal_id_"
        private const val PREF_KEY_PRIMARY_COLOR = "tracker_widget_primary_color_"
        private const val PREF_KEY_ACCENT_COLOR = "tracker_widget_accent_color_"
        private const val PREF_KEY_OPACITY = "tracker_widget_opacity_"

        // 默认颜色值(ARGB 格式)
        private const val DEFAULT_PRIMARY_COLOR = 0xFFF44336.toInt() // 红色
        private const val DEFAULT_ACCENT_COLOR = 0xFFFFFFFF.toInt() // 白色
        private const val DEFAULT_OPACITY = 0.95f

        // Action 常量
        private const val ACTION_INCREMENT = "github.hunmer.memento.widgets.TRACKER_GOAL_INCREMENT"
        private const val ACTION_DECREMENT = "github.hunmer.memento.widgets.TRACKER_GOAL_DECREMENT"
        private const val EXTRA_WIDGET_ID = "appWidgetId"

        // 待同步的目标变更（应用启动时读取）
        const val PREF_KEY_PENDING_CHANGES = "tracker_goal_pending_changes"
    }

    override fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_tracker_goal)

        // 1. 读取此小组件实例的配置(用户选择的目标ID)
        val goalId = getConfiguredGoalId(context, appWidgetId)

        if (goalId == null) {
            // 未配置:显示提示,引导用户点击配置
            setupUnconfiguredWidget(views, context, appWidgetId)
        } else {
            // 已配置:读取数据并显示
            val data = loadWidgetData(context)
            if (data != null) {
                val success = setupConfiguredWidget(views, context, data, goalId, appWidgetId)
                if (!success) {
                    setupDefaultWidget(views, context, appWidgetId)
                }
            } else {
                setupDefaultWidget(views, context, appWidgetId)
            }
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    /**
     * 获取用户配置的目标ID
     */
    private fun getConfiguredGoalId(context: Context, appWidgetId: Int): String? {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getString("$PREF_KEY_PREFIX$appWidgetId", null)
    }

    /**
     * 获取配置的背景色(主色调)
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
     * 设置未配置的小组件
     */
    private fun setupUnconfiguredWidget(
        views: RemoteViews,
        context: Context,
        appWidgetId: Int
    ) {
        views.setTextViewText(R.id.widget_goal_name, "计数")
        views.setViewVisibility(R.id.widget_hint_text, View.VISIBLE)
        views.setViewVisibility(R.id.widget_progress_container, View.GONE)
        views.setViewVisibility(R.id.widget_button_container, View.GONE)

        // 设置点击跳转到配置界面
        val intent = Intent(Intent.ACTION_VIEW)
        intent.data = Uri.parse("memento://widget/tracker_goal/config?widgetId=$appWidgetId")
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
     * 设置已配置的小组件
     */
    private fun setupConfiguredWidget(
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

            // 读取颜色配置
            val primaryColor = getConfiguredPrimaryColor(context, appWidgetId)
            val accentColor = getConfiguredAccentColor(context, appWidgetId)
            val opacity = getConfiguredOpacity(context, appWidgetId)

            // 应用背景颜色(使用 backgroundTintList 保持圆角效果)
            val bgColor = adjustColorAlpha(primaryColor, opacity)
            views.setColorStateList(
                R.id.widget_container,
                "setBackgroundTintList",
                ColorStateList.valueOf(bgColor)
            )

            // 应用强调色到标题和数字
            views.setTextColor(R.id.widget_goal_name, accentColor)
            views.setTextColor(R.id.widget_current_value, accentColor)
            views.setTextColor(R.id.widget_target_value, accentColor)

            // 设置目标数据
            val goalName = targetGoal.optString("name", "目标")
            val currentValue = targetGoal.optDouble("currentValue", 0.0).toInt()
            val targetValue = targetGoal.optDouble("targetValue", 100.0).toInt()
            val unitType = targetGoal.optString("unitType", "")

            views.setTextViewText(R.id.widget_goal_name, goalName)
            views.setTextViewText(R.id.widget_current_value, currentValue.toString())
            views.setTextViewText(R.id.widget_target_value, "/$targetValue")

            // 显示数据,隐藏提示
            views.setViewVisibility(R.id.widget_hint_text, View.GONE)
            views.setViewVisibility(R.id.widget_progress_container, View.VISIBLE)
            views.setViewVisibility(R.id.widget_button_container, View.VISIBLE)

            // 设置减号按钮(灰色背景)
            views.setColorStateList(
                R.id.widget_button_decrement,
                "setBackgroundTintList",
                ColorStateList.valueOf(adjustColorAlpha(0xFF9E9E9E.toInt(), 0.3f))
            )
            views.setColorStateList(
                R.id.widget_icon_decrement,
                "setImageTintList",
                ColorStateList.valueOf(accentColor)
            )

            // 设置加号按钮(强调色背景)
            views.setColorStateList(
                R.id.widget_button_increment,
                "setBackgroundTintList",
                ColorStateList.valueOf(adjustColorAlpha(accentColor, 0.2f))
            )
            views.setColorStateList(
                R.id.widget_icon_increment,
                "setImageTintList",
                ColorStateList.valueOf(accentColor)
            )

            // 设置按钮点击事件
            setupButtonClicks(views, context, appWidgetId, goalId, goalName)

            // 设置主体点击事件(跳转到目标详情页)
            setupMainClick(views, context, goalId)

            Log.d(TAG, "Widget configured: $goalName ($currentValue/$targetValue $unitType)")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to setup configured widget", e)
            false
        }
    }

    /**
     * 设置默认小组件(数据加载失败时)
     */
    private fun setupDefaultWidget(
        views: RemoteViews,
        context: Context,
        appWidgetId: Int
    ) {
        views.setTextViewText(R.id.widget_goal_name, "计数")
        views.setTextViewText(R.id.widget_current_value, "0")
        views.setTextViewText(R.id.widget_target_value, "/0")
        views.setViewVisibility(R.id.widget_hint_text, View.GONE)
        views.setViewVisibility(R.id.widget_progress_container, View.VISIBLE)
        views.setViewVisibility(R.id.widget_button_container, View.VISIBLE)

        val primaryColor = getConfiguredPrimaryColor(context, appWidgetId)
        val accentColor = getConfiguredAccentColor(context, appWidgetId)
        val opacity = getConfiguredOpacity(context, appWidgetId)

        val bgColor = adjustColorAlpha(primaryColor, opacity)
        views.setColorStateList(
            R.id.widget_container,
            "setBackgroundTintList",
            ColorStateList.valueOf(bgColor)
        )
        views.setTextColor(R.id.widget_goal_name, accentColor)
        views.setTextColor(R.id.widget_current_value, accentColor)
        views.setTextColor(R.id.widget_target_value, accentColor)
    }

    /**
     * 设置按钮点击事件
     */
    private fun setupButtonClicks(
        views: RemoteViews,
        context: Context,
        appWidgetId: Int,
        goalId: String,
        goalName: String
    ) {
        // 加号按钮
        val incrementIntent = Intent(context, TrackerGoalWidgetProvider::class.java)
        incrementIntent.action = ACTION_INCREMENT
        incrementIntent.putExtra(EXTRA_WIDGET_ID, appWidgetId)
        incrementIntent.putExtra("goalId", goalId)
        incrementIntent.putExtra("goalName", goalName)

        val incrementPendingIntent = PendingIntent.getBroadcast(
            context,
            appWidgetId * 2,
            incrementIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_button_increment, incrementPendingIntent)

        // 减号按钮
        val decrementIntent = Intent(context, TrackerGoalWidgetProvider::class.java)
        decrementIntent.action = ACTION_DECREMENT
        decrementIntent.putExtra(EXTRA_WIDGET_ID, appWidgetId)
        decrementIntent.putExtra("goalId", goalId)
        decrementIntent.putExtra("goalName", goalName)

        val decrementPendingIntent = PendingIntent.getBroadcast(
            context,
            appWidgetId * 2 + 1,
            decrementIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_button_decrement, decrementPendingIntent)
    }

    /**
     * 设置主体点击事件(跳转到目标详情页)
     */
    private fun setupMainClick(views: RemoteViews, context: Context, goalId: String) {
        val intent = Intent(Intent.ACTION_VIEW)
        intent.data = Uri.parse("memento://plugin/tracker/goal/$goalId")
        intent.setPackage("github.hunmer.memento")
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP

        val pendingIntent = PendingIntent.getActivity(
            context,
            goalId.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        views.setOnClickPendingIntent(R.id.widget_progress_container, pendingIntent)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        when (intent.action) {
            ACTION_INCREMENT -> handleIncrement(context, intent)
            ACTION_DECREMENT -> handleDecrement(context, intent)
        }
    }

    /**
     * 处理增加操作
     */
    private fun handleIncrement(context: Context, intent: Intent) {
        val appWidgetId = intent.getIntExtra(EXTRA_WIDGET_ID, -1)
        val goalId = intent.getStringExtra("goalId")
        val goalName = intent.getStringExtra("goalName") ?: "目标"

        if (appWidgetId == -1 || goalId == null) {
            Log.w(TAG, "Invalid increment request")
            return
        }

        try {
            // 读取当前数据
            val data = loadWidgetData(context)
            if (data != null) {
                val goals = data.optJSONArray("goals")
                if (goals != null) {
                    for (i in 0 until goals.length()) {
                        val goal = goals.getJSONObject(i)
                        if (goal.optString("id") == goalId) {
                            val currentValue = goal.optDouble("currentValue", 0.0)
                            val newValue = currentValue + 1

                            // 更新数据(仅内存中,实际应由 Flutter 端处理)
                            goal.put("currentValue", newValue)

                            // 保存数据
                            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                            prefs.edit().putString("tracker_goal_widget_data", data.toString()).apply()

                            // 记录待同步的变更（应用恢复时处理）
                            recordPendingChange(context, goalId, 1.0)

                            // 刷新小组件
                            val appWidgetManager = AppWidgetManager.getInstance(context)
                            updateAppWidget(context, appWidgetManager, appWidgetId)

                            // 显示 Toast
                            Toast.makeText(
                                context,
                                "$goalName +1",
                                Toast.LENGTH_SHORT
                            ).show()

                            Log.d(TAG, "Incremented: $goalName -> $newValue")
                            break
                        }
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to handle increment", e)
            Toast.makeText(context, "操作失败", Toast.LENGTH_SHORT).show()
        }
    }

    /**
     * 处理减少操作
     */
    private fun handleDecrement(context: Context, intent: Intent) {
        val appWidgetId = intent.getIntExtra(EXTRA_WIDGET_ID, -1)
        val goalId = intent.getStringExtra("goalId")
        val goalName = intent.getStringExtra("goalName") ?: "目标"

        if (appWidgetId == -1 || goalId == null) {
            Log.w(TAG, "Invalid decrement request")
            return
        }

        try {
            // 读取当前数据
            val data = loadWidgetData(context)
            if (data != null) {
                val goals = data.optJSONArray("goals")
                if (goals != null) {
                    for (i in 0 until goals.length()) {
                        val goal = goals.getJSONObject(i)
                        if (goal.optString("id") == goalId) {
                            val currentValue = goal.optDouble("currentValue", 0.0)
                            val newValue = (currentValue - 1).coerceAtLeast(0.0)
                            val actualDelta = newValue - currentValue // 实际变更值（可能是 0 或 -1）

                            // 更新数据(仅内存中,实际应由 Flutter 端处理)
                            goal.put("currentValue", newValue)

                            // 保存数据
                            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                            prefs.edit().putString("tracker_goal_widget_data", data.toString()).apply()

                            // 记录待同步的变更（应用恢复时处理）
                            if (actualDelta != 0.0) {
                                recordPendingChange(context, goalId, actualDelta)
                            }

                            // 刷新小组件
                            val appWidgetManager = AppWidgetManager.getInstance(context)
                            updateAppWidget(context, appWidgetManager, appWidgetId)

                            // 显示 Toast
                            Toast.makeText(
                                context,
                                "$goalName -1",
                                Toast.LENGTH_SHORT
                            ).show()

                            Log.d(TAG, "Decremented: $goalName -> $newValue")
                            break
                        }
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to handle decrement", e)
            Toast.makeText(context, "操作失败", Toast.LENGTH_SHORT).show()
        }
    }

    /**
     * 记录待同步的目标变更
     * 应用启动时会读取并同步这些变更到实际的目标数据
     */
    private fun recordPendingChange(context: Context, goalId: String, delta: Double) {
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val pendingJson = prefs.getString(PREF_KEY_PENDING_CHANGES, "{}") ?: "{}"
            val pending = JSONObject(pendingJson)

            // 累加变更值：goalId -> 累计的增减值
            val existingDelta = pending.optDouble(goalId, 0.0)
            pending.put(goalId, existingDelta + delta)

            prefs.edit().putString(PREF_KEY_PENDING_CHANGES, pending.toString()).apply()
            Log.d(TAG, "Recorded pending change: goalId=$goalId, delta=$delta, total=${existingDelta + delta}")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to record pending change", e)
        }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        super.onDeleted(context, appWidgetIds)
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val editor = prefs.edit()
        for (appWidgetId in appWidgetIds) {
            // 清理所有相关配置
            editor.remove("$PREF_KEY_PREFIX$appWidgetId")
            editor.remove("$PREF_KEY_PRIMARY_COLOR$appWidgetId")
            editor.remove("$PREF_KEY_ACCENT_COLOR$appWidgetId")
            editor.remove("$PREF_KEY_OPACITY$appWidgetId")
        }
        editor.apply()
    }
}
