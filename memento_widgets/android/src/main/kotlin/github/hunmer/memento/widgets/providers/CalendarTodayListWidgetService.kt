package github.hunmer.memento.widgets.providers

import android.content.Context
import android.content.Intent
import android.widget.RemoteViewsService

/**
 * 今日事件列表小组件的 RemoteViewsService
 * 提供可滚动的事件列表
 */
class CalendarTodayListWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return CalendarTodayListRemoteViewsFactory(applicationContext, intent)
    }
}
