package github.hunmer.memento.widgets.providers

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.util.Log
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import com.example.memento_widgets.R
import github.hunmer.memento.widgets.BasePluginWidgetProvider
import org.json.JSONObject

/**
 * 快捷记账小组件的 RemoteViewsFactory
 * 负责创建和管理快捷预设列表项
 */
class BillShortcutsRemoteViewsFactory(
    private val context: Context,
    private val intent: Intent
) : RemoteViewsService.RemoteViewsFactory {

    companion object {
        private const val TAG = "BillShortcutsFactory"
    }

    private var shortcuts: List<ShortcutItem> = emptyList()
    private val appWidgetId: Int = intent.getIntExtra(
        AppWidgetManager.EXTRA_APPWIDGET_ID,
        AppWidgetManager.INVALID_APPWIDGET_ID
    )

    // 颜色配置(默认值)
    private var textColor: Int = 0xFF1F2937.toInt()
    private var iconColor: Int = 0xFF10B981.toInt()

    /**
     * 快捷预设数据项
     */
    data class ShortcutItem(
        val id: String,
        val name: String,
        val accountId: String,
        val category: String,
        val amount: Double?,
        val isExpense: Boolean,
        val iconCodePoint: Int,
        val iconColor: Int
    )

    override fun onCreate() {
        Log.d(TAG, "onCreate: appWidgetId=$appWidgetId")
    }

    override fun onDataSetChanged() {
        Log.d(TAG, "onDataSetChanged: Loading shortcuts for widgetId=$appWidgetId")
        loadColorConfig()
        shortcuts = loadShortcuts()
        Log.d(TAG, "Loaded ${shortcuts.size} shortcuts")
    }

    override fun onDestroy() {
        shortcuts = emptyList()
    }

    override fun getCount(): Int = shortcuts.size

    override fun getViewAt(position: Int): RemoteViews {
        if (position < 0 || position >= shortcuts.size) {
            return RemoteViews(context.packageName, R.layout.widget_bill_shortcuts_item)
        }

        val shortcut = shortcuts[position]
        val views = RemoteViews(context.packageName, R.layout.widget_bill_shortcuts_item)

        // 设置复选框(默认未选中,实际功能可由用户自定义)
        views.setImageViewResource(R.id.shortcut_checkbox, R.drawable.ic_checkbox_unchecked)

        // 设置图标
        // 注意: RemoteViews 不支持动态设置 IconData,这里使用默认图标
        // 实际实现中可以根据 iconCodePoint 映射到对应的 drawable 资源
        views.setImageViewResource(R.id.shortcut_icon, getIconResource(shortcut.iconCodePoint))
        views.setInt(R.id.shortcut_icon, "setColorFilter", shortcut.iconColor)

        // 设置预设名称
        views.setTextViewText(R.id.shortcut_name, shortcut.name)
        views.setTextColor(R.id.shortcut_name, textColor)

        // 设置预设详情(分类)
        views.setTextViewText(R.id.shortcut_detail, shortcut.category)
        views.setTextColor(R.id.shortcut_detail, 0xFF6B7280.toInt())

        // 设置金额
        if (shortcut.amount != null) {
            val amountText = if (shortcut.isExpense) {
                "-¥${String.format("%.2f", shortcut.amount)}"
            } else {
                "+¥${String.format("%.2f", shortcut.amount)}"
            }
            views.setTextViewText(R.id.shortcut_amount, amountText)

            // 支出显示红色,收入显示绿色
            val amountColor = if (shortcut.isExpense) 0xFFEF4444.toInt() else 0xFF10B981.toInt()
            views.setTextColor(R.id.shortcut_amount, amountColor)
        } else {
            views.setTextViewText(R.id.shortcut_amount, "")
        }

        // 设置点击事件 - 打开记账界面并预填充数据
        val fillIntent = Intent().apply {
            putExtra("action", "add_bill")
            putExtra("shortcut_id", shortcut.id)
            putExtra("account_id", shortcut.accountId)
            putExtra("category", shortcut.category)
            if (shortcut.amount != null) {
                putExtra("amount", shortcut.amount)
            }
            putExtra("is_expense", shortcut.isExpense)
        }
        views.setOnClickFillInIntent(R.id.shortcut_item_container, fillIntent)

        return views
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = true

    /**
     * 从 SharedPreferences 加载快捷预设数据
     */
    private fun loadShortcuts(): List<ShortcutItem> {
        return try {
            val prefs = context.getSharedPreferences(
                BasePluginWidgetProvider.PREFS_NAME,
                Context.MODE_PRIVATE
            )
            val configKey = "bill_shortcuts_widget_$appWidgetId"
            val jsonString = prefs.getString(configKey, null)

            if (jsonString.isNullOrEmpty()) {
                Log.w(TAG, "No shortcut config found for widgetId=$appWidgetId")
                return emptyList()
            }

            val json = JSONObject(jsonString)
            val shortcutsArray = json.optJSONArray("shortcuts") ?: return emptyList()

            val result = mutableListOf<ShortcutItem>()

            for (i in 0 until shortcutsArray.length()) {
                val shortcutJson = shortcutsArray.getJSONObject(i)
                val shortcut = ShortcutItem(
                    id = shortcutJson.optString("id", ""),
                    name = shortcutJson.optString("name", ""),
                    accountId = shortcutJson.optString("accountId", ""),
                    category = shortcutJson.optString("category", ""),
                    amount = if (shortcutJson.has("amount") && !shortcutJson.isNull("amount")) {
                        shortcutJson.optDouble("amount")
                    } else {
                        null
                    },
                    isExpense = shortcutJson.optBoolean("isExpense", true),
                    iconCodePoint = shortcutJson.optInt("iconCodePoint", 0xe530), // 默认图标
                    iconColor = shortcutJson.optInt("iconColor", 0xFF10B981.toInt())
                )
                result.add(shortcut)
            }

            result
        } catch (e: Exception) {
            Log.e(TAG, "Failed to load shortcuts", e)
            emptyList()
        }
    }

    /**
     * 加载颜色配置
     * 注意: 颜色值存储为 String 类型,需要转换为 Int
     */
    private fun loadColorConfig() {
        try {
            val prefs = context.getSharedPreferences(
                BasePluginWidgetProvider.PREFS_NAME,
                Context.MODE_PRIVATE
            )
            val colorKey = "bill_shortcuts_widget_color_$appWidgetId"
            val colorJson = prefs.getString(colorKey, null)

            if (!colorJson.isNullOrEmpty()) {
                val json = JSONObject(colorJson)

                // 按照 CUSTOM_WIDGET_GUIDE.md 的要求,颜色值存储为 String
                textColor = json.optString("textColor", null)?.toLongOrNull()?.toInt()
                    ?: 0xFF1F2937.toInt()
                iconColor = json.optString("iconColor", null)?.toLongOrNull()?.toInt()
                    ?: 0xFF10B981.toInt()

                Log.d(TAG, "Color config loaded: textColor=$textColor, iconColor=$iconColor")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to load color config", e)
        }
    }

    /**
     * 根据 iconCodePoint 获取对应的 drawable 资源
     *
     * 注意: RemoteViews 不支持动态设置 IconData,这里映射 Material Icons 到对应的 drawable
     * 目前使用系统默认图标,未来可以根据需要添加更多自定义图标
     */
    private fun getIconResource(codePoint: Int): Int {
        // 使用 Android 系统内置的图标资源
        // 未来可以根据 codePoint 映射到自定义的 drawable 资源
        return android.R.drawable.ic_menu_info_details
    }
}
