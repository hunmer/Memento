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
import com.example.memento_widgets.R
import github.hunmer.memento.widgets.BasePluginWidgetProvider
import org.json.JSONObject

/**
 * 快捷记账小组件 Provider
 * 显示用户配置的快捷记账预设列表
 *
 * 交互逻辑：
 * - 首次添加：显示"点击设置小组件"，点击后打开配置页面
 * - 点击快捷项：打开记账界面并预填充数据
 * - 点击添加按钮：打开配置页面
 * - 点击标题栏：打开账单插件主界面
 */
class BillShortcutsWidgetProvider : BasePluginWidgetProvider() {
    override val pluginId: String = "bill_shortcuts"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_2X2

    companion object {
        private const val TAG = "BillShortcutsWidget"

        // 配置键前缀
        private const val CONFIG_KEY_PREFIX = "bill_shortcuts_widget_"
        private const val COLOR_KEY_PREFIX = "bill_shortcuts_widget_color_"

        // 默认颜色(绿色系)
        private const val DEFAULT_BACKGROUND_COLOR = 0xFFFFFFFF.toInt()
        private const val DEFAULT_TEXT_COLOR = 0xFF1F2937.toInt()
        private const val DEFAULT_ICON_COLOR = 0xFF10B981.toInt()

        // 广播 Action
        const val ACTION_SHORTCUT_CLICK = "github.hunmer.memento.widgets.BILL_SHORTCUTS_CLICK"

        /**
         * 静态方法：刷新所有快捷记账小组件
         */
        fun refreshAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, BillShortcutsWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)

