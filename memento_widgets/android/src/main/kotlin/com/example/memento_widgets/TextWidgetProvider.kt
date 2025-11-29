package com.example.memento_widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * 文本小组件提供器
 * 负责管理文本小组件的更新和显示
 */
class TextWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            // 使用 home_widget 插件从 SharedPreferences 读取数据
            val widgetData = HomeWidgetPlugin.getData(context)

            val views = RemoteViews(context.packageName, R.layout.text_widget_layout).apply {
                val text = widgetData.getString("text_key", "默认文本") ?: "默认文本"
                setTextViewText(R.id.widget_text, text)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        super.onUpdate(context, appWidgetManager, appWidgetIds)
    }
}
