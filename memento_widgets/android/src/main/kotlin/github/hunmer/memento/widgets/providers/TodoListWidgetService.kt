package github.hunmer.memento.widgets.providers

import android.content.Context
import android.content.Intent
import android.widget.RemoteViewsService

/**
 * 待办列表小组件的 RemoteViewsService
 * 提供可滚动的任务列表
 */
class TodoListWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return TodoListRemoteViewsFactory(applicationContext, intent)
    }
}
