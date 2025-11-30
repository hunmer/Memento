package github.hunmer.memento.widgets.providers

import android.appwidget.AppWidgetManager
import android.content.Context
import android.view.View
import android.widget.RemoteViews
import com.example.memento_widgets.R
import github.hunmer.memento.widgets.BasePluginWidgetProvider
import org.json.JSONObject

class CheckinItemWidgetProvider : BasePluginWidgetProvider() {
    override val pluginId: String = "checkin_item"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_2X2

    override fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_checkin_item)
        val data = loadWidgetData(context)

        if (data != null) {
            setupCustomWidget(views, data)
        } else {
            // Handle no data case if necessary, maybe show default UI
        }
        
        setupClickIntent(context, views)
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun setupCustomWidget(views: RemoteViews, data: JSONObject) {
        val stats = data.optJSONArray("stats")
        val checkinCount = if (stats != null && stats.length() > 0) {
            stats.getJSONObject(0).optString("value", "0")
        } else {
            "0"
        }
        views.setTextViewText(R.id.widget_checkin_count, checkinCount)

        // For the weekly checkmarks, let's assume the second stat is a string like "1,1,1,1,1,0,0"
        val weekState = if (stats != null && stats.length() > 1) {
            stats.getJSONObject(1).optString("value", "")
        } else {
            ""
        }
        
        val checks = weekState.split(",").map { it == "1" }
        val checkIds = listOf(R.id.week_checks_1, R.id.week_checks_2, R.id.week_checks_3, R.id.week_checks_4, R.id.week_checks_5, R.id.week_checks_6, R.id.week_checks_7)

        for (i in 0 until 7) {
            if (i < checks.size && checks[i]) {
                views.setViewVisibility(checkIds[i], View.VISIBLE)
            } else {
                views.setViewVisibility(checkIds[i], View.INVISIBLE)
            }
        }
    }
}
