package github.hunmer.memento.widgets.providers

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import com.example.memento_widgets.R
import github.hunmer.memento.widgets.BasePluginWidgetProvider
import github.hunmer.memento.widgets.services.HabitTimerForegroundService
import org.json.JSONObject

/**
 * 习惯计时器小组件 Provider（2x2尺寸）
 *
 * 功能：
 * 1. 首次添加显示"点击设置小组件"提示
 * 2. 配置后显示习惯图标、名称、计时显示
 * 3. 支持播放/暂停按钮控制计时
 * 4. 点击时间区域切换正/倒计时模式
 * 5. 点击小组件打开timer_dialog
 * 6. 支持可变颜色配置
 * 7. 实时更新计时显示（通过前台服务）
 */
class HabitTimerWidgetProvider : BasePluginWidgetProvider() {

    companion object {
        private const val TAG = "HabitTimerWidget"
        private const val PREFS_NAME = "HomeWidgetPreferences"

        // Actions
        const val ACTION_TOGGLE_TIMER = "github.hunmer.memento.widgets.HABIT_TIMER_TOGGLE"
        const val ACTION_SWITCH_MODE = "github.hunmer.memento.widgets.HABIT_TIMER_SWITCH_MODE"
        const val ACTION_COMPLETE_TIMER = "github.hunmer.memento.widgets.HABIT_TIMER_COMPLETE"

        // Preference Keys
        const val PREF_KEY_HABIT_ID = "habit_timer_habit_id_"
        const val PREF_KEY_HABIT_NAME = "habit_timer_habit_name_"
        const val PREF_KEY_HABIT_ICON = "habit_timer_habit_icon_"
        const val PREF_KEY_DURATION_MINUTES = "habit_timer_duration_minutes_"
        const val PREF_KEY_PRIMARY_COLOR = "habit_timer_primary_color_"
        const val PREF_KEY_ACCENT_COLOR = "habit_timer_accent_color_"
        const val PREF_KEY_BUTTON_COLOR = "habit_timer_button_color_"
        const val PREF_KEY_OPACITY = "habit_timer_opacity_"
        const val PREF_KEY_TIMER_STATE = "habit_timer_state_"
        const val PREF_KEY_PENDING_CHANGES = "habit_timer_pending_changes"

        // Default Colors
        private const val DEFAULT_PRIMARY_COLOR = 0xFFF3F4F6.toInt() // Light gray background
        private const val DEFAULT_ACCENT_COLOR = 0xFF1F2937.toInt() // Dark gray text
        private const val DEFAULT_BUTTON_COLOR = 0xFF10B981.toInt() // Emerald green button
        private const val DEFAULT_OPACITY = 1.0f
    }

