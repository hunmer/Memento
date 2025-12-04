package github.hunmer.memento.widgets.services

import android.content.Intent
import android.widget.RemoteViewsService

/**
 * 本日活动详细视图小组件RemoteViewsService
 *
 * 为ListView提供数据
 */
class ActivityDailyWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return ActivityDailyRemoteViewsFactory(
            applicationContext,
            intent
        )
    }
}
