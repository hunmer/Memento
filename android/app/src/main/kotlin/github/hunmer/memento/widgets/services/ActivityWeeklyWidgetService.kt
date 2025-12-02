package github.hunmer.memento.widgets.services

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.widget.RemoteViewsService

/**
 * 活动周视图小组件RemoteViewsService
 *
 * 为ListView提供数据
 */
class ActivityWeeklyWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return ActivityWeeklyRemoteViewsFactory(
            applicationContext,
            intent
        )
    }
}
