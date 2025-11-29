package com.example.memento_widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.BitmapFactory
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import java.io.File

/**
 * 图像小组件提供器
 * 负责管理图像小组件的更新和显示
 */
class ImageWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            // 使用 home_widget 插件从 SharedPreferences 读取数据
            val widgetData = HomeWidgetPlugin.getData(context)

            val views = RemoteViews(context.packageName, R.layout.image_widget_layout).apply {
                val imageKey = widgetData.getString("image_key", "") ?: ""

                if (!imageKey.isNullOrEmpty()) {
                    // 尝试从文件加载图片
                    try {
                        val imageFile = File(imageKey)
                        if (imageFile.exists()) {
                            val bitmap = BitmapFactory.decodeFile(imageKey)
                            setImageViewBitmap(R.id.widget_image, bitmap)
                        } else {
                            // 尝试解析为 URI
                            val uri = Uri.parse(imageKey)
                            setImageViewUri(R.id.widget_image, uri)
                        }
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        super.onUpdate(context, appWidgetManager, appWidgetIds)
    }
}
