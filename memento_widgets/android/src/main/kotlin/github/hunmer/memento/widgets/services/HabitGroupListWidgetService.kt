package github.hunmer.memento.widgets.services

import android.content.Context
import android.content.Intent
import android.widget.RemoteViewsService

/**
 * 习惯分组列表小组件的 RemoteViewsService
 * 负责创建 RemoteViewsFactory
 */
class HabitGroupListWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return HabitGroupListRemoteViewsFactory(applicationContext, intent)
    }
}
