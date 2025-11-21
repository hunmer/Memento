package github.hunmer.memento.widget.providers

import github.hunmer.memento.widget.BasePluginWidgetProvider

/**
 * 活动记录小组件 - 1x1 尺寸
 */
class ActivityWidgetProvider : BasePluginWidgetProvider() {
    override val pluginId: String = "activity"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_1X1
}

/**
 * 活动记录小组件 - 2x2 尺寸
 */
class ActivityWidget2x1Provider : BasePluginWidgetProvider() {
    override val pluginId: String = "activity"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_2X2
}
