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
import com.example.memento_widgets.R
import github.hunmer.memento.widgets.BasePluginWidgetProvider
import org.json.JSONObject

class CheckinItemWidgetProvider : BasePluginWidgetProvider() {
    override val pluginId: String = "checkin_item"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_2X2

    companion object {
        private const val PREF_KEY_PREFIX = "checkin_item_id_"
        private const val PREF_KEY_PRIMARY_COLOR = "checkin_widget_primary_color_"
        private const val PREF_KEY_ACCENT_COLOR = "checkin_widget_accent_color_"
        private const val PREF_KEY_OPACITY = "checkin_widget_opacity_"

        // 默认颜色
        private const val DEFAULT_PRIMARY_COLOR = 0xFF5A9E9A.toInt()  // 绿色背景
        private const val DEFAULT_ACCENT_COLOR = 0xFFFFFFFF.toInt()   // 白色标题
        private const val DEFAULT_OPACITY = 0.95f
    }

    override fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_checkin_item)

        // 读取颜色和透明度配置
        val primaryColor = getConfiguredPrimaryColor(context, appWidgetId)
        val accentColor = getConfiguredAccentColor(context, appWidgetId)
        val opacity = getConfiguredOpacity(context, appWidgetId)

        // 应用背景颜色（带透明度）- 使用 backgroundTintList 保持圆角效果
        val bgColor = adjustColorAlpha(primaryColor, opacity)
        views.setColorStateList(R.id.widget_container, "setBackgroundTintList", ColorStateList.valueOf(bgColor))

        // 应用标题色（强调色）
        views.setTextColor(R.id.widget_title, accentColor)

        Log.d("CheckinItemWidget", "应用颜色: bg=${Integer.toHexString(primaryColor)}, accent=${Integer.toHexString(accentColor)}, opacity=$opacity")

        // 检查是否已配置打卡项目
        val checkinItemId = getConfiguredCheckinItemId(context, appWidgetId)
        Log.d("CheckinItemWidget", "updateAppWidget: appWidgetId=$appWidgetId, checkinItemId=$checkinItemId")

        if (checkinItemId == null) {
            // 未配置，显示选择提示
            Log.d("CheckinItemWidget", "小组件未配置，显示选择提示")
            setupUnconfiguredWidget(views, context, appWidgetId)
        } else {
            // 已配置，显示打卡数据
            Log.d("CheckinItemWidget", "小组件已配置，itemId=$checkinItemId")
            val data = loadWidgetData(context)
            if (data != null) {
                val applied = setupCustomWidget(views, data, checkinItemId)
                if (!applied) {
                    setupDefaultWidget(views)
                }
            } else {
                Log.w("CheckinItemWidget", "无法加载小组件数据")
                setupDefaultWidget(views)
            }
            // 设置点击事件，传递 itemId 参数以便打开对应的打卡记录对话框
            setupClickIntentWithItemId(context, views, checkinItemId)
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    /**
     * 设置未配置状态的小组件
     */
    private fun setupUnconfiguredWidget(views: RemoteViews, context: Context, appWidgetId: Int) {
        views.setTextViewText(R.id.widget_title, "打卡")

        // 显示提示文本，隐藏数据显示
        views.setViewVisibility(R.id.widget_hint_text, View.VISIBLE)
        views.setViewVisibility(R.id.widget_checkin_count, View.GONE)
        views.setViewVisibility(R.id.week_days, View.GONE)
        views.setViewVisibility(R.id.week_checks, View.GONE)

        // 设置点击事件：打开配置页面
        val intent = Intent(Intent.ACTION_VIEW)
        intent.data = Uri.parse("memento://widget/checkin_item/config?widgetId=$appWidgetId")
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
     * 获取配置的打卡项目ID
     */
    private fun getConfiguredCheckinItemId(context: Context, appWidgetId: Int): String? {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getString("$PREF_KEY_PREFIX$appWidgetId", null)
    }

    /**
     * 保存配置的打卡项目ID
     */
    fun saveConfiguredCheckinItemId(context: Context, appWidgetId: Int, checkinItemId: String) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putString("$PREF_KEY_PREFIX$appWidgetId", checkinItemId).apply()
    }

    /**
     * 获取配置的背景色（主色调）
     * 注意：Flutter HomeWidget 使用 String 存储，需要转换
     */
    private fun getConfiguredPrimaryColor(context: Context, appWidgetId: Int): Int {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val colorStr = prefs.getString("$PREF_KEY_PRIMARY_COLOR$appWidgetId", null)
        return colorStr?.toLongOrNull()?.toInt() ?: DEFAULT_PRIMARY_COLOR
    }

    /**
     * 获取配置的标题色（强调色）
     * 注意：Flutter HomeWidget 使用 String 存储，需要转换
     */
    private fun getConfiguredAccentColor(context: Context, appWidgetId: Int): Int {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val colorStr = prefs.getString("$PREF_KEY_ACCENT_COLOR$appWidgetId", null)
        return colorStr?.toLongOrNull()?.toInt() ?: DEFAULT_ACCENT_COLOR
    }

    /**
     * 获取配置的透明度
     * 注意：Flutter HomeWidget 使用 String 存储，需要转换
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
     * 删除配置
     */
    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        super.onDeleted(context, appWidgetIds)
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val editor = prefs.edit()
        for (appWidgetId in appWidgetIds) {
            editor.remove("$PREF_KEY_PREFIX$appWidgetId")
            editor.remove("$PREF_KEY_PRIMARY_COLOR$appWidgetId")
            editor.remove("$PREF_KEY_ACCENT_COLOR$appWidgetId")
            editor.remove("$PREF_KEY_OPACITY$appWidgetId")
        }
        editor.apply()
    }

    private fun setupDefaultWidget(views: RemoteViews) {
        views.setTextViewText(R.id.widget_checkin_count, "0")
        val checkIds = listOf(R.id.week_checks_1, R.id.week_checks_2, R.id.week_checks_3, R.id.week_checks_4, R.id.week_checks_5, R.id.week_checks_6, R.id.week_checks_7)
        for (id in checkIds) {
            views.setViewVisibility(id, View.INVISIBLE)
        }
    }


    private fun setupCustomWidget(views: RemoteViews, data: JSONObject, checkinItemId: String): Boolean {
        return try {
            // 从数据中读取特定打卡项目的信息
            val items = data.optJSONArray("items")
            var targetItem: JSONObject? = null

            // 查找对应ID的打卡项目
            if (items != null) {
                for (i in 0 until items.length()) {
                    val item = items.getJSONObject(i)
                    if (item.optString("id") == checkinItemId) {
                        targetItem = item
                        break
                    }
                }
            }

            if (targetItem == null) {
                // 未找到对应项目，显示默认状态
                return false
            }

            // 设置标题为打卡项目名称
            val itemName = targetItem.optString("name", "打卡")
            views.setTextViewText(R.id.widget_title, itemName)

            // 隐藏提示文本，显示数据
            views.setViewVisibility(R.id.widget_hint_text, View.GONE)
            views.setViewVisibility(R.id.widget_checkin_count, View.VISIBLE)

            // 获取七日打卡记录
            val weekChecks = targetItem.optString("weekChecks", "")
            val checks = weekChecks
                .split(",")
                .map { it.trim() == "1" }
                .takeIf { it.isNotEmpty() }
                ?: List(7) { false }

            // 计算本周打卡次数
            val checkinCount = checks.count { it }
            views.setTextViewText(R.id.widget_checkin_count, checkinCount.toString())

            // 显示七日打卡状态
            views.setViewVisibility(R.id.week_days, View.VISIBLE)
            views.setViewVisibility(R.id.week_checks, View.VISIBLE)

            val checkIds = listOf(
                R.id.week_checks_1, R.id.week_checks_2, R.id.week_checks_3,
                R.id.week_checks_4, R.id.week_checks_5, R.id.week_checks_6, R.id.week_checks_7
            )

            for (i in 0 until 7) {
                val isChecked = i < checks.size && checks[i]
                views.setViewVisibility(checkIds[i], if (isChecked) View.VISIBLE else View.INVISIBLE)
            }
            true
        } catch (e: Exception) {
            Log.e("CheckinItemWidget", "Failed to bind widget data", e)
            false
        }
    }

    /**
     * 设置已配置状态的点击事件（带 itemId 参数）
     */
    private fun setupClickIntentWithItemId(context: Context, views: RemoteViews, itemId: String) {
        val uriString = "memento://widget/checkin_item?itemId=$itemId"
        Log.d("CheckinItemWidget", "setupClickIntentWithItemId: itemId=$itemId, uri=$uriString")

        val intent = Intent(Intent.ACTION_VIEW)
        intent.data = Uri.parse(uriString)
        intent.setPackage("github.hunmer.memento")
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP

        val pendingIntent = PendingIntent.getActivity(
            context,
            itemId.hashCode(),  // 使用 itemId 的 hashCode 确保唯一性
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)
        Log.d("CheckinItemWidget", "点击事件已设置")
    }
}
