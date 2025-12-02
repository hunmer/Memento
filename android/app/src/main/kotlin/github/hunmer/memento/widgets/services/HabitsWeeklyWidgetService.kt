package github.hunmer.memento.widgets.services

import android.content.Intent
import android.widget.RemoteViewsService

/**
 * 习惯周视图小组件RemoteViewsService
 *
 * 为ListView提供习惯列表数据
 */
class HabitsWeeklyWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return HabitsWeeklyRemoteViewsFactory(
            applicationContext,
            intent
        )
    }
}
