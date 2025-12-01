package github.hunmer.memento.widgets.providers

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import com.example.memento_widgets.R
import github.hunmer.memento.widgets.BasePluginWidgetProvider
import org.json.JSONObject
import java.util.*

class CheckinMonthWidgetProvider : BasePluginWidgetProvider() {
    override val pluginId: String = "checkin_month"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_4X2

    companion object {
        // 复用签到项的配置键前缀
        private const val PREF_KEY_PREFIX = "checkin_item_id_"
        private const val TAG = "CheckinMonthWidget"
    }

    /**
     * 覆盖 loadWidgetData 方法，读取 checkin_item 的数据
     * 因为打卡月份视图和打卡项使用相同的数据源
     */
    override fun loadWidgetData(context: Context): JSONObject? {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        // 读取 checkin_item_widget_data 而不是 checkin_month_widget_data
        val jsonString = prefs.getString("checkin_item_widget_data", null)
        if (jsonString == null) {
            Log.w(TAG, "未找到 checkin_item_widget_data 数据")
            return null
        }

        return try {
            val data = JSONObject(jsonString)
            Log.d(TAG, "成功加载数据: $jsonString")
            data
        } catch (e: Exception) {
            Log.e(TAG, "解析数据失败", e)
            null
        }
    }

    override fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_checkin_month)

        // 检查是否已配置打卡项目
        val checkinItemId = getConfiguredCheckinItemId(context, appWidgetId)
        Log.d(TAG, "updateAppWidget: appWidgetId=$appWidgetId, checkinItemId=$checkinItemId")

        if (checkinItemId == null) {
            // 未配置，显示选择提示
            Log.d(TAG, "小组件未配置，显示选择提示")
            setupUnconfiguredWidget(views, context, appWidgetId)
        } else {
            // 已配置，显示月历数据
            Log.d(TAG, "小组件已配置，itemId=$checkinItemId")
            val data = loadWidgetData(context)
            if (data != null) {
                val applied = setupMonthCalendar(context, views, data, checkinItemId)
                if (!applied) {
                    // 显示默认状态
                    views.setTextViewText(R.id.month_widget_title, "打卡月历")
                    views.setTextViewText(R.id.month_widget_month, "")
                    views.setViewVisibility(R.id.month_widget_hint, View.VISIBLE)
                    views.setViewVisibility(R.id.month_calendar_container, View.GONE)
                }
            } else {
                Log.w(TAG, "无法加载小组件数据")
                // 显示默认状态
                views.setTextViewText(R.id.month_widget_title, "打卡月历")
                views.setTextViewText(R.id.month_widget_month, "")
                views.setViewVisibility(R.id.month_widget_hint, View.VISIBLE)
                views.setViewVisibility(R.id.month_calendar_container, View.GONE)
            }
            // 设置点击事件，传递 itemId 参数
            setupClickIntentWithItemId(context, views, checkinItemId)
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    /**
     * 设置未配置状态的小组件
     */
    private fun setupUnconfiguredWidget(views: RemoteViews, context: Context, appWidgetId: Int) {
        views.setTextViewText(R.id.month_widget_title, "打卡月历")
        views.setTextViewText(R.id.month_widget_month, "")

        // 显示提示文本
        views.setViewVisibility(R.id.month_widget_hint, View.VISIBLE)
        views.setViewVisibility(R.id.month_calendar_container, View.GONE)

        // 设置点击事件：打开配置页面（复用签到项的配置界面）
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

        views.setOnClickPendingIntent(R.id.month_widget_container, pendingIntent)
    }

    /**
     * 设置月历视图
     */
    private fun setupMonthCalendar(context: Context, views: RemoteViews, data: JSONObject, itemId: String): Boolean {
        return try {
            // 从 data 中查找对应 ID 的项目
            val items = data.optJSONArray("items")
            var targetItem: JSONObject? = null

            if (items != null) {
                for (i in 0 until items.length()) {
                    val item = items.getJSONObject(i)
                    if (item.optString("id") == itemId) {
                        targetItem = item
                        break
                    }
                }
            }

            if (targetItem == null) {
                Log.w(TAG, "未找到ID为 $itemId 的签到项目")
                return false
            }

            // 设置标题和月份
            val itemName = targetItem.optString("name", "打卡")
            val currentMonth = "${Calendar.getInstance().get(Calendar.MONTH) + 1}月"

            views.setTextViewText(R.id.month_widget_title, itemName)
            views.setTextViewText(R.id.month_widget_month, currentMonth)

            // 显示日历，隐藏提示
            views.setViewVisibility(R.id.month_widget_hint, View.GONE)
            views.setViewVisibility(R.id.month_calendar_container, View.VISIBLE)

            // 获取本月打卡数据
            val monthChecks = targetItem.optString("monthChecks", "")
            val checkedDates = if (monthChecks.isNotEmpty()) {
                monthChecks.split(",").mapNotNull { it.toIntOrNull() }.toSet()
            } else {
                emptySet()
            }

            // 获取今天的完整日期信息
            val nowCalendar = Calendar.getInstance()
            val today = nowCalendar.get(Calendar.DAY_OF_MONTH)
            val currentYear = nowCalendar.get(Calendar.YEAR)
            val monthIndex = nowCalendar.get(Calendar.MONTH)  // 0-11

            // 计算本月第一天是星期几 (1=周一, 7=周日)
            val calendar = Calendar.getInstance()
            calendar.set(Calendar.DAY_OF_MONTH, 1)
            val firstDayOfWeek = when (calendar.get(Calendar.DAY_OF_WEEK)) {
                Calendar.MONDAY -> 1
                Calendar.TUESDAY -> 2
                Calendar.WEDNESDAY -> 3
                Calendar.THURSDAY -> 4
                Calendar.FRIDAY -> 5
                Calendar.SATURDAY -> 6
                Calendar.SUNDAY -> 7
                else -> 1
            }

            // 获取本月总天数
            val daysInMonth = calendar.getActualMaximum(Calendar.DAY_OF_MONTH)

            // 日期视图ID列表（7列 x 6行 = 42个格子）
            val dayViewIds = listOf(
                R.id.day_1, R.id.day_2, R.id.day_3, R.id.day_4, R.id.day_5, R.id.day_6, R.id.day_7,
                R.id.day_8, R.id.day_9, R.id.day_10, R.id.day_11, R.id.day_12, R.id.day_13, R.id.day_14,
                R.id.day_15, R.id.day_16, R.id.day_17, R.id.day_18, R.id.day_19, R.id.day_20, R.id.day_21,
                R.id.day_22, R.id.day_23, R.id.day_24, R.id.day_25, R.id.day_26, R.id.day_27, R.id.day_28,
                R.id.day_29, R.id.day_30, R.id.day_31, R.id.day_32, R.id.day_33, R.id.day_34, R.id.day_35,
                R.id.day_36, R.id.day_37, R.id.day_38, R.id.day_39, R.id.day_40, R.id.day_41, R.id.day_42
            )

            // 填充日期
            for (i in dayViewIds.indices) {
                val dayPosition = i + 1 - (firstDayOfWeek - 1)

                if (dayPosition in 1..daysInMonth) {
                    // 显示日期
                    views.setViewVisibility(dayViewIds[i], View.VISIBLE)
                    views.setTextViewText(dayViewIds[i], dayPosition.toString())

                    // 检查是否是未来日期
                    val isFuture = dayPosition > today

                    // 根据打卡状态设置背景
                    val isChecked = checkedDates.contains(dayPosition)
                    val isToday = dayPosition == today

                    when {
                        isFuture -> {
                            // 未来日期：禁用状态（透明背景，灰色文字）
                            views.setInt(dayViewIds[i], "setBackgroundResource", 0)
                            views.setTextColor(dayViewIds[i], 0xFFd1d5db.toInt()) // 浅灰色
                        }
                        isChecked && isToday -> {
                            // 今天已打卡：实心紫色圆圈
                            views.setInt(dayViewIds[i], "setBackgroundResource", R.drawable.day_checked_bg)
                            views.setTextColor(dayViewIds[i], 0xFFFFFFFF.toInt())
                        }
                        isChecked -> {
                            // 已打卡（非今天）：实心紫色圆圈
                            views.setInt(dayViewIds[i], "setBackgroundResource", R.drawable.day_checked_bg)
                            views.setTextColor(dayViewIds[i], 0xFFFFFFFF.toInt())
                        }
                        isToday -> {
                            // 今天未打卡：空心紫色圆圈
                            views.setInt(dayViewIds[i], "setBackgroundResource", R.drawable.day_today_bg)
                            views.setTextColor(dayViewIds[i], 0xFF8a4bde.toInt())
                        }
                        else -> {
                            // 过去日期未打卡：透明背景，正常文字
                            views.setInt(dayViewIds[i], "setBackgroundResource", 0)
                            views.setTextColor(dayViewIds[i], 0xFF1f2937.toInt())
                        }
                    }

                    // 为每个日期设置独立的点击事件
                    if (!isFuture) {
                        setupDayClickIntent(context, views, dayViewIds[i], itemId, currentYear, monthIndex, dayPosition)
                    }
                } else {
                    // 隐藏非本月日期
                    views.setViewVisibility(dayViewIds[i], View.GONE)
                }
            }

            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to setup month calendar", e)
            false
        }
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
     * 设置已配置状态的点击事件（带 itemId 参数）
     * 仅为标题栏设置点击事件，打开打卡项详情
     */
    private fun setupClickIntentWithItemId(context: Context, views: RemoteViews, itemId: String) {
        val uriString = "memento://widget/checkin_item?itemId=$itemId"
        Log.d(TAG, "setupClickIntentWithItemId: itemId=$itemId, uri=$uriString")

        val intent = Intent(Intent.ACTION_VIEW)
        intent.data = Uri.parse(uriString)
        intent.setPackage("github.hunmer.memento")
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP

        val pendingIntent = PendingIntent.getActivity(
            context,
            itemId.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // 只为标题设置点击事件，不影响日期的点击
        views.setOnClickPendingIntent(R.id.month_widget_title, pendingIntent)
        views.setOnClickPendingIntent(R.id.month_widget_month, pendingIntent)
    }

    /**
     * 为单个日期设置点击事件
     */
    private fun setupDayClickIntent(
        context: Context,
        views: RemoteViews,
        dayViewId: Int,
        itemId: String,
        year: Int,
        month: Int,
        day: Int
    ) {
        // 格式化日期为 YYYY-MM-DD
        val dateString = String.format("%04d-%02d-%02d", year, month + 1, day)
        val uriString = "memento://widget/checkin_item?itemId=$itemId&date=$dateString"

        val intent = Intent(Intent.ACTION_VIEW)
        intent.data = Uri.parse(uriString)
        intent.setPackage("github.hunmer.memento")
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP

        // 使用唯一的 requestCode (itemId.hashCode + day) 确保每个日期都有独立的 PendingIntent
        val requestCode = itemId.hashCode() + day
        val pendingIntent = PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        views.setOnClickPendingIntent(dayViewId, pendingIntent)
        Log.d(TAG, "setupDayClickIntent: day=$day, date=$dateString, uri=$uriString")
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        super.onDeleted(context, appWidgetIds)
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val editor = prefs.edit()
        for (appWidgetId in appWidgetIds) {
            editor.remove("$PREF_KEY_PREFIX$appWidgetId")
        }
        editor.apply()
    }
}
