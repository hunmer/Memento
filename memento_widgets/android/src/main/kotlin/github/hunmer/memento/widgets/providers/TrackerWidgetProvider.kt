package github.hunmer.memento.widgets.providers

import github.hunmer.memento.widgets.BasePluginWidgetProvider

/**
 * 目标追踪小组件 - 1x1 尺寸
 */
class TrackerWidgetProvider : BasePluginWidgetProvider() {
    override val pluginId: String = "tracker"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_1X1
}

/**
 * 目标追踪小组件 - 2x2 尺寸
 */
class TrackerWidget2x1Provider : BasePluginWidgetProvider() {
    override val pluginId: String = "tracker"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_2X2
}
