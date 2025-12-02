package github.hunmer.memento.widgets.providers

import android.content.Intent
import android.widget.RemoteViewsService

/**
 * 快捷记账小组件的 RemoteViewsService
 * 提供可滚动的快捷预设列表
 */
class BillShortcutsWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return BillShortcutsRemoteViewsFactory(applicationContext, intent)
    }
}