    override val pluginId: String = "habit_timer"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_2X2

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        when (intent.action) {
            ACTION_TOGGLE_TIMER -> {
                val widgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, -1)
                if (widgetId != -1) {
                    handleToggleTimer(context, widgetId)
                }
            }
            ACTION_SWITCH_MODE -> {
                val widgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, -1)
                if (widgetId != -1) {
                    handleSwitchMode(context, widgetId)
                }
            }
            ACTION_COMPLETE_TIMER -> {
                val widgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, -1)
                if (widgetId != -1) {
                    handleCompleteTimer(context, widgetId)
                }
            }
        }
    }

    override fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_habit_timer)

        // 1. 读取配置
        val habitId = getConfiguredHabitId(context, appWidgetId)

        if (habitId == null) {
            // 未配置：显示提示
            setupUnconfiguredWidget(views, context, appWidgetId)
        } else {
            // 已配置：显示计时器
            val success = setupConfiguredWidget(views, context, appWidgetId, habitId)
            if (!success) {
                setupDefaultWidget(views, context, appWidgetId)
            }
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    /**
     * 获取配置的习惯ID
     */
    private fun getConfiguredHabitId(context: Context, appWidgetId: Int): String? {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getString("$PREF_KEY_HABIT_ID$appWidgetId", null)
    }

    /**
     * 设置未配置的小组件
     */
    private fun setupUnconfiguredWidget(
        views: RemoteViews,
        context: Context,
        appWidgetId: Int
    ) {
        // 隐藏所有内容，显示提示文本
        views.setViewVisibility(R.id.habit_icon_container, View.GONE)
        views.setViewVisibility(R.id.habit_title, View.GONE)
        views.setViewVisibility(R.id.timer_display, View.GONE)
        views.setViewVisibility(R.id.play_pause_button, View.GONE)
        views.setViewVisibility(R.id.complete_button, View.GONE)
        views.setViewVisibility(R.id.hint_text, View.VISIBLE)

        views.setTextViewText(R.id.hint_text, "点击设置小组件")

        // 设置背景颜色
        views.setColorStateList(
            R.id.widget_container,
            "setBackgroundTintList",
            ColorStateList.valueOf(DEFAULT_PRIMARY_COLOR)
        )

        // 点击跳转到配置页面（使用deeplink）
        val intent = Intent(Intent.ACTION_VIEW).apply {
            data = android.net.Uri.parse("memento://widget/habit_timer/config?widgetId=$appWidgetId")
            setPackage("github.hunmer.memento")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }

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
        appWidgetId: Int,
        habitId: String
    ): Boolean {
        return try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

            // 读取习惯信息
            val habitName = prefs.getString("$PREF_KEY_HABIT_NAME$appWidgetId", null) ?: "习惯"
            val habitIcon = prefs.getString("$PREF_KEY_HABIT_ICON$appWidgetId", null)
            val durationMinutes = prefs.getString("$PREF_KEY_DURATION_MINUTES$appWidgetId", "25")?.toIntOrNull() ?: 25

            // 读取颜色配置
            val primaryColor = getConfiguredColor(context, appWidgetId, PREF_KEY_PRIMARY_COLOR, DEFAULT_PRIMARY_COLOR)
            val accentColor = getConfiguredColor(context, appWidgetId, PREF_KEY_ACCENT_COLOR, DEFAULT_ACCENT_COLOR)
            val buttonColor = getConfiguredColor(context, appWidgetId, PREF_KEY_BUTTON_COLOR, DEFAULT_BUTTON_COLOR)
            val opacity = getConfiguredOpacity(context, appWidgetId)

            // 读取计时器状态
            val timerStateJson = prefs.getString("$PREF_KEY_TIMER_STATE$appWidgetId", null)
            val timerState = if (timerStateJson != null) {
                try {
                    JSONObject(timerStateJson)
                } catch (e: Exception) {
                    null
                }
            } else {
                null
            }

            val isRunning = timerState?.optBoolean("isRunning", false) ?: false
            val elapsedSeconds = timerState?.optInt("elapsedSeconds", 0) ?: 0
            val isCountdown = timerState?.optBoolean("isCountdown", true) ?: true

            Log.d(TAG, "Read timer state: isRunning=$isRunning, elapsed=$elapsedSeconds, json=$timerStateJson")

            // 显示所有内容，隐藏提示
            views.setViewVisibility(R.id.habit_icon_container, View.VISIBLE)
            views.setViewVisibility(R.id.habit_title, View.VISIBLE)
            views.setViewVisibility(R.id.timer_display, View.VISIBLE)
            views.setViewVisibility(R.id.play_pause_button, View.VISIBLE)
            views.setViewVisibility(R.id.hint_text, View.GONE)

            // 完成按钮：仅在有计时数据时显示
            if (elapsedSeconds > 0) {
                views.setViewVisibility(R.id.complete_button, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.complete_button, View.GONE)
            }

            // 设置背景颜色（带透明度）
            val bgColor = adjustColorAlpha(primaryColor, opacity)
            views.setColorStateList(
                R.id.widget_container,
                "setBackgroundTintList",
                ColorStateList.valueOf(bgColor)
            )

            // 设置习惯图标
            if (habitIcon != null) {
                try {
                    val iconCodePoint = habitIcon.toIntOrNull() ?: 0xE87C
                    val iconBitmap = createIconBitmap(context, iconCodePoint, 48, accentColor)
                    if (iconBitmap != null) {
                        views.setImageViewBitmap(R.id.habit_icon, iconBitmap)
                    }
                } catch (e: Exception) {
                    Log.w(TAG, "Failed to set habit icon", e)
                }
            }

            // 设置习惯名称
            views.setTextViewText(R.id.habit_title, habitName)
            views.setTextColor(R.id.habit_title, accentColor)

            // 设置时间显示
            val timeString = formatTime(elapsedSeconds, isCountdown, durationMinutes)
            views.setTextViewText(R.id.timer_display, timeString)
            views.setTextColor(R.id.timer_display, accentColor)

            // 设置播放/暂停按钮
            val playPauseIcon = if (isRunning) {
                android.R.drawable.ic_media_pause
            } else {
                android.R.drawable.ic_media_play
            }
            views.setImageViewResource(R.id.play_pause_button, playPauseIcon)
            views.setColorStateList(
                R.id.play_pause_button,
                "setBackgroundTintList",
                ColorStateList.valueOf(buttonColor)
            )

            // 设置按钮点击事件
            setupButtonClicks(views, context, appWidgetId, habitId, habitName, durationMinutes, isRunning, elapsedSeconds)

            // 设置时间显示点击事件（切换模式）
            setupTimeClick(views, context, appWidgetId)

            // 设置主体点击事件（打开timer_dialog）
            setupMainClick(views, context, habitId)

            Log.d(TAG, "Widget configured: $habitName, running=$isRunning, time=$timeString")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to setup configured widget", e)
            false
        }
    }

    /**
     * 设置默认小组件
     */
    private fun setupDefaultWidget(
        views: RemoteViews,
        context: Context,
        appWidgetId: Int
    ) {
        views.setViewVisibility(R.id.habit_icon_container, View.VISIBLE)
        views.setViewVisibility(R.id.habit_title, View.VISIBLE)
        views.setViewVisibility(R.id.timer_display, View.VISIBLE)
        views.setViewVisibility(R.id.play_pause_button, View.VISIBLE)
        views.setViewVisibility(R.id.complete_button, View.GONE)
        views.setViewVisibility(R.id.hint_text, View.GONE)

        views.setTextViewText(R.id.habit_title, "习惯")
        views.setTextViewText(R.id.timer_display, "25:00")
    }

    /**
     * 设置按钮点击事件
     */
    private fun setupButtonClicks(
        views: RemoteViews,
        context: Context,
        appWidgetId: Int,
        habitId: String,
        habitName: String,
        durationMinutes: Int,
        isRunning: Boolean,
        elapsedSeconds: Int
    ) {
        // 播放/暂停按钮
        if (isRunning) {
            // 当前正在运行，点击暂停
            val pauseIntent = Intent(context, HabitTimerForegroundService::class.java).apply {
                action = HabitTimerForegroundService.ACTION_PAUSE_TIMER
            }
            val pausePendingIntent = PendingIntent.getService(
                context,
                appWidgetId * 10 + 1,
                pauseIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.play_pause_button, pausePendingIntent)
        } else {
            // 当前未运行，点击启动
            val startIntent = Intent(context, HabitTimerForegroundService::class.java).apply {
                action = HabitTimerForegroundService.ACTION_START_TIMER
                putExtra(HabitTimerForegroundService.EXTRA_WIDGET_ID, appWidgetId)
                putExtra(HabitTimerForegroundService.EXTRA_HABIT_ID, habitId)
                putExtra(HabitTimerForegroundService.EXTRA_HABIT_NAME, habitName)
                putExtra(HabitTimerForegroundService.EXTRA_DURATION_MINUTES, durationMinutes)
            }
            val startPendingIntent = PendingIntent.getService(
                context,
                appWidgetId * 10 + 1,
                startIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.play_pause_button, startPendingIntent)
        }

        // 完成按钮（仅在有计时数据时设置点击事件）
        if (elapsedSeconds > 0) {
            val completeIntent = Intent(context, HabitTimerWidgetProvider::class.java).apply {
                action = ACTION_COMPLETE_TIMER
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            }
            val completePendingIntent = PendingIntent.getBroadcast(
                context,
                appWidgetId * 10 + 3,
                completeIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.complete_button, completePendingIntent)
        }
    }

    /**
     * 设置时间显示点击事件（切换模式）
     */
    private fun setupTimeClick(
        views: RemoteViews,
        context: Context,
        appWidgetId: Int
    ) {
        val switchIntent = Intent(context, HabitTimerWidgetProvider::class.java).apply {
            action = ACTION_SWITCH_MODE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        }
        val switchPendingIntent = PendingIntent.getBroadcast(
            context,
            appWidgetId * 10 + 2,
            switchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.timer_display, switchPendingIntent)
    }

    /**
     * 设置主体点击事件（打开timer_dialog）
     */
    /**
     * 设置主体点击事件（打开timer_dialog）
     */
    private fun setupMainClick(
        views: RemoteViews,
        context: Context,
        habitId: String
    ) {
        val intent = Intent(Intent.ACTION_VIEW).apply {
            data = android.net.Uri.parse("memento://plugin/habits/timer?habitId=$habitId")
            setPackage("com.example.memento_widgets_example")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            habitId.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.habit_icon_container, pendingIntent)
    }
    /**
     * 处理播放/暂停切换
     */
    private fun handleToggleTimer(context: Context, appWidgetId: Int) {
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val habitId = prefs.getString("$PREF_KEY_HABIT_ID$appWidgetId", null) ?: return

            // 读取当前状态
            val stateKey = "$PREF_KEY_TIMER_STATE$appWidgetId"
            val stateJson = prefs.getString(stateKey, null)
            val state = if (stateJson != null) JSONObject(stateJson) else JSONObject()

            val isRunning = state.optBoolean("isRunning", false)

            // 切换状态
            state.put("isRunning", !isRunning)
            state.put("timestamp", System.currentTimeMillis())

            // 保存状态
            prefs.edit().putString(stateKey, state.toString()).apply()

            // 记录待处理变更
            recordPendingChange(context, habitId, !isRunning)

            // 刷新小组件
            refreshWidget(context, appWidgetId)

            // 显示Toast
            android.widget.Toast.makeText(
                context,
                if (!isRunning) "▶ 开始计时" else "⏸ 暂停计时",
                android.widget.Toast.LENGTH_SHORT
            ).show()

            Log.d(TAG, "Timer toggled: $habitId, running=${!isRunning}")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to toggle timer", e)
        }
    }

    /**
     * 处理计时模式切换
     */
    private fun handleSwitchMode(context: Context, appWidgetId: Int) {
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

            // 读取当前状态
            val stateKey = "$PREF_KEY_TIMER_STATE$appWidgetId"
            val stateJson = prefs.getString(stateKey, null)
            val state = if (stateJson != null) JSONObject(stateJson) else JSONObject()

            val isCountdown = state.optBoolean("isCountdown", true)

            // 切换模式
            state.put("isCountdown", !isCountdown)

            // 保存状态
            prefs.edit().putString(stateKey, state.toString()).apply()

            // 刷新小组件
            refreshWidget(context, appWidgetId)

            // 显示Toast
            android.widget.Toast.makeText(
                context,
                if (!isCountdown) "切换到正计时" else "切换到倒计时",
                android.widget.Toast.LENGTH_SHORT
            ).show()

            Log.d(TAG, "Mode switched: countdown=${!isCountdown}")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to switch mode", e)
        }
    }

    /**
     * 处理完成计时
     */
    private fun handleCompleteTimer(context: Context, appWidgetId: Int) {
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val habitId = prefs.getString("$PREF_KEY_HABIT_ID$appWidgetId", null) ?: return
            val habitName = prefs.getString("$PREF_KEY_HABIT_NAME$appWidgetId", null) ?: "习惯"

            // 读取当前状态
            val stateKey = "$PREF_KEY_TIMER_STATE$appWidgetId"
            val stateJson = prefs.getString(stateKey, null)
            val state = if (stateJson != null) JSONObject(stateJson) else JSONObject()

            val elapsedSeconds = state.optInt("elapsedSeconds", 0)

            // 如果没有计时数据，不执行操作
            if (elapsedSeconds <= 0) {
                android.widget.Toast.makeText(
                    context,
                    "暂无计时数据",
                    android.widget.Toast.LENGTH_SHORT
                ).show()
                return
            }

            // 停止前台服务（如果正在运行）
            val stopIntent = Intent(context, HabitTimerForegroundService::class.java).apply {
                action = HabitTimerForegroundService.ACTION_STOP_TIMER
            }
            context.startService(stopIntent)

            // 记录完成的计时数据到待处理变更
            recordCompletionChange(context, habitId, elapsedSeconds)

            // 重置计时状态
            val newState = JSONObject().apply {
                put("isRunning", false)
                put("elapsedSeconds", 0)
                put("isCountdown", state.optBoolean("isCountdown", true))
                put("timestamp", System.currentTimeMillis())
            }
            prefs.edit().putString(stateKey, newState.toString()).apply()

            // 刷新小组件
            refreshWidget(context, appWidgetId)

            // 显示 Toast
            val minutes = elapsedSeconds / 60
            val seconds = elapsedSeconds % 60
            val timeStr = if (minutes > 0) {
                "${minutes}分${seconds}秒"
            } else {
                "${seconds}秒"
            }
            android.widget.Toast.makeText(
                context,
                "✓ 已完成「$habitName」计时 $timeStr",
                android.widget.Toast.LENGTH_SHORT
            ).show()

            Log.d(TAG, "Timer completed: $habitId, elapsed=$elapsedSeconds")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to complete timer", e)
        }
    }

    /**
     * 记录完成的计时数据（供Flutter端同步）
     */
    private fun recordCompletionChange(context: Context, habitId: String, elapsedSeconds: Int) {
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val pendingJson = prefs.getString(PREF_KEY_PENDING_CHANGES, "{}")
            val pending = if (pendingJson != null) JSONObject(pendingJson) else JSONObject()

            val change = JSONObject().apply {
                put("action", "complete")
                put("elapsedSeconds", elapsedSeconds)
                put("timestamp", System.currentTimeMillis())
            }

            pending.put(habitId, change)
            prefs.edit().putString(PREF_KEY_PENDING_CHANGES, pending.toString()).apply()

            Log.d(TAG, "Completion change recorded: $habitId, elapsed=$elapsedSeconds")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to record completion change", e)
        }
    }

    /**
     * 记录待处理变更（供Flutter端同步）
     */
    private fun recordPendingChange(context: Context, habitId: String, isRunning: Boolean) {
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val pendingJson = prefs.getString(PREF_KEY_PENDING_CHANGES, "{}")
            val pending = if (pendingJson != null) JSONObject(pendingJson) else JSONObject()

            val change = JSONObject().apply {
                put("isRunning", isRunning)
                put("timestamp", System.currentTimeMillis())
            }

            pending.put(habitId, change)
            prefs.edit().putString(PREF_KEY_PENDING_CHANGES, pending.toString()).apply()

            Log.d(TAG, "Pending change recorded: $habitId, running=$isRunning")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to record pending change", e)
        }
    }

    /**
     * 刷新小组件
     */
    private fun refreshWidget(context: Context, appWidgetId: Int) {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        updateAppWidget(context, appWidgetManager, appWidgetId)
    }

    /**
     * 获取配置的颜色
     */
    private fun getConfiguredColor(
        context: Context,
        appWidgetId: Int,
        prefKey: String,
        defaultColor: Int
    ): Int {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val colorStr = prefs.getString("$prefKey$appWidgetId", null)
        return colorStr?.toLongOrNull()?.toInt() ?: defaultColor
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
     * 格式化时间显示
     */
    private fun formatTime(seconds: Int, isCountdown: Boolean, durationMinutes: Int): String {
        val displaySeconds = if (isCountdown) {
            (durationMinutes * 60 - seconds).coerceAtLeast(0)
        } else {
            seconds
        }

        val hours = displaySeconds / 3600
        val minutes = (displaySeconds % 3600) / 60
        val secs = displaySeconds % 60

        return if (hours > 0) {
            String.format("%d:%02d:%02d", hours, minutes, secs)
        } else {
            String.format("%02d:%02d", minutes, secs)
        }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        super.onDeleted(context, appWidgetIds)
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val editor = prefs.edit()

        for (appWidgetId in appWidgetIds) {
            // 清理所有相关配置
            editor.remove("$PREF_KEY_HABIT_ID$appWidgetId")
            editor.remove("$PREF_KEY_HABIT_NAME$appWidgetId")
            editor.remove("$PREF_KEY_HABIT_ICON$appWidgetId")
            editor.remove("$PREF_KEY_DURATION_MINUTES$appWidgetId")
            editor.remove("$PREF_KEY_PRIMARY_COLOR$appWidgetId")
            editor.remove("$PREF_KEY_ACCENT_COLOR$appWidgetId")
            editor.remove("$PREF_KEY_BUTTON_COLOR$appWidgetId")
            editor.remove("$PREF_KEY_OPACITY$appWidgetId")
            editor.remove("$PREF_KEY_TIMER_STATE$appWidgetId")
        }

        editor.apply()
        Log.d(TAG, "Widget deleted: ${appWidgetIds.contentToString()}")
    }
}