            // 触发小组件更新
            val intent = Intent(context, BillShortcutsWidgetProvider::class.java)
            intent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetIds)
            context.sendBroadcast(intent)

            // 通知列表数据已更改
            appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetIds, R.id.shortcuts_list_view)
            Log.d(TAG, "refreshAllWidgets: updated ${appWidgetIds.size} widgets")
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
        appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetIds, R.id.shortcuts_list_view)

        Log.d(TAG, "onUpdate: notified ListView data changed for ${appWidgetIds.size} widgets")
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        when (intent.action) {
            ACTION_SHORTCUT_CLICK -> handleShortcutClick(context, intent)
        }
    }

    /**
     * 处理快捷项点击事件
     */
    private fun handleShortcutClick(context: Context, intent: Intent) {
        val action = intent.getStringExtra("action") ?: return

        Log.d(TAG, "handleShortcutClick: action=$action")

        when (action) {
            "add_bill" -> {
                // 打开记账界面并预填充数据
                val shortcutId = intent.getStringExtra("shortcut_id")
                val accountId = intent.getStringExtra("account_id")
                val category = intent.getStringExtra("category")
                val amount = intent.getDoubleExtra("amount", -1.0)
                val isExpense = intent.getBooleanExtra("is_expense", true)

                Log.d(TAG, "Open bill edit: accountId=$accountId, category=$category, amount=$amount")

                // 构建 deeplink URI
                val uri = buildString {
                    append("memento://widget/bill_shortcuts/add?")
                    append("accountId=$accountId")
                    append("&category=$category")
                    if (amount > 0) {
                        append("&amount=$amount")
                    }
                    append("&isExpense=$isExpense")
                }

                val billIntent = Intent(Intent.ACTION_VIEW)
                billIntent.data = Uri.parse(uri)
                billIntent.setPackage("github.hunmer.memento")
                billIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                context.startActivity(billIntent)
            }
        }
    }

    override fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_bill_shortcuts)

        // 检查是否已配置
        val hasConfig = hasWidgetConfig(context, appWidgetId)
        Log.d(TAG, "updateAppWidget: appWidgetId=$appWidgetId, hasConfig=$hasConfig")

        if (!hasConfig) {
            // 未配置，显示配置提示
            Log.d(TAG, "小组件未配置，显示配置提示")
            setupUnconfiguredWidget(views, context, appWidgetId)
        } else {
            // 已配置，显示快捷列表
            Log.d(TAG, "小组件已配置")

            // 读取颜色配置
            val colorConfig = loadColorConfig(context, appWidgetId)

            setupConfiguredWidget(views, context, appWidgetId, colorConfig)
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    /**
     * 设置未配置状态的小组件
     */
    private fun setupUnconfiguredWidget(views: RemoteViews, context: Context, appWidgetId: Int) {
        // 设置默认标题
        views.setTextViewText(R.id.widget_title, "快捷记账")

        // 隐藏快捷列表，显示配置提示
        views.setViewVisibility(R.id.widget_hint_text, View.VISIBLE)
        views.setViewVisibility(R.id.shortcuts_list_view, View.GONE)
        views.setViewVisibility(R.id.widget_empty_text, View.GONE)

        // 设置点击事件：打开配置页面
        val intent = Intent(Intent.ACTION_VIEW)
        intent.data = Uri.parse("memento://widget/bill_shortcuts/config?widgetId=$appWidgetId")
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
        colorConfig: Map<String, Int>
    ) {
        val backgroundColor = colorConfig["backgroundColor"] ?: DEFAULT_BACKGROUND_COLOR
        val textColor = colorConfig["textColor"] ?: DEFAULT_TEXT_COLOR
        val iconColor = colorConfig["iconColor"] ?: DEFAULT_ICON_COLOR

        // 设置标题颜色
        views.setTextViewText(R.id.widget_title, "快捷记账")
        views.setTextColor(R.id.widget_title, iconColor)

        // 设置添加按钮颜色
        views.setInt(R.id.widget_add_button, "setColorFilter", iconColor)

        // 设置背景色 (使用 setBackgroundColor 替代 setBackgroundTintList)
        views.setInt(
            R.id.widget_container,
            "setBackgroundColor",
            backgroundColor
        )

        // 隐藏配置提示
        views.setViewVisibility(R.id.widget_hint_text, View.GONE)

        // 获取快捷数量
        val shortcutCount = getShortcutCount(context, appWidgetId)

        if (shortcutCount > 0) {
            views.setViewVisibility(R.id.shortcuts_list_view, View.VISIBLE)
            views.setViewVisibility(R.id.widget_empty_text, View.GONE)
        } else {
            views.setViewVisibility(R.id.shortcuts_list_view, View.GONE)
            views.setViewVisibility(R.id.widget_empty_text, View.VISIBLE)
        }

        // 设置 ListView 的 RemoteViewsService
        val serviceIntent = Intent(context, BillShortcutsWidgetService::class.java).apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
        }
        views.setRemoteAdapter(R.id.shortcuts_list_view, serviceIntent)
        views.setEmptyView(R.id.shortcuts_list_view, R.id.widget_empty_text)

        // 设置 ListView 项目点击的 PendingIntent 模板（广播）
        val clickIntent = Intent(context, BillShortcutsWidgetProvider::class.java).apply {
            action = ACTION_SHORTCUT_CLICK
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        }
        val clickPendingIntent = PendingIntent.getBroadcast(
            context,
            appWidgetId,
            clickIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        )
        views.setPendingIntentTemplate(R.id.shortcuts_list_view, clickPendingIntent)

        // 设置标题栏点击 - 跳转到账单插件主界面
        setupHeaderClickIntent(context, views)

        // 设置添加按钮点击 - 打开配置页面
        setupAddButtonClickIntent(context, views, appWidgetId)
    }

    /**
     * 获取快捷数量
     */
    private fun getShortcutCount(context: Context, appWidgetId: Int): Int {
        return try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val configKey = "$CONFIG_KEY_PREFIX$appWidgetId"
            val jsonString = prefs.getString(configKey, null) ?: return 0
            val json = JSONObject(jsonString)
            val shortcuts = json.optJSONArray("shortcuts") ?: return 0
            shortcuts.length()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get shortcut count", e)
            0
        }
    }

    /**
     * 检查是否已配置
     */
    private fun hasWidgetConfig(context: Context, appWidgetId: Int): Boolean {
        return try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val configKey = "$CONFIG_KEY_PREFIX$appWidgetId"
            val jsonString = prefs.getString(configKey, null)
            !jsonString.isNullOrEmpty()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to check config", e)
            false
        }
    }

    /**
     * 加载颜色配置
     * 注意：颜色值存储为 String 类型，需要转换为 Int
     */
    private fun loadColorConfig(context: Context, appWidgetId: Int): Map<String, Int> {
        return try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val colorKey = "$COLOR_KEY_PREFIX$appWidgetId"
            val colorJson = prefs.getString(colorKey, null)

            if (!colorJson.isNullOrEmpty()) {
                val json = JSONObject(colorJson)

                // 按照 CUSTOM_WIDGET_GUIDE.md 的要求，颜色值存储为 String
                val backgroundColor = json.optString("backgroundColor", null)?.toLongOrNull()?.toInt()
                    ?: DEFAULT_BACKGROUND_COLOR
                val textColor = json.optString("textColor", null)?.toLongOrNull()?.toInt()
                    ?: DEFAULT_TEXT_COLOR
                val iconColor = json.optString("iconColor", null)?.toLongOrNull()?.toInt()
                    ?: DEFAULT_ICON_COLOR

                Log.d(TAG, "Color config loaded: bg=$backgroundColor, text=$textColor, icon=$iconColor")

                mapOf(
                    "backgroundColor" to backgroundColor,
                    "textColor" to textColor,
                    "iconColor" to iconColor
                )
            } else {
                Log.d(TAG, "No color config found, using defaults")
                mapOf(
                    "backgroundColor" to DEFAULT_BACKGROUND_COLOR,
                    "textColor" to DEFAULT_TEXT_COLOR,
                    "iconColor" to DEFAULT_ICON_COLOR
                )
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to load color config", e)
            mapOf(
                "backgroundColor" to DEFAULT_BACKGROUND_COLOR,
                "textColor" to DEFAULT_TEXT_COLOR,
                "iconColor" to DEFAULT_ICON_COLOR
            )
        }
    }

    /**
     * 设置标题栏点击事件 - 跳转到账单插件主界面
     */
    private fun setupHeaderClickIntent(context: Context, views: RemoteViews) {
        val intent = Intent(Intent.ACTION_VIEW)
        intent.data = Uri.parse("memento://widget/bill")
        intent.setPackage("github.hunmer.memento")
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP

        val pendingIntent = PendingIntent.getActivity(
            context,
            "bill_header".hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        views.setOnClickPendingIntent(R.id.widget_header, pendingIntent)
    }

    /**
     * 设置添加按钮点击事件 - 打开配置页面
     */
    private fun setupAddButtonClickIntent(context: Context, views: RemoteViews, appWidgetId: Int) {
        val intent = Intent(Intent.ACTION_VIEW)
        intent.data = Uri.parse("memento://widget/bill_shortcuts/config?widgetId=$appWidgetId")
        intent.setPackage("github.hunmer.memento")
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP

        val pendingIntent = PendingIntent.getActivity(
            context,
            appWidgetId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        views.setOnClickPendingIntent(R.id.widget_add_button, pendingIntent)
    }

    /**
     * 删除配置
     */
    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        super.onDeleted(context, appWidgetIds)
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val editor = prefs.edit()
        for (appWidgetId in appWidgetIds) {
            editor.remove("$CONFIG_KEY_PREFIX$appWidgetId")
            editor.remove("$COLOR_KEY_PREFIX$appWidgetId")
            Log.d(TAG, "Deleted config for widgetId=$appWidgetId")
        }
        editor.apply()
    }
}
